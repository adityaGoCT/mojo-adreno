"""Run the worklog's kernels on the phone: every kernel at one shape, each in its own process, cooled first.

  ADB_SERVER_SOCKET=... ANDROID_SERIAL=... python3 run.py [--size 4096] [group ...]
groups: alu (kernels 1-6, NN), nn (the whole cooperative-matrix NN space: kernels 7 and 8), tn, pp, pq, rc,
        k1slice (kernel 1 on the first 512 rows: one 4096^3 dispatch loses the device), f16loose (kernel 6 with fp16
        accumulators, checked at 5% instead of 2%, to time it)
Results: results_<size>.json (merged: a rerun of a kernel replaces its entry).
Before every kernel the phone must be at most 45 C on gpuss-0 with no thermal cap, and no llama.cpp process may
be running (another session shares this phone).
"""
import argparse, json, os, pathlib, subprocess, sys

HERE = pathlib.Path(__file__).resolve().parent
# AdrenoBLAS (gen.py, sweep.py): a checkout of github.com/adityaGoCT/adrenoblas next to this one, or $ADRENOBLAS
sys.path.insert(0, str(pathlib.Path(os.environ.get("ADRENOBLAS", HERE.parent.parent / "adrenoblas")) / "ablas"))
sys.path.insert(0, str(HERE))
import gen  # noqa: E402
from sweep import make_shape  # noqa: E402
import alu_kernels  # noqa: E402

BENCH = HERE.parent / "asm/peak/vk_gemm_bench"
DEV = "/data/local/tmp/gemmlog"
PICKS = {  # the best configurations from AdrenoBLAS's sweeps (adrenoblas: ablas/results), re-measured here
    "tn": ["gTN_w1x2_t1x2_n32_f16_k1", "gTN_w2x4_t1x2_n32_f16_k1", "gTN_w1x4_t1x2_n32_f16_k1"],
    "pp": ["gPP_w1x1_t1x2_n32_f16_k1", "gPP_w1x2_t1x2_n32_f16_k1"],
    "pq": ["gPQ_w2x2_t1x1_n64_f16_k1", "gPQ_w4x2_t1x1_n64_f16_k1", "gPQ_w2x4_t1x1_n64_f16_k1"],
    "rc": ["gRC_w2x2_t1x1_n64_f16_k1", "gRC_w4x2_t1x1_n64_f16_k1", "gRC_w2x4_t1x1_n64_f16_k1"],
}
LAYOUT = {"nn": "NN", "tn": "TN", "pp": "PP", "pq": "PQ", "rc": "RC"}

def adb(*a, check=True):
    r = subprocess.run(["adb", *map(str, a)], capture_output=True, text=True)
    if check and r.returncode:
        sys.exit(f"adb {a}: {r.stdout}{r.stderr}")
    return r

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("groups", nargs="*", default=["alu", "nn", "tn", "pp", "pq", "rc"])
    ap.add_argument("--size", type=int, default=4096)
    ap.add_argument("--only", default=None, help="substring of kernel names")
    a = ap.parse_args()
    S = a.size
    kdir = HERE / f"k{S}"
    kdir.mkdir(exist_ok=True)
    lines, shapes, flops_of, loose = [], set(), {}, []
    for g in a.groups:
        if g == "alu":
            shape = make_shape(S, S, S, "N", "N", 2e-2)
            for name, src, (gx, gy) in alu_kernels.kernels(S, S, S):
                comp = kdir / f"{name}.comp"
                comp.write_text(src)
                subprocess.run(["glslc", "--target-env=vulkan1.3", "-O", str(comp), "-o", str(comp.with_suffix(".spv"))], check=True)
                lines.append(f"{name} {shape.name} 64 1 k{S}/{name}.spv {gx} {gy} 1")
        elif g == "k1slice":
            shape = make_shape(512, S, S, "N", "N", 2e-2)
            name, src, (gx, gy) = next(iter(alu_kernels.kernels(512, S, S)))
            name = "k1_naive_rows512"
            comp = kdir / f"{name}.comp"
            comp.write_text(src)
            subprocess.run(["glslc", "--target-env=vulkan1.3", "-O", str(comp), "-o", str(comp.with_suffix(".spv"))], check=True)
            lines.append(f"{name} {shape.name} 64 1 k{S}/{name}.spv {gx} {gy} 1")
            flops_of[name] = 2.0 * 512 * S * S
        elif g == "f16loose":
            shape = make_shape(S, S, S, "N", "N", 2e-2)
            name, src, (gx, gy) = [k for k in alu_kernels.kernels(S, S, S) if k[0] == "k6_vec_f16"][0]
            comp = kdir / f"{name}.comp"
            comp.write_text(src)
            subprocess.run(["glslc", "--target-env=vulkan1.3", "-O", str(comp), "-o", str(comp.with_suffix(".spv"))], check=True)
            lines.append(f"{name}_loose {shape.name}_loose 64 1 k{S}/{name}.spv {gx} {gy} 1")
            loose.append(shape.name)
        else:
            la, lb = LAYOUT[g]
            shape = make_shape(S, S, S, la, lb, 2e-2)
            cfgs = list(gen.space("N", "N")) if g == "nn" else [gen.parse(n) for n in PICKS[g]]
            for c in cfgs:
                BM, BN = gen.tile(c)
                if S % BM or S % BN:
                    continue
                spv = gen.build(c, S, S, S, kdir)
                lines.append(f"{gen.name(c)} {shape.name} 64 1 k{S}/{spv.name} {S // BN} {S // BM} 1")
        shapes.add(shape)
    if a.only:
        lines = [l for l in lines if a.only in l.split()[0]]
    (kdir / "manifest.txt").write_text("\n".join(lines) + "\n")
    print(f"{len(lines)} kernels", flush=True)
    adb("shell", f"mkdir -p {DEV}/k{S} {DEV}/shapes")
    adb("push", BENCH, f"{DEV}/")
    for shape in sorted(shapes):
        if adb("shell", f"ls {DEV}/shapes/{shape.name}/meta.txt", check=False).returncode:
            print("pushing", shape.name, flush=True)
            adb("push", shape, f"{DEV}/shapes/")
    used = {l.split()[4].split("/")[1] for l in lines}
    adb("push", *[kdir / u for u in sorted(used)], kdir / "manifest.txt", f"{DEV}/k{S}/")
    gate = ("Z=$(for z in /sys/class/thermal/thermal_zone*; do [ \"$(cat $z/type)\" = gpuss-0 ] && echo $z/temp; done); "
            "n=0; while [ \"$(cat /sys/class/kgsl/kgsl-3d0/thermal_pwrlevel)\" != 0 ] || [ \"$(cat $Z)\" -gt 45000 ] "
            "|| ps -A | grep -q llama- || pidof bench >/dev/null; do sleep 2; n=$((n+2)); [ $n -ge 600 ] && break; done; ")
    links = " && ".join([f"ln -sfn shapes/{s.name} {s.name}" for s in sorted(shapes)] +
                        [f"mkdir -p shapes/{n}_loose && ln -sf ../{n}/A.bin ../{n}/B.bin ../{n}/Cref.bin shapes/{n}_loose/ && "
                         f"echo '{S} {S} {S} N N 0.05' > shapes/{n}_loose/meta.txt && ln -sfn shapes/{n}_loose {n}_loose" for n in loose])
    cmd = (f"cd {DEV} && {links} && while read l; do {gate}echo \"$l\" > one.txt; t0=$(cat $Z); "
           f"r=$(./vk_gemm_bench --manifest=one.txt --target-ms=200 --reps=5 2>/dev/null) "
           f"|| r=\"{{\\\"name\\\":\\\"${{l%% *}}\\\",\\\"ok\\\":false,\\\"error\\\":\\\"rc=$?\\\"}}\"; "
           f"echo \"$r\" | sed \"s/}}$/,\\\"t0\\\":$t0,\\\"waited\\\":$n}}/\"; done < k{S}/manifest.txt")
    r = adb("shell", cmd, check=False)
    flops = 2.0 * S ** 3
    path = HERE / f"results_{S}.json"
    merged = {j["name"]: j for j in (json.loads(path.read_text()) if path.exists() else [])}
    for line in r.stdout.splitlines():
        if not line.startswith("{"):
            continue
        j = json.loads(line)
        if "us_min" in j:
            j["tflops"] = flops_of.get(j["name"], flops) / (j["us_min"] * 1e-6) / 1e12
        merged[j["name"]] = j
        if j.get("ok"):
            print(f"  {j['name']:36s} {j['tflops'] * 1e3:9.1f} GFLOP/s  err {j['err']:.1e}  {j['us_min'] / 1e3:9.2f} ms  (start {j['t0'] / 1e3:.1f} C)", flush=True)
        else:
            print(f"  {j['name']:36s} FAIL {j.get('error', '')} err {j.get('err', '')}", flush=True)
    path.write_text(json.dumps(sorted(merged.values(), key=lambda j: -j.get("tflops", 0)), indent=1))

if __name__ == "__main__":
    main()
