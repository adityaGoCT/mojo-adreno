# lt-convert: a model's files to an AdrenoBLASLt plan, run by a generic runtime on the phone

`../lt/llama_lt.c` is Llama 3.2 3B written by hand as a list of AdrenoBLASLt calls. lt-convert writes that list
from the model's own files instead:

```
model.gguf | config.json + *.safetensors
   -> convert.py (host, numpy + gguf-py)
        source      metadata -> config; tensors under GGUF's names; GGUF Llama's Q/K rows back to rotate-half order
        IR          the decoder-LLM family template, unfused: embedding, RMSNorm, Linear, RoPE, attention,
                    residual add, GLU, LM head on the prompt's last row
        fusion      q;k;v + RoPE -> ROPE_QKV; gate|up + SiLU/GELU -> SWIGLU/GEGLU; o/down + add -> RESIDUAL, whose
                    row sums the next RMSNorm takes; the LM head on the 64-row tile with the last token
        planner     layouts (fp32 rows for the residual stream, fp16 tiles between calls), buffers by liveness
                    (a*M + b bytes, M = the prompt's rows padded to its bucket), workspace left to the runtime
        packer      AdrenoBLAS's B formats (fp16 tiles, Q4_0), the GATE_UP row order, 4 KB-aligned
   -> model.plan (text) + weights.bin
   -> plan_run (phone, C): allocate, load, record one command buffer per prompt-length bucket (plus the LM
                            head's per last-token tile), replay
```

Nothing in `plan_run.c` knows Llama: it reads the plan, maps the weights, sizes the workspace by asking the library
(`ablasLt*WorkspaceSize`) and makes the calls the plan lists.

## Files

| file | what |
|---|---|
| `convert.py` | the converter: `python convert.py MODEL -o OUTDIR [--type q4_0\|f16] [--layers L] [--plan-only]` |
| `formats.py` | AdrenoBLAS's weight formats in numpy, packing and unpacking (reuses `../q4ref.py`) |
| `plan_run.c` | the runtime: `plan_run -p model.plan -t tokens.bin [-n N] [-g G] [-r R] [-b 512,1024] [-o DIR] [-P] [-d]` |
| `check_weights.py` | host check: every packed weight against the C `ablasLtWeightPack`, and against `../llama3b/export.py`'s |
| `lt_index.py` | an index that lets `llama_lt` read a converted `weights.bin`, for timing only (see Results) |
| `ref_hf.py` | fp32 reference for any HF decoder LLM with the phone's weights (transformers' own class), and `cmp` |
| `build.sh`, `stage.sh`, `bench.sh` | build (Android + a host binary for `-d` dry runs), push to the phone resumably, thermal-gated A/B |

## The plan format (version 0)

One statement per line, `#` comments. Integers may be linear in `M`, the run's row count (the prompt padded to its
bucket), and `T`, the first row of the 64-row tile holding the prompt's last token: `M`, `64`, `6144*M-393216`,
`6144*T`. An operand is a buffer or weight name, optionally at a byte offset: `h@6144*T`. The calls that use `T`
(the LM head) and any after them are recorded into a second, small command buffer per (bucket, `T`), so the body
is one command buffer per bucket.

```
ltplan 0
model arch=llama wtype=q4_0 layers=28 dim=3072 heads=24 kv_heads=8 head_dim=128 ffn=8192 vocab=128256 row_align=64
weights weights.bin 1807777792
weight blk.0.ffn_gate_up q4_0 16384 3072 gate_up 235810816 28311552     # name type rows cols use offset bytes
buffer x 12288 0                                                          # name bytes-per-row-of-M fixed-bytes
buffer logits 0 32833536
workspace ws                                                              # sized by plan_run from the calls
host embed out=x table=token_embd                                         # CPU: embedding rows (ablasLtWeightRow)
host rope_table out=cs inv_freq=rope.inv_freq dim=128                     # CPU: cos | sin per position
call rmsnorm M=M D=3072 x=x sumsq=ss weight=blk.0.ffn_norm eps=9.999999747378752e-06 out=h ws=-
call matmul epi=rope_qkv A=h a=f16:tiled:M:3072 W=blk.0.attn_qkv heads=24 kv_heads=8 rope=cs q=q k=k vt=vt ws=ws
call attention M=M heads=24 kv_heads=8 scale=0.0883883461356163 q=q k=k vt=vt out=h
call matmul epi=residual A=h a=f16:tiled:M:3072 W=blk.0.attn_output D=x d=f32:row:M:3072 aux=ss ws=-
call matmul epi=default A=h@6144*T a=f16:tiled:64:3072 W=token_embd D=logits d=f32:row:64:128256 ws=-
output logits buf=logits layout=f32:row:64:128256 row0=T                # the last token's row is len-1-row0
output hidden buf=h layout=f16:tiled:M:3072
```

`call` lines map one to one onto `ablasLtRmsNorm`, `ablasLtLayerNorm`, `ablasLtMatmul` (every epilogue and
descriptor field: `aux rope q k vt bias heads kv_heads head_dim head_dim_valid kv_rows kv_offset`),
`ablasLtAttention` and `ablasLtAttentionMasked` (`batches kv_batch keys key_valid suffix_base suffix_count
suffix_causal out_cols key_splits`). A weight's layout comes from its `weight` line. The converter writes the
Llama subset today; `layernorm`, `attention_masked` and the general ROPE_QKV fields are parsed and passed through
but no plan has exercised them yet.

## Results (Llama 3.2 3B Instruct, Adreno 850, QDC SM8975 QRD serial b3ba6e19, 2026-11-22)

Converted from `~/runix/llama.cpp-gguf/Llama-3.2-3B-Instruct-F16.gguf`: 396 IR ops fuse into 198 calls (28 x 7 + the
final norm + the LM head), the same sequence as `llama_lt.c`, in 10 buffers (`attn` shares `h`'s). Q4_0: 33 s on the
Mac, 1.808 GB; fp16: 23 s, 6.426 GB.

### Weights: byte-identical to llama_lt's

`check_weights.py`, every tensor of the plan:

| | Q4_0 | fp16 |
|---|---|---|
| vs `ablasLtWeightPack` (C, from the same rows) | identical\* | identical |
| vs `../llama3b/export.py` (from the HF safetensors; what `llama_lt` loads, gate/up interleaved as it does) | identical, except `inv_freq` | identical, except `inv_freq` |

- **Three sources, one blob.** The Q4_0 `weights.bin` from the F16 GGUF (requantized), from the Q4_0-pure GGUF
  (llama-quantize's blocks, repacked without requantizing: 17 s) and from the HF safetensors (bf16) are the same
  bytes, and the plans are the same text, except RoPE frequencies.
- **RoPE frequencies:** 5 of 64 differ from transformers' by 1 ulp from the GGUF (its `rope_freqs` divisors), 2
  from the HF path (the llama3 formula in numpy). Nothing else differs.
- **GGUF Llama's Q/K rows** come permuted for ggml's interleaved RoPE (`convert_hf_to_gguf.py`); the converter
  un-permutes them. The byte-identity with `export.py` checks this.
- \* **A library finding:** `ablasLtWeightPack`'s own fp32 -> Q4_0 quantizer differs from ggml's reference in
  ~0.4% of blocks (430k of 100M): clang contracts `v[j] * id + 8.5f` into a fused multiply-add (the default
  `-ffp-contract=on`, host and NDK), which rounds differently from ggml's product-then-sum. Built with
  `-ffp-contract=off` it matches exactly (so the checker builds it that way). Not fixed here: see Next.

### Accuracy: the same as llama_lt, bit-identical with the same RoPE frequencies

`plan_run -o`, then `../llama3b/ref.py cmp` (fp32 reference with the phone's weights), 512 tokens:

| | last-token logits cosine | top-1 | top-5 | KL(ref ‖ device) | hidden cosine mean / worst row |
|---|---|---|---|---|---|
| plan_run, Q4_0 | 0.99998 | same (304) | 5/5 | 4e-4 | 0.99992 / 0.9910 |
| llama_lt, Q4_0 (its README) | 0.99997 | same | 5/5 | 5e-4 | 0.99992 / 0.9929 |
| plan_run, fp16 | 0.99997 | same (304) | 5/5 | 6e-4 | 0.99993 / 0.9956 |
| llama_lt, fp16 (its README) | 0.99997 | same | 4/5 | 5e-4 | 0.99993 / 0.9948 |

- **Bit-identical:** with `export.py`'s 64 RoPE frequencies written into a copy of `weights.bin` (256 bytes, `dd` on
  the phone), `plan_run`'s logits and hidden states equal `llama_lt`'s byte for byte. Greedy generation (`-n 500 -g
  20`, through buckets of 512 and 576 rows) gives the same 20 tokens. With the GGUF's own frequencies the first 18
  tokens agree and token 19 flips between `,` and `.`.
- **Buckets:** a 500-token prompt in a 1024-row bucket (`-b 1024,2048`) gives hidden states and logits bit-identical
  to the 512-row run (and takes twice as long: the padding rows are computed).

### Speed: the same as llama_lt

Thermal-gated (`bench.sh`: each run starts at <= 45 °C with the thermal cap off), alternating, best of 3 runs each,
both orders. The Q4_0 rows ran while the 6.4 GB fp16 model was being pushed, the fp16 rows after; `llama_lt` too runs
0-3% slower here than in `../lt/README.md` (a warmer phone), so compare within the table:

| prefill | plan_run | llama_lt |
|---|---|---|
| Q4_0, 512 tokens | 205.2, 206.9 ms | 207.5, 207.9 ms |
| Q4_0, 1024 | 423.5, 432.8 ms | 434.9, 438.2 ms |
| Q4_0, 2048 | 943.0, 955.2 ms | 950.5, 949.4 ms |
| fp16, 512 | 223.6, 229.0 ms | 224.3, 220.9 ms |
| fp16, 1024 | 468.5, 475.5, 479.0, 476.8, 482.7, 471.8 ms (mean 475.7) | 461.5, 460.8, 472.8, 477.8, 473.6, 473.2 ms (mean 470.0) |
| fp16, 2048 | 995.1, 1023.6 ms | 983.6, 995.7 ms |
| Q4_0, 512, after the fp16 runs | 207.8 ms | 206.5 ms |

The task's targets were `llama_lt`'s README numbers, 207.7 ms (Q4_0) and 219.2 ms (fp16) at 512 tokens: `plan_run`
took 205.2-207.8 ms and 222.6-229.0 ms, with `llama_lt` itself at 206.5-207.9 and 220.9-224.3 ms on the phone today.
Q4_0 is equal or slightly faster at every length; fp16 is within ~1% (1024 tokens, six pairs: +1.2% on the means,
less than either runner's own spread). The calls and weights are the same and the buffers differ only in `attn`
sharing `h`'s, so no difference is expected beyond the LM head's second command buffer (one boundary per prefill).

`llama_lt`'s fp16 runs read the converter's fp16 `weights.bin` through `lt_index.py`'s index (timing only: it
interleaves gate/up a second time, so its output is wrong): pushing `export.py`'s 6.4 GB copy as well takes ~20
minutes over the QDC tunnel. Kernel timing does not depend on the values: on Q4_0, `llama_lt` took 207.1 and
208.1 ms that way against 207.3 and 207.5 ms on its own weights.

Where the time goes (`plan_run -P`: a timestamp after each call; Q4_0, 512 tokens, 207.6 ms in all):

| calls | count | ms | share |
|---|---|---|---|
| `matmul.swiglu` (gate\|up) | 28 | 82.4 | 39.7% |
| `matmul.residual` (o, down) | 56 | 63.5 | 30.6% |
| `matmul.rope_qkv` (GEMM + rope_qk + vtrans) | 28 | 38.7 | 18.7% |
| `attention` | 28 | 11.3 | 5.4% |
| `rmsnorm` | 57 | 7.9 | 3.8% |
| `matmul.default` (LM head, 64 rows) | 1 | 3.9 | 1.9% |

Recording the 198 calls takes ~125 ms on the phone's CPU, once per bucket (and the LM head's tail once per bucket and
last-token tile); later prompts in the bucket only rewrite the embedding rows and submit.

## A second model: Qwen2.5-1.5B-Instruct (HF safetensors), same day and phone

What the template needed: `model_type: qwen2` and q/k/v biases, which go into ROPE_QKV's general form (bias +
RoPE). The rest was already there: heads of 128 (12 query, 2 KV: a group of 6), dim 1536, ffn 8960, a tied
151,936-row LM head, RoPE theta 1e6, eps 1e-6. Converted in 15 s to 0.87 GB of Q4_0 and 198 calls; no C changes.

- **First run: NaN everywhere.** Bisected with plan edits on the phone: without the bias (`sed` out `bias=`) no NaN;
  the general form without the bias (`head_dim=128` instead) is bit-identical to the simple form. So the bias.
  Cause: `fa3` (`../lt/kernels/fa3.comp`) accumulates Q K^T in an fp16 cooperative-matrix accumulator and applies
  the softmax scale afterwards. Qwen2's K bias (up to 316) makes the raw logits reach 274,656 in layer 0 (14,033 in
  layer 15; 190-2,463 elsewhere), past fp16's 65,504: inf, then NaN in the softmax. Activations elsewhere fit fp16
  (the SwiGLU output peaks at 3,969; the fp32 residual at 6,440).
- **Fix, in the converter:** the qwen2 template folds 1/16 of the scale into W_q and b_q (a power of two: exact in
  fp16 and Q4_0, and it commutes with RoPE) and passes scale x 16 to the attention. Raw logits now peak at 17,166.
- **Result** (`ref_hf.py`: transformers' Qwen2 in fp32 with the phone's Q4_0-dequantized weights, 512 tokens of the
  same blog text in Qwen's tokenizer):

  | | logits cosine | top-1 | top-5 | KL | hidden cosine mean / worst row |
  |---|---|---|---|---|---|
  | plan_run, Q4_0 | 0.99998 | same (11) | 5/5 | 1e-4 | 0.99997 / 0.9996 |

  Prefill 512 tokens: **97.1 ms (5,271 tok/s)**. Greedy continuation of the prompt (which ends inside "(NN, NT,
  TN"): ", TT) at 12.0 to 14.6 with the weights packed once.\n\n## Setup\n\n###", 24 tokens through two buckets.

### What did not match, and limits

- **Not bit-identical out of the box:** the GGUF's RoPE frequencies are not transformers' (5 of 64 values by 1 ulp),
  and `llama_lt` uses transformers'. The difference is below the accuracy the table measures (KL 4e-4 vs 5e-4), but
  greedy text flips one near-tie in 20 tokens. With the same frequencies the outputs are bit-identical.
- **Coarse buckets need a second variable.** The first version read the LM head's rows at `M - 64`, as `llama_lt`
  does; a 500-token prompt in a 1024-row bucket then has its last token outside those rows (`plan_run` stopped with
  "the last token is not in the logits rows"). The plan now has `T`, the 64-row tile holding the last token, and
  `plan_run` records the calls that use it as a small tail command buffer per (bucket, `T`); the body stays one
  command buffer per bucket.
- **One template, two families.** Llama (GGUF `llama`, HF `llama`) and Qwen2 (HF `qwen2` only: GGUF `qwen2` is
  not wired up); SwiGLU, full RoPE, heads of 128, causal attention. Anything else stops with a message naming what
  is missing. Llama 3.2 1B (heads of 64) would need heads padded to 128 with RoPE, which ROPE_QKV's general form
  does not take yet.
- **Weights:** fp16 and Q4_0 only. Other GGUF quant types (Q6_K, Q8_0, ...) are dequantized with gguf-py and
  requantized to the target (`convert.py` reports them as lossy). The plain `Llama-3.2-3B-Instruct-Q4_0.gguf` (Q6_K
  `token_embd`) converts in 18 s: its 112 Q4_0 tensors repack to the same bytes as above, `token_embd` goes Q6_K ->
  Q4_0 and differs in 99% of its blocks from the F16-derived one. Not run on the phone.
- **Prefill only**, as `llama_lt`: `-g` predicts by prefilling again (no KV cache).
- `layernorm`, `attention_masked` and the general `rope_qkv` fields are parsed and passed to the library but no
  converted plan uses them yet.
- No host-side executor of plans (a numpy interpreter to check a plan without a phone) was written: the phone was
  available.

## Running it

```bash
./build.sh                                                     # plan_run + llama_lt for Android, plan_run_host
python3 convert.py ~/runix/llama.cpp-gguf/Llama-3.2-3B-Instruct-F16.gguf -o out/l3b_q4            # 33 s
python3 convert.py ~/runix/llama.cpp-gguf/Llama-3.2-3B-Instruct-F16.gguf -o out/l3b_f16 --type f16
python3 check_weights.py out/l3b_q4 ~/runix/llama.cpp-gguf/Llama-3.2-3B-Instruct-F16.gguf --export ../llama3b/weights/llama3b_q4
./build/plan_run_host -d -p out/l3b_q4/model.plan -t ../llama3b/ref/tokens.bin -n 500    # dry run: the calls at M
ANDROID_SERIAL=<serial> LLAMA_LT=q4 ./stage.sh out/l3b_q4                                  # re-runnable after drops
adb shell "cd /data/local/tmp/ltc && ./plan_run -p l3b_q4/model.plan -t tokens.bin -n 512 -o out"
adb pull /data/local/tmp/ltc/out/logits.bin /data/local/tmp/ltc/out/hidden.bin out/dev/
python ../llama3b/ref.py cmp q4 512 out/dev                    # needs torch + transformers (the llm-mlc env here)
adb shell "cd /data/local/tmp/ltc && sh bench.sh 'plan l3b_q4 512' 'lt q4 512'"
```

`tokens.bin` is `../llama3b/ref/tokens.bin` (`../llama3b/ref.py tokens`); `convert.py` reads only the weights and
metadata, not the tokenizer.

## Next

- **`fa3`'s fp16 Q K^T accumulator** is a range risk for any model with large attention logits (Qwen2's K bias
  here). The converter's power-of-two prescale works around it per template; an fp32 accumulator for S, or the
  library pre-scaling Q itself, would remove it for every caller.
- **Fix `ablasLtWeightPack`'s Q4_0 rounding** (`../lt/ablasLt.c`, `quantize_q4_0_row`): the product in its own
  statement, or `#pragma STDC FP_CONTRACT OFF`, so device-side packing equals ggml's.
- **More templates from the same IR:** Qwen3 (QK-norm needs a per-head RMSNorm call), Gemma 3 (GeGLU, pre/post
  norms, embedding scale, sliding windows -> `attention_masked`), π0 from safetensors (LayerNorm, BIAS_GELU,
  masked attention: the calls `plan_run` already parses).
- **Decode:** a KV cache in the tile layouts and an M = 1 path, as `../lt/README.md` lists; plans would then have a
  prefill program and a decode program.
- **K-quants** (Q4_K/Q6_K as AdrenoBLAS formats) instead of requantizing, and MoE.
- **Zero-copy weights:** `weights.bin` is page-aligned so it could be imported with `VK_EXT_external_memory_host`
  instead of copied (load is 0.5 s for Q4_0, 3.5 s for fp16 today).
