"""AdrenoBLAS's weight formats in numpy, both ways: what ablasLtWeightPack (../lt/ablasLt.c) writes, and its inverse.
convert.py packs with these; plan_ref.py and check_weights.py unpack.

  f16    K-minor 64 x 16 tiles: ((n/64)*(K/16) + k/16)*1024 + (n%64)*16 + k%16  (pack_tiles, ../q4ref.py)
  q4_0   ggml Q4_0 (blocks of 32 along K, d = the value of largest magnitude / -8) in AdrenoBLAS's layout: the
         quants (N*K/2 bytes, [panel][K block][half][lane][2 words]) then the scales (N*K/32 halves, [panel][K
         block][lane])                                                           (pack_q4, ../q4ref.py)
  GATE_UP the same formats over the rows reordered into 64-row groups [32 gate | 32 up] (group j = half j % 2 of
         gate panel j / 2 and of up panel j / 2): interleave_gate_up of the packed bytes is this row order packed.
"""
import pathlib
import sys

import numpy as np

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent.parent))
from q4ref import pack_q4, pack_tiles, quant_q4_0  # noqa: E402  (ablas/q4ref.py: the formats' reference code)

TYPES = ("f16", "q4_0")


def packed_size(wtype, N, K):
    """ablasLtWeightSize."""
    return N * K // 2 + N * K // 16 if wtype == "q4_0" else N * K * 2


def gate_up_rows(N):
    """Row r of a GATE_UP weight is row gate_up_rows(N)[r] of [gate; up] (N = 2F rows)."""
    F, r = N // 2, np.arange(N)
    j, t = r // 64, r % 64
    base = 64 * (j // 2) + 32 * (j % 2)
    return np.where(t < 32, base + t, F + base + t - 32)


def ggml_q4_0_split(blocks, K):
    """ggml block_q4_0 rows (uint8 [N, K/32*18]) -> q uint8 [N, K] (0..15), d float16 [N, K/32]."""
    N = blocks.shape[0]
    b = np.ascontiguousarray(blocks).reshape(N, K // 32, 18)
    d = b[..., :2].copy().view("<f2")[..., 0]
    qs = b[..., 2:]
    q = np.concatenate([qs & 15, qs >> 4], -1).reshape(N, K)  # byte j: element j (low), element j + 16 (high)
    return q, d


def pack_chunk(wtype, rows=None, q4_blocks=None):
    """A chunk of whole 64-row panels -> (bytes at chunk offset in the first region, bytes in the second region).
    f16: (tiles, b""). q4_0: (quants, scales); each region of the full weight is the chunks' in order."""
    if wtype == "f16":
        return pack_tiles(rows.astype(np.float16)).astype("<f2").tobytes(), b""
    if q4_blocks is not None:
        q, d = ggml_q4_0_split(q4_blocks, q4_blocks.shape[1] // 18 * 32)
    else:
        q, d = quant_q4_0(np.ascontiguousarray(rows, dtype=np.float32))
    n, K = q.shape
    b = pack_q4(q, d)
    return b[: n * K // 2], b[n * K // 2:]


def unpack(wtype, buf, N, K):
    """A packed PLAIN weight (bytes / uint8 array) -> float32 [N, K] (Q4_0 dequantized as the GPU does)."""
    buf = np.frombuffer(buf, np.uint8) if not isinstance(buf, np.ndarray) else buf
    if wtype == "f16":
        t = buf[: N * K * 2].view("<f2").reshape(N // 64, K // 16, 64, 16)
        return t.transpose(0, 2, 1, 3).reshape(N, K).astype(np.float32)
    q, d = unpack_q4(buf, N, K)
    return ((q.astype(np.float32) - 8).reshape(N, K // 32, 32) * d.astype(np.float32)[..., None]).reshape(N, K)


def unpack_q4(buf, N, K):
    """The inverse of pack_q4: -> q uint8 [N, K], d float16 [N, K/32]."""
    P, KB = N // 64, K // 32
    words = buf[: N * K // 2].view("<u4").reshape(P, KB, 2, 64, 2)  # p, kb, half, lane, word
    kk = np.arange(16)
    i = kk // 2
    w, shift = i // 4, 4 * (i % 4) + 16 * (kk % 2)                   # pack_q4's nibble order
    nib = (words[..., w] >> shift.astype(np.uint32)) & 15             # p, kb, half, lane, kk
    q = nib.transpose(0, 3, 1, 2, 4).reshape(N, K).astype(np.uint8)  # n = p*64 + lane, k = kb*32 + half*16 + kk
    d = buf[N * K // 2: N * K // 2 + N * K // 16].view("<f2").reshape(P, KB, 64).transpose(0, 2, 1).reshape(N, KB)
    return q, d


def unpack_rows(wtype, buf, N, K, rows):
    """Selected rows of a packed PLAIN weight as float32 (ablasLtWeightRow for many rows): the embedding."""
    rows = np.asarray(rows)
    p, lane = rows // 64, rows % 64
    buf = np.frombuffer(buf, np.uint8) if not isinstance(buf, np.ndarray) else buf
    if wtype == "f16":
        t = buf[: N * K * 2].view("<f2").reshape(N // 64, K // 16, 64, 16)
        return t[p, :, lane, :].reshape(len(rows), K).astype(np.float32)
    KB = K // 32
    words = buf[: N * K // 2].view("<u4").reshape(N // 64, KB, 2, 64, 2)[p, :, :, lane, :]  # r, kb, half, word
    kk = np.arange(16)
    i = kk // 2
    w, shift = i // 4, 4 * (i % 4) + 16 * (kk % 2)
    nib = (words[..., w] >> shift.astype(np.uint32)) & 15                                   # r, kb, half, kk
    d = buf[N * K // 2: N * K // 2 + N * K // 16].view("<f2").reshape(N // 64, KB, 64)[p, :, lane]  # r, kb
    v = (nib.reshape(len(rows), KB, 32).astype(np.float32) - 8) * d.astype(np.float32)[..., None]
    return v.reshape(len(rows), K)
