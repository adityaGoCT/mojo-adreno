# A checkpoint's tensors, read straight from its model.safetensors on the phone: the header's JSON lists each
# tensor's dtype, shape and byte range; the program reads the bytes of the tensors it needs. Only the format
# the safetensors library writes is parsed (entries {"dtype":"..","shape":[..],"data_offsets":[a,b]}).
from std.collections import Dict


def _name_before(s: String) raises -> String:
    """The key that ends `s`: `..."name":` -> name."""
    if not s.endswith('":'):
        raise Error("safetensors header: unexpected text before an entry")
    var t = String(s[byte = 0 : s.byte_length() - 2])
    return String(t[byte = t.rfind('"') + 1 : t.byte_length()])


struct Checkpoint(Movable):
    var path: String
    var offsets: Dict[String, Int]  # absolute file offsets
    var sizes: Dict[String, Int]  # bytes
    var dtypes: Dict[String, String]  # "BF16", "F32", ...

    def __init__(out self, path: String) raises:
        self.path = path
        self.offsets = Dict[String, Int]()
        self.sizes = Dict[String, Int]()
        self.dtypes = Dict[String, String]()
        var f = open(path, "r")
        var head = f.read_bytes(8)
        var n = 0
        for i in range(8):
            n |= Int(head[i]) << (8 * i)
        var header = f.read(n)
        f.close()
        var pieces = header.split('{"dtype":"')
        var name = _name_before(String(pieces[0]))
        for j in range(1, len(pieces)):
            var p = String(pieces[j])
            var o = p.find('"data_offsets":[')
            if o < 0:
                raise Error("safetensors header: no data_offsets for " + name)
            o += 16
            var comma = p.find(",", o)
            var close = p.find("]", o)
            var start = Int(String(p[byte=o:comma]))
            var end = Int(String(p[byte = comma + 1 : close]))
            self.offsets[name] = 8 + n + start
            self.sizes[name] = end - start
            self.dtypes[name] = String(p[byte = 0 : p.find('"')])
            if j + 1 < len(pieces):
                name = _name_before(String(p[byte = close + 3 : p.byte_length()]))

    def __contains__(self, name: String) -> Bool:
        return name in self.offsets

    def read(self, f: FileHandle, name: String) raises -> List[UInt8]:
        """The tensor's bytes."""
        if name not in self.offsets:
            raise Error("checkpoint has no tensor " + name)
        _ = f.seek(self.offsets[name])
        var data = f.read_bytes(self.sizes[name])
        if len(data) != self.sizes[name]:
            raise Error("short read of " + name)
        return data^
