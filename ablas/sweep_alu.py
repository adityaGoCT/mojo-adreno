"""Tune AdrenoBLAS's Adreno 840 ALU kernels (gen_alu.py) for one GEMM shape, per compiler.

Every config that divides the shape is timed (fp16, TN layout) under three compilers:
  stock          Qualcomm's driver
  turnip-bank    Mesa Turnip built with ../asm/mesa/turnip-ra-bank.patch (register-bank-aware RA)
  turnip-nobank  the same Turnip with the bank-aware RA off (the library selects this per kernel by tagging the
                 SPIR-V, gen_alu.mark_nobankra; here IR3_SHADER_DEBUG=nobankra does the same for the process)
Runs go through the 840 harness in ../asm/mesa (run.py: one plain command per adb call for Samsung RTL's RDB
bridge, thermal gate before each run, result checked against an fp32 reference). Candidates within --confirm %
of the best are re-timed three times, interleaved; the median decides (the stock driver's timings vary).
Writes results/alu840_<M>x<N>x<K>.json (best first); build_lib.py turns those into ablas_kernels_840.h.

  RTL_SERIAL=localhost:<port> python3 sweep_alu.py 2048 2048 2048
Once per (wiped) phone: cd ../asm/mesa; python3 run.py push; python3 run.py pushbank
"""
import argparse, json, pathlib, subprocess, sys

HERE = pathlib.Path(__file__).resolve().parent
MESA = HERE.parent / "asm" / "mesa"
sys.path.insert(0, str(MESA))
sys.path.insert(0, str(HERE))
import gen_alu  # noqa: E402
import run  # noqa: E402  (../asm/mesa/run.py)
_argv, sys.argv = sys.argv, sys.argv[:1]
import tune_alu  # noqa: E402  (../asm/mesa/tune_alu.py: data generation and upload)
sys.argv = _argv

COMPILERS = {
    "stock": ("stock", []),
    "turnip-bank": ("turnip-bank", ["MESA_SHADER_CACHE_DISABLE=true"]),
    "turnip-nobank": ("turnip-bank", ["MESA_SHADER_CACHE_DISABLE=true", "IR3_SHADER_DEBUG=nobankra"]),
}


def push_f16_data(hn):
    run.sh(f"mkdir -p {run.DEV}/shape/{hn}")
    for f in sorted((MESA / "shape" / hn).iterdir()):
        if tune_alu.remote_size(f"{run.DEV}/shape/{hn}/{f.name}") != f.stat().st_size:
            run.adb("push", f, f"{run.DEV}/shape/{hn}/")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("M", type=int)
    ap.add_argument("N", type=int)
    ap.add_argument("K", type=int)
    ap.add_argument("--compilers", default="stock,turnip-bank,turnip-nobank")
    ap.add_argument("--reps", type=int, default=5)
    ap.add_argument("--target-ms", type=int, default=150)
    ap.add_argument("--confirm", type=float, default=3.0)
    a = ap.parse_args()
    M, N, K = a.M, a.N, a.K
    comps = a.compilers.split(",")
    hn, _ = tune_alu.make_data(M, N, K)
    push_f16_data(hn)
    tag = f"alu840_{M}x{N}x{K}"
    man, spvs = [], []
    for c in gen_alu.CONFIGS:
        if not gen_alu.fits(c, M, N, K):
            continue
        n = gen_alu.name(c)
        p = MESA / "spv" / f"{tag}_{n}.comp"
        p.write_text(gen_alu.glsl(c, M, N, K))
        subprocess.run(["glslc", "--target-env=vulkan1.1", "-O", str(p), "-o", str(p.with_suffix(".spv"))], check=True)
        spvs.append(p.with_suffix(".spv"))
        groups = (N // c[2]) * (M // c[1])
        man.append(f"{tag}_{n} shape/{hn} 64 1 spv/{tag}_{n}.spv {N // c[2]} {M // c[1]} 1 # flops={2 * M * N * K // groups}")
    mf = MESA / f"manifest_{tag}.txt"
    mf.write_text("\n".join(man) + "\n")
    run.adb("push", *spvs, f"{run.DEV}/spv/")
    res = {}
    for line in man:
        full = line.split()[0]
        for comp in comps:
            d, env = COMPILERS[comp]
            r = run.run(str(mf), d, env, f"{tag}_{comp}", a.target_ms, a.reps, names=[full], quiet=True)[0]
            res[(full, comp)] = r
            tf = r.get("tflops")
            print(f"{full.split('_', 2)[2]:22s} {comp:14s} {tf if tf is None else round(tf, 3)} ok={r.get('ok')}", flush=True)
    ok = sorted(((r["tflops"], k) for k, r in res.items() if r.get("ok") and r.get("tflops")), reverse=True)
    if a.confirm > 0 and ok:
        close = [k for t, k in ok if t >= ok[0][0] * (1 - a.confirm / 100)]
        if len(close) > 1:
            print(f"confirming {len(close)} candidates within {a.confirm}% of the best", flush=True)
            runs = {k: [] for k in close}
            for _ in range(3):
                for full, comp in close:
                    d, env = COMPILERS[comp]
                    r = run.run(str(mf), d, env, f"{tag}_confirm_{comp}", a.target_ms, a.reps, names=[full], quiet=True)[0]
                    if r.get("ok") and r.get("tflops"):
                        runs[(full, comp)].append(r["tflops"])
            for k, ts in runs.items():
                if ts:
                    res[k]["tflops_single"] = res[k]["tflops"]
                    res[k]["tflops"] = sorted(ts)[len(ts) // 2]
                    res[k]["confirm_runs"] = ts
    out = [{"name": full.split("_", 2)[2], "compiler": comp, "tflops": r.get("tflops"), "ok": bool(r.get("ok")),
            "err": r.get("err"), **({"confirm_runs": r["confirm_runs"]} if "confirm_runs" in r else {})}
           for (full, comp), r in res.items()]
    out.sort(key=lambda j: -(j["tflops"] or 0) if j["ok"] else 1)
    (HERE / "results" / f"{tag}.json").write_text(json.dumps(out, indent=1))
    for comp in comps:
        best = next((j for j in out if j["ok"] and j["compiler"] == comp), None)
        if best:
            print(f"best {comp:14s} {best['name']:22s} {best['tflops']:.3f} TFLOP/s")


if __name__ == "__main__":
    main()
