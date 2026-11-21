"""Run the peak-ALU microbenchmarks on the phone (stock driver and/or Mesa Turnip) and print GFLOP/s.

  ADB_SERVER_SOCKET='tcp:[::1]:5037' ANDROID_SERIAL=<serial> python3 run_peak.py [stock] [turnip]
"""
import json, os, pathlib, subprocess, sys

HERE = pathlib.Path(__file__).resolve().parent
TURNIP = pathlib.Path.home() / "runix/adreno-port/build"
DEV = "/data/local/tmp/asm_peak"
GROUPS = int(os.environ.get("GROUPS", 8192))
MANIFEST = os.environ.get("MANIFEST", "manifest.txt")
VARIANTS = os.environ.get("VARIANTS", "spv/variants.txt")

def adb(*a, check=True):
    r = subprocess.run(["adb", *map(str, a)], capture_output=True, text=True)
    if check and r.returncode:
        sys.exit(f"adb {a}: {r.stdout}{r.stderr}")
    return r

def push():
    adb("shell", f"mkdir -p {DEV}/spv {DEV}/spv_cm {DEV}/shape {DEV}/turnip")
    adb("push", HERE / "vk_gemm_bench", *sorted(HERE.glob("manifest*.txt")), f"{DEV}/")
    adb("push", *sorted((HERE / "spv").glob("*.spv")), f"{DEV}/spv/")
    if (HERE / "spv_cm").exists():
        adb("push", *sorted((HERE / "spv_cm").glob("*.spv")), f"{DEV}/spv_cm/")
    adb("push", HERE / "shape/meta.txt", HERE / "shape/A.bin", f"{DEV}/shape/")
    adb("push", TURNIP / "turnip-android/src/freedreno/vulkan/libvulkan_freedreno.so",
        TURNIP / "turnip-shim/libvulkan.so", f"{DEV}/turnip/")

def run(driver, extra_env=""):
    env = f"LD_LIBRARY_PATH={DEV}/turnip " if driver == "turnip" else ""
    r = adb("shell", f"cd {DEV} && {env}{extra_env}./vk_gemm_bench --manifest={MANIFEST} --target-ms=200 --reps=5 2>err_{driver}.txt",
            check=False)
    err = adb("shell", f"cat {DEV}/err_{driver}.txt", check=False).stdout
    flops = dict(l.split() for l in (HERE / VARIANTS).read_text().splitlines())
    rows = []
    for line in r.stdout.splitlines():
        try:
            j = json.loads(line)
        except json.JSONDecodeError:
            continue
        if not j.get("ok"):
            rows.append((j["name"], None, j.get("error")))
            continue
        gf = int(flops[j["name"]]) * GROUPS / (j["us_min"] * 1e-6) / 1e9
        rows.append((j["name"], gf, j["us_min"]))
    return rows, err

def main():
    drivers = sys.argv[1:] or ["stock", "turnip"]
    push()
    out = {}
    for d in drivers:
        rows, err = run(d)
        print(f"== {d}\n{err.strip()}")
        for name, gf, us in rows:
            print(f"  {name:22s} " + (f"{gf:9.1f} GFLOP/s  ({us:.1f} us)" if gf else f"FAILED {us}"))
        out[d] = rows
    (HERE / f"results_{pathlib.Path(MANIFEST).stem}.json").write_text(json.dumps(out, indent=1))

if __name__ == "__main__":
    main()
