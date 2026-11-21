# Hand-written Adreno assembly on the Adreno 840 through Mesa Turnip

Second step of the AdrenoBLAS assembly question (step 1, on the QDC Adreno 850, is `../README.md`): can
hand-written ir3 assembly run on an Adreno 840, and does it beat the compilers (Qualcomm's stock driver and Mesa
Turnip's own ir3 compiler) for GEMM-style ALU math? Measured 2026-11-21.

## Verdict

* **Assembly runs.** Mesa Turnip (commit 745709a) drives the 840 unmodified, and its `IR3_SHADER_OVERRIDE_PATH`
  hook swaps any compiled shader for a hand-written `.asm` file. Proof: an unchanged dump round-trips (Turnip logs
  "Native code (overridden)", same timing). Changing one loop increment halves the run time (8.68 → 4.36 ms).
  The hand-written GEMM loops below pass the harness's check against a reference C.
* **Peak ALU loops: nothing to gain.** Turnip's compiler already reaches 99% of peak for fp32 and fp16 multiply-add
  loops. Hand-written loops, `(rpt3)` included, match it but cannot beat it. The stock compiler is at 99% for
  fp32 but only 89% for fp16.
* **GEMM: assembly wins, but only up to a memory-path ceiling.** I measured an ALU register-file rule that
  Turnip's register allocator ignores (the stock compiler's code was not inspected): a `mad` whose three
  register sources all sit in the same bank issues at about 1/3 rate. There are two banks, by the parity of
  the register's scalar index: `.x/.z` vs `.y/.w`; for fp16, the low vs high 16-bit half. Turnip's fp16 GEMM
  loops have half their mads in that form. A hand-written fp16 GEMM loop with a bank-aware register layout
  (plus `(rpt3)` and cheaper addressing) runs its ALU part at 90% of peak, against 56% for Turnip's loop. End to end it reaches
  **3.65 TFLOP/s at 2048³**. That is +10% over Turnip's 3.33 on the same kernel and +8% over the best stock
  kernel (3.39). The kernel is then bound by operand bandwidth: about 120 B/clk/SP on the texture path and about
  107 B/clk/SP from shared memory, while an 8×8 register tile needs about 256 B/clk/SP at peak.
* **The 840 has no matrix unit.** The stock cooperative-matrix path tops out at 7.35 TFLOP/s fp16, below the
  7.99 fp16 ALU peak, so it runs on the ALUs (the 850 has 2.1× matrix throughput). Turnip exposes no cooperative
  matrix on the 840. For AdrenoBLAS on the 840, ALU GEMM is the only path. Its speed is set by data movement
  (tile shape, splitting operands across the shared-memory and texture paths) more than by instruction
  selection. Assembly adds the last ~10% once a kernel is ALU-bound. Teaching Turnip's register allocator
  the bank rule (`turnip-ra-bank.patch`, section below) removes the slow mads. It gains up to +18% on some
  GEMM kernels but only +1.5% across all 22, because moving registers costs scheduling freedom and fp16 has
  a second placement effect not yet characterized.

## Device and setup

Samsung Galaxy Z Fold SM-F976B (SM8850, Android 17 build CP2A.260605.016) on Samsung Remote Test Lab, reached
through RDB as adb serial `localhost:59796`. GPU `Adreno840v2`, 19 clock levels from 160 to 1300 MHz, subgroup 64,
32 KB shared memory.

* **Turnip:** the prebuilt `~/runix/adreno-port/build/turnip-android` (Mesa 26.3-devel, git 745709a) plus the
  `turnip-shim` loader shim. No rebuild was needed: Mesa already lists the 840 (chip id 0xffff44050A31, a8xx gen2).
  `vkinfo` under Turnip reports "Adreno (TM) 840", Vulkan 1.4.363, 160 extensions, shaderFloat16/Int8, and
  subgroup size control (64 only). It does not expose VK_KHR_cooperative_matrix.
* **Theoretical peak** (inferred from the measurements and the 1.3 GHz top clock): 1536 fp32 FMA/clk =
  **3.99 TFLOP/s fp32**, and twice that for fp16 = **7.99 TFLOP/s**.
* **Thermals:** after a few minutes of back-to-back runs the phone caps the GPU (`thermal_pwrlevel` went to 9 =
  578 MHz once). `run.py` waits for the cap to lift before every run. Each result also records the fraction of
  busy time at 1300 MHz from `gpu_clock_stats` (the `clk` column; approximate, because it includes ramp-up). The
  stock fp16 GEMM numbers moved by up to ±8% between rounds, so the final comparison was run back to back.

## Peak ALU throughput (8192 work-groups × 128 lanes × 512 iterations, GPU timestamps)

| path | stock | Turnip | of theoretical |
|---|---|---|---|
| fp32 mad (best of 8 shapes) | 3.947 | **3.964** | 99% / 99% |
| fp16 mad | 7.093 | **7.901** | 89% / 99% |
| fp32 mad, operands in registers (`_rr`) | 3.820 | 3.964 | |
| fp16 mad, operands in registers | 7.091 | 7.828 | |
| fp16 cooperative matrix (fresh A per iteration) | 7.35 | n/a | below the ALU peak: no matrix unit |
| fp32 cooperative matrix | 3.68 | n/a | |
| hand-written asm loop, fp32 `(rpt3)mad` | | 3.948 | 99% |
| hand-written asm loop, fp16 `(rpt3)mad` | | 7.895 | 99% |

Throughput needs at least 32 independent fp32 or 64 independent fp16 mads per iteration. With 8–16 chains every
variant takes the same ~7.6 ms: a fixed per-iteration cost of about 7 clocks per wave per SP.

## Injecting assembly

```
IR3_SHADER_DEBUG=cs MESA_LOG_FILE=/data/local/tmp/asm_mesa/out/x.log   # dump NIR + disassembly + blake3
python3 extract_asm.py dumps/x.log asm_dump                              # -> asm_dump/<blake3>.asm
IR3_SHADER_OVERRIDE_PATH=<dir with <blake3>.asm> MESA_SHADER_CACHE_DISABLE=true   # use it
```

* (a) Round trip of the unchanged `peak_f32_w2_c16` dump: the log says "Native code (overridden)" and timing is
  identical (3.957 TFLOP/s). The re-disassembled code matches apart from padding nops and the const block.
* (b) Visible edit (`edits/half_loop/`): `add.u r49.z, r49.z, 1` → `2` (the shared-register loop counter).
  Run time drops from 8.68 to 4.36 ms.
* (c) Hand-written kernels: `gen_asm_peak.py` and `gen_asm_gemm.py` keep Turnip's prologue and epilogue and
  replace the loop. The GEMM variants pass the harness's comparison against a reference result.

Practical notes (all hit during this work):

* `@const(cN.x)` lines are re-applied relative to the immediates base, so they land at a later offset and grow
  `constlen`. The compiled variant's immediates survive the override anyway, so the generators drop those lines.
  Hand-written code should use the existing consts or `mov` immediates.
* Half registers end at `hr47.w`. `hr48`+ are the shared (wave-uniform) registers. An fp16 double buffer that
  crossed into hr48 ran silently and produced garbage.
* `isam` may read its address register after issue (ir3_legalize's WAR rule). Overwriting that register needs
  `(ss)` or `(sy)`.
* `(nopN)` inserts N nops *after* the instruction. Delays on a8xx: ALU→ALU 3 slots, ALU→load/store 6, mad src3
  read 2 cycles late. `(sy)` waits for *all* outstanding texture/global loads and `(ss)` for all shared-memory
  loads; there is no partial wait.
* In `ldl.u16`/`stl.u16` the disassembler prints half registers without the `h` (`ldl.u16 r39.z` = hr39.z). Write
  them the same way.
* On Android, Mesa logs go to logcat unless `MESA_LOG_FILE` is set. Without `MESA_SHADER_CACHE_DISABLE=true`,
  a cached variant would skip the override.

## The register-bank rule (hand-written peak loops, Turnip, TFLOP/s)

`gen_asm_peak.py` rewrites the loop of the fp32 peak kernel (32 or 64 accumulators) with chosen operand
registers. The layout is GEMM order, `mad acc, m, d, acc`, and the components are relative to the accumulator's.
(The fp16 column of this first table was measured with uninitialised fp16 accumulators; the clean fp16 sweep
below supersedes it.)

| sources | fp32 | fp16 |
|---|---|---|
| const, reg, const (what the compiler emits for the peak loop) | 3.940 | 7.861 |
| same with `(rpt3)` | 3.948 | 7.895 |
| 3 registers, three different components | 3.943 | 7.199 |
| 3 registers, src1 = src2 component | 3.944 | 7.200 |
| 3 registers, src1 = src3 component | 3.900 | 7.200 |
| 3 registers, src2 = src3 component | 3.944 | 7.230 |
| **3 registers, all the same component** | **1.318** | **2.420** |
| all the same component, `(rpt3)` | 2.717 | |
| 3 registers, m two components from acc, d on acc's (`.x/.z/.x`) | 1.317 | |
| 3 registers, m on acc's, d two components away | 1.317 | |
| 3 registers, m and d both two components away | 1.317 | |

So the bank is not the component but its **parity**: `.x` and `.z` share one bank, `.y` and `.w` the other. A
mad pays ~3× when all three register sources are in the same bank; any mix is free; const and immediate
sources don't count.

fp16 (`gen_f16_sweep.py`, `analyze_f16_sweep.py`; Turnip's compiled `peak_f16_w4_c16_rr` loop rewritten with
64 fp16 mads, accumulators initialised, register footprint pinned so every variant has 16 waves):

| fp16 sources (m = src2, d = src3, accumulator = src1; same with the accumulator as src3) | TFLOP/s |
|---|---|
| any placement where the three are not all in the same 16-bit half | 7.84 |
| accumulators in low halves (`.x/.z`), m `.x`, d `.x` | 2.30 |
| accumulators in high halves (`.y/.w`), m `.y`, d `.y` | 2.30 |
| accumulators spread over all halves, m and d in the same half (half the mads conflict) | 4.0 |
| m and d rotating through the components, never in the same half | 7.83 |

For half registers the bank is the 16-bit half: `.x/.z` (low) vs `.y/.w` (high), the parity of the half
register's index, the same rule as for full registers. Operand order doesn't matter. `bankcheck.py` counts
such mads (`--comp` for the older same-letter count). Turnip's GEMM loops: fp16 50% of their mads in
every kernel (128 of 256 in `gemm_f16_gg_128x128`), fp32 11–50%.

## GEMM (2048³, fp16 C, A stored transposed; TFLOP/s; `gen_gemm.py`)

Thread tile 8×8 (two 4-wide chunks each way); 128- or 256-thread work-groups. The source letters say where A and B
come from in each k step: `l` = a shared-memory tile staged with barriers (`ldl`), `g` = straight from the
buffer (`isam`, the L1/texture path).

| kernel | fp32 stock | fp32 Turnip | fp16 stock | fp16 Turnip |
|---|---|---|---|---|
| ll 128×128×16 | 1.35 | 1.40 | 2.14 | 2.16 |
| ll 64×128×8 | 1.42 | 1.38 | 2.14 | 2.19 |
| lg 64×128×16 | 2.05 | 1.56 | 3.13 (3.39*) | 3.10 (3.13*) |
| lg 64×64×16 | **2.06** | 1.84 | 2.69 | 2.41 |
| gl 128×128×16 | 1.90 | 1.55 | 2.95 | 3.11 |
| gl 64×64×16 | 1.90 | 1.96 | 2.60 | 2.50 |
| gg 128×128 | 1.71 | 1.28 | 2.83 (3.04–3.22*) | **3.33** |
| **hand-written asm**, gg 128×128 | | | | **3.65** |

\* the final back-to-back round (5 reps × 200 ms).

Best result per column: fp32 2.06 = 52% of peak; fp16 compiled 3.39 = 42%; fp16 asm 3.65 = 46%. Splitting
the operands across the two memory paths (lg/gl) beats putting both on one path, for both compilers.

### Where the time goes (asm diagnostics: strip one instruction class from the loop, re-time; results wrong by design)

| kernel | full | no loads (ALU part) | no mads (loads part) |
|---|---|---|---|
| fp32 ll 128×128×16, Turnip (round 1: fp16-stored operands) | 12.35 ms | 6.79 ms (no `ldl`) | 10.41 ms |
| fp32 gg 128×128, Turnip | 13.35 ms | 8.50 ms = 2.02 TFLOP/s (51%) | 9.05 ms |
| fp16 gg 128×128, Turnip | 5.16 ms | 3.81 ms = 4.51 TFLOP/s (56%) | 4.56 ms |
| fp16 gg 128×128, **hand-written** | **4.70 ms** | **2.39 ms = 7.17 TFLOP/s (90%)** | 4.72 ms |
| fp16 lg 64×128×16, Turnip | 5.55 ms | | 3.87 ms |

* The texture path is byte-bound at about 120 B/clk per SP. fp32 loads (16 B) take twice as long as fp16 (8 B)
  for the same instruction count. A loads (4 distinct addresses per wave) cost the same as B loads (16): 3.12 vs
  3.03 ms when the other is removed. So broadcasts don't help.
* Shared-memory loads deliver about 107 B/clk per SP (fp32 ll kernel).
* Turnip's fp32 loops also convert all 64 accumulators to fp16 inside the loop (`cov.f32f16` per K tile; the
  conversion belongs after the loop), on top of 14% conflicting mads.

### What the hand-written fp16 loop does (`gen_asm_gemm.py`, template = Turnip's `gemm_f16_gg_128x128`)

* **Bank-aware layout.** The epilogue keeps acc[i][h] in `hr(17-2i-h).xyzw`, so the accumulator's component
  equals the B column's. B vectors are loaded starting one component late (`isam ... hr18.y`), so src1 (B) and
  src3 (acc) always differ in parity, and no mad can have all three sources in one bank. That gives 0
  conflicts with no extra instructions.
* **`(rpt3)mad.f16 acc.x, (r)b, a_i, (r)acc.x`**: one instruction per accumulator vector, 16 per k step
  instead of 64.
* **Incremental addressing** (one add per row) instead of Turnip's per-iteration shift/sad recomputation.
  This took the loop from 3.52 to 3.65 TFLOP/s.
* Double-buffering the loads (`dbuf2`: 3.65, `dbuf1`: 3.40) does not help: the kernel is load-bound, not
  latency-bound.
* The split-path (lg) loop, written the same way, is correct but slower than Turnip's (2.99 vs 3.10;
  B-pipelined 2.57). My version waits on a whole batch of loads before its mads, and it needs more registers.
  Turnip interleaves `ldl`/`isam` for the next k step between the current mads, which overlaps better. A
  faster lg kernel needs that fine-grained schedule plus the bank-aware layout.

## Bank-aware register allocation in Turnip (`turnip-ra-bank.patch`)

The bank rule, applied in Turnip's own compiler instead of in assembly. The patch changes ir3's register
allocator (`src/freedreno/ir3/ir3_ra.c`; ~165 lines, a8xx only):

* Before allocation it records every `mad` whose three sources are GPRs.
* When `find_best_gap` places a value that such mads read, it scores each free spot. A mad whose three sources
  would all share a component costs 4. One with two known sources sharing a component and the third not yet
  placed costs 1, which steers the first-placed operand away from the accumulator's bank. The allocator takes
  the lowest-cost spot, scanning onward from its usual round-robin position.
* Values produced by shared-memory loads (`ldl`) are left where the allocator would put them anyway (see below).
* `IR3_SHADER_DEBUG=nobankra` turns it off. With it off, the compiled shaders are byte-identical to the
  unpatched Turnip (checked by blake3). `IR3_BANKRA_MODE` (default 5) selects the variants tested below.
* It is built in `~/runix/adreno-port/build/turnip-android-bankra`; the original `build/turnip-android`
  binary is unchanged. On the phone it lives in `turnip_bank/` (`python3 run.py pushbank`, driver
  `turnip-bank`).

Results, 2048³, unpatched vs patched in the same session, interleaved per kernel (5 reps × 150 ms;
run-to-run noise ±2–3%). Every result passes the check against the reference.

| kernel | same-component mads in loop (unpatched) | unpatched TFLOP/s | patched | change |
|---|---|---|---|---|
| f32 ll 128×128×16 | 64/1024 | 1.40 | 1.40 | +0.0% |
| f32 ll 64×128×8 | 26/512 | 1.38 | 1.39 | +0.3% |
| f32 ll 64×64×16 | 28/1024 | 1.30 | 1.29 | −0.4% |
| f32 lg 128×128×16 | 110/1024 | 1.51 | 1.48 | −1.8% |
| f32 lg 64×128×16 | 170/1024 | 1.54 | 1.60 | +3.7% |
| f32 lg 64×64×16 | 54/1024 | 1.79 | 1.74 | −2.3% |
| f32 gl 128×128×16 | 77/1024 | 1.55 | 1.54 | −0.9% |
| f32 gl 64×64×16 | 52/1024 | 2.00 | 1.90 | −4.8% |
| f32 gg 128×128 | 37/256 | 1.28 | 1.36 | **+6.1%** |
| f32 gg 64×128 | 37/256 | 1.36 | 1.35 | −0.4% |
| f32 gg 64×64 | 37/256 | 1.57 | 1.52 | −2.9% |
| f16 ll 128×128×16 | 154/1024 | 2.16 | 2.16 | +0.1% |
| f16 ll 64×128×8 | 101/512 | 2.19 | 2.20 | +0.3% |
| f16 ll 64×64×16 | 67/1024 | 2.02 | 2.02 | −0.1% |
| f16 lg 128×128×16 | 115/1024 | 2.95 | 3.04 | +2.9% |
| f16 lg 64×128×16 | 116/1024 | 3.10 | 3.10 | −0.1% |
| f16 lg 64×64×16 | 213/1024 | 2.42 | 2.76 | **+14.3%** |
| f16 gl 128×128×16 | 105/1024 | 3.08 | 3.09 | +0.2% |
| f16 gl 64×64×16 | 67/1024 | 2.49 | 2.49 | −0.0% |
| f16 gg 128×128 | 55/256 | 3.28 | 3.32 | +1.3% |
| f16 gg 64×128 | 55/256 | 3.21 | 3.26 | +1.6% |
| f16 gg 64×64 | 55/256 | 2.53 | 2.99 | **+18.0%** |

Geometric mean +1.5%. The patch removes the same-component mads (to 0 in most loops; a few lg/gl loops keep
1–39). Register footprint and wave count are unchanged. The peak-loop kernels compile to identical code.

What limits it:

* **False dependencies.** Moving a load's destination away from the allocator's round-robin spot can land
  on registers that are still being read. Turnip's post-RA scheduler then can't hoist the load. In
  fp32 lg 64×64, texture loads move from ~40 instructions before their use to 2–20, and the loop gains three
  `(sy)` waits. Leaving shared-memory-load results in place (variant 5) removed the 3–5% losses on the ll
  kernels (variant 1 steered everything). The price: fp16 gl 64×64, whose conflicts sit in shared-memory-loaded
  operands, loses the +13.9% it had with variant 1 (±0 with variant 5). I tried and dropped three alternatives: limiting the search to 3
  shifts (variants 2/3), shifting half registers only by whole 32-bit registers (9/13), and picking the
  conflict-free spot freed longest ago (17/21). None did better than variant 5 (results/ab_mode*, st_mode*).
* **A second fp16 effect, not yet characterized.** In `peak_f16_w4_c16_rr` (three-register fp16 mads), the
  patch moves `d` from `hr9.y` to `hr9.w` (no component conflict either way), and the loop drops from 7.81 to
  7.17 TFLOP/s. Moving that operand by hand through the override (`edits/f16rule_*`) shows strong placement
  sensitivity. `d` in a high 16-bit half (`.y`/`.w`) runs at 7.78; in a low half (`.x`/`.z`) 6.04; `m` in
  a high half next to a high `d` 5.53. A "same 16-bit half for all three sources" rule fits those placements,
  but not the patched kernel: its loop scores the same as the unpatched one on every pairwise metric. A
  systematic placement sweep is needed before the allocator can model fp16 correctly.

Verdict: the bank rule is real and the allocator can avoid it cheaply. It gives up to +18% on kernels where
conflicts dominate. As a general default it is a small net win (+1.5%) with losses of up to 5% from
scheduling side effects and the unknown fp16 rule. Fixing those needs scheduler awareness (or a post-RA
renaming pass that keeps the round-robin order) plus the full fp16 placement rule.

## Reproduce

```
cd ~/runix/mojo-adreno/asm/mesa
export RTL_SERIAL=localhost:59796          # adb serial of the RTL phone (port changes per session)
NDK=/opt/homebrew/share/android-ndk/toolchains/llvm/prebuilt/darwin-x86_64/bin/aarch64-linux-android34-clang
$NDK -O2 -I ~/runix/adreno-port/third_party/iree/third_party/vulkan_headers/include -o vk_bench vk_bench.c -ldl -lm
python3 gen_peak.py; python3 gen_gemm.py   # shaders, manifests, 2048^3 test matrices (64 MB)
python3 run.py push                        # bench, Turnip, shaders, matrices (~2 min over RDB)
adb -s $RTL_SERIAL shell "ln -s /data/local/tmp/asm_mesa/shape/g2048_h/Cref.bin /data/local/tmp/asm_mesa/shape/g2048_s/Cref.bin"
python3 run.py run manifest_peak.txt stock;  python3 run.py run manifest_peak.txt turnip --env MESA_SHADER_CACHE_DISABLE=true
python3 run.py run manifest_gemm.txt stock;  python3 run.py run manifest_gemm.txt turnip --env MESA_SHADER_CACHE_DISABLE=true
python3 gen_asm_peak.py; adb -s $RTL_SERIAL push manifest_asmpeak.txt /data/local/tmp/asm_mesa/
./run_override.sh manifest_asmpeak.txt asmpeak_f32_pall asmpeak_f32_pall        # bank-conflict loop: 1.32 TFLOP/s
python3 gen_asm_gemm.py
./run_override.sh manifest_gemm.txt gemm_f16_gg_128x128 asmgemm_f16_single      # hand-written GEMM: 3.65, ok=True
```

The hand-written files depend on the exact Turnip build: the override file name is the blake3 of the
compiled variant, and the generators splice into templates from `asm_dump/`. After rebuilding Mesa, re-dump the
templates (`IR3_SHADER_DEBUG=cs`) and update the hashes in `gen_asm_*.py`.

`run.py` issues one plain command per `adb shell` call. The RDB bridge drops on `&&`, `&`, loops, `chmod`,
`nohup`, `setsid` and `sh script.sh`. Each manifest line runs in its own process, with output written to files
on the phone and read back with `cat`.

## Files

```
run.py               runner: push, one process per candidate, thermal gate, GPU-clock stats, results/<tag>.jsonl
run_override.sh      push edits/<dir>/*.asm and run one candidate on Turnip with IR3_SHADER_OVERRIDE_PATH
diag.sh, asm_edit.py strip an instruction class from a dumped loop (diagnostics)
vk_bench.c           copy of ../peak/vk_bench.c + optional ESZ field in meta.txt (fp32 operands)
gen_peak.py          peak shaders (copy of ../peak/gen_peak.py + register-operand variants) -> manifest_peak.txt
gen_gemm.py          GEMM shaders (ll/lg/gl/gg, fp32/fp16) + 2048^3 data -> manifest_gemm.txt
extract_asm.py       Mesa log -> asm_dump/<blake3>.asm
gen_asm_peak.py      hand-written peak loops (bank-conflict study) -> edits/asmpeak_*/
gen_asm_gemm.py      hand-written GEMM loops -> edits/asmgemm_f16_*/
bankcheck.py         count same-component 3-register mads in an .asm
turnip-ra-bank.patch Mesa patch: bank-aware ir3 RA (apply in ~/runix/adreno-port/third_party/mesa at 745709a)
bank_ab.py           run kernels on a driver with disassembly logged: TFLOP/s, check, conflicts per loop
asm_dump/            Turnip's disassembly of the kernels used as templates (and their blake3 names)
dumps/               raw Mesa logs (NIR + disassembly)
edits/               every injected .asm (half_loop = the loop-count proof; *_no* = diagnostics)
results/             every run (jsonl); gemm_{stock,turnip} = round 1 with fp16-stored fp32 kernels (superseded)
manifest_cml.txt     stock cooperative-matrix peak (shaders from ../peak/gen_coopmat_load.py)
```

## Follow-ups

* Read the stock driver's machine code on the 840 (the pipeline-cache route from `../isa`) to see whether
  Qualcomm's compiler avoids same-component mads. Its fp16 peak loop at 89% suggests something else is going
  on there.
* Bank-aware RA (above): characterize the fp16 half-register placement rule with an operand-placement sweep,
  and make the placement change scheduler-aware, so it stops costing up to 5% on some kernels.
* A faster ALU GEMM needs less operand traffic per FMA: larger register tiles (fp16 operands and accumulators
  must fit in hr0–hr47), and interleaved shared-memory and texture loads.
* Shipping route if assembly is ever used: apps would have to bring Turnip (e.g. libadrenotools, as Android
  emulators do). The stock driver's pipeline cache is checksummed (step 1).
