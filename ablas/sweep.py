"""Sweep AdrenoBLAS kernel configs for one GEMM shape on the phone; check each against NumPy, rank by TFLOP/s.

  ADB_SERVER_SOCKET='tcp:[::1]:5037' ANDROID_SERIAL=<serial> python3 sweep.py 2048 2048 2048 [--la N --lb N] [--only REGEX]
Each config runs in its own process on the phone (a driver crash or GPU hang only loses that config).
Results: results/<M>x<N>x<K>_<la><lb>.json
"""
import argparse, json, pathlib, re, subprocess, sys
import numpy as np
from gen import build, name, space, tile

HERE = pathlib.Path(__file__).resolve().parent
BENCH = HERE.parent / "asm/peak/vk_gemm_bench"
DEV = "/data/local/tmp/ablas"

def adb(*a, check=True):
    r = subprocess.run(["adb", *map(str, a)], capture_output=True, text=True)
    if check and r.returncode:
        sys.exit(f"adb {a}: {r.stdout}{r.stderr}")
    return r

def make_shape(M, N, K, la, lb, tol):
    d = HERE / "shapes" / f"{M}x{N}x{K}_{la}{lb}"
    if (d / "meta.txt").exists():
        return d
    d.mkdir(parents=True, exist_ok=True)
    rng = np.random.default_rng(0)
    A = rng.uniform(-1, 1, (M, K)).astype(np.float16)
    B = rng.uniform(-1, 1, (K, N)).astype(np.float16)
    if la == "P":  # 64(M) x 16(K) tiles, column-major inside, K-tiles adjacent: [M/64][K/16][16][64]
        A.reshape(M // 64, 64, K // 16, 16).transpose(0, 2, 3, 1).copy().tofile(d / "A.bin")
    else:
        (A if la == "N" else A.T.copy()).tofile(d / "A.bin")
    if lb == "P":  # 16(K) x 32(N) tiles, row-major inside, K-tiles adjacent: [N/32][K/16][16][32]
        B.reshape(K // 16, 16, N // 32, 32).transpose(2, 0, 1, 3).copy().tofile(d / "B.bin")
    else:
        (B if lb == "N" else B.T.copy()).tofile(d / "B.bin")
    (A.astype(np.float32) @ B.astype(np.float32)).astype(np.float32).tofile(d / "Cref.bin")
    (d / "meta.txt").write_text(f"{M} {N} {K} {la} {lb} {tol}\n")
    return d

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("M", type=int); ap.add_argument("N", type=int); ap.add_argument("K", type=int)
    ap.add_argument("--la", default="N"); ap.add_argument("--lb", default="N")
    ap.add_argument("--only", default=None, help="regex on config names")
    ap.add_argument("--tol", type=float, default=2e-2)
    ap.add_argument("--target-ms", type=float, default=100)
    ap.add_argument("--big", action="store_true", help="also workgroups of up to 16 subgroups (1024 threads)")
    ap.add_argument("--stage", action="store_true", help="also shared-memory staging of A and/or B (kc 16/32)")
    ap.add_argument("--dual", action="store_true", help="two K steps per iteration into alternating accumulator sets")
    a = ap.parse_args()
    M, N, K = a.M, a.N, a.K
    shape = make_shape(M, N, K, a.la, a.lb, a.tol)
    out = HERE / "kernels" / shape.name
    out.mkdir(parents=True, exist_ok=True)
    lines, flops = [], 2.0 * M * N * K
    kw = dict(wms=(1, 2, 4, 8), wns=(1, 2, 4, 8), max_sg=16) if a.big else {}
    if a.stage:
        kw["stages"] = ((0, 0, 0), (0, 1, 16), (0, 1, 32), (1, 0, 16), (1, 0, 32), (1, 1, 16), (1, 1, 32))
    if a.dual:  # chaining two multiplies into one accumulator per iteration loses the device on the 850
        kw.update(duals=(1,), kus=(2,))
        kw.setdefault("stages", ((0, 0, 0), (0, 1, 32), (1, 0, 32), (1, 1, 32)))
    for c in space(a.la, a.lb, **kw):
        BM, BN = tile(c)
        if M % BM or N % BN or K % (16 * c["ku"]) or (a.only and not re.search(a.only, name(c))):
            continue
        spv = build(c, M, N, K, out)
        lines.append(f"{name(c)} {shape.name} 64 1 kernels/{shape.name}/{spv.name} {N // BN} {M // BM} 1\n")
    (out / "manifest.txt").write_text("".join(lines))
    print(f"{shape.name}: {len(lines)} configs")
    adb("shell", f"mkdir -p {DEV}/kernels/{shape.name} {DEV}/shapes")
    adb("push", BENCH, f"{DEV}/")
    if adb("shell", f"ls {DEV}/shapes/{shape.name}/meta.txt", check=False).returncode:
        adb("push", shape, f"{DEV}/shapes/")
    adb("push", *sorted(out.glob("*.spv")), out / "manifest.txt", f"{DEV}/kernels/{shape.name}/")
    cmd = (f"cd {DEV} && ln -sfn shapes/{shape.name} {shape.name} && while read l; do echo \"$l\" > one.txt; "
           f"./vk_gemm_bench --manifest=one.txt --target-ms={a.target_ms} --reps=5 2>/dev/null "
           f"|| echo \"{{\\\"name\\\":\\\"${{l%% *}}\\\",\\\"ok\\\":false,\\\"error\\\":\\\"rc=$?\\\"}}\"; "
           f"done < kernels/{shape.name}/manifest.txt")
    r = adb("shell", cmd, check=False)
    res = []
    for line in r.stdout.splitlines():
        if line.startswith("{"):
            j = json.loads(line)
            if "us_min" in j:
                j["tflops"] = flops / (j["us_min"] * 1e-6) / 1e12
            res.append(j)
    res.sort(key=lambda j: -j.get("tflops", 0) if j.get("ok") else 1)
    (HERE / "results").mkdir(exist_ok=True)
    path = HERE / "results" / f"{shape.name}.json"
    merged = {j["name"]: j for j in (json.loads(path.read_text()) if path.exists() else [])}
    merged.update({j["name"]: j for j in res})  # keep earlier sweeps of this shape, newest result wins
    path.write_text(json.dumps(sorted(merged.values(), key=lambda j: -j.get("tflops", 0) if j.get("ok") else 1), indent=1))
    for j in res:
        if j.get("ok"):
            print(f"  {j['name']:40s} {j['tflops']:6.2f} TFLOP/s  err {j['err']:.1e}  {j['us_min']:.0f} us")
        else:
            print(f"  {j['name']:40s} FAIL {j.get('error', '')} err {j.get('err', '')}")

if __name__ == "__main__":
    main()
