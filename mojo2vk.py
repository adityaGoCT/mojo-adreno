"""mojo2vk: retarget a Mojo GPU kernel's LLVM IR to a Vulkan compute shader (SPIR-V) for Adreno.

Mojo 1.2 has no SPIR-V/Vulkan GPU target, but it emits LLVM IR for its kernels, and LLVM 22's
SPIR-V backend can produce Vulkan compute shaders. What differs is the kernel ABI: Mojo kernels
take raw pointers and read CUDA-style thread registers; Vulkan shaders have no arguments, reach
memory through descriptor-bound storage buffers (logical addressing, no raw pointers) and read
SPIR-V builtins. This tool rewrites one kernel function:

  pointer arg k          -> storage buffer at (set 0, binding k): llvm.spv.resource.handlefrombinding
  gep T, ptr %arg_k, idx -> llvm.spv.resource.getpointer(handle_k, idx)   (ptr addrspace(11))
  load/store through it  -> addrspace(11) (SPIR-V StorageBuffer)
  scalar arg j           -> int64 slot j of a params storage buffer at binding <#pointer args>
  NVPTX tid/ctaid/nctaid -> SPIR-V LocalInvocationId / WorkgroupId / NumWorkgroups; ntid -> the local size
  AMDGPU workitem.id / workgroup.id, implicitarg block sizes / counts -> the same
  warp ops               -> OpGroupNonUniformShuffle (llvm.spv.wave.readlane) on the subgroup lane:
    NVPTX shfl.sync.{bfly,down,up,idx} (full mask, 32-lane segments), laneid
    AMDGPU ds.bpermute, update.dpp (quad_perm, row_shl/shr/ror, row_mirror, row_half_mirror), mbcnt
    (64-lane waves); correct whenever the hardware subgroup is a multiple of the warp size
  (host-IR kernels may call llvm.spv.thread.id etc. directly; those pass through)

Mojo's --emit llvm is unoptimized IR, so the kernel first goes through a target-neutral opt -O3
(--opt none: only the SROA / instcombine / simplifycfg cleanup that removes allocas and aggregates).
Shared memory (addrspace(3) arrays) becomes Workgroup variables; barriers become OpControlBarrier.
Logical addressing has no pointer arithmetic, so every pointer is tracked as (buffer or shared array,
element index) through GEP chains. Then the Vulkan triple, hlsl.shader="compute" + hlsl.numthreads,
and llc (without loop strength reduction, which would build pointer induction variables).

  mojo2vk.py kernel.ll --kernel vecadd --local 64 -o vecadd.spv
"""

import argparse
import os
import pathlib
import re
import subprocess
import sys

LLVM = pathlib.Path(os.environ.get("LLVM_BIN", "/opt/homebrew/opt/llvm/bin"))  # llc with the SPIR-V backend (LLVM >= 22)
DATALAYOUT = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024-n8:16:32:64-G10"
TRIPLE = "spirv1.6-unknown-vulkan1.3-compute"
MANGLE = {"float": "f32", "half": "f16", "double": "f64", "i8": "i8", "i16": "i16", "i32": "i32", "i64": "i64"}
SIZE = {"float": 4, "half": 2, "double": 8, "i8": 1, "i16": 2, "i32": 4, "i64": 8}
NVPTX_REG = {  # NVPTX special registers -> SPIR-V intrinsic (ntid: the local-size constant)
    "tid": "llvm.spv.thread.id.in.group", "ctaid": "llvm.spv.group.id", "nctaid": "llvm.spv.num.workgroups",
    "ntid": None}
AMD_ID = {"workitem": "llvm.spv.thread.id.in.group", "workgroup": "llvm.spv.group.id"}
# AMDGPU implicit kernel arguments (code object v5): byte offset -> (NVPTX-style register, component)
IMPLICITARG = {0: ("nctaid", 0), 4: ("nctaid", 1), 8: ("nctaid", 2), 12: ("ntid", 0), 14: ("ntid", 1), 16: ("ntid", 2)}
LANE = "llvm.spv.subgroup.local.invocation.id"


def dpp_src(r, ctrl, lane):
    """IR computing the source lane of an AMDGPU DPP move -> (lines, src, in-row-valid flag or None)."""
    if ctrl <= 0xFF:  # quad_perm: lane reads (lane & ~3) | perm[lane & 3]
        return [f"  {r}.q = and i32 {lane}, 3", f"  {r}.qs = shl i32 {r}.q, 1", f"  {r}.qp = lshr i32 {ctrl}, {r}.qs",
                f"  {r}.p = and i32 {r}.qp, 3", f"  {r}.qb = and i32 {lane}, -4", f"  {r}.src = or i32 {r}.qb, {r}.p"], f"{r}.src", None
    if ctrl in (0x140, 0x141):  # row_mirror (15 - x) / row_half_mirror (7 - x)
        return [f"  {r}.src = xor i32 {lane}, {15 if ctrl == 0x140 else 7}"], f"{r}.src", None
    n = ctrl & 0xF
    if 0x121 <= ctrl <= 0x12F:  # row_ror:n, data moves right: lane reads (lane - n) mod 16 within its row
        return [f"  {r}.rb = and i32 {lane}, -16", f"  {r}.ra = add i32 {lane}, {16 - n}", f"  {r}.rr = and i32 {r}.ra, 15",
                f"  {r}.src = or i32 {r}.rb, {r}.rr"], f"{r}.src", None
    if 0x101 <= ctrl <= 0x10F or 0x111 <= ctrl <= 0x11F:  # row_shl:n (reads lane + n) / row_shr:n (lane - n)
        d = n if ctrl < 0x110 else -n
        return [f"  {r}.rx = and i32 {lane}, 15", f"  {r}.ry = add i32 {r}.rx, {d}", f"  {r}.ok = icmp ult i32 {r}.ry, 16",
                f"  {r}.sc = add i32 {lane}, {d}", f"  {r}.src = select i1 {r}.ok, i32 {r}.sc, i32 {lane}"], f"{r}.src", f"{r}.ok"
    sys.exit(f"unsupported DPP control 0x{ctrl:x}")


def split_args(s):
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


SAT = re.compile(r"^(\s*)(%[\w.]+) = (?:tail )?call (i\d+) @llvm\.(usub|uadd)\.sat\.i\d+\(i\d+ ([^,]+), i\d+ ([^)]+)\)\s*$", re.M)


def legalize(text):
    """Expand intrinsics that opt forms but LLVM 22's SPIR-V backend cannot select (saturating add/sub)."""
    def expand(m):
        ind, r, ty, op, x, y = m.groups()
        if op == "usub":
            return f"{ind}{r}.d = sub {ty} {x}, {y}\n{ind}{r}.c = icmp ugt {ty} {x}, {y}\n{ind}{r} = select i1 {r}.c, {ty} {r}.d, {ty} 0"
        return f"{ind}{r}.s = add {ty} {x}, {y}\n{ind}{r}.c = icmp ult {ty} {r}.s, {x}\n{ind}{r} = select i1 {r}.c, {ty} -1, {ty} {r}.s"
    return SAT.sub(expand, text)


def handle_type(elem):
    return f'target("spirv.VulkanBuffer", [0 x {elem}], 12, 1)'


def handle_suffix(elem):
    return f"tspirv.VulkanBuffer_a0{MANGLE[elem]}_12_1t"


def narrow_i64(body):
    """Rewrite 64-bit integer arithmetic to 32 bits (for drivers without shaderInt64, e.g. the stock
    Adreno Vulkan 1.1 driver). Valid while every index and length fits in int32; constants outside
    int32 (overflow guards such as INT64_MAX - 15) are clamped to its range."""
    body = re.sub(r"\brange\([^)]*\)\s*", "", body)  # value-range hints would not survive the clamp
    body = re.sub(r"\bi64\b", "i32", body)
    body = re.sub(r"(%[\w.]+) = (?:zext|sext|trunc)(?: nneg| nuw| nsw)* i32 (%[\w.]+|-?\d+) to i32", r"\1 = add i32 \2, 0", body)
    clamp = lambda m: str(min(max(int(m.group(0)), -2**31), 2**31 - 1))  # noqa: E731
    return re.sub(r"(?<![\w.%@$+-])-?\d{10,}(?![\w.])", clamp, body)


def optimize(ir, level="O3"):
    """opt on Mojo's unoptimized kernel IR, before retargeting. Even level "none" runs SROA +
    instcombine + simplifycfg: they remove the allocas, Optional aggregates and lifetime markers that
    iterators leave behind. Vectorizers are off. The triple is dropped so that only target-independent rewrites happen
    (Homebrew LLVM 22 also cannot parse Mojo's amdgpu9.0a triple)."""
    # no vectorizers: they fuse register tiles into <16 x float> math (Vulkan vectors stop at 4 lanes),
    # and the drivers' compilers vectorize for the real hardware anyway
    passes = (["-passes=sroa,instcombine<no-verify-fixpoint>,simplifycfg"] if level == "none"
              else [f"-{level}", "-vectorize-slp=false", "-vectorize-loops=false"])
    r = subprocess.run([str(LLVM / "opt"), *passes, "-S", "-o", "-"],
                       input=re.sub(r"^target triple = .*$", "", ir, flags=re.M), capture_output=True, text=True)
    if r.returncode:
        sys.exit("opt failed:\n" + r.stderr)
    return r.stdout


def fix_barriers(spv, env):
    """LLVM 22 lowers llvm.spv.group.memory.barrier.with.group.sync to OpControlBarrier with
    SequentiallyConsistent semantics and no storage class, which Vulkan forbids. Use AcquireRelease |
    UniformMemory | WorkgroupMemory (0x148): like NVPTX bar.sync, it orders shared and global memory."""
    dis = subprocess.run(["spirv-dis", str(spv)], capture_output=True, text=True).stdout
    if "OpControlBarrier" not in dis:
        return
    sem, out = "%barrier_semantics", []
    for line in dis.splitlines():
        line = re.sub(r"^(\s*OpControlBarrier %\S+ %\S+) %\S+\s*$", rf"\1 {sem}", line)
        out.append(line)
        if re.match(r"\s*%uint = OpTypeInt 32 0\s*$", line):
            out.append(f"{sem} = OpConstant %uint 328")
    r = subprocess.run(["spirv-as", "--target-env", env, "-o", str(spv), "-"], input="\n".join(out) + "\n",
                       capture_output=True, text=True)
    if r.returncode:
        sys.exit("spirv-as (barrier fix) failed:\n" + r.stderr)


def kernel_def(ir, kernel):
    """(argument list, body) of `define ... void @kernel(...)`; argument attributes such as
    captures(none) contain parentheses, so the argument list is matched by depth."""
    m = re.search(r"^define\s+[^@\n]*?void\s+@\"?" + re.escape(kernel) + r"\"?\(", ir, re.M)
    if not m:
        sys.exit(f"kernel @{kernel} not found")
    i, depth = m.end(), 1
    while depth:
        depth += {"(": 1, ")": -1}.get(ir[i], 0)
        i += 1
    return ir[m.end():i - 1], re.compile(r"\{\n(.*?)^\}", re.S | re.M).search(ir, i).group(1)


def retarget(ir, kernel, local, i32=False, triple=TRIPLE, pad_shared=False):
    arglist, body = kernel_def(ir, kernel)
    # numbered values/labels must count from %0 inside a function; ours lose their args and gain
    # a prologue, so give every numbered value and label a name
    num = lambda s: re.sub(r"%(\d+)\b", r"%v\1", s)  # noqa: E731
    args = [num(a) for a in split_args(arglist)]
    body = re.sub(r"^(\d+):", r"v\1:", num(body), flags=re.M)
    # the kernel's unlabeled entry block is implicitly numbered after its arguments (%0..%k-1 ->
    # block %k); phis name it, so the original body must start under that label
    entry = f"v{len(args)}" if all(re.search(r"%v\d+$", x) for x in args) else "body"
    # shared memory: module-level addrspace(3) arrays -> Workgroup variables @shared.j
    shared, gvars = {}, []
    for j, (g, n, t, al) in enumerate(re.findall(
            r"^(@[\w.$]+) = (?:internal |private |dso_local )*(?:unnamed_addr )?addrspace\(3\) global "
            r"\[(\d+) x (\w+)\] (?:undef|poison|zeroinitializer)(?:, align (\d+))?", ir, re.M)):
        if re.search(re.escape(g) + r"(?![\w.$])", body):
            body = re.sub(re.escape(g) + r"(?![\w.$])", f"@shared.{j}", body)
            shared[f"@shared.{j}"] = (int(n), "i32" if i32 and t == "i64" else t)
            # Qualcomm's Vulkan driver overlaps two 16-bit shared arrays (a[N/2 + j] aliases b[j]); padding
            # each sub-32-bit array to 4 bytes per element avoids it (indices stay below N)
            size = int(n) * max(1, 4 // SIZE[t]) if pad_shared and t in SIZE else int(n)
            gvars.append(f"@shared.{j} = internal addrspace(3) global [{size} x {shared[f'@shared.{j}'][1]}] poison, align {al or 4}")
            shared[f"@shared.{j}"] = (size, shared[f"@shared.{j}"][1])
    # barriers: NVPTX bar.sync / AMDGPU s_barrier (with its workgroup fences) -> one control barrier
    barrier = r"call void @llvm\.(?:nvvm\.barrier0|nvvm\.barrier\.cta\.sync\.aligned\.all|nvvm\.barrier\.sync|amdgcn\.s\.barrier)\((?:i32 0)?\)"
    if re.search(barrier, body):
        body = re.sub(r"^\s*fence syncscope\(\"workgroup\"\) \w+\s*$\n?", "", body, flags=re.M)
        body = re.sub(r"(?:tail )?" + barrier, "call void @llvm.spv.group.memory.barrier.with.group.sync()", body)
    if i32:
        body = narrow_i64(body)
        args = [re.sub(r"\bi64\b", "i32", x) for x in args]
    ptr_args, scalar_args = [], []
    for a in args:
        name = a.split()[-1]
        if a.startswith("ptr"):
            ptr_args.append(name)
        else:
            scalar_args.append((a.split()[0], name))

    # element type of each pointer arg: from typed GEPs and loads / stores on it or on pointers derived from it
    root = {p: p for p in ptr_args}
    for _ in range(2):  # GEP chains may be defined out of text order across blocks
        for res, base in re.findall(r"(%[\w.]+) = getelementptr [^,]*, ptr(?: addrspace\(\d+\))? (%[\w.]+),", body):
            if base in root:
                root[res] = root[base]
    elem = {}
    for p in ptr_args:
        mine = "|".join(re.escape(q) for q, r in root.items() if r == p)
        t = re.findall(r"getelementptr (?:inbounds |nuw |nusw )*(\w+), ptr(?: addrspace\(\d+\))? (?:" + mine + r"),", body)
        t += re.findall(r"load (\w+), ptr(?: addrspace\(\d+\))? (?:" + mine + r")\b", body)
        t += re.findall(r"store (\w+) [^,]+, ptr(?: addrspace\(\d+\))? (?:" + mine + r")\b", body)
        t = [x for x in t if x != "i8"] or t
        elem[p] = t[0] if t else "float"

    pro, decls, names = [], set(), []  # names: the backend needs a name string per resource (null crashes llc 22)
    sb = set()  # values that now point into a storage buffer
    for k, p in enumerate(ptr_args):
        e = elem[p]
        hs = handle_suffix(e)
        pro.append(f"  %h.{k} = call {handle_type(e)} @llvm.spv.resource.handlefrombinding.{hs}(i32 0, i32 {k}, i32 1, i32 0, ptr @.buf{k})")
        names.append(f'@.buf{k} = private unnamed_addr constant [{len(str(k)) + 4} x i8] c"buf{k}\\00"')
        decls.add(f"declare {handle_type(e)} @llvm.spv.resource.handlefrombinding.{hs}(i32, i32, i32, i32, ptr)")
        decls.add(f"declare ptr addrspace(11) @llvm.spv.resource.getpointer.p11.{hs}({handle_type(e)}, i32)")
    pbind = len(ptr_args)
    if scalar_args and i32:
        hs = handle_suffix("i32")
        pro.append(f"  %h.params = call {handle_type('i32')} @llvm.spv.resource.handlefrombinding.{hs}(i32 0, i32 {pbind}, i32 1, i32 0, ptr @.params)")
        names.append('@.params = private unnamed_addr constant [7 x i8] c"params\\00"')
        decls.add(f"declare {handle_type('i32')} @llvm.spv.resource.handlefrombinding.{hs}(i32, i32, i32, i32, ptr)")
        decls.add(f"declare ptr addrspace(11) @llvm.spv.resource.getpointer.p11.{hs}({handle_type('i32')}, i32)")
        for j, (ty, name) in enumerate(scalar_args):  # slot j = int64; its low word is int32 index 2j
            pro.append(f"  %sp.{j} = call ptr addrspace(11) @llvm.spv.resource.getpointer.p11.{hs}({handle_type('i32')} %h.params, i32 {2 * j})")
            if ty == "float":
                pro.append(f"  %sv.{j} = load i32, ptr addrspace(11) %sp.{j}, align 4")
                pro.append(f"  {name} = bitcast i32 %sv.{j} to float")
            else:
                pro.append(f"  {name} = load i32, ptr addrspace(11) %sp.{j}, align 4")
    elif scalar_args:
        hs = handle_suffix("i64")
        pro.append(f"  %h.params = call {handle_type('i64')} @llvm.spv.resource.handlefrombinding.{hs}(i32 0, i32 {pbind}, i32 1, i32 0, ptr @.params)")
        names.append('@.params = private unnamed_addr constant [7 x i8] c"params\\00"')
        decls.add(f"declare {handle_type('i64')} @llvm.spv.resource.handlefrombinding.{hs}(i32, i32, i32, i32, ptr)")
        decls.add(f"declare ptr addrspace(11) @llvm.spv.resource.getpointer.p11.{hs}({handle_type('i64')}, i32)")
        for j, (ty, name) in enumerate(scalar_args):
            pro.append(f"  %sp.{j} = call ptr addrspace(11) @llvm.spv.resource.getpointer.p11.{hs}({handle_type('i64')} %h.params, i32 {j})")
            pro.append(f"  %sv.{j} = load i64, ptr addrspace(11) %sp.{j}, align 8")
            if ty == "i64":
                pro.append(f"  {name} = add i64 %sv.{j}, 0")
            elif ty.startswith("i"):
                pro.append(f"  {name} = trunc i64 %sv.{j} to {ty}")
            elif ty == "float":
                pro.append(f"  %sv32.{j} = trunc i64 %sv.{j} to i32")
                pro.append(f"  {name} = bitcast i32 %sv32.{j} to float")
            else:
                sys.exit(f"unsupported scalar argument type {ty}")

    def lane(res):  # this invocation's index in its subgroup
        decls.add(f"declare i32 @{LANE}()")
        return f"  {res}.lane = call i32 @{LANE}()"

    def readlane(res, ty, val, src):  # OpGroupNonUniformShuffle
        m = {"float": "f32", "i32": "i32"}[ty]
        decls.add(f"declare {ty} @llvm.spv.wave.readlane.{m}({ty}, i32)")
        return f"  {res} = call {ty} @llvm.spv.wave.readlane.{m}({ty} {val}, i32 {src})"

    out = []
    implicit, consts = {}, {}  # AMDGPU implicitarg pointers -> byte offset; folded loads -> constant
    # logical addressing has no pointer arithmetic: every pointer into a buffer or a shared array is
    # tracked as (buffer k or @shared.j, i32 element index or None for element 0)
    ptrs = {p: (k, None) for k, p in enumerate(ptr_args)}
    ptrs.update({g: (g, None) for g in shared})
    for line in body.splitlines():
        line = re.sub(r",\s*![\w.]+ !\d+", "", line)  # drop metadata attachments
        line = re.sub(r"\s+#\d+\s*$", "", line)          # drop attribute-group refs on calls
        if consts:
            line = re.sub(r"%[\w.]+(?![\w.])", lambda v: consts.get(v.group(0), v.group(0)), line)
            line = re.sub(r"^(\s*%[\w.]+) = (?:zext|sext) (?:nneg )?i\d+ (-?\d+) to (i\d+)\s*$", r"\1 = add \3 0, \2", line)
        g = re.match(r"\s*(%[\w.]+) = getelementptr (?:inbounds |nuw |nusw )*(\w+), ptr(?: addrspace\(\d+\))? ([%@][\w.$]+), (i64|i32) (%[\w.]+|-?\d+)\s*$", line)
        if g and g.group(3) in ptrs:
            res, gty, base, ity, idx = g.groups()
            k, bidx = ptrs[base]
            e = shared[k][1] if k in shared else elem[ptr_args[k]]
            if gty == "i8" and e != "i8":  # byte offset -> element index
                sh = SIZE[e].bit_length() - 1
                if idx.lstrip("-").isdigit():
                    idx = str(int(idx) >> sh)
                else:
                    out.append(f"  {res}.ei = ashr exact {ity} {idx}, {sh}")
                    idx = f"{res}.ei"
            elif gty != e and gty in SIZE and SIZE[gty] % SIZE[e] == 0:  # e.g. i64 steps over i32 elements
                out.append(f"  {res}.ei = mul {ity} {idx}, {SIZE[gty] // SIZE[e]}")
                idx = f"{res}.ei"
            elif gty != e:
                sys.exit(f"unsupported GEP element type {gty} on {base} (elements of {e})")
            if ity == "i64" and not idx.lstrip("-").isdigit():
                out.append(f"  {res}.i32 = trunc i64 {idx} to i32")
                idx = f"{res}.i32"
            if bidx is not None:  # GEP chain: offsets add up
                out.append(f"  {res}.ix = add i32 {bidx}, {idx}")
                idx = f"{res}.ix"
            ptrs[res] = (k, idx)
            if k in shared:
                out.append(f"  {res} = getelementptr inbounds [{shared[k][0]} x {e}], ptr addrspace(3) {k}, i32 0, i32 {idx}")
            else:
                out.append(f"  {res} = call ptr addrspace(11) @llvm.spv.resource.getpointer.p11.{handle_suffix(e)}({handle_type(e)} %h.{k}, i32 {idx})")
                sb.add(res)
            continue
        if re.match(r"\s*%[\w.]+ = (?:phi|select)\b.*\bptr\b", line) and any(
                re.search(re.escape(p) + r"(?![\w.$])", line) for p in ptrs):
            sys.exit(f"unsupported pointer phi/select (logical addressing): {line.strip()}")
        r = re.match(r"\s*(%[\w.]+) = (?:tail )?call (?:noundef )?(?:range\([^)]*\) )?i32 @llvm\.nvvm\.read\.ptx\.sreg\.(tid|ctaid|nctaid|ntid)\.([xyz])\(\)", line)
        r = r or re.match(r"\s*(%[\w.]+) = (?:tail )?call (?:noundef )?(?:range\([^)]*\) )?i32 @llvm\.amdgcn\.(workitem|workgroup)\.id\.([xyz])\(\)", line)
        if r:
            res, reg, comp = r.groups()
            c = "xyz".index(comp)
            if reg == "ntid":
                out.append(f"  {res} = add i32 0, {local[c]}")
            else:
                fn = AMD_ID.get(reg) or NVPTX_REG[reg]
                out.append(f"  {res} = call i32 @{fn}.i32(i32 {c})")
                decls.add(f"declare i32 @{fn}.i32(i32)")
            continue
        # AMDGPU block sizes / counts: loads at fixed offsets from llvm.amdgcn.implicitarg.ptr
        r = re.match(r"\s*(%[\w.]+) = (?:tail )?call (?:noundef )?(?:align \d+ )?ptr addrspace\(4\) @llvm\.amdgcn\.implicitarg\.ptr\(\)", line)
        if r:
            implicit[r.group(1)] = 0
            continue
        r = re.match(r"\s*(%[\w.]+) = getelementptr (?:inbounds |nuw |nusw )*(\w+), ptr addrspace\(4\) (%[\w.]+), i(?:32|64) (\d+)\s*$", line)
        if r and r.group(3) in implicit:
            implicit[r.group(1)] = implicit[r.group(3)] + int(r.group(4)) * SIZE[r.group(2)]
            continue
        r = re.match(r"\s*(%[\w.]+) = load (i16|i32|i64), ptr addrspace\(4\) (%[\w.]+)", line)
        if r and r.group(3) in implicit:
            res, ty, p = r.groups()
            if implicit[p] not in IMPLICITARG:
                sys.exit(f"unsupported implicit argument at byte {implicit[p]}: {line.strip()}")
            reg, c = IMPLICITARG[implicit[p]]
            if reg == "ntid":
                consts[res] = str(local[c])
            else:
                decls.add("declare i32 @llvm.spv.num.workgroups.i32(i32)")
                out.append(f"  {res}.w = call i32 @llvm.spv.num.workgroups.i32(i32 {c})")
                out.append(f"  {res} = {'add i32' if ty == 'i32' else ('trunc i32' if ty == 'i16' else 'zext i32')} {res}.w{', 0' if ty == 'i32' else ' to ' + ty}")
            continue
        # warp ops -> subgroup shuffles. NVPTX: 32-lane segments of the subgroup (shfl clamp 31)
        r = re.match(r"\s*(%[\w.]+) = (?:tail )?call (?:noundef )?(?:range\([^)]*\) )?i32 @llvm\.nvvm\.read\.ptx\.sreg\.laneid\(\)", line)
        if r:
            res = r.group(1)
            out += [lane(res), f"  {res} = and i32 {res}.lane, 31"]
            continue
        r = re.match(r"\s*(%[\w.]+) = (?:tail )?call (?:\w+ )*(float|i32) @llvm\.nvvm\.shfl\.sync\.(bfly|down|up|idx)\.(?:f32|i32)\(i32 (-?\d+), (?:float|i32) ([^,]+), i32 ([^,]+), i32 (-?\d+)\)", line)
        if r:
            res, ty, mode, mask, val, b, clamp = r.groups()
            if mask != "-1" or clamp != "31":
                sys.exit(f"unsupported shfl (partial mask or segment width): {line.strip()}")
            L = f"{res}.lane"
            out.append(lane(res))
            if mode == "bfly":
                out += [f"  {res}.bm = and i32 {b}, 31", f"  {res}.src = xor i32 {L}, {res}.bm"]
            elif mode == "down":  # lanes past the segment end read their own value
                out += [f"  {res}.seg = and i32 {L}, 31", f"  {res}.t = add i32 {res}.seg, {b}", f"  {res}.ok = icmp ule i32 {res}.t, 31",
                        f"  {res}.cand = add i32 {L}, {b}", f"  {res}.src = select i1 {res}.ok, i32 {res}.cand, i32 {L}"]
            elif mode == "up":
                out += [f"  {res}.seg = and i32 {L}, 31", f"  {res}.ok = icmp uge i32 {res}.seg, {b}",
                        f"  {res}.cand = sub i32 {L}, {b}", f"  {res}.src = select i1 {res}.ok, i32 {res}.cand, i32 {L}"]
            else:  # idx: lane b of this segment
                out += [f"  {res}.base = and i32 {L}, -32", f"  {res}.bi = and i32 {b}, 31", f"  {res}.src = or i32 {res}.base, {res}.bi"]
            out.append(readlane(res, ty, val, f"{res}.src"))
            continue
        # AMDGPU: 64-lane waves of the subgroup
        r = re.match(r"\s*(%[\w.]+) = (?:tail )?call (?:noundef )?i32 @llvm\.amdgcn\.mbcnt\.(lo|hi)\(i32 (-?\d+), i32 ([^)]+)\)", line)
        if r:  # with a full mask: lo = min(wave lane, 32), hi = max(wave lane - 32, 0)
            res, half, mask, x = r.groups()
            if mask != "-1":
                sys.exit(f"unsupported mbcnt mask: {line.strip()}")
            out += [lane(res), f"  {res}.wl = and i32 {res}.lane, 63", f"  {res}.lt = icmp ult i32 {res}.wl, 32"]
            if half == "lo":
                out.append(f"  {res}.c = select i1 {res}.lt, i32 {res}.wl, i32 32")
            else:
                out += [f"  {res}.hm = sub i32 {res}.wl, 32", f"  {res}.c = select i1 {res}.lt, i32 0, i32 {res}.hm"]
            out.append(f"  {res} = add i32 {x}, {res}.c")
            continue
        r = re.match(r"\s*(%[\w.]+) = (?:tail )?call (?:noundef )?i32 @llvm\.amdgcn\.ds\.bpermute\(i32 ([^,]+), i32 ([^)]+)\)", line)
        if r:  # read the lane at byte address addr of this 64-lane wave
            res, addr, val = r.groups()
            out += [lane(res), f"  {res}.base = and i32 {res}.lane, -64", f"  {res}.w = lshr i32 {addr}, 2",
                    f"  {res}.wi = and i32 {res}.w, 63", f"  {res}.src = or i32 {res}.base, {res}.wi", readlane(res, "i32", val, f"{res}.src")]
            continue
        r = re.match(r"\s*(%[\w.]+) = (?:tail )?call (?:noundef )?i32 @llvm\.amdgcn\.update\.dpp\.i32\(i32 ([^,]+), i32 ([^,]+), i32 (\d+), i32 (\d+), i32 (\d+), i1 (true|false)\)", line)
        if r:
            res, old, val, ctrl, rmask, bmask, bound = r.groups()
            if rmask != "15" or bmask != "15":
                sys.exit(f"unsupported DPP row/bank mask: {line.strip()}")
            lines, src, ok = dpp_src(res, int(ctrl), f"{res}.lane")
            out += [lane(res), *lines]
            if ok is None:
                out.append(readlane(res, "i32", val, src))
            else:  # out-of-row lanes get 0 (bound_ctrl) or keep old
                out += [readlane(f"{res}.rl", "i32", val, src),
                        f"  {res} = select i1 {ok}, i32 {res}.rl, i32 {'0' if bound == 'true' else old}"]
            continue
        if re.search(r"@llvm\.nvvm\.|@llvm\.amdgcn\.", line):
            sys.exit(f"unsupported target intrinsic: {line.strip()}")
        out.append(line)
    # direct uses of a pointer argument (offset 0)
    for k, p in enumerate(ptr_args):
        if re.search(r"ptr(?: addrspace\(\d+\))? " + re.escape(p) + r"\b", "\n".join(out)):
            e = elem[p]
            pro.append(f"  {p}.p0 = call ptr addrspace(11) @llvm.spv.resource.getpointer.p11.{handle_suffix(e)}({handle_type(e)} %h.{k}, i32 0)")
            out = [re.sub(r"ptr(?: addrspace\(\d+\))? " + re.escape(p) + r"\b", f"ptr addrspace(11) {p}.p0", l) for l in out]
    text = "\n".join(out)
    for v in sb:  # loads/stores through rewritten pointers live in StorageBuffer
        text = re.sub(r"ptr(?: addrspace\(\d+\))? " + re.escape(v) + r"\b", f"ptr addrspace(11) {v}", text)
    if re.search(r"\bcall\b(?!.*@llvm\.)", text):
        sys.exit("kernel still calls non-intrinsic functions (inline them first)")
    # keep declarations of intrinsics the body still uses (e.g. llvm.spv.thread.id from host IR, llvm.smin)
    for d in re.findall(r"^declare .*@llvm\.[\w.]+\(.*$", ir, re.M):
        d = narrow_i64(d) if i32 else d
        f = re.search(r"@(llvm\.[\w.]+)\(", d).group(1)
        if f"@{f}(" in text and not f.startswith(("llvm.nvvm", "llvm.amdgcn")):
            decls.add(d)
    if "@llvm.spv.group.memory.barrier.with.group.sync()" in text:
        decls.add("declare void @llvm.spv.group.memory.barrier.with.group.sync()")
    decls = {re.sub(r"\s+#\d+\s*$", "", d) for d in decls}
    lx, ly, lz = local
    return "\n".join([
        f'target datalayout = "{DATALAYOUT}"',
        f'target triple = "{triple}"',
        "",
        *names,
        *gvars,
        "",
        "define void @main() #0 {",
        "entry:",
        *pro,
        f"  br label %{entry}",
        f"{entry}:",
        text,
        "}",
        "",
        *sorted(decls),
        "",
        f'attributes #0 = {{ "hlsl.numthreads"="{lx},{ly},{lz}" "hlsl.shader"="compute" }}',
        "",
    ])


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("ir")
    ap.add_argument("--kernel", default=None, help="kernel function name (default: the module's only kernel)")
    ap.add_argument("--local", default="64,1,1", help="workgroup size x,y,z (also the value of NVPTX ntid)")
    ap.add_argument("-o", "--out", required=True)
    ap.add_argument("--i32", action="store_true", help="narrow 64-bit integers to 32 bits (no shaderInt64)")
    ap.add_argument("--vulkan", default="1.3", choices=["1.1", "1.3"],
                    help="1.3: SPIR-V 1.6 (Turnip); 1.1: SPIR-V 1.4 (stock driver, needs VK_KHR_spirv_1_4)")
    ap.add_argument("--pad-shared", action="store_true",
                    help="pad 8/16-bit shared arrays to 4 bytes per element (works around the stock driver)")
    ap.add_argument("--opt", default="O3", choices=["O3", "O2", "O1", "none"],
                    help="LLVM opt pipeline on the kernel IR before retargeting (Mojo's --emit llvm is unoptimized)")
    a = ap.parse_args()
    local = [int(x) for x in a.local.split(",")] + [1, 1]
    ir = pathlib.Path(a.ir).read_text()
    kernel = a.kernel
    if kernel is None:  # Mojo sidecars hold one kernel with a mangled name; host IR: exported defs
        defs = re.findall(r"^define\s+[^@]*?void\s+@\"?([\w.$]+)\"?\(", ir, re.M)
        if len(defs) != 1:
            sys.exit(f"pick --kernel among {defs}")
        kernel = defs[0]
    print(f"kernel: {kernel}")
    triple = TRIPLE if a.vulkan == "1.3" else "spirv-unknown-vulkan1.1-compute"
    out = pathlib.Path(a.out)
    kir = optimize(ir, a.opt)
    out.with_suffix(".kernel.ll").write_text(kir)
    src = out.with_suffix(".vk.ll")
    src.write_text(legalize(retarget(kir, kernel, local[:3], i32=a.i32, triple=triple, pad_shared=a.pad_shared)))
    r = subprocess.run([str(LLVM / "llc"), "-O2", "-disable-lsr", "-filetype=obj", "-o", str(out), str(src)],
                       capture_output=True, text=True)
    if r.returncode:
        sys.exit(f"llc failed{' (try --opt none)' if a.opt != 'none' else ''}:\n" + r.stderr)
    env = "vulkan1.3" if a.vulkan == "1.3" else "vulkan1.1spv1.4"
    fix_barriers(out, env)
    r = subprocess.run(["spirv-val", "--target-env", env, str(out)], capture_output=True, text=True)
    print(f"{out}: {out.stat().st_size} bytes, spirv-val {'OK' if r.returncode == 0 else 'FAILED: ' + r.stderr.strip()}")
    sys.exit(r.returncode)


if __name__ == "__main__":
    main()
