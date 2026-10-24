"""mojo2cl: translate a Mojo GPU kernel's LLVM IR to OpenCL C, for Qualcomm's OpenCL compiler.

The phone's OpenCL 3.0 driver does not accept SPIR-V (no cl_khr_il_program;
clCreateProgramWithIL returns CL_INVALID_OPERATION), but it compiles OpenCL C. This tool turns
the (small, already optimized) kernel IR that Mojo emits into equivalent OpenCL C: one C
variable per SSA value, one label per basic block, phis resolved on the incoming edges.

Pointers are carried as `__global uchar*` and offset in bytes, so typed and byte (i8) GEPs work
alike; loads and stores cast to the element type. Thread indices:
  NVPTX tid/ctaid/ntid/nctaid -> get_local_id / get_group_id / get_local_size / get_num_groups
  llvm.spv.thread.id(.in.group) / group.id (host-IR kernels) -> get_global_id / get_local_id / get_group_id

  mojo2cl.py kernel.ll [--kernel NAME] [--name vecadd] -o vecadd.cl
Supported: integer/float arithmetic, icmp/fcmp, select, casts, GEP, load/store, br, phi, ret.
"""

import argparse
import pathlib
import re
import sys

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
}
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


def translate(ir, kernel, out_name):
    m = re.search(r"^define\s+[^@]*?void\s+@\"?" + re.escape(kernel) + r"\"?\((.*?)\)[^{]*\{\n(.*?)^\}", ir, re.S | re.M)
    if not m:
        sys.exit(f"kernel @{kernel} not found")
    params, decl_vars, lines = [], {}, []
    for a in split_top(m.group(1)):
        ty, v = a.split()[0], a.split()[-1]
        params.append(f"__global uchar* {name(v)}" if ty == "ptr" else f"{CTYPE[ty]} {name(v)}")
    blocks, cur = [], None
    for raw in m.group(2).splitlines():
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
            nargs = len(split_top(m.group(1)))
            cur = [str(nargs) if all(re.search(r"%\d+$", x) for x in split_top(m.group(1))) else "entry", []]
            blocks.append(cur)
        cur[1].append(line.strip())

    phis = {}  # (pred label, succ label) -> [(dst var, value)]
    for lbl, ins in blocks:
        for i in ins:
            p = re.match(r"(%[\w.]+) = phi (?:fast |nnan |ninf |contract )*(\w+) (.*)$", i)
            if p:
                dst, ty, rest = p.groups()
                decl_vars[name(dst)] = CTYPE.get(ty, "__global uchar*") if ty != "ptr" else "__global uchar*"
                for v, pred in re.findall(r"\[\s*([^,]+),\s*%([\w.$-]+)\s*\]", rest):
                    phis.setdefault((pred, lbl), []).append((name(dst), val(v, ty)))

    def emit_edge(src, dst):
        return [f"{d} = {v};" for d, v in phis.get((src, dst), [])] + [f"goto L_{dst.replace('.', '_')};"]

    body = []
    for lbl, ins in blocks:
        body.append(f"L_{lbl.replace('.', '_')}:;")
        for i in ins:
            if re.match(r"%[\w.]+ = phi ", i):
                continue
            st = translate_inst(i, decl_vars, lbl, emit_edge)
            body.extend("  " + s for s in st)
    out = [f"// generated by mojo2cl.py from Mojo kernel @{kernel}"]
    if any(t == "half" for t in decl_vars.values()):
        out.append("#pragma OPENCL EXTENSION cl_khr_fp16 : enable")
    out.append(f"__kernel void {out_name}({', '.join(params)}) {{")
    for v, t in sorted(decl_vars.items()):
        out.append(f"  {t} {v};")
    out += body
    out.append("}")
    return "\n".join(out) + "\n"


def translate_inst(i, decl, lbl, edge):
    def d(dst, ty):
        decl[name(dst)] = "__global uchar*" if ty == "ptr" else CTYPE[ty]
        return name(dst)
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
        sys.exit(f"unsupported call: {i}")
    m = re.match(r"(%[\w.]+) = getelementptr (?:inbounds |nuw |nusw )*(\w+), ptr(?: addrspace\(\d+\))? (%[\w.]+), (i\d+) (\S+)$", i)
    if m:
        dst, ety, base, ity, idx = m.groups()
        return [f"{d(dst, 'ptr')} = {val(base)} + ({val(idx, ity)}) * {SIZE[ety]};"]
    m = re.match(r"(%[\w.]+) = load (?:volatile )?(\w+), ptr(?: addrspace\(\d+\))? (%[\w.]+)", i)
    if m:
        dst, ty, p = m.groups()
        return [f"{d(dst, ty)} = *(__global {CTYPE[ty]}*)({val(p)});"]
    m = re.match(r"store (?:volatile )?(\w+) ([^,]+), ptr(?: addrspace\(\d+\))? (%[\w.]+)", i)
    if m:
        ty, v, p = m.groups()
        return [f"*(__global {CTYPE[ty]}*)({val(p)}) = {val(v, ty)};"]
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
    m = re.match(r"(%[\w.]+) = (zext|sext|trunc|sitofp|uitofp|fptosi|fptoui|fpext|fptrunc|bitcast) (?:nneg )?(\w+) (\S+) to (\w+)$", i)
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
    ap.add_argument("-o", "--out", required=True)
    a = ap.parse_args()
    ir = pathlib.Path(a.ir).read_text()
    kernel = a.kernel
    if kernel is None:
        defs = re.findall(r"^define\s+[^@]*?void\s+@\"?([\w.$]+)\"?\(", ir, re.M)
        if len(defs) != 1:
            sys.exit(f"pick --kernel among {defs}")
        kernel = defs[0]
    src = translate(ir, kernel, a.name)
    pathlib.Path(a.out).write_text(src)
    print(f"kernel: {kernel} -> {a.out}")


if __name__ == "__main__":
    main()
