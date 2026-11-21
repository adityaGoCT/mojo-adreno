"""Tune the Adreno 840 ALU GEMM for one shape: kernel config x compiler, including the bank-aware RA on/off.

For C[M,N] = A[M,K] @ B[K,N] (A stored transposed, fp16 C), every gen_gemm.py config that divides the shape
(operand paths ll/lg/gl/gg x workgroup tile; fp16 and/or fp32 math) is compiled and timed with:
  stock        Qualcomm's driver
  turnip-bank  Mesa Turnip with the register-bank-aware RA (turnip-ra-bank.patch, default)
  turnip-nobank  the same Turnip build with IR3_SHADER_DEBUG=nobankra (= unpatched register allocation)
Configs run interleaved (one process per candidate, thermal gate before each, results checked against an fp32
reference). The best (config, compiler) per math type goes into results/alu_catalogue.json, the way
AdrenoBLAS's catalogue holds the best cooperative-matrix kernel per shape on the 850.

  python3 tune_alu.py 2048 2048 2048 [--dtype f16|f32|both] [--drivers stock,turnip-bank,turnip-nobank]
                      [--reps 5] [--target-ms 150]
Needs: python3 run.py push / pushbank done once (bench, both Turnip builds on the phone).
"""
import argparse, json, pathlib, subprocess, sys, time
import numpy as np

HERE = pathlib.Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import run  # noqa: E402
_argv, sys.argv = sys.argv, sys.argv[:1]
import gen_gemm  # noqa: E402
sys.argv = _argv

DRIVERS = {
    "stock": ("stock", []),
    "turnip-bank": ("turnip-bank", ["MESA_SHADER_CACHE_DISABLE=true"]),
    "turnip-nobank": ("turnip-bank", ["MESA_SHADER_CACHE_DISABLE=true", "IR3_SHADER_DEBUG=nobankra"]),
}


def shape_dirs(M, N, K):
    if M == N == K and (HERE / "shape" / f"g{M}_h" / "Cref.bin").exists():
        return f"g{M}_h", f"g{M}_s"                                 # data made by gen_gemm.py
    return f"t{M}x{N}x{K}_h", f"t{M}x{N}x{K}_s"


def make_data(M, N, K):
    hn, sn = shape_dirs(M, N, K)
    h, s = HERE / "shape" / hn, HERE / "shape" / sn
    h.mkdir(parents=True, exist_ok=True)
    s.mkdir(parents=True, exist_ok=True)
    (h / "meta.txt").write_text(f"{M} {N} {K} C R 0.03\n")
    (s / "meta.txt").write_text(f"{M} {N} {K} C R 0.004 4\n")
    if not (h / "Cref.bin").exists() or not (s / "A.bin").exists():
        rng = np.random.default_rng(0)
        A = rng.uniform(-1, 1, (M, K)).astype(np.float16)
        B = rng.uniform(-1, 1, (K, N)).astype(np.float16)
        A.T.copy().tofile(h / "A.bin")
        B.tofile(h / "B.bin")
        A.T.astype(np.float32).tofile(s / "A.bin")
        B.astype(np.float32).tofile(s / "B.bin")
        (A.astype(np.float32) @ B.astype(np.float32)).astype(np.float32).tofile(h / "Cref.bin")
    return hn, sn


def remote_size(path):
    r = run.sh(f"ls -l {path}", check=False).stdout.split()
    return int(r[4]) if len(r) > 4 and r[4].isdigit() else -1


def push_data(hn, sn):
    for d in (hn, sn):
        run.sh(f"mkdir -p {run.DEV}/shape/{d}")
        for f in sorted((HERE / "shape" / d).iterdir()):
            if remote_size(f"{run.DEV}/shape/{d}/{f.name}") != f.stat().st_size:
                run.adb("push", f, f"{run.DEV}/shape/{d}/")
    if remote_size(f"{run.DEV}/shape/{sn}/Cref.bin") < 0:
        run.sh(f"ln -s {run.DEV}/shape/{hn}/Cref.bin {run.DEV}/shape/{sn}/Cref.bin")


def configs(M, N, K, dtypes):
    out = []
    for dt in dtypes:
        for src, BM, BN, BK in gen_gemm.CONFIGS:
            step = BK if BK else 4
            if M % BM or N % BN or K % step:
                continue
            out.append((dt, src, BM, BN, BK))
    return out


def pick(res, dtypes, drivers):
    """best (kernel, compiler) per math type over correct results; also the best kernel for each compiler."""
    entry = {}
    for dt in dtypes:
        rows = [(v["tflops"], n.split(f"_{dt}_", 1)[1], drv) for n, dv in res.items() if f"_{dt}_" in n
                for drv, v in dv.items() if v.get("ok") and v.get("tflops")]
        if not rows:
            continue
        tf, cfg, drv = max(rows)
        per = {}
        for t, c, d in rows:
            if d not in per or t > per[d]["tflops"]:
                per[d] = {"kernel": c, "tflops": round(t, 3)}
        entry[dt] = {"kernel": cfg, "compiler": drv, "tflops": round(tf, 3),
                     "bank_ra": {"turnip-bank": "on", "turnip-nobank": "off"}.get(drv),
                     "best_per_compiler": {d: per[d] for d in drivers if d in per}}
    return entry


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("M", type=int)
    ap.add_argument("N", type=int)
    ap.add_argument("K", type=int)
    ap.add_argument("--dtype", default="both", choices=["f16", "f32", "both"])
    ap.add_argument("--drivers", default="stock,turnip-bank,turnip-nobank")
    ap.add_argument("--reps", type=int, default=5)
    ap.add_argument("--target-ms", type=int, default=150)
    ap.add_argument("--dry-run", action="store_true", help="generate data, shaders and manifest only")
    a = ap.parse_args()
    M, N, K = a.M, a.N, a.K
    dtypes = ["f16", "f32"] if a.dtype == "both" else [a.dtype]
    drivers = a.drivers.split(",")
    hn, sn = make_data(M, N, K)
    if not a.dry_run:
        push_data(hn, sn)
    tag = f"tune_{M}x{N}x{K}"
    man, spvs = [], []
    for dt, src, BM, BN, BK in configs(M, N, K, dtypes):
        name = f"t{M}x{N}x{K}_{dt}_{src}_{BM}x{BN}" + (f"x{BK}" if BK else "")
        p = HERE / "spv" / f"{name}.comp"
        p.write_text(gen_gemm.shader(dt, src, BM, BN, BK, M, N, K))
        subprocess.run(["glslc", "--target-env=vulkan1.1", "-O", str(p), "-o", str(p.with_suffix(".spv"))], check=True)
        spvs.append(p.with_suffix(".spv"))
        shape = f"shape/{hn if dt == 'f16' else sn}"
        man.append(f"{name} {shape} 64 1 spv/{name}.spv {N // BN} {M // BM} 1 # flops={2 * M * N * K // ((N // BN) * (M // BM))}")
    mf = HERE / f"manifest_{tag}.txt"
    mf.write_text("\n".join(man) + "\n")
    if a.dry_run:
        print("\n".join(man))
        print(f"{len(man)} kernels x {len(drivers)} compilers; data in shape/{hn}, shape/{sn}")
        return
    run.adb("push", *spvs, f"{run.DEV}/spv/")
    res = {}
    for line in man:
        name = line.split()[0]
        for drv in drivers:
            d, env = DRIVERS[drv]
            r = run.run(str(mf), d, env, f"{tag}_{drv}", a.target_ms, a.reps, names=[name], quiet=True)[0]
            res.setdefault(name, {})[drv] = {"tflops": r.get("tflops"), "ok": r.get("ok"), "err": r.get("err"),
                                            "clk_mhz": r.get("clk_eff_mhz")}
            tf = r.get("tflops")
            print(f"{name:40s} {drv:14s} {tf if tf is None else round(tf, 3)} ok={r.get('ok')}", flush=True)
    cat_path = HERE / "results" / "alu_catalogue.json"
    cat = json.loads(cat_path.read_text()) if cat_path.exists() else {}
    entry = pick(res, dtypes, drivers)
    for dt, e in entry.items():
        print(f"\nbest {dt}: {e['kernel']} on {e['compiler']}: {e['tflops']:.3f} TFLOP/s; per compiler: "
              + ", ".join(f"{k} {v['tflops']} ({v['kernel']})" for k, v in e["best_per_compiler"].items()))
    cat[f"{M}x{N}x{K}"] = {"date": time.strftime("%Y-%m-%d"), **entry}
    cat_path.write_text(json.dumps(cat, indent=1))
    (HERE / "results" / f"{tag}.json").write_text(json.dumps(res, indent=1))


if __name__ == "__main__":
    main()
