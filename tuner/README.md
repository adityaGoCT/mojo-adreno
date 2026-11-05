# tuner/: tuning the prefill's matrix kernel on the phone

Mojo has no autotuning decorator: `@adaptive` and `autotune()` were removed in 0.7.0, and Modular now
tunes kernels offline with `kbench`, a grid of compile-time parameters per kernel. `kbench` builds
and runs on the machine with the GPU. Here the GPU is in a phone, so the tuner builds on the Mac and
measures over adb.

It tunes `p_gemm_t2v` (`bonsai/kernels/prefill.mojo`), the ternary matrix kernel that Qwen3's and
Bonsai's batched prefills spend most of their time in. Its candidates are compile-time parameters,
so each one is a separate Vulkan compute shader inside one Android program. The result is a table,
`qwen3/gemm_table.mojo`, that `Qwen3.prefill` dispatches through per matrix and prompt length.

```
propose ──> verifier ──> cost model ──> build ──> phone (check, then time) ──> learn
(search.py)  (verifier.py)  (cost_model.py)  (runner.py)  (gemm_bench.mojo)        (cost_model.py, devices/)
```

| File | What it does |
|---|---|
| `space.py` | A candidate (`Cand`), the space (1,200 candidates), and each model's matrix shapes |
| `verifier.py` | A device's profile (`devices/<model>-<build>.json`): its limits, rules learned on it with their evidence, and every candidate that failed there |
| `cost_model.py` | An analytic roofline: matrix-unit work, memory traffic, shared-memory traffic, barriers, memory latency. Gradient-boosted regression trees (numpy) on the roofline's terms, the options and the shape predict each candidate's time relative to the reference kernel, refitted on every measurement |
| `evaluate.py` | How much the learned model saves: hold out a shape, rank its candidates, and score the top k |
| `runner.py` | Builds `gemm_bench` with a round's candidates (4–12 s), waits for the phone to cool under 40 °C, runs it one prompt length at a time, and keeps every result (with the temperature it started at) in `build/tuner/<device>/measurements.jsonl` |
| `gemm_bench.mojo` | On the phone: random X, W and scales per shape; each candidate must match the reference kernel to 1e-5 of the largest output, then all are timed in interleaved rounds |
| `search.py` | The loop (`run`), the final re-measurement (`confirm`), the cheap path from the learned model alone (`tune`), the table (`table`), a summary (`report`) |

## The candidates

A workgroup has WM × WN subgroups of 64 threads. Each subgroup computes TM × TN tiles of 64 × 64 on
the matrix units (fp32, 64 × 64 × 8 a product). Other parameters:
- the K step BK (16, 32 or 64), and PAD floats of padding per shared-memory row;
- STAGES: two shared buffers, one barrier a step instead of two;
- PF: fetch the next step's slices into registers before this step's products;
- XG: load X's tiles straight from memory, so shared memory holds only W's unpacked slice.

The reference is `p_gemm_t2`, which is 2×2 subgroups, 1×1 tiles, BK 16, one buffer, no prefetch.
It was checked end to end against PyTorch and MLX.

## Run it

```bash
export ANDROID_SERIAL=<phone>
# a GPU and driver build the database has not seen: search, then confirm
python3 tuner/search.py run --model qwen3 --rows 128,512,1024 --rounds 4
python3 tuner/search.py confirm --model qwen3
# once it has: new shapes or prompt lengths from the learned model, one short run on the phone
python3 tuner/search.py tune --model qwen3 --rows 256,768 --top 6
python3 tuner/search.py table --model qwen3      # writes qwen3/gemm_table.mojo
python3 android/build.py qwen3
```

Each round fits the model on every measurement so far. It then measures the candidates the model
ranks best for each shape, plus 6 untried ones at random, on every shape they fit. The reference
runs in every round, and each time is taken relative to it in the same run. That cancels clock
and temperature changes between runs: the phone's reference time for one shape drifted from 50 to
73 ms during a search.

## On the Galaxy S26 Ultra (SM-S948U, driver 512.842.19)

The device taught the verifier two rules (`devices/SM-S948U-S948USQS4AZG3.json`):
- **One accumulator a subgroup.** With two or four 64 × 64 fp32 accumulators a subgroup, the driver
  cannot create the pipeline, for every block shape tried (23 candidates).
- **Under 32 KB of shared memory.** At exactly 32,768 bytes, the limit Vulkan reports, the kernel
  runs and returns wrong results. The two such candidates were off by more than the outputs' own size.

That leaves 160 of the 1,200 candidates. Among the 22 that only change the block shape, K step and
padding, the reference was already the fastest. The gains come from the pipeline options: X straight
from memory, prefetch, two buffers.

The search ran 4 rounds after a seed grid of 22 candidates. Then `confirm` timed each shape's three
best against the reference, in 7 interleaved rounds:

| Projection (n × k) | 128 rows | 512 rows | 1024 rows |
|---|---|---|---|
| q/k/v (6144 × 4096) | 1.04× `2x1-k32-xg` | 1.27× `2x2-s2-pf-xg` | 1.18× `2x2-s2-pf-xg` |
| o (4096 × 4096) | 1.26× `1x2-k32-pf-xg` | 1.30× `2x2-s2-pf-xg` | 1.11× `1x2-xg` |
| gate/up (24576 × 4096) | 1.22× `2x2-s2-pf-xg` | 1.20× `2x2-s2-pf-xg` | 1.16× `1x2-xg` |
| down (4096 × 12288) | 1.20× `1x2-k32-pf-xg` | 1.08× `1x2-pf-xg` | 1.08× `1x2-pf-xg` |

Unnamed parameters are the reference's: 1×1 tiles, BK 16, no padding, one buffer. The cost model's
rank correlation on each round's new candidates, before it saw them: 0.23, 0.70, 0.64, 0.25. It
improves once a round shows it what an option does. It drops when the best candidates are already
measured and only close ones remain.

## The learned model: fewer runs, less heat

Each run heats the phone, and a hot phone throttles: during the search, the reference kernel's time
for one shape went from 50 to 73 ms. So the fewer candidates the phone has to time, the better.
`evaluate.py` measures how few are enough. For each shape, it trains on the other 11 shapes'
measurements (828 of 57 candidates) and ranks the held-out shape's candidates. It then asks what
share of the best possible speedup the top k contain:

| Ranker | top 1 | top 3 | top 6 | top 8 | rank correlation |
|---|---|---|---|---|---|
| the analytic roofline alone | 0.00 | 0.10 | 0.13 | 0.28 | −0.03 |
| ridge regression on its terms | 0.46 | 0.53 | 0.59 | 0.59 | 0.60 |
| **gradient-boosted trees (ours, numpy)** | **0.65** | **0.77** | **1.00** | **1.00** | **0.80** |
| the same trees in scikit-learn | 0.65 | 0.73 | 0.92 | 1.00 | 0.80 |
| random order | 0.07 | 0.20 | 0.35 | 0.40 | |

For a shape it has never seen, the trees' top 6 always contained its best candidate. The search
timed 40 to 57 candidates a shape to find the same ones. `tune --top 6` times only those 6 and the
reference, so a new shape or prompt length costs about a seventh of the GPU time. The roofline alone
ranks no better than chance on this kernel: what it misses, such as the cost of staging X in shared
memory and the driver's scheduling, the trees learn from the phone's own measurements.

## End to end: Qwen3-8B's prefill with the tuned table

On the same S26 Ultra, `Qwen3.prefill` with the generated `qwen3/gemm_table.mojo` against the reference
kernel everywhere. The two builds alternate, each run after the phone cooled under 40 °C:

| Prompt | Reference kernel | Tuned table | Speedup | Generated tokens |
|---|---|---|---|---|
| 408 tokens (Llama's passage) | 3.94, 4.01 s | 3.64, 3.69 s | 1.08× | the same 80 |
| 1000 tokens | 9.10, 9.14 s | 8.49, 8.50 s | 1.07× | the same 24 |

The tuned build also passes the 16-step MLX check (all greedy tokens, logits within 0.011). Decode
is unchanged, because it does not use this kernel. The projections gain 1.04–1.30× each; the rest of
the prefill (attention, norms) is untouched, so the whole prompt gains about 1.08×.
