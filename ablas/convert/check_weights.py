#!/usr/bin/env python3
"""Host checks of a converted weights.bin against the C library and against llama_lt's weights.

  python check_weights.py OUTDIR MODEL [--export ../llama3b/weights/llama3b_q4]

1. Every weight in OUTDIR/model.plan is packed again by AdrenoBLASLt's own ablasLtWeightPack (../lt/ablasLt.c,
   built for this host as build/libablaslt_host.dylib) from the source's rows in their plain order ([gate; up] for
   GATE_UP: the C code does the interleave), and compared byte for byte. The library is built with
   -ffp-contract=off: with clang's default, `v[j] * id + 8.5f` in its Q4_0 quantizer becomes a fused multiply-add,
   which rounds differently from ggml's quantize_row_q4_0_ref (product, then sum) in ~0.4% of blocks (README.md).
2. With --export: each weight is compared with ../llama3b/export.py's tensor (from the Hugging Face safetensors),
   after the transform llama_lt applies when it loads it (ablasLtWeightPack(GATE_UP, SRC_PACKED) for wgu), i.e.
   with the bytes llama_lt's buffers hold on the phone.
"""
import argparse
import ctypes
import pathlib
import subprocess
import sys

import numpy as np

HERE = pathlib.Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import convert  # noqa: E402
import formats as fm  # noqa: E402

LIB = HERE / "build/libablaslt_host.dylib"
TYPE = {"f16": 0, "f32": 1, "q4_0": 2}
USE = {"plain": 0, "gate_up": 1}
SRC_F32_ROWS, SRC_F16_ROWS, SRC_GGML_Q4_0, SRC_PACKED = 0, 1, 2, 3


def lib():
    if not LIB.exists() or LIB.stat().st_mtime < max(p.stat().st_mtime for p in (HERE.parent / "lt/ablasLt.c", HERE.parent / "ablas.c")):
        LIB.parent.mkdir(exist_ok=True)
        subprocess.run(["clang", "-O2", "-ffp-contract=off", "-shared", "-fPIC", "-I/usr/local/include", "-o", str(LIB),
                        str(HERE.parent / "ablas.c"), str(HERE.parent / "lt/ablasLt.c")], check=True)
    L = ctypes.CDLL(str(LIB))
    L.ablasLtWeightPack.argtypes = [ctypes.c_int, ctypes.c_int, ctypes.c_int, ctypes.c_void_p, ctypes.c_uint32,
                                    ctypes.c_uint32, ctypes.c_void_p]
    return L


def read_plan(path):
    ws = []
    for line in open(path):
        t = line.split()
        if t and t[0] == "weight":
            ws.append((t[1], t[2], int(t[3]), int(t[4]), t[5], int(t[6]), int(t[7])))
    return ws


def c_pack(L, t, use, kind, src, N, K):
    out = np.empty(fm.packed_size(t, N, K), np.uint8)
    src = np.ascontiguousarray(src)
    st = L.ablasLtWeightPack(TYPE[t], USE[use], kind, src.ctypes.data, N, K, out.ctypes.data)
    assert st == 0, st
    return out


def plain_rows(src, parts):
    """The weight's rows in plain order (parts concatenated, Q/K rotate-half), as the source's own dtype."""
    out = []
    for p in parts:
        perm = src.row_perm(p)
        if src.kind(p) == "f16" and isinstance(src, convert.GGUFSource):
            d = src.t[p].data
            out.append(np.asarray(d if perm is None else d[perm], np.float16))
        else:
            out.append(src.rows(p, perm))
    return np.concatenate(out)


def export_name(name):
    if name == "token_embd":
        return "tok"
    if name == "rope.inv_freq":
        return "inv_freq"
    if name == "output_norm":
        return "out_norm"
    l, w = name[len("blk."):].split(".")
    return f"L{l}." + {"attn_norm": "attn_norm", "ffn_norm": "ffn_norm", "attn_qkv": "wqkv", "attn_output": "wo",
                       "ffn_gate_up": "wgu", "ffn_down": "wd"}[w]


def diff(a, b, t, N, K):
    """(bytes differing, units differing: fp16 values / Q4_0 blocks (quants or scale))."""
    a, b = np.frombuffer(a, np.uint8), np.frombuffer(b, np.uint8)
    nb = int((a != b).sum())
    if not nb:
        return 0, 0
    if t == "q4_0":
        qa, da = fm.unpack_q4(a, N, K)
        qb, db = fm.unpack_q4(b, N, K)
        blk = (qa.reshape(N, K // 32, 32) != qb.reshape(N, K // 32, 32)).any(-1) | (da.view(np.uint16) != db.view(np.uint16))
        return nb, int(blk.sum())
    return nb, int((a.view(np.uint16 if t == "f16" else np.uint32) != b.view(np.uint16 if t == "f16" else np.uint32)).sum())


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("outdir")
    ap.add_argument("model")
    ap.add_argument("--export", help="prefix of export.py's .bin/.idx (llama_lt's weights)")
    ap.add_argument("--skip-c", action="store_true")
    a = ap.parse_args()
    out = pathlib.Path(a.outdir)
    W = np.memmap(out / "weights.bin", np.uint8, mode="r")
    src = convert.open_source(a.model)
    L = lib()
    exp = None
    if a.export:
        idx = {l.split()[0]: (int(l.split()[1]), int(l.split()[2])) for l in open(a.export + ".idx")}
        exp = (np.memmap(a.export + ".bin", np.uint8, mode="r"), idx)
    tot = {"c": [0, 0, 0], "export": [0, 0, 0]}
    for name, t, N, K, use, off, nbytes in read_plan(out / "model.plan"):
        mine = W[off:off + nbytes]
        line = f"{name:22s} {t:5s} [{N}, {K}] {use:7s}"
        if not a.skip_c:
            if t == "f32":
                ref = np.asarray(src.rows(name) if name != "rope.inv_freq" else src.cfg.inv_freq, "<f4").view(np.uint8)
            else:
                parts = {"attn_qkv": ["attn_q", "attn_k", "attn_v"], "ffn_gate_up": ["ffn_gate", "ffn_up"]}
                suf = name.rsplit(".", 1)[-1]
                pn = [name.rsplit(".", 1)[0] + "." + p for p in parts[suf]] if suf in parts else [name]
                rows = plain_rows(src, pn)
                kind = SRC_F16_ROWS if rows.dtype == np.float16 else SRC_F32_ROWS
                ref = c_pack(L, t, use, kind, rows.astype(np.float16 if kind == SRC_F16_ROWS else np.float32), N, K)
            nb, nu = diff(mine, ref, t, N, K)
            tot["c"][0] += nb; tot["c"][1] += nu; tot["c"][2] += 1  # noqa: E702
            line += f"  vs ablasLtWeightPack: {'identical' if not nb else f'{nb} bytes, {nu} units differ'}"
        if exp is not None:
            o, n = exp[1][export_name(name)]
            e = exp[0][o:o + n]
            if use == "gate_up":
                e = c_pack(L, t, use, SRC_PACKED, np.asarray(e), N, K)
            if n != nbytes:
                line += f"  vs export: size {n} != {nbytes}"
                tot["export"][0] += nbytes
            else:
                nb, nu = diff(mine, e, t, N, K)
                tot["export"][0] += nb; tot["export"][1] += nu  # noqa: E702
                line += f"  vs export: {'identical' if not nb else f'{nb} bytes, {nu} units differ'}"
            tot["export"][2] += 1
        print(line, flush=True)
    for k, (nb, nu, n) in tot.items():
        if n:
            print(f"TOTAL vs {k}: {n} weights, {nb} bytes differ ({nu} fp16 values / Q4_0 blocks / f32 values)")


if __name__ == "__main__":
    main()
