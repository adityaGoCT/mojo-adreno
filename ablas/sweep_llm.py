"""Tune AdrenoBLAS's packed fp16 (RC) and Q4_0 kernels, with and without fused epilogues, on LLM GEMM shapes.
Timing only (random operands; the kernels' correctness is covered by sweep.py / q4test.py / the model checks).
  ADB_SERVER_SOCKET=... ANDROID_SERIAL=... python3 sweep_llm.py f16|q4 M,M,.. N:K[:ep],N:K[:ep],...
Writes results/llm_<fmt>_<M>x<N>x<K>[_e<ep>].json (configs ranked by TFLOP/s); build_lib.py reads them.
"""
import json, pathlib, re, subprocess, sys, time
import gen, gen_q4

HERE = pathlib.Path(__file__).resolve().parent
DEV = "/data/local/tmp/l3b/tune"
WS = [(1, 1), (1, 2), (2, 1), (2, 2), (1, 4), (4, 1), (2, 4), (4, 2)]

def adb(*a):
    return subprocess.run(["adb", *map(str, a)], capture_output=True, text=True)

def gpu_temp():
    r = adb("shell", "for z in /sys/class/thermal/thermal_zone*; do [ \"$(cat $z/type)\" = gpuss-0 ] && cat $z/temp; done")
    try:
        return int(r.stdout.split()[0]) / 1000
    except Exception:
        return 0.0

def configs(fmt, ep):
    for wm, wn in WS:
        if fmt == "f16":
            c = dict(la="R", lb="C", wm=wm, wn=wn, tm=1, tn=1, nt=64, acc="f16", ku=1, pf=0, sw=0, sa=0, sb=0, kc=0, dual=0)
            if ep:
                c["ep"] = ep
            yield gen.name(c), c
        else:
            c = dict(wm=wm, wn=wn, ks=32)
            if ep:
                c["ep"] = ep
            yield gen_q4.name(c), c

def main():
    fmt = sys.argv[1]
    Ms = [int(m) for m in sys.argv[2].split(",")]
    shapes = [s.split(":") for s in sys.argv[3].split(",")]
    out = HERE / "build/llm_tune"
    out.mkdir(parents=True, exist_ok=True)
    adb("shell", f"mkdir -p {DEV}")
    adb("push", HERE / "llama3b/vkrun", DEV)
    for M in Ms:
        for sh in shapes:
            N, K, ep = int(sh[0]), int(sh[1]), (sh[2] if len(sh) > 2 else None)
            while gpu_temp() > 50:
                time.sleep(3)
            tag = f"llm_{fmt}_{M}x{N}x{K}" + (f"_e{ep}" if ep else "")
            if (HERE / "results" / f"{tag}.json").exists() and "--redo" not in sys.argv:
                continue
            res, todo = [], []
            for n, c in configs(fmt, ep):  # build every config, then one push and one on-device loop
                BM, BN = 64 * c["wm"], 64 * c["wn"]
                if M % BM or N % BN:
                    continue
                src = (gen.glsl(c, M, N, K) if fmt == "f16" else gen_q4.glsl(c, M, N, K))
                comp = out / f"{n}_{M}x{N}x{K}.comp"
                comp.write_text(src)
                spv = comp.with_suffix(".spv")
                r = subprocess.run(["glslc", "--target-env=vulkan1.3", "-O", str(comp), "-o", str(spv)], capture_output=True, text=True)
                if r.returncode:
                    print(n, "compile error", r.stderr[:200]); continue
                todo.append((n, c, spv))
            if not todo:
                continue
            adb("shell", f"rm -f {DEV}/*.spv")
            adb("push", *[t[2] for t in todo], DEV)
            bbytes = N * K * 2 if fmt == "f16" else N * K // 2 + N * K // 16
            flops = 2.0 * M * N * K
            reps = max(3, int(0.05 / (flops / 15e12)))
            cmds = [f"echo K {t[0]}; ./vkrun {t[2].name} {N // (64 * t[1]['wn'])} {M // (64 * t[1]['wm'])} 1 -r {reps} -o {DEV} "
                    f"b0=~{M * K * 2} b1=~{bbytes} b2=@{M * N * 4} b3=@{M * N // 16}" + (f" -p {M}" if ep == "f" else "") for t in todo]
            r = adb("shell", f"cd {DEV} && " + " ; ".join(cmds))
            cur = None
            for line in r.stdout.splitlines():
                if line.startswith("K "):
                    cur = line[2:].strip()
                elif line.startswith("ms ") and cur:
                    ms = float(line.split()[1])
                    res.append(dict(name=cur, ms=ms, tflops=flops / ms / 1e9, ok=True))
                    print(f"{fmt} {M}x{N}x{K}{'_e' + ep if ep else ''} {cur:34s} {ms:8.3f} ms {flops / ms / 1e9:6.2f} TFLOP/s", flush=True)
            res.sort(key=lambda j: -j["tflops"])
            if not res:  # nothing ran (device gone?): leave no result file, so a rerun redoes this shape
                print("NO RESULTS", tag, (r.stdout + r.stderr)[:200], flush=True)
                continue
            (HERE / "results" / f"{tag}.json").write_text(json.dumps(res, indent=1))
            if res:
                print("BEST", tag, res[0]["name"], f"{res[0]['tflops']:.2f}", flush=True)

main()
