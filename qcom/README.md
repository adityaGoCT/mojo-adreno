# Prompt kernels for VK_QCOM_cooperative_matrix_conversion

`VK_QCOM_cooperative_matrix_conversion` (Vulkan 1.4.342) adds four shader instructions to
`VK_KHR_cooperative_matrix` that move data between a thread's registers and a matrix tile. The
kernels here are drop-in replacements for the prompt matrix products (same bindings, parameters
and grid) that use it to multiply in fp16 and sum in fp32:

| file | replaces | models |
|---|---|---|
| `p_gemm_t2.comp` | `bonsai/kernels/prefill.mojo` `p_gemm_t2` (ternary weights) | Bonsai 2 2B (and a future ternary Qwen3-8B prefill) |
| `p_gemm.comp` | `llama/kernels/prefill/p_gemm.mojo` (fp16 weights) | Llama 3.2 1B |
| `p_gemm_q4.comp` | `llama/kernels/prefill/p_gemm_q4.mojo` (int4 weights) | Llama 3.2 1B, 4-bit |

Each subgroup owns a 64 x 64 tile of the output, without shared memory. Thread i builds row i of the
A tile from the activations and column i of the B tile from the weights, in registers
(`vectorToCoopmatQCOM`): one 32-bit word of ternary codes is exactly one fp16 K16 column. The tiles
multiply in fp16, the Adreno 840's fastest product, which sums only in fp16. So after each group of
128 values (64 for int4), thread i pulls row i of the partial sum out (`coopmatToVectorQCOM`), scales
it by the group's column scales and adds it into its fp32 row of the output: fp16 products, fp32
accumulation, as the decode kernels do.

They are GLSL because Mojo's SPIR-V target cannot emit the QCOM instructions yet: LLVM's SPIR-V
backend has none of them. They compile with glslang 16.2 and pass `spirv-val`. **They have not run:
neither driver we tested has the extension** (512.842.19, Galaxy S26 Ultra; 512.842.25, Qualcomm's
SM8850 reference phone).

## Testing them on a driver that has the extension

```bash
glslangValidator -V --target-env vulkan1.3 qcom/p_gemm_t2.comp -o build/bonsai/prefill/qcom/p_gemm_t2.spv
glslangValidator -V --target-env vulkan1.3 qcom/p_gemm.comp -o build/llama/prefill840/qcom/p_gemm.spv
glslangValidator -V --target-env vulkan1.3 qcom/p_gemm_q4.comp -o build/llama/prefill840/qcom/p_gemm_q4.spv
python bonsai/run.py --model M512 --hf H --prefill            # pushes qcom/ too; reports the extension
QCOM_COOPMAT=0 python bonsai/run.py --model M512 --hf H --prefill   # the KHR-only kernels, to compare
python3 llama/run.py --model <snapshot> --prefill --prompt-file llama/prompts/long.txt
```

`bonsai_vk`, `llama_vk` and `qwen3_vk` print `VK_QCOM_cooperative_matrix_conversion: yes/no`. With a
prefill on a driver that has it, the runners enable the feature (declared in
[`runner/qcom_coopmat.h`](../runner/qcom_coopmat.h), since the NDK's headers predate it) and load each
kernel that `<prefill dir>/qcom/` has in place of the default, printing which. `QCOM_COOPMAT=0` keeps
the KHR-only kernels. Validation against the references then shows both the speed and the effect of
fp16 products on the logits. Qwen3-8B only reports the extension: its decode is matrix-vector work.
