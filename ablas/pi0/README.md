# π0 on the Adreno 850's GPU, through AdrenoBLASLt

Physical Intelligence's **π0**, as [`../../pi0`](../../pi0) runs it, with every stage on the GPU of a Qualcomm Device
Cloud SM8975 QRD (Adreno 850). The model is written against [AdrenoBLASLt](../lt) only (`pi0_lt.c`). One action
chunk has three stages:
- **vision:** SigLIP So400m on three images (27 layers over 768 patch rows), then the projector;
- **prefix:** PaliGemma's Gemma 2B over the 816-row prefix (18 layers, 832 rows with padding), keeping each layer's
  K/V;
- **steps:** 10 Euler steps of the action expert (Gemma 300M, 18 layers over 51 rows, padded to 64) against that
  cache.

On the Adreno 840, the prefix was compute-bound and the GPU code of the time slow: 2.3–2.6 s on the 840's GPU against
0.80 s on its Hexagon NPU. So the earlier split ran the prefix on the NPU and the rest on the GPU (2.05–2.16 s a
chunk). With the 850's matrix units and AdrenoBLAS, the whole chunk on the GPU takes **445–448 ms**.

**No checkpoint is read.** The weights are random (fp16, or Q4_0 with `-q`), generated on the phone. This is the
architecture and its timing, not the model's actions: same shapes, same operations, same work. Correctness is
checked per operation instead, against double-precision references (`../lt/lt_test`, [below](#checks)).

## Results (QDC SM8975 QRD, Adreno 850, 2026-11-22)

One command buffer per chunk, GPU timestamps, 4 runs after a warm-up (`pi0_lt -r 4`). The GPU stays at its top clock
(1450 MHz) throughout. The 840 columns are [`../../pi0/README.md`](../../pi0/README.md)'s, on a Galaxy Z Fold with real
weights.

| Stage | Work | **850 GPU, fp16** | 850 GPU, Q4_0 | 840: all on the GPU (Mojo) | 840: NPU prefix + GPU |
|---|---|---|---|---|---|
| Vision | SigLIP So400m, 3 × 256 patches; projector | **84 ms** | 81 ms | 494–514 ms | 494–496 ms |
| Prefix | Gemma 2B, 832 rows: 3.1 TFLOP | **229–230 ms** | 218 ms | 2.34–2.35 s | 0.80 s (NPU) |
| 10 steps | expert, 64 rows against an 896-key cache | **134 ms** (13.4 ms a step) | 93 ms | 749–784 ms | 745–748 ms |
| **Chunk** | | **447–448 ms** | 392 ms | 3.59–3.61 s | 2.05–2.16 s |

- **The whole chunk runs 4.6× faster than the NPU + GPU split**, and the prefix alone 3.5× faster than the 840's
  NPU. The prefix does 13.6 TFLOP/s overall and its GEMMs 15.3; gate|up runs at 17.7 TFLOP/s, the matrix units'
  peak.
- **The 850's own NPU is not measured yet.** The QDC session ended while its graphs compiled. From
  [Llama 3.2 3B's prefill](../../npu/README.md#llama-32-3b-on-the-adreno-850-phones-npu-hexagon-v85) (the HTP's
  fp16 matmuls at ~10 TFLOP/s), this 3.1 TFLOP prefix should take about 0.31–0.33 s there, against 230 ms on the GPU.
  `compare.sh` measures it ([below](#the-npu-comparison)).
- **Q4_0 weights** take the chunk to 392 ms, mostly in the steps: at 64 rows the expert's matmuls are bound by
  reading its 622 MB of fp16 weights per step (~67 GB/s). What Q4_0 does to the actions needs the real weights.

### Where the time goes

`pi0_lt -p` (a timestamp after every operation), fp16, ms per chunk:

| | vision (84) | prefix (230) | 10 steps (134) |
|---|---|---|---|
| norms | 7.0 (LayerNorm) | 5.5 | 3.9 |
| qkv projection + split (+ RoPE) | 24.5 | 17.3 | 16.6 |
| attention | 9.7 | 21.0 | 36.8 |
| o proj | 9.8 | 11.7 | 12.0 |
| MLP up (gate\|up) | 12.3 | 107.6 | 39.7 |
| MLP down | 19.8 | 67.8 | 23.7 |
| other (patch embed, projector, action in/out, glue) | 0.9 | | 1.1 |

### What it took

- **New operations in AdrenoBLAS and AdrenoBLASLt.** All are checked on the 850 in [`../lt/lt_test`](../lt):
  - three epilogues: GeGLU (Gemma's MLP), bias + GELU into tiles and residual + bias (SigLIP);
  - the q/k/v split for heads of 256 (Gemma) and 72 zero-padded to 128 (SigLIP), with bias, RoPE or not, writing
    K/V into a longer cache at a row offset (the expert's 64 rows after the prefix's 832);
  - masked attention: bidirectional with a key mask (the prefix: 783 valid of 832 rows), π0's block-causal suffix
    (the state row sees only itself among the 51), and per-image batches (SigLIP);
  - LayerNorm.
- **Heads of 256 need one accumulator per subgroup.** The first attention kernel gave each subgroup two 64 × 64 output
  accumulators (256 dims over 2 subgroups) and hung the GPU: driver bug #4. Now P V runs once per 128 dims, and S is
  recomputed for the second round.
- **Row split: 832 rows were taking small tiles** (first run: prefix 279–291 ms, chunk 520–532 ms):
  - With M = 832, only AdrenoBLAS's 64-row tiles divide M. The down projection (N 2048, K 16384) then ran at 8.6
    TFLOP/s in the chunk, 6.5 ms a layer (4.3 ms alone in `shape_bench`).
  - Lt now runs such GEMMs as two row ranges, 768 rows on 256 × 128 tiles plus 64 rows: down 4.0 ms, o proj 1.06 →
    0.69 ms. Prefix: **280 → 230 ms**.
  - It applies only for N ≤ 4096: gate|up (N 32768) went 6.3 → 8.0 ms split, as its 64-row tiles already fill the GPU.
- **The expert's attention had 8 workgroups** (64 rows × 8 heads). Its 896 keys are now split among 7 workgroups per
  head, with a merge kernel (flash-decoding style): **steps 155 → 131–134 ms**.

### Checks

`../lt/lt_test`, every new operation against double-precision math on the same fp16 inputs (max error relative to
the largest output):

| check | error |
|---|---|
| GeGLU / bias + GELU / residual + bias | 2.2e-3 / 1.3e-3 / 8.6e-4 |
| q/k/v split, heads of 256, RoPE, K/V at a cache offset | 1.9e-3 |
| attention: prefix (key mask, 8 query heads on 1 KV head) | 2.2e-3 |
| attention: suffix (prefix keys + block-causal suffix); with 3 and 2 key splits | 3.1e-3; 1.2e-3, 1.9e-3 |
| q/k/v split, heads of 72 padded, bias; ViT attention over 3 images | 1.4e-3; 1.0e-3 |
| LayerNorm (D 1152); GEMMs split as 256 + 64 rows (GeGLU, Q4_0 residual) | 4.8e-4; 1.7e-3, 1.1e-3 |

The chunk's actions (random here) come out finite. Accuracy against PyTorch needs the checkpoint.

## The NPU comparison

`npu/export_pi0.py --random` writes the NPU's prefix graphs (6 parts of 3 layers, fp16, as on the 840) without a
checkpoint: random RMSNorm scales, a `recipe.txt` whose `rand` lines make `npu/pi0_f16` write a random `gemma.bin`
(3.75 GB, 2 s on the phone), and random inputs in `pi0/reference.py`'s formats. `compare.sh` stages it all on a
freshly assigned phone, compiles the parts on the HTP (`npu/run_pi0npu.sh`, one process each), times the NPU prefix
(`pi0npu_tool`, the 840's program), then the GPU chunk:

```bash
ADB_SERVER_SOCKET='tcp:[::1]:5037' ablas/pi0/compare.sh          # or: stage | compile | npu | gpu
```

## Running it

```bash
./build.sh                                     # pi0_lt, shape_bench, qkv_bench (and ../lt's kernels)
adb push build/pi0_lt /data/local/tmp/pi0/
adb shell "cd /data/local/tmp/pi0 && ./pi0_lt -r 4"       # -p: per operation; -q: Q4_0 weights
```

- `ABLASLT_NO_ROW_SPLIT=1` and `PI0_NO_KEY_SPLIT=1` turn off the two optimizations above.
- `shape_bench M N K res|geglu|tiles|f32` times one Lt matmul. `ABLAS_KERNEL_EP` picks its kernel by name.
- `qkv_bench siglip|gemma` times the q/k/v split against its GEMM alone.

## Next

- **The NPU on the 850**: `compare.sh` once a phone is connected.
- **Fuse the q/k/v split into the GEMM's epilogue.** The split costs 0.3–0.5 ms a layer beyond its GEMM
  (`qkv_bench`), about 20 ms a chunk. `../llama3b/gen_fused.py` does this for Llama's heads of 128.
- **The expert's attention** (37 ms a chunk):
  - With 2 key blocks per split, `famask256s1` computes S once instead of three times. It was not faster in the
    chunk yet (36.8 ms against 33.6 for the general split kernel with tile output).
  - The merge (`../lt/kernels/facombine.comp`) is the suspect. It gives each lane one row of the row-major partials,
    so a 64-lane load reads 64 rows 512 bytes apart. The expert also gets only 8 workgroups of 64 threads from it,
    each thread doing 224 loads in sequence (32 chunks of 8 dims × 7 splits).
  - **`../lt/kernels/facombine_coalesced.comp` is the replacement, written but NOT TESTED on a device** (the QDC
    phone dropped first; it compiles):
    - one thread per 8 dims of a row, so consecutive threads read consecutive 16 bytes and 32 threads cover a row;
    - the expert gets 16,384 threads, each doing 7 loads (one per split) instead of 224;
    - the math is the same.
    - To try it: list it in `../lt/gen_kernels.py` in place of `facombine`, and dispatch
      `(qrows * HD / 8 + 255) / 256` × heads workgroups in `ablasLtAttentionMasked`. Then run `lt_test`'s key-split
      cases and time `pi0_lt`.
    - The merge's own share of the 36.8 ms was not measured separately, so the gain is not known yet. If the merge
      is what held `famask256s1` back, the s1 kernel's halved matrix work should then show.
- **Vision:**
  - SigLIP's fc2 (768 × 1152 × 4352) runs 10% faster on 128 × 128 tiles than on the 256 × 128 ones it gets.
  - LayerNorm could take its statistics from the residual epilogue, as RMSNorm does (~3 ms).
- **Real weights:** compare the actions with PyTorch (`../../pi0/reference.py`). The prefix's fp16 accumulation
  matters there: the 840's fp32 GPU path was within 1.1e-5, the NPU's fp16 within 3.2e-3.
