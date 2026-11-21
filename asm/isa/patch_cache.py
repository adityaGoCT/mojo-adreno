"""Patch shader machine code inside a Qualcomm (Adreno 8xx) Vulkan pipeline-cache blob.

Blob layout (reverse-engineered on the Adreno 850 driver E17.52.10.04):
  32-byte VkPipelineCacheHeaderVersionOne, then entries:
    key[8]  u32 size  u32 flag  { u32 uncompressed_size  u32 1  zlib stream }   (size covers the braces)
  The entry holding the hardware shader contains the ISA as 64-bit instruction words.

  patch_cache.py in.cache out.cache <old_lo:old_hi>=<new_lo:new_hi> ...   (hex dwords of one instruction)
"""
import struct, sys, zlib

def entries(b):
    off = 0x20
    while off < len(b):
        key = b[off:off + 8]
        size, flag = struct.unpack_from("<II", b, off + 8)
        usz, one = struct.unpack_from("<II", b, off + 16)
        raw = zlib.decompressobj().decompress(b[off + 24:off + 16 + size])
        assert len(raw) == usz
        yield key, flag, one, raw
        off += 16 + size

def pack(header, ents):
    out = bytearray(header)
    for key, flag, one, raw in ents:
        z = zlib.compress(bytes(raw), 9)
        out += key + struct.pack("<IIII", 8 + len(z), flag, len(raw), one) + z
    return bytes(out)

def main():
    src, dst, *subs = sys.argv[1:]
    b = open(src, "rb").read()
    ents = [list(e) for e in entries(b)]
    for sub in subs:
        old, new = sub.split("=")
        o = struct.pack("<II", *(int(x, 16) for x in old.split(":")))
        n = struct.pack("<II", *(int(x, 16) for x in new.split(":")))
        hits = 0
        for e in ents:
            raw = bytearray(e[3])
            i = raw.find(o)
            while i >= 0:
                if i % 8 == 0:
                    raw[i:i + 8] = n; hits += 1
                i = raw.find(o, i + 1)
            e[3] = bytes(raw)
        print(f"{old} -> {new}: {hits} instruction(s) patched")
    open(dst, "wb").write(pack(b[:0x20], ents))

if __name__ == "__main__":
    main()
