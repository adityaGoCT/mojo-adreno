# Adreno 850 Vulkan driver: cooperative-matrix bug reproductions

Standalone reproductions of 13 problems in the Adreno 850's Vulkan driver: 12 around `VK_KHR_cooperative_matrix`,
and one (#13) with `VK_KHR_push_descriptor`.
Each has a minimal or real-world compute shader, a control shader that differs only in the construct that triggers
the problem, and an automatic check. They were found building AdrenoBLAS (an fp16/Q4_0 GEMM library) and a
Llama 3.2 3B prefill on this GPU ([`../ablas/`](../ablas/)), and #13 putting AdrenoBLAS into llama.cpp
([`../ablas/llamacpp/`](../ablas/llamacpp/)). Impact estimates are in [`../urgent_matter.md`](../urgent_matter.md).

## Device and driver

| | |
| --- | --- |
| device | Qualcomm Device Cloud "Art" QRD, SM8975 (`ro.soc.model`), Adreno 850 (`gpu_model` Adreno850v2, chip id 0x44051431) |
| OS | Android 17 userdebug, `qti/art/art:17/CQ2A.260820.002-CP2A.260605.016/eng.lnxbui:userdebug/test-keys` |
| driver | Qualcomm Technologies Inc. Adreno Vulkan Driver, Driver Build: dbca1a4c11, Ie9dcd0093d, 1787853470, Date 08/27/26; compiler E17.52.10.04 (`libllvm-qgl.so`); Vulkan 1.4.351 |
| features used | `VK_KHR_cooperative_matrix` (fp16 64 x 16 x {32, 64}, int8 64 x 32 x 32), `VK_KHR_push_descriptor`, shaderFloat16, shaderInt8, 8/16-bit storage, vulkanMemoryModel |

Every result below was reproduced on this build on 2026-11-21 with `run_all.sh` (`results/run_2026-11-21.txt`; per-test
logs and crash backtraces in `results/logs/`). All 12 problems reproduce, and all 16 controls pass. #13 was added
later the same day (`results/run_2026-11-21_b13.txt`): it reproduces and its control passes.

## The problems

| # | what | repro (control) | expected | observed |
| --- | --- | --- | --- | --- |
| 1 | K loop unrolled by 2: two dependent `coopMatMulAdd` into each of two 64 x 32 fp16 accumulators per iteration | `b01_min_two_acc_kunroll2` (`b01_min_control_two_acc_ku1`); real kernel `b01_kunroll2_gemm_tn_1024` | C = A B | **GPU hang**: the submit never completes. One accumulator unrolled by 2 runs (`b01_note_one_acc_kunroll2`) |
| 2 | adding two cooperative matrices: `c0 + c1` (fp16 accumulators), `ma + ma` (int8 A matrices) | `b02_add_f16` (`b02_control_add_elementwise`); `b02_add_i8_loop` (`b02_control_i8_loop_noadd`) | the sum | fp16: **wrong sums** (510 of 2,048, no error); int8: `vkCreateComputePipelines` returns -13. (An earlier build segfaulted on both.) |
| 3 | converting an fp32 accumulator to an fp16 accumulator: `coopmat<float16_t, ...>(acc32)` | `b03_f32_to_f16` (`b03_control_store_f32`) | the product in fp16 | **wrong values** (error 6.5e4, no error reported). (An earlier build segfaulted.) |
| 4 | two 64 x 64 fp16 accumulators per subgroup | `b04_min_two_acc64` (`b04_min_control_one_acc64`); real kernel `b04_two_acc64_gemm_tn_2048` | C = A B | **GPU hang** |
| 5 | `coopMatLoad` from a `uint` or `uvec4` shared array | `b05_shared_uvec4`, `b05_shared_uint` (`b05_control_shared_f16vec4`) | exact copy | **wrong data**, no error (1,008 of 1,024 values) |
| 6 | four 64 x 32 accumulators, two chains combined element-wise | `b06_dual_t1x2_gemm_tn_1024` (`b06_control_dual_t1x1_gemm_tn_1024`) | pipeline created | `vkCreateComputePipelines` returns **-13** (VK_ERROR_UNKNOWN) |
| 7 | M, N, K as specialization constants (same SPIR-V otherwise) | `b07_nn_2048_specconst` (`b07_control_nn_2048_literals`); `b07_tn_1024_specconst` (`b07_control_tn_1024_literals`) | same speed as literals | **2x slower** (4,114 vs 2,107 µs at NN 2048³); TN 1024³ **GPU hang** |
| 8 | element writes into a cooperative matrix that was never initialized | `b08_q4_uninit` (`b09_q4_control_runtime_index`) | compiles | **compiler segfault** in `vkCreateComputePipelines` (`llvm::SwitchInst::SwitchInst` → `llvm::BasicBlock::getContext`) |
| 9 | a write to element 4 of a 16 x 64 fp16 B matrix with a constant index (`b[4] = x`) | `b09_q4_elem4_const` (`b09_q4_control_runtime_index`) | C exact | **the write is dropped**: every C value with k % 16 == 4 is wrong (keeps the initial 0). A runtime index (always 4) works |
| 10 | constant-index reads of accumulator elements into a vector constructor (`f16vec4(acc[0], acc[1], ...)`) | `b10_const_acc_element_read` (`b10_control_loop_read`) | compiles, exact copy | **compiler segfault** (`spv::SPIRVCodeGen::handleOpLoad`) |
| 11 | `coopMatMulAdd` under a branch that differs between the subgroups of a workgroup (uniform within each) | `b11_branch_mma` (`b11_control_unconditional`); real kernel `b11_fa3_original` (`b11_control_fa3_workaround`) | compiles | **compiler segfault** (recursion in `llvm::CoopMatLayoutNode::getUseCommonMask`) |
| 12 (candidate) | 16 element writes into an initialized B matrix in straight-line code, then one multiply | `b12_elem_write_straightline` (`b12_control_coopmatload`) | C exact | **every C value wrong**. The same writes inside the Q4_0 kernel (bug 9) are right except element 4, so this may share bug 9's cause |
| 13 | push descriptors in a command buffer that also dispatches another pipeline with an ordinary descriptor set: three push-descriptor dispatches (own output buffer, tag 1..3 in push constants), each followed by such a dispatch | `b13_push_then_bound_set` (`b13_control_no_bound_set`) | buffer t = t * 65536 + i | **wrong results, no error**: buffers 1 and 2 never written, buffer 3 = 6 * 65536 + i, so every push-descriptor dispatch used the descriptors pushed last (push constants were each dispatch's own) |

Notes:
- **Element mapping relied on (bugs 8, 9, 12):** after `coopMatLoad`, a 16 x 64 B matrix holds column n in lane n and k
  in element k; a 64 x 16 A matrix holds row r in lane r; a 64 x 64 accumulator holds row r in lane r and column e
  in element e (`../ablas/llama3b/probe/map.comp`). The Vulkan spec leaves this mapping to the implementation; the
  tests only assume it is the same for writes as for loads of the same matrix type, which bug 9's control confirms.
- **Hangs** (1, 4, 7): the process sits in `vkQueueWaitIdle` until killed (120 s here); no `VK_ERROR_DEVICE_LOST`
  is returned within that time, and the next process gets a working device. The controls of the same size finish
  in under 6 ms. (Earlier sessions also saw `VK_ERROR_DEVICE_LOST` from these kernels.)
- **Crash backtraces** (8, 10, 11) from logcat are in `results/logs/<test>.backtrace.txt`; all are inside
  `/vendor/lib64/libllvm-qgl.so` (BuildId e73eea03221340e9b47d082c4902a8c3) during `vkCreateComputePipelines`.
- **#13** needs no cooperative matrices: `b13_push_then_bound_set.comp` is a one-line fill shader, and the other
  dispatch is `b13_bound_set_dispatch.comp` (its own pipeline layout, one ordinary descriptor set at set 0), recorded
  with a barrier on each side. Binding that pipeline and set without dispatching does not trigger it. Found because
  llama.cpp's Vulkan backend (ordinary descriptor sets) and AdrenoBLAS (push descriptors) share command buffers.
- **The real kernels** (`*_gemm_*`, `b11_fa3_original`) are AdrenoBLAS's generated GLSL, unchanged; each header
  names the generator and configuration.

## Run it

Prebuilt: `repro` (Android arm64, needs only `libvulkan.so`) and `shaders/*.spv`. On the phone:

```bash
adb shell mkdir -p /data/local/tmp/adreno_repro/shaders
adb push repro run_all.sh /data/local/tmp/adreno_repro/
adb push shaders/*.spv /data/local/tmp/adreno_repro/shaders/
adb shell "cd /data/local/tmp/adreno_repro && ./run_all.sh"                  # every test, one process each
adb shell "cd /data/local/tmp/adreno_repro && ./run_all.sh b09_q4_elem4_const b09_q4_control_runtime_index"
```

Each test prints `RESULT <test> PASS | WRONG | PIPELINE_ERROR | DEVICE_LOST <details>`; `run_all.sh` reports
`CRASH` (signal) and `TIMEOUT` (hang) itself, keeps each test's log in `logs/`, and saves the crash backtrace from
logcat (`logs/<test>.backtrace.txt`). `./repro list` lists the tests.

Rebuild: `./build.sh` (glslc `--target-env=vulkan1.3 -O`, Android NDK clang; `spirv-dis` writes `shaders/*.spvasm`).

## Files

```
repro.c           the harness: Vulkan setup, one pipeline per test, deterministic inputs, CPU check, GPU timing
run_all.sh        runs every test in its own process, classifies crashes and hangs, collects backtraces
build.sh          SPIR-V (+ .spvasm disassembly) and the Android binary
shaders/          GLSL sources, SPIR-V, disassembly; bNN_* = bug NN, *_control_* = its control
results/          the run on the device above, and the crash backtraces
```
