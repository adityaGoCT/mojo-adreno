"""A/B the register-bank-aware RA patch: for each kernel, run it on a Turnip driver with the disassembly logged,
then report TFLOP/s, correctness and same-component 3-register mads in the main loop (bankcheck.py).

  python3 bank_ab.py <manifest> <tag> [driver=turnip-bank] [--env K=V ...] [--only name ...]
  e.g. python3 bank_ab.py manifest_gemm.txt bank turnip-bank
       python3 bank_ab.py manifest_gemm.txt nobank turnip-bank --env IR3_SHADER_DEBUG=nobankra
Writes asm_<tag>/<blake3>.asm, results/<tag>.jsonl (via run.py) and results/<tag>_banks.json.
"""
import argparse, json, pathlib, subprocess, sys

HERE = pathlib.Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import run, extract_asm, bankcheck  # noqa: E402


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("manifest")
    ap.add_argument("tag")
    ap.add_argument("driver", nargs="?", default="turnip-bank")
    ap.add_argument("--env", action="append", default=[])
    ap.add_argument("--only", action="append")
    ap.add_argument("--reps", type=int, default=3)
    ap.add_argument("--target-ms", type=int, default=100)
    a = ap.parse_args()
    names = [n for n, _, _ in run.parse_manifest(a.manifest)]
    if a.only:
        names = [n for n in names if n in a.only]
    outdir = HERE / f"asm_{a.tag}"
    outdir.mkdir(exist_ok=True)
    (HERE / "dumps").mkdir(exist_ok=True)
    report = {}
    for n in names:
        log = f"{run.DEV}/out/{a.tag}__{n}.log"
        dbg = [e for e in a.env if e.startswith("IR3_SHADER_DEBUG=")]
        env = [e for e in a.env if not e.startswith("IR3_SHADER_DEBUG=")]
        flags = ",".join(["cs"] + [d.split("=", 1)[1] for d in dbg])
        env += [f"IR3_SHADER_DEBUG={flags}", f"MESA_LOG_FILE={log}", "MESA_SHADER_CACHE_DISABLE=true"]
        res = run.run(a.manifest, a.driver, env, a.tag, a.target_ms, a.reps, names=[n])[0]
        local = HERE / "dumps" / f"{a.tag}__{n}.log"
        run.adb("pull", log, local, check=False)
        shaders = extract_asm.extract(local) if local.exists() else []
        loop = whole = (0, 0)
        if shaders:
            s = shaders[-1]
            body = s["body"]
            (outdir / f"{s['hash']}.asm").write_text("\n".join(body) + "\n")
            L = body
            for j in range(len(L) - 1, -1, -1):
                import re
                m = re.match(r"^\S*jump #(l\d+)", L[j])
                if m:
                    L = L[L.index(m.group(1) + ":"):j]
                    break
            loop, whole = bankcheck.scan(L), bankcheck.scan(body)
            stats = [b for b in body if "max_waves" in b or " full, " in b]
        report[n] = {"tflops": res.get("tflops"), "ok": res.get("ok"), "err": res.get("err"),
                     "loop_conflicts": loop[1], "loop_mads": loop[0], "hash": shaders[-1]["hash"] if shaders else None,
                     "stats": stats if shaders else []}
        print(f"  {n:28s} conflicts {loop[1]:4d}/{loop[0]:4d}  {[x.split(':')[-1].strip() for x in report[n]['stats']]}",
              flush=True)
    out = HERE / "results" / f"{a.tag}_banks.json"
    merged = json.loads(out.read_text()) if out.exists() else {}
    merged.update(report)
    out.write_text(json.dumps(merged, indent=1))


if __name__ == "__main__":
    main()
