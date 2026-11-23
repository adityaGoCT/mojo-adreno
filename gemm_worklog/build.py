"""Build the worklog kernels for one size and write the run list.
  python3 build.py [S]     (default 4096: M = N = K = S)
Writes build/spv/*.spv and build/runlist.txt (name gx gy la lb chunks per line). Needs glslc and the Android NDK (for bench)."""
import os, pathlib, subprocess, sys

HERE = pathlib.Path(__file__).resolve().parent
S = int(sys.argv[1]) if len(sys.argv) > 1 else 4096
M = N = K = S
NDK_CLANG = os.environ.get("NDK_CLANG", "/opt/homebrew/share/android-ndk/toolchains/llvm/prebuilt/darwin-x86_64/bin/aarch64-linux-android33-clang")

runs = []  # (name, source, defines, gx, gy, la, lb, chunks)
def add(name, src, gx, gy, la="N", lb="N", chunks=1, **d):
    runs.append((name, src, d, gx, gy, la, lb, chunks))

add("01_naive", "01_naive.comp", M // 64, N // 4, chunks=max(1, S // 512))  # 5 s at 4096^3: split for the GPU watchdog
add("02_coalesced", "02_coalesced.comp", N // 64, M // 4)
add("03_readonly", "03_readonly.comp", N // 64, M // 4)
add("04_shared", "04_shared.comp", N // 32, M // 32)
add("04b_shared_t16", "04_shared.comp", N // 16, M // 16, T_=16)
add("05_1d_tiling", "05_1d_tiling.comp", N // 64, M // 64)
add("06_2d_tiling", "06_2d_tiling.comp", N // 128, M // 128)
add("07_vectorized", "07_vectorized.comp", N // 128, M // 128)
add("08_fp16_math", "08_fp16_math.comp", N // 128, M // 128)
# kernel 9: kernel 8's tile sizes swept
for bm, bn, bk, tm, tn in [(128, 128, 16, 8, 8), (128, 128, 8, 8, 8), (128, 128, 32, 8, 8), (64, 128, 16, 8, 8),
                           (128, 64, 16, 8, 8), (64, 64, 16, 8, 8), (256, 128, 16, 8, 8), (128, 256, 16, 8, 8),
                           (64, 128, 16, 4, 8), (128, 128, 16, 4, 8), (128, 128, 16, 8, 16), (128, 128, 16, 16, 8),
                           (256, 256, 16, 16, 16), (128, 256, 16, 8, 16), (256, 128, 16, 16, 8)]:
    nt = (bm // tm) * (bn // tn)
    if nt > 1024 or nt < 64:
        continue
    add(f"09_alu_b{bm}x{bn}x{bk}_t{tm}x{tn}", "08_fp16_math.comp", N // bn, M // bm,
        BM_=bm, BN_=bn, BK_=bk, TM_=tm, TN_=tn, NT_=nt)
add("10_coopmat", "10_coopmat.comp", N // 32, M // 64)
add("11_kmajor", "11_kmajor.comp", N // 32, M // 64, la="T")
add("12_panels", "12_panels.comp", N // 32, M // 64, la="P", lb="P")
add("13_tile64", "13_tile64.comp", N // 64, M // 64, la="P", lb="Q")
for wm, wn in [(1, 2), (2, 1), (2, 2), (1, 4), (4, 1), (2, 4), (4, 2), (4, 4)]:
    add(f"14_wg_{wm}x{wn}", "14_workgroup.comp", N // (64 * wn), M // (64 * wm), la="P", lb="Q", WM_=wm, WN_=wn, NT_=64 * wm * wn)
for wm, wn in [(1, 1), (2, 2), (4, 2), (2, 4)]:
    add(f"15_kminor_{wm}x{wn}", "15_kminor_tiles.comp", N // (64 * wn), M // (64 * wm), la="R", lb="C", WM_=wm, WN_=wn, NT_=64 * wm * wn)

out = HERE / "build" / "spv"
out.mkdir(parents=True, exist_ok=True)
for f in out.glob("*.spv"):
    f.unlink()
lines = []
for name, src, d, gx, gy, la, lb, chunks in runs:
    defs = [f"-DSIZE_M={M}", f"-DSIZE_N={N}", f"-DSIZE_K={K}"] + [f"-D{k}={v}" for k, v in d.items()]
    r = subprocess.run(["glslc", "--target-env=vulkan1.3", "-O", *defs, str(HERE / "kernels" / src), "-o", str(out / f"{name}.spv")],
                       capture_output=True, text=True)
    if r.returncode:
        print(name, "compile error:", r.stderr[:300]); continue
    lines.append(f"{name} {gx} {gy} {la} {lb} {chunks}")
# AdrenoBLAS's own generated kernel for this shape (its ablas/gen.py: a checkout of github.com/adityaGoCT/adrenoblas
# next to this one, or $ADRENOBLAS), as a cross-check of kernel 15
sys.path.insert(0, str(pathlib.Path(os.environ.get("ADRENOBLAS", HERE.parent.parent / "adrenoblas")) / "ablas"))
import gen
cfg = dict(la="R", lb="C", wm=2, wn=2, tm=1, tn=1, nt=64, acc="f16", ku=1, pf=0, sw=0, sa=0, sb=0, kc=0, dual=0)
(out / "ablas_gen.comp").write_text(gen.glsl(cfg, M, N, K))
subprocess.run(["glslc", "--target-env=vulkan1.3", "-O", str(out / "ablas_gen.comp"), "-o", str(out / "16_adrenoblas_gRC_w2x2.spv")], check=True)
(out / "ablas_gen.comp").unlink()
lines.append(f"16_adrenoblas_gRC_w2x2 {N // 128} {M // 128} R C 1")
(HERE / "build" / "runlist.txt").write_text("\n".join(lines) + "\n")
subprocess.run([NDK_CLANG, "-O2", "-Wall", "-I/usr/local/include", "-o", str(HERE / "build" / "bench"), str(HERE / "bench.c"), "-ldl", "-lm"], check=True)
print(f"{len(lines)} kernels for {M}x{N}x{K} in build/spv, build/runlist.txt, build/bench")
