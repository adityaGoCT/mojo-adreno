# Toward peak GEMM on Adreno: peak measurements and an assembly feasibility probe

First step of an "AdrenoBLAS" project (a cuBLAS/rocBLAS-style GEMM library for Adreno GPUs):
measure what the hardware can do, see how far the current GEMMs are from it, and test whether
hand-written assembly can run on the device. Measured 2026-11-21 on a Qualcomm Device Cloud QRD.

## Device

QDC "Art" QRD (`ro.soc.model` SM8975, Android 17 userdebug, root shell): **Adreno 850**
(chip id 0x44051431, `gpu_model` Adreno850v2), GPU clock up to 1.45 GHz (sampled at 1.45 GHz for
85% of the run), stock Vulkan 1.4.351 driver, compiler E17.52.10.04, subgroup size 64, 32 KB shared memory.

## Peak throughput (stock driver, GPU timestamps)

| path | measured | theoretical at 1.45 GHz | kernel |
|---|---|---|---|
| fp32 ALU (mad) | **4.41 TFLOP/s** | 4.45 (1536 lanes x 2) | `peak/spv/peak_f32_w2_c16` |
| fp16 ALU (mad) | **8.36 TFLOP/s** | 8.91 (2x fp32) | `peak/spv/peak_f16_w1_c32` |
| fp16 cooperative matrix, fp16 acc | **17.5 TFLOP/s** | (matrix path, see below) | `peak/spv_cml/cml_f16f16_n32k16_b1` |
| fp16 cooperative matrix, fp32 acc | **15.9 TFLOP/s** | | `cml_f16f32_n32k16_b1` |
| fp32 cooperative matrix | 3.4-4.1 TFLOP/s | runs on the ALUs | `cml_f32f32_*` |

The fp16 cooperative-matrix path runs at 2.1x the fp16 ALU peak, so the 850 has matrix hardware
for fp16 (17.5 TFLOP/s = ~6,000 FMA per clock). The driver's statistics agree: a loop of 64 matrix
multiplies counts as 32 fp32 + 1 fp16 ALU instructions. Its fp16 results are 3x more accurate than
rounding every product and sum to fp16 (the 840 matched that model exactly), i.e. a wider internal
accumulator.

Microbenchmark pitfalls found on the way (all in the generators' comments):
- fp16 `x == 1234.5` is provably false (not representable): the compiler deleted the whole loop.
- coopMatMulAdd with the same A and B every iteration is hoisted (time ~ M*N, not M*N*K); scaling A
  by a scalar each iteration is factored out too. Only a fresh A loaded each iteration is honest.
- Stock-driver bugs: adding two cooperative matrices (`c0 + c1`) segfaults the compiler; int8
  cooperative matrices segfault; 64x64 tiles with a fresh A per iteration hang the GPU (device lost).

## Where today's GEMM stands (2048^3, stock driver)

| kernel | TFLOP/s | of peak |
|---|---|---|
| Mojo `matmul_coopmat_smem_f16` (840-tuned) | 4.25 | 24% of the fp16 matrix path |
| Mojo `matmul_coopmat_smem_f32` | 2.82 | 63% of fp32 ALU |

The gap is in the kernel, not in the driver's code generation: the same compiler sustains 98% of
17.5 TFLOP/s in the microbenchmark. Tile shape, staging and occupancy are what's missing.

## Assembly: what works and what doesn't

| route | status |
|---|---|
| Mesa Turnip + `IR3_SHADER_OVERRIDE_PATH` (hand-written ir3 assembly in place of a compiled shader) | works in principle for the **840** (Mesa knows it); Turnip refuses the **850** (`chip_id 44051431 unsupported`), also on Mesa main as of 2026-11-21 |
| Read the stock driver's machine code | **works**: `VK_KHR_pipeline_executable_properties` gives statistics only, but the pipeline cache holds the ISA (`isa/patch_cache.py` unpacks it) and Mesa's `ir3-disasm -c 44050A31` decodes almost all of it |
| Matrix instructions | four words Mesa doesn't know in the loop body (`82014200_00000220`, `e6580000_00000000`, `92405a00_01300200`, `82215200_00000200`): new cat4/cat7 encodings, to be reverse-engineered by diffing shader variants |
| Inject patched ISA through the pipeline cache | **blocked**: re-packed unmodified blobs hit (0.6 ms pipeline creation), but any code change is detected (100 ms: silent recompile). Entry header word 9 is a content checksum; not CRC32/CRC32C/Adler32/FNV/Murmur3/xxHash32 over the obvious ranges |

Cache blob layout (driver E17.52.10.04): 32-byte Vulkan header; entries of `key[8] u32 size u32 flag
{u32 raw_size u32 1 zlib}`; entry 0 is the driver's LLVM 17 IR (`llvm.qgpu.coopmat.*` intrinsics),
entry 1 the hardware shader: 0x50-byte header (magic `b10bcace`, word 9 checksum), sections, code
at 0x880 for the probe kernel.

## Files

```
peak/gen_peak.py           ALU peak shaders (fp32/fp16, widths 1-4, 8-32 chains)
peak/gen_coopmat_peak.py   cooperative-matrix shaders with loop-invariant inputs (shows the hoisting)
peak/gen_coopmat_load.py   cooperative-matrix shaders with a fresh A per iteration (the honest number)
peak/vk_bench.c            harness (from iree-adreno-genai-tuner gemm/harness) + Vulkan 1.3 features,
                           cooperative matrix, VK_BENCH_CACHE_IN/OUT, pipeline-creation timing
peak/run_peak.py, run_list.sh   push + run + TFLOP/s
isa/vk_isa_dump.c          pipeline statistics / internal representations / cache blob of one shader
isa/patch_cache.py         unpack, patch and re-pack a pipeline-cache blob
isa/hashes.py              checksum candidates tried
isa/dump/                  blobs and disassembly from the 850
```

Run (QDC tunnel on [::1]:5037):
```
export ADB_SERVER_SOCKET='tcp:[::1]:5037' ANDROID_SERIAL=<serial>
cd peak
python3 gen_peak.py && python3 run_peak.py stock
python3 gen_coopmat_load.py && python3 run_peak.py stock >/dev/null && ./run_list.sh manifest_cml.txt spv_cml/variants.txt 2048
```
