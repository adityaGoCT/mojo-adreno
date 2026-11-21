"""Q4_0 quantization (ggml's reference rounding) and AdrenoBLAS packing, shared by the tests and export.py."""
import numpy as np

def quant_q4_0(w):
    """w [N, K] float32 -> q uint8 [N, K] (0..15), d float16 [N, K/32]; ggml quantize_row_q4_0_ref."""
    N, K = w.shape
    b = w.reshape(N, K // 32, 32).astype(np.float32)
    idx = np.abs(b).argmax(-1)
    mx = np.take_along_axis(b, idx[..., None], -1)[..., 0]          # signed value of max |x|
    d = mx / -8.0
    idv = np.where(d != 0, 1.0 / np.where(d != 0, d, 1), 0).astype(np.float32)
    q = np.minimum(15, (b * idv[..., None] + 8.5).astype(np.int8)).astype(np.uint8)  # trunc toward 0 like (int8_t)
    return q.reshape(N, K), d.astype(np.float16)

def dequant_q4_0(q, d):
    N, K = q.shape
    return ((q.reshape(N, K // 32, 32).astype(np.float32) - 8) * d.astype(np.float32)[..., None]).reshape(N, K)

def pack_q4(q, d):
    """-> bytes in the 'Q4' layout of gen_q4.py: quants (N*K/2 bytes) then scales (N*K/32 halves)."""
    N, K = q.shape
    P, KB = N // 64, K // 32
    # q[n, k] -> [p, kb, h, lane, 16]
    t = q.reshape(P, 64, KB, 2, 16).transpose(0, 2, 3, 1, 4)        # p, kb, h, lane, kk
    # nibble order within the 16: word w (kk 0..7 / 8..15), nibble j: low half = kk 8w+2j, high half = kk 8w+2j+1
    lo = t[..., 0::2].astype(np.uint32)   # kk = 0,2,4,...,14 -> (w, j) = divmod(idx, 4)
    hi = t[..., 1::2].astype(np.uint32)
    words = np.zeros(t.shape[:-1] + (2,), np.uint32)
    for i in range(8):
        w, j = divmod(i, 4)
        words[..., w] |= (lo[..., i] << (4 * j)) | (hi[..., i] << (16 + 4 * j))
    s = d.reshape(P, 64, KB).transpose(0, 2, 1)                     # p, kb, lane
    return words.astype("<u4").tobytes() + np.ascontiguousarray(s).astype("<f2").tobytes()

def pack_tiles(x):
    """x [X, K] (A [M,K] or a weight [N,K]) -> K-minor 64 x 16 tiles: ((x/64)*(K/16) + k/16)*1024 + (x%64)*16 + k%16."""
    X, K = x.shape
    return np.ascontiguousarray(x.reshape(X // 64, 64, K // 16, 16).transpose(0, 2, 1, 3)).ravel()
