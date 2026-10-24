"""mojo2cl: translate a Mojo GPU kernel's LLVM IR to OpenCL C, for Qualcomm's OpenCL compiler.

The phone's OpenCL 3.0 driver does not accept SPIR-V (no cl_khr_il_program;
clCreateProgramWithIL returns CL_INVALID_OPERATION), but it compiles OpenCL C. This tool turns
the (small, already optimized) kernel IR that Mojo emits into equivalent OpenCL C: one C
variable per SSA value, one label per basic block, phis resolved on the incoming edges.

The IR first gets the same SROA / instcombine / simplifycfg cleanup as in mojo2vk.py (Mojo's
--emit llvm is unoptimized; Qualcomm's compiler does the optimizing). Pointers are carried as
`__global uchar*` (or `__local uchar*` for shared memory) and offset in bytes, so typed and byte (i8)
GEPs work alike; loads and stores cast to the element type. Shared memory (addrspace(3) arrays)
becomes __local arrays, NVPTX bar.sync / AMDGPU s_barrier become barrier(). Thread indices:
  NVPTX tid/ctaid/ntid/nctaid -> get_local_id / get_group_id / get_local_size / get_num_groups
  AMDGPU workitem.id / workgroup.id, implicitarg block sizes / counts -> the same
  llvm.spv.thread.id(.in.group) / group.id (host-IR kernels) -> get_global_id / get_local_id / get_group_id

Warp ops (NVPTX shfl.sync / laneid on 32-lane segments; AMDGPU ds.bpermute / update.dpp / mbcnt on
64-lane waves) run on a virtual subgroup: lanes are local ids, and each shuffle goes through __local
memory between two barriers. Qualcomm's OpenCL has cl_khr_subgroups but no general shuffle, and this
keeps the lane layout independent of the driver's wave size. Needs a 1-D workgroup whose size is a
multiple of the warp width, with every work-item reaching each shuffle.

  mojo2cl.py kernel.ll [--kernel NAME] [--name vecadd] [--local 64] -o vecadd.cl
Supported: integer/float arithmetic, icmp/fcmp, select, casts, GEP, load/store, br, phi, ret, freeze,
min/max/abs/fma/sqrt intrinsics.
"""

import argparse
import pathlib
import re
import sys

from mojo2vk import kernel_def, optimize

CTYPE = {"i1": "int", "i8": "char", "i16": "short", "i32": "int", "i64": "long", "half": "half",
         "float": "float", "double": "double"}
UNSIGNED = {"i8": "uchar", "i16": "ushort", "i32": "uint", "i64": "ulong"}
SIZE = {"i8": 1, "i16": 2, "i32": 4, "i64": 8, "half": 2, "float": 4, "double": 8}
BINOP = {"add": "+", "sub": "-", "mul": "*", "shl": "<<", "and": "&", "or": "|", "xor": "^",
         "fadd": "+", "fsub": "-", "fmul": "*", "fdiv": "/", "sdiv": "/", "srem": "%", "frem": "%"}
UBINOP = {"udiv": "/", "urem": "%", "lshr": ">>"}
ICMP = {"eq": "==", "ne": "!=", "slt": "<", "sle": "<=", "sgt": ">", "sge": ">=",
        "ult": "<", "ule": "<=", "ugt": ">", "uge": ">="}
FCMP = {"oeq": "==", "one": "!=", "olt": "<", "ole": "<=", "ogt": ">", "oge": ">=",
        "ueq": "==", "une": "!=", "ult": "<", "ule": "<=", "ugt": ">", "uge": ">="}
CALLS = {
    "llvm.nvvm.read.ptx.sreg.tid": "get_local_id", "llvm.nvvm.read.ptx.sreg.ctaid": "get_group_id",
    "llvm.nvvm.read.ptx.sreg.ntid": "get_local_size", "llvm.nvvm.read.ptx.sreg.nctaid": "get_num_groups",
    "llvm.amdgcn.workitem.id": "get_local_id", "llvm.amdgcn.workgroup.id": "get_group_id",
}
# AMDGPU implicit kernel arguments (code object v5): byte offset -> (OpenCL query, dimension)
IMPLICITARG = {0: ("get_num_groups", 0), 4: ("get_num_groups", 1), 8: ("get_num_groups", 2),
               12: ("get_local_size", 0), 14: ("get_local_size", 1), 16: ("get_local_size", 2)}
MATH = {"smin": "min", "smax": "max", "umin": "min", "umax": "max", "minnum": "fmin", "maxnum": "fmax",
        "fabs": "fabs", "sqrt": "sqrt", "fma": "fma", "fmuladd": "fma", "abs": "abs"}
BARRIER = r"(?:tail )?call void @llvm\.(?:nvvm\.barrier0|nvvm\.barrier\.cta\.sync\.aligned\.all|nvvm\.barrier\.sync|amdgcn\.s\.barrier)\((?:i32 0)?\)"
LOCAL = {}  # shared-memory global -> C expression for its first byte
SPV_CALLS = {"llvm.spv.thread.id": "get_global_id", "llvm.spv.thread.id.in.group": "get_local_id",
             "llvm.spv.group.id": "get_group_id"}


def name(v):
    """SSA value / label -> C identifier."""
    return "v_" + v.lstrip("%").replace(".", "_").replace("-", "_")


def split_top(s):
    out, depth, cur = [], 0, ""
    for ch in s:
        if ch == "," and depth == 0:
            out.append(cur.strip())
            cur = ""
            continue
        depth += ch in "([{<"
        depth -= ch in ")]}>"
        cur += ch
    if cur.strip():
        out.append(cur.strip())
    return out


def val(v, ty=None):
    v = v.strip()
    if v.startswith("%"):
        return name(v)
    if v in LOCAL:
        return LOCAL[v]
    if v in ("true", "false"):
        return "1" if v == "true" else "0"
    if v in ("null", "zeroinitializer", "undef", "poison"):
        return "0"
    if ty == "float" and re.fullmatch(r"0x[0-9A-Fa-f]{16}", v):  # LLVM hex double for a float const
        import struct
        return repr(struct.unpack(">d", bytes.fromhex(v[2:]))[0]) + "f"
    if ty in ("float", "half") and re.fullmatch(r"-?\d+\.\d*e?[+-]?\d*", v):
        return v + "f"
    if ty == "i64" and re.fullmatch(r"-?\d+", v):
        return v + "L"
    return v


def dpp_src(ctrl):
    """Source lane of an AMDGPU DPP move -> (C expression, in-row-valid C expression or None)."""
    if ctrl <= 0xFF:  # quad_perm
        return f"((_lane & ~3u) | (({ctrl}u >> ((_lane & 3u) * 2u)) & 3u))", None
    if ctrl in (0x140, 0x141):  # row_mirror / row_half_mirror
        return f"(_lane ^ {15 if ctrl == 0x140 else 7}u)", None
    n = ctrl & 0xF
    if 0x121 <= ctrl <= 0x12F:  # row_ror:n, data moves right
        return f"((_lane & ~15u) | ((_lane + {16 - n}u) & 15u))", None
    if 0x101 <= ctrl <= 0x10F or 0x111 <= ctrl <= 0x11F:  # row_shl:n / row_shr:n
        d = n if ctrl < 0x110 else -n
        ok = f"((int)(_lane & 15u) + ({d}) >= 0 && (int)(_lane & 15u) + ({d}) < 16)"
        return f"({ok} ? (uint)((int)_lane + ({d})) : _lane)", ok
    sys.exit(f"unsupported DPP control 0x{ctrl:x}")


def shuffle(st, dst, ty, v, src):
    """dst = v of virtual-subgroup lane src, through __local memory."""
    st["shuffle"] = True
    return [f"_shf[_lane] = as_uint({v});", "barrier(CLK_LOCAL_MEM_FENCE);",
            f"{dst} = as_{CTYPE[ty]}(_shf[{src}]);", "barrier(CLK_LOCAL_MEM_FENCE);"]


def translate(ir, kernel, out_name, local=64):
    arglist, kbody = kernel_def(ir, kernel)
    params, decl_vars, lines = [], {}, []
    for a in split_top(arglist):
        ty, v = a.split()[0], a.split()[-1]
        params.append(f"__global uchar* {name(v)}" if ty == "ptr" else f"{CTYPE[ty]} {name(v)}")
    arrays = []  # shared memory: addrspace(3) arrays -> __local arrays
    for j, (g, n, t) in enumerate(re.findall(r"^(@[\w.$]+) = (?:internal |private |dso_local )*(?:unnamed_addr )?"
                                             r"addrspace\(3\) global \[(\d+) x (\w+)\]", ir, re.M)):
        if re.search(re.escape(g) + r"(?![\w.$])", kbody):
            LOCAL[g] = f"((__local uchar*)_shared{j})"
            arrays.append(f"  __local {CTYPE[t]} _shared{j}[{n}];")
    blocks, cur = [], None
    for raw in kbody.splitlines():
        line = re.sub(r";.*$", "", raw).rstrip()
        line = re.sub(r",\s*![\w.]+ !\d+", "", line)
        if not line.strip():
            continue
        lab = re.match(r"^([\w.$-]+):", line)
        if lab:
            cur = [lab.group(1), []]
            blocks.append(cur)
            continue
        if cur is None:  # unlabeled entry block: LLVM numbers it after the (numbered) arguments
            nargs = len(split_top(arglist))
            cur = [str(nargs) if all(re.search(r"%\d+$", x) for x in split_top(arglist)) else "entry", []]
            blocks.append(cur)
        cur[1].append(line.strip())

    phis = {}  # (pred label, succ label) -> [(dst var, value)]
    for lbl, ins in blocks:
        for i in ins:
            p = re.match(r"(%[\w.]+) = phi (?:fast |nnan |ninf |contract )*(\w+) (.*)$", i)
            if p:
                dst, ty, rest = p.groups()
                decl_vars[name(dst)] = (("__local" if rest.startswith("addrspace(3)") else "__global") + " uchar*"
                                        if ty == "ptr" else CTYPE[ty])
                for v, pred in re.findall(r"\[\s*([^,]+),\s*%([\w.$-]+)\s*\]", rest):
                    phis.setdefault((pred, lbl), []).append((name(dst), val(v, ty)))

    def emit_edge(src, dst):
        return [f"{d} = {v};" for d, v in phis.get((src, dst), [])] + [f"goto L_{dst.replace('.', '_')};"]

    body, state = [], {"implicit": {}, "shuffle": False, "barrier": bool(re.search(BARRIER, kbody))}
    for lbl, ins in blocks:
        body.append(f"L_{lbl.replace('.', '_')}:;")
        for i in ins:
            if re.match(r"%[\w.]+ = phi ", i):
                continue
            st = translate_inst(i, decl_vars, lbl, emit_edge, state)
            body.extend("  " + s for s in st)
    out = [f"// generated by mojo2cl.py from Mojo kernel @{kernel}"]
    if any(t == "half" for t in decl_vars.values()):
        out.append("#pragma OPENCL EXTENSION cl_khr_fp16 : enable")
    out.append(f"__kernel void {out_name}({', '.join(params)}) {{")
    out += arrays
    if state["shuffle"]:
        out += [f"  __local uint _shf[{local}];", "  uint _lane = (uint)get_local_id(0);"]
    for v, t in sorted(decl_vars.items()):
        out.append(f"  {t} {v};")
    out += body
    out.append("}")
    return "\n".join(out) + "\n"


def translate_inst(i, decl, lbl, edge, st):
    def d(dst, ty):  # ty: an LLVM type, or a C pointer type
        decl[name(dst)] = ty if ty.endswith("*") else "__global uchar*" if ty == "ptr" else CTYPE[ty]
        return name(dst)

    def space(asp):
        return "__local" if asp == "3" else "__global"
    if re.fullmatch(BARRIER, i):
        return ["barrier(CLK_LOCAL_MEM_FENCE | CLK_GLOBAL_MEM_FENCE);"]
    if re.fullmatch(r"fence syncscope\(\"workgroup\"\) \w+", i) and st["barrier"]:
        return []  # AMDGPU brackets s_barrier with workgroup fences; barrier() already fences
    # AMDGPU block sizes / counts: loads at fixed offsets from llvm.amdgcn.implicitarg.ptr
    m = re.match(r"(%[\w.]+) = (?:tail )?call (?:noundef )?(?:align \d+ )?ptr addrspace\(4\) @llvm\.amdgcn\.implicitarg\.ptr\(\)", i)
    if m:
        st["implicit"][m.group(1)] = 0
        return []
    m = re.match(r"(%[\w.]+) = getelementptr (?:inbounds |nuw |nusw )*(\w+), ptr addrspace\(4\) (%[\w.]+), i\d+ (\d+)$", i)
    if m and m.group(3) in st["implicit"]:
        st["implicit"][m.group(1)] = st["implicit"][m.group(3)] + int(m.group(4)) * SIZE[m.group(2)]
        return []
    m = re.match(r"(%[\w.]+) = load (\w+), ptr addrspace\(4\) (%[\w.]+)", i)
    if m and m.group(3) in st["implicit"]:
        dst, ty, p = m.groups()
        if st["implicit"][p] not in IMPLICITARG:
            sys.exit(f"unsupported implicit argument at byte {st['implicit'][p]}: {i}")
        fn, c = IMPLICITARG[st["implicit"][p]]
        return [f"{d(dst, ty)} = ({CTYPE[ty]}){fn}({c});"]
    # warp ops. NVPTX: 32-lane segments; AMDGPU: 64-lane waves
    m = re.match(r"(%[\w.]+) = (?:tail )?call (?:noundef )?(?:range\([^)]*\) )?i32 @llvm\.nvvm\.read\.ptx\.sreg\.laneid\(\)", i)
    if m:
        st["shuffle"] = True
        return [f"{d(m.group(1), 'i32')} = (int)(_lane & 31u);"]
    m = re.match(r"(%[\w.]+) = (?:tail )?call (?:\w+ )*(float|i32) @llvm\.nvvm\.shfl\.sync\.(bfly|down|up|idx)\.(?:f32|i32)\(i32 (-?\d+), (?:float|i32) ([^,]+), i32 ([^,]+), i32 (-?\d+)\)", i)
    if m:
        dst, ty, mode, mask, v, b, clamp = m.groups()
        if mask != "-1" or clamp != "31":
            sys.exit(f"unsupported shfl (partial mask or segment width): {i}")
        b = f"(uint)({val(b, 'i32')})"
        src = {"bfly": f"(_lane ^ ({b} & 31u))",
               "down": f"((_lane & 31u) + {b} <= 31u ? _lane + {b} : _lane)",
               "up": f"((_lane & 31u) >= {b} ? _lane - {b} : _lane)",
               "idx": f"((_lane & ~31u) | ({b} & 31u))"}[mode]
        return shuffle(st, d(dst, ty), ty, val(v, ty), src)
    m = re.match(r"(%[\w.]+) = (?:tail )?call (?:noundef )?i32 @llvm\.amdgcn\.mbcnt\.(lo|hi)\(i32 (-?\d+), i32 ([^)]+)\)", i)
    if m:  # with a full mask: lo = min(wave lane, 32), hi = max(wave lane - 32, 0)
        dst, half, mask, x = m.groups()
        if mask != "-1":
            sys.exit(f"unsupported mbcnt mask: {i}")
        st["shuffle"] = True
        c = "min(_lane & 63u, 32u)" if half == "lo" else "((_lane & 63u) > 32u ? (_lane & 63u) - 32u : 0u)"
        return [f"{d(dst, 'i32')} = {val(x, 'i32')} + (int){c};"]
    m = re.match(r"(%[\w.]+) = (?:tail )?call (?:noundef )?i32 @llvm\.amdgcn\.ds\.bpermute\(i32 ([^,]+), i32 ([^)]+)\)", i)
    if m:
        dst, addr, v = m.groups()
        src = f"((_lane & ~63u) | (((uint){val(addr, 'i32')} >> 2) & 63u))"
        return shuffle(st, d(dst, "i32"), "i32", val(v, "i32"), src)
    m = re.match(r"(%[\w.]+) = (?:tail )?call (?:noundef )?i32 @llvm\.amdgcn\.update\.dpp\.i32\(i32 ([^,]+), i32 ([^,]+), i32 (\d+), i32 (\d+), i32 (\d+), i1 (true|false)\)", i)
    if m:
        dst, old, v, ctrl, rmask, bmask, bound = m.groups()
        if rmask != "15" or bmask != "15":
            sys.exit(f"unsupported DPP row/bank mask: {i}")
        src, ok = dpp_src(int(ctrl))
        out = shuffle(st, d(dst, "i32"), "i32", val(v, "i32"), src)
        if ok:  # out-of-row lanes get 0 (bound_ctrl) or keep old
            out.append(f"if (!{ok}) {name(dst)} = {'0' if bound == 'true' else val(old, 'i32')};")
        return out
    m = re.match(r"(%[\w.]+) = (?:tail )?call (?:noundef )?(?:range\([^)]*\) )?(\w+) @([\w.]+)\((.*)\)", i)
    if m:
        dst, ty, fn, args = m.groups()
        base = re.sub(r"\.(x|y|z)$", "", fn)
        comp = {"x": 0, "y": 1, "z": 2}.get(fn.rsplit(".", 1)[-1], 0)
        if base in CALLS:
            return [f"{d(dst, ty)} = ({CTYPE[ty]}){CALLS[base]}({comp});"]
        spv = re.sub(r"\.i(32|64)$", "", fn)
        if spv in SPV_CALLS:
            c = int(re.search(r"i32 (\d+)", args).group(1))
            return [f"{d(dst, ty)} = ({CTYPE[ty]}){SPV_CALLS[spv]}({c});"]
        op = re.sub(r"^llvm\.|\.(?:[if]\d+)$", "", fn)
        if op in MATH:
            xs = [x.split() for x in split_top(args)]
            xs = [val(x[-1], x[0]) for x in xs if x[0] != "i1"]  # (abs: drop the is_int_min_poison flag)
            if op[0] == "u" or op == "abs":
                u = UNSIGNED[ty]
                xs = [f"({u}){x}" for x in xs] if op[0] == "u" else xs
                return [f"{d(dst, ty)} = ({CTYPE[ty]}){MATH[op]}({', '.join(xs)});"]
            return [f"{d(dst, ty)} = {MATH[op]}({', '.join(xs)});"]
        sys.exit(f"unsupported call: {i}")
    m = re.match(r"(%[\w.]+) = getelementptr (?:inbounds |nuw |nusw )*(\w+), ptr(?: addrspace\((\d+)\))? ([%@][\w.$]+), (i\d+) (\S+)$", i)
    if m:
        dst, ety, asp, base, ity, idx = m.groups()
        return [f"{d(dst, space(asp) + ' uchar*')} = {val(base)} + ({val(idx, ity)}) * {SIZE[ety]};"]
    m = re.match(r"(%[\w.]+) = load (?:volatile )?(\w+), ptr(?: addrspace\((\d+)\))? ([%@][\w.$]+)", i)
    if m:
        dst, ty, asp, p = m.groups()
        return [f"{d(dst, ty)} = *({space(asp)} {CTYPE[ty]}*)({val(p)});"]
    m = re.match(r"store (?:volatile )?(\w+) ([^,]+), ptr(?: addrspace\((\d+)\))? ([%@][\w.$]+)", i)
    if m:
        ty, v, asp, p = m.groups()
        return [f"*({space(asp)} {CTYPE[ty]}*)({val(p)}) = {val(v, ty)};"]
    m = re.match(r"(%[\w.]+) = freeze (\w+) (\S+)$", i)
    if m:
        dst, ty, v = m.groups()
        return [f"{d(dst, ty)} = {val(v, ty)};"]
    m = re.match(r"(%[\w.]+) = (\w+) (?:nuw |nsw |exact |disjoint |fast |nnan |ninf |contract |reassoc |afn |arcp )*(\w+) ([^,]+), (.+)$", i)
    if m and (m.group(2) in BINOP or m.group(2) in UBINOP or m.group(2) == "ashr"):
        dst, op, ty, a, b = m.groups()
        if op in UBINOP:
            u = UNSIGNED[ty]
            return [f"{d(dst, ty)} = ({CTYPE[ty]})(({u}){val(a, ty)} {UBINOP[op]} ({u}){val(b, ty)});"]
        if op == "ashr":
            return [f"{d(dst, ty)} = {val(a, ty)} >> {val(b, ty)};"]
        return [f"{d(dst, ty)} = {val(a, ty)} {BINOP[op]} {val(b, ty)};"]
    m = re.match(r"(%[\w.]+) = icmp (?:samesign )?(\w+) (\w+) ([^,]+), (.+)$", i)
    if m:
        dst, pred, ty, a, b = m.groups()
        if pred.startswith("u") and ty in UNSIGNED:
            u = UNSIGNED[ty]
            return [f"{d(dst, 'i1')} = ({u}){val(a, ty)} {ICMP[pred]} ({u}){val(b, ty)};"]
        return [f"{d(dst, 'i1')} = {val(a, ty)} {ICMP[pred]} {val(b, ty)};"]
    m = re.match(r"(%[\w.]+) = fcmp (?:fast |nnan |ninf |contract )*(\w+) (\w+) ([^,]+), (.+)$", i)
    if m:
        dst, pred, ty, a, b = m.groups()
        return [f"{d(dst, 'i1')} = {val(a, ty)} {FCMP[pred]} {val(b, ty)};"]
    m = re.match(r"(%[\w.]+) = select (?:\w+ )*i1 ([^,]+), (\w+) ([^,]+), \w+ (.+)$", i)
    if m:
        dst, c, ty, a, b = m.groups()
        return [f"{d(dst, ty)} = {val(c)} ? {val(a, ty)} : {val(b, ty)};"]
    m = re.match(r"(%[\w.]+) = (zext|sext|trunc|sitofp|uitofp|fptosi|fptoui|fpext|fptrunc|bitcast)(?: nneg| nuw| nsw)* (\w+) (\S+) to (\w+)$", i)
    if m:
        dst, op, sty, v, dty = m.groups()
        if op == "zext" and sty in UNSIGNED:
            return [f"{d(dst, dty)} = ({CTYPE[dty]})({UNSIGNED[sty]}){val(v, sty)};"]
        if op == "zext":  # i1
            return [f"{d(dst, dty)} = ({CTYPE[dty]})({val(v, sty)} != 0);"]
        if op == "bitcast":
            return [f"{d(dst, dty)} = as_{CTYPE[dty]}({val(v, sty)});"]
        return [f"{d(dst, dty)} = ({CTYPE[dty]}){val(v, sty)};"]
    m = re.match(r"br i1 ([^,]+), label %([\w.$-]+), label %([\w.$-]+)$", i)
    if m:
        c, t, f = m.groups()
        return [f"if ({val(c)}) {{ {' '.join(edge(lbl, t))} }} else {{ {' '.join(edge(lbl, f))} }}"]
    m = re.match(r"br label %([\w.$-]+)$", i)
    if m:
        return edge(lbl, m.group(1))
    if i == "ret void":
        return ["return;"]
    sys.exit(f"unsupported instruction: {i}")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("ir")
    ap.add_argument("--kernel", default=None)
    ap.add_argument("--name", default="vecadd", help="name of the OpenCL kernel to emit")
    ap.add_argument("--local", type=int, default=64, help="workgroup size (sizes the __local shuffle buffer)")
    ap.add_argument("-o", "--out", required=True)
    a = ap.parse_args()
    ir = optimize(pathlib.Path(a.ir).read_text(), "none")
    kernel = a.kernel
    if kernel is None:
        defs = re.findall(r"^define\s+[^@]*?void\s+@\"?([\w.$]+)\"?\(", ir, re.M)
        if len(defs) != 1:
            sys.exit(f"pick --kernel among {defs}")
        kernel = defs[0]
    src = translate(ir, kernel, a.name, a.local)
    pathlib.Path(a.out).write_text(src)
    print(f"kernel: {kernel} -> {a.out}")


if __name__ == "__main__":
    main()
