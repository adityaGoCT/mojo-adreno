import sys, subprocess, numpy as np, pathlib
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parents[2]))
from gen_q4 import build
from q4ref import quant_q4_0, dequant_q4_0, pack_q4, pack_tiles
M, N, K = 64, 64, 64
A = np.zeros((M, K), np.float16)
for r in range(M): A[r, r % K] = 1
rng = np.random.default_rng(1)
W = rng.standard_normal((N, K)).astype(np.float32)
q, s = quant_q4_0(W)
dq = dequant_q4_0(q, s)
d = pathlib.Path("build/q4dbg"); d.mkdir(parents=True, exist_ok=True)
pack_tiles(A).astype("<f2").tofile(d / "a.bin"); (d / "b.bin").write_bytes(pack_q4(q, s))
import gen_q4, subprocess as sp
src = gen_q4.glsl(dict(wm=1, wn=1, ks=int(sys.argv[1])), M, N, K)
for a in sys.argv[2:]:
    old, new = a.split("=>")
    assert old in src, old
    src = src.replace(old, new)
(d / "k.comp").write_text(src)
spv = d / "k.spv"
sp.run(["glslc", "--target-env=vulkan1.3", *(["-O"] if "NOOPT" not in __import__("os").environ else []), str(d / "k.comp"), "-o", str(spv)], check=True)
D = "/data/local/tmp/l3b/q4dbg"
run = lambda *a: subprocess.run(["adb", *a], capture_output=True, text=True)
run("shell", f"mkdir -p {D}"); run("push", str(d / "a.bin"), str(d / "b.bin"), str(spv), "vkrun", D)
r = run("shell", f"cd {D} && ./vkrun {spv.name} 1 1 1 b0=a.bin b1=b.bin b2=@{M*N*2}"); print(r.stdout, r.stderr)
run("pull", f"{D}/b2.bin", str(d / "c.bin"))
C = np.fromfile(d / "c.bin", np.float16).astype(np.float32).reshape(M, N)
# C[r, n] should be dq[n, r]
got = C.T  # got[n, k] for k = r
print("max err", np.abs(got - dq).max())
print("n=0 want", np.round(dq[0, :20], 3)); print("n=0 got ", np.round(got[0, :20], 3))
print("q n=0", q[0, :20], "d", s[0])
# find for each k which k' matches
for k in range(16):
    m = [kk for kk in range(K) if np.allclose(got[:, k], dq[:, kk], atol=1e-3)]
    print(k, "->", m, end="; ")
print()
bad = np.abs(got - dq) > 1e-3
print("bad k columns:", [k for k in range(K) if bad[:, k].any()], "count per k:", bad.sum(0)[bad.sum(0) > 0])
print("got where bad (k=4):", np.unique(got[bad[:, 4], 4])[:10])
