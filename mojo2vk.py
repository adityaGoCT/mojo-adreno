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
  NVPTX tid/ctaid/ntid   -> SPIR-V LocalInvocationId / WorkgroupId / the fixed local size
  (host-IR kernels may call llvm.spv.thread.id etc. directly; those pass through)

then sets the Vulkan triple, adds hlsl.shader="compute" + hlsl.numthreads and runs llc.

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
NVPTX_REG = {  # NVPTX special registers -> (SPIR-V intrinsic, component) or local-size constant
    "tid": "llvm.spv.thread.id.in.group", "ctaid": "llvm.spv.group.id", "ntid": None}


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


def handle_type(elem):
    return f'target("spirv.VulkanBuffer", [0 x {elem}], 12, 1)'


def handle_suffix(elem):
    return f"tspirv.VulkanBuffer_a0{MANGLE[elem]}_12_1t"


def narrow_i64(body):
    """Rewrite 64-bit integer arithmetic to 32 bits (for drivers without shaderInt64, e.g. the stock
    Adreno Vulkan 1.1 driver). Valid while every index and length fits in int32."""
    body = re.sub(r"\bi64\b", "i32", body)
    body = re.sub(r"(%[\w.]+) = (?:zext|sext|trunc) (?:nneg )?i32 (%[\w.]+|-?\d+) to i32", r"\1 = add i32 \2, 0", body)
    return body


def retarget(ir, kernel, local, i32=False, triple=TRIPLE):
    m = re.search(r"^define\s+(?:[\w\s]*?)void\s+@\"?" + re.escape(kernel) + r"\"?\((.*?)\)([^{]*)\{\n(.*?)^\}", ir, re.S | re.M)
    if not m:
        sys.exit(f"kernel @{kernel} not found")
    # numbered values/labels must count from %0 inside a function; ours lose their args and gain
    # a prologue, so give every numbered value and label a name
    num = lambda s: re.sub(r"%(\d+)\b", r"%v\1", s)  # noqa: E731
    args = [num(a) for a in split_args(m.group(1))]
    body = re.sub(r"^(\d+):", r"v\1:", num(m.group(3)), flags=re.M)
    # the kernel's unlabeled entry block is implicitly numbered after its arguments (%0..%k-1 ->
    # block %k); phis name it, so the original body must start under that label
    entry = f"v{len(args)}" if all(re.search(r"%v\d+$", x) for x in args) else "body"
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

    # element type of each pointer arg: from typed GEPs / direct loads and stores
    elem = {}
    for p in ptr_args:
        pe = re.escape(p)
        t = re.findall(r"getelementptr (?:inbounds |nuw |nusw )*(\w+), ptr(?: addrspace\(\d+\))? " + pe + r",", body)
        t += re.findall(r"load (\w+), ptr(?: addrspace\(\d+\))? " + pe + r"\b", body)
        t += re.findall(r"store (\w+) [^,]+, ptr(?: addrspace\(\d+\))? " + pe + r"\b", body)
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

    out = []
    for line in body.splitlines():
        line = re.sub(r",\s*![\w.]+ !\d+", "", line)  # drop metadata attachments
        line = re.sub(r"\s+#\d+\s*$", "", line)          # drop attribute-group refs on calls
        g = re.match(r"\s*(%[\w.]+) = getelementptr (?:inbounds |nuw |nusw )*(\w+), ptr(?: addrspace\(\d+\))? (%[\w.]+), (i64|i32) (%[\w.]+|-?\d+)\s*$", line)
        if g and g.group(3) in ptr_args:
            res, gty, base, ity, idx = g.groups()
            k = ptr_args.index(base)
            e = elem[base]
            if gty == "i8" and e != "i8":  # byte offset -> element index
                sh = SIZE[e].bit_length() - 1
                if idx.lstrip("-").isdigit():
                    idx = str(int(idx) >> sh)
                else:
                    out.append(f"  {res}.ei = ashr exact {ity} {idx}, {sh}")
                    idx = f"{res}.ei"
            elif gty != e:
                sys.exit(f"unsupported GEP element type {gty} on {base} (buffer of {e})")
            if ity == "i64":
                if idx.lstrip("-").isdigit():
                    i32 = idx
                else:
                    out.append(f"  {res}.i32 = trunc i64 {idx} to i32")
                    i32 = f"{res}.i32"
            else:
                i32 = idx
            out.append(f"  {res} = call ptr addrspace(11) @llvm.spv.resource.getpointer.p11.{handle_suffix(e)}({handle_type(e)} %h.{k}, i32 {i32})")
            sb.add(res)
            continue
        r = re.match(r"\s*(%[\w.]+) = (?:tail )?call (?:noundef )?(?:range\([^)]*\) )?i32 @llvm\.nvvm\.read\.ptx\.sreg\.(tid|ctaid|ntid)\.([xyz])\(\)", line)
        if r:
            res, reg, comp = r.groups()
            c = "xyz".index(comp)
            if reg == "ntid":
                out.append(f"  {res} = add i32 0, {local[c]}")
            else:
                fn = NVPTX_REG[reg]
                out.append(f"  {res} = call i32 @{fn}.i32(i32 {c})")
                decls.add(f"declare i32 @{fn}.i32(i32)")
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
    # keep declarations of intrinsics the body still uses (e.g. llvm.spv.thread.id from host IR)
    for d in re.findall(r"^declare .*@(llvm\.[\w.]+)\(.*$", ir, re.M):
        if f"@{d}(" in text and not d.startswith(("llvm.nvvm", "llvm.amdgcn")):
            decls.add(re.search(r"^declare .*@" + re.escape(d) + r"\(.*$", ir, re.M).group(0))
    decls = {re.sub(r"\s+#\d+\s*$", "", d) for d in decls}
    lx, ly, lz = local
    return "\n".join([
        f'target datalayout = "{DATALAYOUT}"',
        f'target triple = "{triple}"',
        "",
        *names,
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
    ll = retarget(ir, kernel, local[:3], i32=a.i32, triple=triple)
    out = pathlib.Path(a.out)
    out.with_suffix(".vk.ll").write_text(ll)
    r = subprocess.run([str(LLVM / "llc"), "-O2", "-filetype=obj", "-o", str(out), str(out.with_suffix(".vk.ll"))],
                       capture_output=True, text=True)
    if r.returncode:
        sys.exit("llc failed:\n" + r.stderr)
    env = "vulkan1.3" if a.vulkan == "1.3" else "vulkan1.1spv1.4"
    r = subprocess.run(["spirv-val", "--target-env", env, str(out)], capture_output=True, text=True)
    print(f"{out}: {out.stat().st_size} bytes, spirv-val {'OK' if r.returncode == 0 else 'FAILED: ' + r.stderr.strip()}")
    sys.exit(r.returncode)


if __name__ == "__main__":
    main()
