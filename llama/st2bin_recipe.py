"""Write st2bin's recipe: how to build llama_vk's weights.bin from Llama's model.safetensors on the phone.

When adb is slow (Samsung's Remote Test Lab bridge dropped to 0.16 MB/s, four hours for 2.47 GB), the
phone can download model.safetensors itself and convert it with st2bin.c. The recipe comes from the
same file's header on the Mac and from run.py's export (build/llama/model): for each exported tensor,
the byte ranges of bf16 values to convert to fp16 and where they go, and the RoPE tables (computed
by transformers) as small files.

  python3 llama/st2bin_recipe.py <model.safetensors> <out dir>   # -> recipe.txt, rope.cos, rope.sin
  adb push <out dir>/* build/llama/st2bin /data/local/tmp/llama/conv/
  adb shell curl -L -o /data/local/tmp/llama/model.safetensors <url of the same file>
  adb shell /data/local/tmp/llama/conv/st2bin /data/local/tmp/llama/model.safetensors \
      /data/local/tmp/llama/conv/recipe.txt /data/local/tmp/llama/conv /data/local/tmp/llama/model/weights.bin

Check the result with sha256sum against build/llama/model/weights.bin; push manifest.txt as usual.
"""

import json
import pathlib
import struct
import sys

HERE = pathlib.Path(__file__).resolve().parent
MODEL = HERE.parent / "build/llama/model"


def main():
    st, out = pathlib.Path(sys.argv[1]), pathlib.Path(sys.argv[2])
    out.mkdir(parents=True, exist_ok=True)
    with open(st, "rb") as f:
        n = struct.unpack("<Q", f.read(8))[0]
        header = json.loads(f.read(n))

    def source(name):  # (byte offset, bf16 values)
        t = header[name]
        assert t["dtype"] == "BF16", (name, t["dtype"])
        start, end = t["data_offsets"]
        return 8 + n + start, (end - start) // 2

    manifest = [line.split() for line in (MODEL / "manifest.txt").read_text().splitlines()[1:] if line.strip()]
    place = {name: (int(off), int(nbytes)) for name, off, nbytes in manifest}
    lines = []

    def emit(name, parts):
        off, nbytes = place[name]
        assert sum(count for _, count in parts) * 2 == nbytes, name
        for at, count in parts:
            lines.append(f"conv {off} {at} {count}")
            off += count * 2

    emb, count = source("model.embed_tokens.weight")
    chunk = count // 4  # run.py splits the embedding into 4 row chunks
    for i in range(4):
        emit(f"embed.{i}", [(emb + i * chunk * 2, chunk)])
    for l in range(16):
        p = f"model.layers.{l}."
        emit(f"l{l}.attn_norm", [source(p + "input_layernorm.weight")])
        emit(f"l{l}.wqkv", [source(p + f"self_attn.{c}_proj.weight") for c in "qkv"])
        emit(f"l{l}.wo", [source(p + "self_attn.o_proj.weight")])
        emit(f"l{l}.mlp_norm", [source(p + "post_attention_layernorm.weight")])
        emit(f"l{l}.wgu", [source(p + "mlp.gate_proj.weight"), source(p + "mlp.up_proj.weight")])
        emit(f"l{l}.wdown", [source(p + "mlp.down_proj.weight")])
    emit("final_norm", [source("model.norm.weight")])
    with open(MODEL / "weights.bin", "rb") as f:
        for name in ("rope.cos", "rope.sin"):
            off, nbytes = place[name]
            f.seek(off)
            (out / name).write_bytes(f.read(nbytes))
            lines.append(f"file {off} {name}")
    size = max(off + nbytes for off, nbytes in place.values())
    (out / "recipe.txt").write_text(f"size {size}\n" + "\n".join(lines) + "\n")
    print(f"{len(lines)} recipe lines, {size} bytes -> {out}")


if __name__ == "__main__":
    main()
