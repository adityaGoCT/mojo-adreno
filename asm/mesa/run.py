"""Run vk_bench candidates on the Adreno 840 (Samsung RTL Fold) through the RDB bridge.

The RDB bridge drops the connection on `&&`, `&`, loops, chmod, nohup, setsid, `sh x.sh` and very long
command lines, so this runner issues exactly one plain command per `adb shell` call: one process per
manifest line, output to files on the phone, then `cat`.

  python3 run.py push                                  # bench binary, Turnip, SPIR-V, shapes, manifests
  python3 run.py run <manifest> <driver> [--env K=V ...] [--tag T] [--groups G] [--target-ms MS]

<driver> is `stock` (system loader + Qualcomm driver) or `turnip` (Mesa, via LD_LIBRARY_PATH).
Manifest lines are vk_bench lines; FLOPs per group come from a `# flops=<n>` suffix in the line or from
`--variants <file>` ("<name> <flops-per-group>"). Results are appended to results/<tag>.jsonl.
"""
import argparse, json, os, pathlib, shlex, subprocess, sys, time

HERE = pathlib.Path(__file__).resolve().parent
PEAK = HERE.parent / "peak"
TURNIP = pathlib.Path.home() / "runix/adreno-port/build"
SERIAL = os.environ.get("RTL_SERIAL", "localhost:59796")
DEV = "/data/local/tmp/asm_mesa"
FREQS = [1300, 1200, 1100, 1050, 1000, 902, 826, 726, 646, 578, 500, 461, 422, 382, 342, 282, 222, 191, 160]


def adb(*a, check=True, timeout=600):
    r = subprocess.run(["adb", "-s", SERIAL, *map(str, a)], capture_output=True, text=True, timeout=timeout)
    if check and r.returncode:
        sys.exit(f"adb {a}: rc={r.returncode} {r.stdout}{r.stderr}")
    return r


def sh(cmd, **kw):
    for bad in ("&&", " & ", "for ", "while ", "chmod", "nohup", "setsid"):
        assert bad not in cmd, f"RDB bridge would drop on {bad!r}: {cmd}"
    assert len(cmd) < 3000, "keep adb shell lines short"
    return adb("shell", cmd, **kw)


def push():
    sh(f"mkdir -p {DEV}/turnip {DEV}/spv {DEV}/m {DEV}/out {DEV}/ovr {DEV}/shape")
    adb("push", HERE / "vk_bench", f"{DEV}/")
    adb("push", TURNIP / "turnip-android/src/freedreno/vulkan/libvulkan_freedreno.so",
        TURNIP / "turnip-shim/libvulkan.so", f"{DEV}/turnip/")
    push_spv()
    push_shapes()


def push_spv():
    spv = sorted((HERE / "spv").glob("*.spv"))
    if spv:
        adb("push", *spv, f"{DEV}/spv/")


def push_shapes():
    for d in sorted((HERE / "shape").iterdir()) if (HERE / "shape").exists() else []:
        sh(f"mkdir -p {DEV}/shape/{d.name}")
        adb("push", *sorted(d.iterdir()), f"{DEV}/shape/{d.name}/")


def thermal():
    r = sh("cat /sys/class/kgsl/kgsl-3d0/thermal_pwrlevel /sys/class/kgsl/kgsl-3d0/temp", check=False).stdout.split()
    return int(r[0]), int(r[1]) / 1000


def cool(max_level=0, max_temp=float(os.environ.get("MAX_GPU_TEMP", 60)), timeout=900):
    """Wait until the thermal cap is off (thermal_pwrlevel 0 = 1300 MHz allowed) and the GPU is cool enough."""
    t0 = time.time()
    while True:
        lvl, temp = thermal()
        if lvl <= max_level and temp <= max_temp:
            return lvl, temp
        if time.time() - t0 > timeout:
            print(f"  [thermal] still capped (level {lvl}, {temp} C) after {timeout} s; running anyway", flush=True)
            return lvl, temp
        print(f"  [thermal] level {lvl} ({FREQS[lvl]} MHz cap), {temp} C: waiting", flush=True)
        time.sleep(20)


def parse_manifest(path):
    rows = []
    for line in pathlib.Path(path).read_text().splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        flops = None
        if "# flops=" in line:
            line, f = line.split("# flops=")
            line, flops = line.strip(), int(f)
        rows.append((line.split()[0], line, flops))
    return rows


def run(manifest, driver, env=(), tag=None, target_ms=200, reps=5, variants=None, groups=None, quiet=False,
        names=None):
    rows = parse_manifest(manifest)
    if names:
        rows = [r for r in rows if r[0] in names]
    vflops = {}
    if variants:
        vflops = {a: int(b) for a, b in (l.split() for l in pathlib.Path(variants).read_text().splitlines() if l.strip())}
    tag = tag or f"{pathlib.Path(manifest).stem}_{driver}"
    mdir = HERE / "results" / "m"
    mdir.mkdir(parents=True, exist_ok=True)
    files = []
    for name, line, _ in rows:
        p = mdir / f"{name}.txt"
        p.write_text(line + "\n")
        files.append(p)
    adb("push", *files, f"{DEV}/m/")
    envs = " ".join(env)
    if driver == "turnip":
        envs = f"LD_LIBRARY_PATH={DEV}/turnip " + envs
    out = []
    for name, line, flops in rows:
        cool()
        o = f"out/{tag}__{name}"
        clk = "/sys/class/kgsl/kgsl-3d0/gpu_clock_stats"
        cmd = (f"cd {DEV}; cat {clk} > {o}.clk; {envs} ./vk_bench --manifest=m/{name}.txt --target-ms={target_ms}"
               f" --reps={reps} > {o}.json 2> {o}.err; echo rc $? >> {o}.err; cat {clk} >> {o}.clk")
        t0 = time.time()
        sh(cmd, check=False)
        j = sh(f"cat {DEV}/{o}.json", check=False).stdout
        err = sh(f"cat {DEV}/{o}.err", check=False).stdout
        res = {"name": name, "driver": driver, "env": envs.strip(), "tag": tag, "wall_s": round(time.time() - t0, 1)}
        for l in j.splitlines():
            if l.startswith("{"):
                res.update(json.loads(l))
        res["stderr"] = err.strip()[-600:]
        clk = sh(f"cat {DEV}/{o}.clk", check=False).stdout.split("\n")
        try:
            a, b = ([int(x) for x in l.split()] for l in clk[:2])
            d = [y - x for x, y in zip(a, b)]
            busy = sum(d[:10]) or 1  # levels >= 500 MHz (idle time collects at the bottom levels)
            res["clk_1300_frac"] = round(d[0] / busy, 3)
            res["clk_eff_mhz"] = round(sum(f * t for f, t in zip(FREQS, d[:10])) / busy)
        except Exception:
            pass
        f = flops or vflops.get(name)
        if f and res.get("us_min"):
            w = line.split()
            g = groups or int(w[5]) * int(w[6]) * int(w[7])
            res["tflops"] = f * g / (res["us_min"] * 1e-6) / 1e12
        out.append(res)
        with open(HERE / "results" / f"{tag}.jsonl", "a") as fh:
            fh.write(json.dumps(res) + "\n")
        if not quiet:
            tf = f"{res['tflops']:6.3f} TFLOP/s" if "tflops" in res else "   -   "
            print(f"{name:32s} {driver:6s} {tf}  us_min={res.get('us_min', '-')} ok={res.get('ok')} "
                  f"err={res.get('err', '-')} clk={res.get('clk_eff_mhz')}MHz({res.get('clk_1300_frac')}) rc={err.strip().splitlines()[-1] if err.strip() else '?'}", flush=True)
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("cmd", choices=["push", "pushspv", "pushshapes", "run"])
    ap.add_argument("manifest", nargs="?")
    ap.add_argument("driver", nargs="?", default="stock")
    ap.add_argument("--env", action="append", default=[])
    ap.add_argument("--tag")
    ap.add_argument("--variants")
    ap.add_argument("--groups", type=int)
    ap.add_argument("--target-ms", type=int, default=200)
    ap.add_argument("--reps", type=int, default=5)
    ap.add_argument("--only", action="append")
    a = ap.parse_args()
    if a.cmd == "push":
        push()
    elif a.cmd == "pushspv":
        push_spv()
    elif a.cmd == "pushshapes":
        push_shapes()
    else:
        run(a.manifest, a.driver, a.env, a.tag, a.target_ms, a.reps, a.variants, a.groups, names=a.only)


if __name__ == "__main__":
    main()
