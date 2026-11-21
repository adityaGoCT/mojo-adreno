"""Q4_0 GEMM kernels on the phone: correctness vs numpy and speed (vkrun, GPU timestamps).
  python3 q4test.py M N K name [name...]     name as in gen_q4.name(), e.g. q4_w2x2_k32_p1
"""
import os, pathlib, subprocess, sys, re
import numpy as np
from gen_q4 import build
from q4ref import quant_q4_0, dequant_q4_0, pack_q4, pack_tiles

HERE = pathlib.Path(__file__).resolve().parent
DEV = "/data/local/tmp/l3b/q4"

def adb(*a, **k):
    return subprocess.run(["adb", *a], capture_output=True, text=True, **k)

def parse(n):
    m = re.match(r"q4_w(\d+)x(\d+)_k(\d+)(_p1)?$", n)
    return dict(wm=int(m[1]), wn=int(m[2]), ks=int(m[3]), pf=int(bool(m[4])))

def main():
    M, N, K = map(int, sys.argv[1:4])
    tag = f"{M}x{N}x{K}"
    d = HERE / "build/q4" / tag
    d.mkdir(parents=True, exist_ok=True)
    rng = np.random.default_rng(0)
    A = rng.standard_normal((M, K), dtype=np.float32).astype(np.float16)
    W = rng.standard_normal((N, K), dtype=np.float32) * 0.05
    q, s = quant_q4_0(W)
    ref = A.astype(np.float32) @ dequant_q4_0(q, s).T
    if not (d / "a.bin").exists():
        pack_tiles(A).astype("<f2").tofile(d / "a.bin")
        (d / "b.bin").write_bytes(pack_q4(q, s))
        adb("shell", f"mkdir -p {DEV}/{tag}")
        adb("push", str(d / "a.bin"), str(d / "b.bin"), f"{DEV}/{tag}/")
    adb("push", str(HERE / "llama3b/vkrun"), f"{DEV}/")
    gx_flops = 2.0 * M * N * K
    for n in sys.argv[4:]:
        c = parse(n)
        spv = build(c, M, N, K, d)
        adb("push", str(spv), f"{DEV}/{tag}/k.spv")
        r = adb("shell", f"cd {DEV}/{tag} && ../vkrun k.spv {N // (64 * c['wn'])} {M // (64 * c['wm'])} 1 -r 10 "
                         f"b0=a.bin b1=b.bin b2=@{M * N * 2}", timeout=120)
        ms = re.search(r"ms ([\d.]+)", r.stdout)
        adb("pull", f"{DEV}/{tag}/b2.bin", str(d / "c.bin"))
        C = np.fromfile(d / "c.bin", np.float16).astype(np.float32).reshape(M, N)
        err = np.abs(C - ref).max() / np.abs(ref).max()
        t = float(ms[1]) if ms else float("nan")
        print(f"{n:22s} {tag}  err {err:.2e}  {t:.3f} ms  {gx_flops / t / 1e9:.2f} TFLOP/s", r.stderr.strip()[:200], flush=True)

main()
