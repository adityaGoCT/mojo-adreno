"""Offline equivalent of ablas.c's specialize(): SPIR-V with spec constants 0,1,2 -> plain OpConstant values."""
import struct, sys

def specialize(words, values):
    ids, out, i = {}, words[:5], 5
    while i < len(words):  # pass 1: which result ids carry SpecId 0/1/2
        op, n = words[i] & 0xffff, words[i] >> 16
        if op == 71 and words[i + 2] == 1 and words[i + 3] in values:  # OpDecorate <id> SpecId <n>
            ids[words[i + 1]] = values[words[i + 3]]
        i += n
    i = 5
    while i < len(words):
        op, n = words[i] & 0xffff, words[i] >> 16
        ins = list(words[i:i + n])
        if op == 71 and ins[2] == 1 and ins[1] in ids:
            ins = []                                   # drop the SpecId decoration
        elif op == 50 and ins[2] in ids:                  # OpSpecConstant <type> <id> <value>
            ins = [(4 << 16) | 43, ins[1], ins[2], ids[ins[2]]]  # OpConstant
        elif op in (51, 52):
            raise ValueError("spec-constant composite/op present")
        out += ins
        i += n
    return out

if __name__ == "__main__":
    src, dst, m, n, k = sys.argv[1:]
    b = open(src, "rb").read()
    w = list(struct.unpack(f"<{len(b) // 4}I", b))
    w = specialize(w, {0: int(m), 1: int(n), 2: int(k)})
    open(dst, "wb").write(struct.pack(f"<{len(w)}I", *w))
