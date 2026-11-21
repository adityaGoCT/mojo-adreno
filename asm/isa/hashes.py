import struct, zlib
M32 = 0xffffffff
def _crc_table(poly):
    t = []
    for i in range(256):
        c = i
        for _ in range(8): c = (c >> 1) ^ poly if c & 1 else c >> 1
        t.append(c)
    return t
_T32C = _crc_table(0x82F63B78)
def crc32c(b, c=0):
    c ^= M32
    for x in b: c = _T32C[(c ^ x) & 0xff] ^ (c >> 8)
    return c ^ M32
def fnv1a(b, h=0x811c9dc5):
    for x in b: h = ((h ^ x) * 0x01000193) & M32
    return h
def fnv1(b, h=0x811c9dc5):
    for x in b: h = ((h * 0x01000193) & M32) ^ x
    return h
def murmur3(b, seed=0):
    c1, c2 = 0xcc9e2d51, 0x1b873593; h = seed; n = len(b) // 4
    for i in range(n):
        k = struct.unpack_from("<I", b, 4 * i)[0]
        k = (k * c1) & M32; k = ((k << 15) | (k >> 17)) & M32; k = (k * c2) & M32
        h ^= k; h = ((h << 13) | (h >> 19)) & M32; h = (h * 5 + 0xe6546b64) & M32
    tail = b[4 * n:]; k = 0
    for i, x in enumerate(tail): k |= x << (8 * i)
    if tail:
        k = (k * c1) & M32; k = ((k << 15) | (k >> 17)) & M32; k = (k * c2) & M32; h ^= k
    h ^= len(b); h ^= h >> 16; h = (h * 0x85ebca6b) & M32; h ^= h >> 13; h = (h * 0xc2b2ae35) & M32; h ^= h >> 16
    return h
P1, P2, P3, P4, P5 = 2654435761, 2246822519, 3266489917, 668265263, 374761393
def _rotl(x, r): return ((x << r) | (x >> (32 - r))) & M32
def xxh32(b, seed=0):
    n = len(b); i = 0
    if n >= 16:
        v = [(seed + P1 + P2) & M32, (seed + P2) & M32, seed, (seed - P1) & M32]
        while i + 16 <= n:
            for j in range(4):
                x = struct.unpack_from("<I", b, i + 4 * j)[0]
                v[j] = (_rotl((v[j] + x * P2) & M32, 13) * P1) & M32
            i += 16
        h = (_rotl(v[0], 1) + _rotl(v[1], 7) + _rotl(v[2], 12) + _rotl(v[3], 18)) & M32
    else:
        h = (seed + P5) & M32
    h = (h + n) & M32
    while i + 4 <= n:
        h = (_rotl((h + struct.unpack_from("<I", b, i)[0] * P3) & M32, 17) * P4) & M32; i += 4
    while i < n:
        h = (_rotl((h + b[i] * P5) & M32, 11) * P1) & M32; i += 1
    h ^= h >> 15; h = (h * P2) & M32; h ^= h >> 13; h = (h * P3) & M32; h ^= h >> 16
    return h
ALGOS = {"crc32": lambda b: zlib.crc32(b), "crc32c": crc32c, "adler32": lambda b: zlib.adler32(b), "fnv1a": fnv1a,
         "fnv1": fnv1, "murmur3": murmur3, "xxh32": xxh32, "sum32": lambda b: sum(struct.unpack(f"<{len(b)//4}I", b[:len(b)//4*4])) & M32}
