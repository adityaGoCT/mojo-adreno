# gemm_worklog: fifteen fp16 GEMM kernels on the Adreno 850

The code behind [BLOG-GEMM-WORKLOG.md](../BLOG-GEMM-WORKLOG.md): one GEMM (C = A B, fp16, 4096³ by default) written
fifteen times, from a naive kernel at 0.028 TFLOP/s to the matrix-unit kernel AdrenoBLAS uses at 16.7 TFLOP/s.
Each kernel is a GLSL compute shader for Vulkan 1.3 with `VK_KHR_cooperative_matrix` (kernels 10-15). Measured
on a Qualcomm Device Cloud SM8975 reference phone (Adreno 850, Android 17, stock driver E17.52.10.04).

## Files

```
kernels/01_naive.comp         one thread per output, lanes along M
kernels/02_coalesced.comp     lanes along N
kernels/03_readonly.comp      inputs readonly restrict (compiles to the same code as 02)
kernels/04_shared.comp        32 x 32 shared-memory tiles (T_ = 16 for 16 x 16)
kernels/05_1d_tiling.comp     8 outputs per thread down a column, 64 x 64 blocks
kernels/06_2d_tiling.comp     8 x 8 outputs per thread, 128 x 128 blocks
kernels/07_vectorized.comp    128-bit global loads, A transposed in shared memory, f16vec4 shared reads
kernels/08_fp16_math.comp     fp16 accumulators and multiply-adds; tile sizes as -D parameters (kernel 9 sweeps them)
kernels/10_coopmat.comp       cooperative matrices, 64 x 32 tile per subgroup, A [M,K] and B [K,N] row-major
kernels/11_kmajor.comp        A stored [K,M]
kernels/12_panels.comp        A and B packed into contiguous tiles (panels)
kernels/13_tile64.comp        one 64 x 64 tile per subgroup, 64-wide B panels
kernels/14_workgroup.comp     WM x WN subgroups per workgroup (swept)
kernels/15_kminor_tiles.comp  tiles with K contiguous inside (A row-major, B column-major tiles)
bench.c       harness: lays out A and B, runs the kernel, checks 1,024 outputs against a double-precision
              reference, times best of 5 runs with GPU timestamps
build.py      SPIR-V for every kernel and sweep point (+ AdrenoBLAS's generated kernel for the shape), the run list, bench
run.sh        on the phone: every kernel in its own process, each started below 45 °C with no thermal cap
plot.py       the chart in ../docs/img/worklog-steps.png
results/      raw runs (run_4096*.txt), pipeline statistics (isa_stats_4096.txt)
```

Operand layouts (bench.c `a_index` / `b_index`; kernels 12-15 read tile (i, k/16) of a panel at
`(i * (K/16) + k/16) * 1024` halves):

| code | A | B |
| --- | --- | --- |
| N | [M, K] row-major | [K, N] row-major |
| T | [K, M] | [N, K] |
| P | 64 x 16 tiles, column-major inside | 16 x 32 tiles, row-major inside |
| Q | | 16 x 64 tiles, row-major inside |
| R | 64 x 16 tiles, row-major inside (K contiguous per row) | |
| C | | 16 x 64 tiles, column-major inside (K contiguous per column) |

## Run

```bash
python3 build.py 4096
adb shell mkdir -p /data/local/tmp/worklog/spv
adb push build/bench build/runlist.txt run.sh /data/local/tmp/worklog/
adb push build/spv/. /data/local/tmp/worklog/spv/
adb shell "cd /data/local/tmp/worklog && ./run.sh 4096"          # all kernels; or ./run.sh 4096 15_ for a subset
python3 plot.py
```

`bench <spv> M N K gx gy la lb` runs one kernel. `BENCH_CHUNKS=n` splits the grid into n separately submitted
slices: the naive kernel takes 5 s at 4096³, and Android's GPU watchdog loses the device when one submission runs
for more than a couple of seconds (`run.sh` takes the slice count from the run list).

## Results (4096³, TFLOP/s)

`results/run_4096_headline.txt`: each step's best kernel in three interleaved rounds; the post's table and chart use
the median (`plot.py` prints it). Single runs of the sweeps:
- `run_4096.txt`: kernels 1-13 and kernel 9's sweep. Kernel 1 failed there (one 5 s submission trips the GPU
  watchdog). Its `14_kminor_tiles` and `15_wg_*` / `15x_pq_wg_*` rows are earlier names of `15_kminor_1x1`,
  `15_kminor_*` and `14_wg_*`.
- `run_4096_extra.txt`: naive in slices, 16 x 16 shared tiles, kernel 6 again (the first run started hot).
- `run_4096_mx.txt`: the sweeps of kernels 14 and 15, and AdrenoBLAS's generated kernel.
- `isa_stats_4096.txt`: the driver's pipeline statistics for kernels 2-8 and 13-15 (`asm/isa/vk_isa_dump`).
