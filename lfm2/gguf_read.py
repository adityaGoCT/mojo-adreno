"""Minimal GGUF reader: metadata and tensor table (no dependencies beyond numpy)."""
import struct, sys
import numpy as np

GGML_TYPES = {0: ("F32", 1, 4), 1: ("F16", 1, 2), 2: ("Q4_0", 32, 18), 3: ("Q4_1", 32, 20),
              6: ("Q5_0", 32, 22), 7: ("Q5_1", 32, 24), 8: ("Q8_0", 32, 34), 10: ("Q2_K", 256, 84),
              11: ("Q3_K", 256, 110), 12: ("Q4_K", 256, 144), 13: ("Q5_K", 256, 176),
              14: ("Q6_K", 256, 210), 30: ("BF16", 1, 2)}


class Reader:
    def __init__(self, buf):
        self.b = buf
        self.o = 0

    def u(self, fmt):
        v = struct.unpack_from("<" + fmt, self.b, self.o)
        self.o += struct.calcsize("<" + fmt)
        return v[0]

    def s(self):
        n = self.u("Q")
        v = bytes(self.b[self.o:self.o + n]).decode("utf-8", "replace")
        self.o += n
        return v

    def val(self, t):
        f = {0: "B", 1: "b", 2: "H", 3: "h", 4: "I", 5: "i", 6: "f", 7: "?", 10: "Q", 11: "q", 12: "d"}
        if t in f:
            return self.u(f[t])
        if t == 8:
            return self.s()
        if t == 9:
            et = self.u("I")
            n = self.u("Q")
            if et in (4, 5, 6) and n > 64:   # big numeric arrays: skip fast
                sz = {4: 4, 5: 4, 6: 4}[et]
                a = np.frombuffer(self.b, dtype={4: "<u4", 5: "<i4", 6: "<f4"}[et], count=n, offset=self.o)
                self.o += n * sz
                return a
            return [self.val(et) for _ in range(n)]
        raise ValueError(t)


def parse(buf):
    r = Reader(buf)
    assert bytes(buf[:4]) == b"GGUF", "not gguf"
    r.o = 4
    ver = r.u("I")
    nt = r.u("Q")
    nkv = r.u("Q")
    meta = {}
    for _ in range(nkv):
        k = r.s()
        t = r.u("I")
        meta[k] = r.val(t)
    tensors = []
    for _ in range(nt):
        name = r.s()
        nd = r.u("I")
        dims = [r.u("Q") for _ in range(nd)]
        t = r.u("I")
        off = r.u("Q")
        tensors.append(dict(name=name, dims=dims, type=t, offset=off))
    align = meta.get("general.alignment", 32)
    data_start = (r.o + align - 1) // align * align
    for t in tensors:
        tn, bs, bb = GGML_TYPES[t["type"]]
        n = int(np.prod(t["dims"]))
        t["tname"] = tn
        t["nbytes"] = n // bs * bb
        t["abs"] = data_start + t["offset"]
    return ver, meta, tensors, data_start


if __name__ == "__main__":
    buf = open(sys.argv[1], "rb").read()
    ver, meta, tensors, ds = parse(buf)
    for k, v in meta.items():
        if isinstance(v, (list, np.ndarray)) and len(v) > 16:
            print(f"{k}: [{len(v)} items]")
        else:
            print(f"{k}: {v}")
    print("data_start", ds)
    from collections import Counter
    print(Counter(t["tname"] for t in tensors))
    for t in tensors:
        if "blk.2." in t["name"] or "blk.0." in t["name"] or "blk" not in t["name"]:
            print(t["name"], t["dims"], t["tname"], t["nbytes"], t["abs"])
    print("end", max(t["abs"] + t["nbytes"] for t in tensors))
