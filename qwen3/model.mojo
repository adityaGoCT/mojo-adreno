# Ternary Qwen3-8B (PrismML's Ternary-Bonsai-8B) decode on the Adreno as MAX DeviceContext launches:
# qwen3_vk.c's forward pass, in Mojo. The projections are the Android port's packed ternary kernels
# (bonsai/kernels/kernels.mojo, unchanged), the rest qwen3/kernels/qwen3k.mojo. Weights from
# qwen3/export.py or qwen3/convert.cpp (manifest.txt, weights.bin); the embedding stays in host memory
# and the CPU dequantizes one row per token. fp32 activations and KV cache. prefill() runs a whole
# prompt at once: the projections on cooperative matrices (bonsai/kernels/prefill.mojo's p_gemm_t2),
# the rest qwen3/kernels/qwen3p.mojo's row kernels.
from std.collections import Dict
from max.gpu.host import DeviceBuffer, DeviceContext, Dim

import kernels
import prefill
import qwen3k
import qwen3p

# Qwen3-8B; must match qwen3k.mojo and export.py
comptime D = 4096
comptime L = 36
comptime F = 12288
comptime QKV = 6144
comptime V = 151669
comptime HEAD0 = 74 * 1024  # vocabulary rows in the first half of the head


def groups(work: Int, per: Int) -> Int:
    return (work + per - 1) // per


def dequantize(emb: Dict[String, List[UInt8]], token: Int, row: Pointer[mut=True, Float32, _]) raises:
    """row = row `token` of the 2-bit embedding: code * scale + bias per group of 128, on the CPU."""
    var w = emb["emb.w"].unsafe_ptr().unsafe_bitcast[UInt32]() + token * (D // 16)
    var s = emb["emb.s"].unsafe_ptr().unsafe_bitcast[Float16]() + token * (D // 128)
    var b = emb["emb.b"].unsafe_ptr().unsafe_bitcast[Float16]() + token * (D // 128)
    for i in range(D):
        var code = (w[i // 16] >> UInt32(2 * (i % 16))) & 3
        row[i] = Float32(code) * Float32(s[i // 128]) + Float32(b[i // 128])


struct Qwen3(Movable):
    var ctx: DeviceContext
    var capacity: Int
    var words: Dict[String, DeviceBuffer[DType.uint32]]  # packed codes (.w)
    var halves: Dict[String, DeviceBuffer[DType.float16]]  # their scales (.s)
    var floats: Dict[String, DeviceBuffer[DType.float32]]  # norms and the RoPE table
    var emb: Dict[String, List[UInt8]]  # emb.w, emb.s, emb.b, in host memory
    var row: List[Float32]  # the embedding row of the current token
    var x: DeviceBuffer[DType.float32]
    var xq: DeviceBuffer[DType.uint32]  # projection inputs: fp16 pairs in 32-bit words
    var gq: DeviceBuffer[DType.uint32]
    var qkv: DeviceBuffer[DType.float32]
    var att: DeviceBuffer[DType.float32]
    var y: DeviceBuffer[DType.float32]
    var gu: DeviceBuffer[DType.float32]
    var partials: DeviceBuffer[DType.float32]
    var scores: DeviceBuffer[DType.float32]
    var logits: DeviceBuffer[DType.float32]
    var logits0: DeviceBuffer[DType.float32]
    var logits1: DeviceBuffer[DType.float32]
    var cand: DeviceBuffer[DType.float32]
    var kc: List[DeviceBuffer[DType.float32]]
    var vc: List[DeviceBuffer[DType.float32]]

    def __init__(out self, ctx: DeviceContext, dir: String) raises:
        self.ctx = ctx
        self.words = Dict[String, DeviceBuffer[DType.uint32]]()
        self.halves = Dict[String, DeviceBuffer[DType.float16]]()
        self.floats = Dict[String, DeviceBuffer[DType.float32]]()
        self.emb = Dict[String, List[UInt8]]()
        self.row = List[Float32](length=D, fill=0)
        var lines = open(dir + "/manifest.txt", "r").read().split("\n")
        var header = lines[0].split(" ")
        if len(header) != 2 or header[0] != "qwen3":
            raise Error("manifest.txt: not a qwen3 manifest")
        self.capacity = Int(header[1])
        var cap = self.capacity
        self.x = ctx.enqueue_create_buffer[DType.float32](D)
        self.xq = ctx.enqueue_create_buffer[DType.uint32](D // 2)
        self.gq = ctx.enqueue_create_buffer[DType.uint32](F // 2)
        self.qkv = ctx.enqueue_create_buffer[DType.float32](QKV)
        self.att = ctx.enqueue_create_buffer[DType.float32](D)
        self.y = ctx.enqueue_create_buffer[DType.float32](D)
        self.gu = ctx.enqueue_create_buffer[DType.float32](2 * F)
        self.partials = ctx.enqueue_create_buffer[DType.float32](8 * F)
        self.scores = ctx.enqueue_create_buffer[DType.float32](32 * cap)
        self.logits = ctx.enqueue_create_buffer[DType.float32](V)
        self.logits0 = self.logits.create_sub_buffer[DType.float32](0, HEAD0)
        self.logits1 = self.logits.create_sub_buffer[DType.float32](HEAD0, V - HEAD0)
        self.cand = ctx.enqueue_create_buffer[DType.float32](3 * 1024)
        self.kc = List[DeviceBuffer[DType.float32]]()
        self.vc = List[DeviceBuffer[DType.float32]]()
        for _ in range(L):
            self.kc.append(ctx.enqueue_create_buffer[DType.float32](1024 * cap))
            self.vc.append(ctx.enqueue_create_buffer[DType.float32](1024 * cap))

        var weights = open(dir + "/weights.bin", "r")
        var total = 0
        for i in range(1, len(lines)):
            var f = lines[i].split(" ")
            if len(f) != 3:
                continue
            var name = String(f[0])
            var bytes = Int(f[2])
            _ = weights.seek(Int(f[1]))
            var data = weights.read_bytes(bytes)
            if len(data) != bytes:
                raise Error("weights.bin: short read of " + name)
            total += bytes
            if name.startswith("emb."):
                self.emb[name] = data^
                continue
            if name.endswith(".w"):
                var b = ctx.enqueue_create_buffer[DType.uint32](bytes // 4)
                ctx.enqueue_copy(b, data.unsafe_ptr().unsafe_bitcast[UInt32]())
                self.words[name] = b
            elif name.endswith(".s"):
                var b = ctx.enqueue_create_buffer[DType.float16](bytes // 2)
                ctx.enqueue_copy(b, data.unsafe_ptr().unsafe_bitcast[Float16]())
                self.halves[name] = b
            else:
                var b = ctx.enqueue_create_buffer[DType.float32](bytes // 4)
                ctx.enqueue_copy(b, data.unsafe_ptr().unsafe_bitcast[Float32]())
                self.floats[name] = b
            ctx.synchronize()  # `data` goes away
        print("weights:", len(lines) - 2, "tensors,", Float64(total) / 1e9, "GB, context", cap)

    def project(self, name: String, input: DeviceBuffer[DType.uint32], output: DeviceBuffer[DType.float32],
                n: Int, k: Int) raises:
        """output = W input for the packed tensor `name` (n outputs, k inputs): eight-group partials, then their sum."""
        self.ctx.enqueue_function[kernels.packed_linear](input, self.words[name + ".w"], self.halves[name + ".s"],
                                                         self.partials, Int32(n), Int32(k),
                                                         grid_dim=Dim(groups(n, 64), groups(k, 1024)), block_dim=64)
        self.ctx.enqueue_function[kernels.packed_reduce](self.partials, output, Int32(n), Int32(groups(k, 1024)),
                                                         grid_dim=groups(n, 64), block_dim=64)

    def embed(mut self, token: Int) raises:
        """x = row `token` of the embedding."""
        dequantize(self.emb, token, self.row.unsafe_ptr())
        self.ctx.enqueue_copy(self.x, self.row.unsafe_ptr())

    def forward(mut self, token: Int, pos: Int) raises:
        """Enqueues one token at position `pos`; its logits end in `self.logits`."""
        var ctx = self.ctx
        var p = Int32(pos)
        var cap = Int32(self.capacity)
        self.embed(token)
        var rope = self.floats["rope"]
        for l in range(L):
            var n = "l" + String(l) + "."
            ctx.enqueue_function[qwen3k.rmsnorm_pack](self.x, self.floats[n + "in_norm"], self.xq, Int32(D),
                                                      grid_dim=1, block_dim=64)
            self.project(n + "qkv", self.xq, self.qkv, QKV, D)
            ctx.enqueue_function[qwen3k.qk_norm_rope](self.qkv, self.floats[n + "q_norm"], self.floats[n + "k_norm"],
                                                      rope, self.kc[l], self.vc[l], p, grid_dim=48, block_dim=64)
            ctx.enqueue_function[qwen3k.attn_scores](self.qkv, self.kc[l], self.scores, p, cap,
                                                     grid_dim=groups(32 * self.capacity, 64), block_dim=64)
            ctx.enqueue_function[qwen3k.attn_values](self.scores, self.vc[l], self.att, p, cap,
                                                     grid_dim=D // 64, block_dim=64)
            ctx.enqueue_function[qwen3k.pack_half](self.att, self.xq, Int32(D), grid_dim=D // 2 // 64, block_dim=64)
            self.project(n + "o", self.xq, self.y, D, D)
            ctx.enqueue_function[qwen3k.add](self.x, self.y, Int32(D), grid_dim=D // 64, block_dim=64)
            ctx.enqueue_function[qwen3k.rmsnorm_pack](self.x, self.floats[n + "post_norm"], self.xq, Int32(D),
                                                      grid_dim=1, block_dim=64)
            self.project(n + "gu", self.xq, self.gu, 2 * F, D)
            ctx.enqueue_function[qwen3k.swiglu_pack](self.gu, self.gq, Int32(F), grid_dim=F // 2 // 64, block_dim=64)
            self.project(n + "down", self.gq, self.y, D, F)
            ctx.enqueue_function[qwen3k.add](self.x, self.y, Int32(D), grid_dim=D // 64, block_dim=64)
        self.head()

    def head(self) raises:
        """The logits of `self.x`: the final norm, then the output head in two halves."""
        var ctx = self.ctx
        ctx.enqueue_function[qwen3k.rmsnorm_pack](self.x, self.floats["final_norm"], self.xq, Int32(D),
                                                  grid_dim=1, block_dim=64)
        ctx.enqueue_function[kernels.packed_head](self.xq, self.words["head0.w"], self.halves["head0.s"], self.logits0,
                                                  self.cand, Int32(HEAD0), Int32(D), Int32(0),
                                                  grid_dim=groups(HEAD0, 1024), block_dim=128)
        ctx.enqueue_function[kernels.packed_head](self.xq, self.words["head1.w"], self.halves["head1.s"], self.logits1,
                                                  self.cand, Int32(V - HEAD0), Int32(D), Int32(0),
                                                  grid_dim=groups(V - HEAD0, 1024), block_dim=128)

    def pproject(self, name: String, input: DeviceBuffer[DType.float32], output: DeviceBuffer[DType.float32],
                 n: Int, k: Int, rows: Int) raises:
        """output = input W^T for `rows` fp32 rows and the packed tensor `name` (n outputs, k inputs): 128 x 128
        tiles on cooperative matrices, 256 threads each."""
        self.ctx.enqueue_function[prefill.p_gemm_t2](input, self.words[name + ".w"], self.halves[name + ".s"], output,
                                                     Int32(n), Int32(k), grid_dim=Dim(n // 128, rows // 128),
                                                     block_dim=256)

    def prefill(mut self, tokens: List[Int]) raises:
        """Enqueues the whole prompt at once, at positions 0 .. len(tokens) - 1: per layer the decode steps
        for all rows (the prompt padded to the matmul's 128 rows), then the last row's logits in
        `self.logits`."""
        var ctx = self.ctx
        var count = len(tokens)
        var rows = (count + 127) // 128 * 128
        if count > self.capacity:
            raise Error("prefill: " + String(count) + " prompt tokens > context " + String(self.capacity))
        var host = List[Float32](length=rows * D, fill=0)  # the embedding rows; the padding rows zero
        for t in range(count):
            dequantize(self.emb, tokens[t], host.unsafe_ptr() + t * D)
        var xr = ctx.enqueue_create_buffer[DType.float32](rows * D)
        ctx.enqueue_copy(xr, host.unsafe_ptr())
        var xnr = ctx.enqueue_create_buffer[DType.float32](rows * D)
        var qkvr = ctx.enqueue_create_buffer[DType.float32](rows * QKV)
        var scores = ctx.enqueue_create_buffer[DType.float32](rows * 32 * self.capacity)
        var attr = ctx.enqueue_create_buffer[DType.float32](rows * D)
        var yr = ctx.enqueue_create_buffer[DType.float32](rows * D)
        var gur = ctx.enqueue_create_buffer[DType.float32](rows * 2 * F)
        var actr = ctx.enqueue_create_buffer[DType.float32](rows * F)
        ctx.enqueue_memset(attr, Float32(0))  # the padding rows' attention, which nothing writes
        var c = Int32(count)
        var cap = Int32(self.capacity)
        var rope = self.floats["rope"]
        for l in range(L):
            var n = "l" + String(l) + "."
            ctx.enqueue_function[qwen3p.p_rmsnorm](xr, self.floats[n + "in_norm"], xnr, grid_dim=Dim(1, rows),
                                                   block_dim=64)
            self.pproject(n + "qkv", xnr, qkvr, QKV, D, rows)
            ctx.enqueue_function[qwen3p.p_qk_norm_rope](qkvr, self.floats[n + "q_norm"], self.floats[n + "k_norm"],
                                                        rope, self.kc[l], self.vc[l], c, grid_dim=Dim(48, rows),
                                                        block_dim=64)
            ctx.enqueue_function[qwen3p.p_attn_scores](qkvr, self.kc[l], scores, c, cap,
                                                       grid_dim=Dim(groups(32 * self.capacity, 64), rows), block_dim=64)
            ctx.enqueue_function[qwen3p.p_attn_values](scores, self.vc[l], attr, c, cap, grid_dim=Dim(D // 64, rows),
                                                       block_dim=64)
            self.pproject(n + "o", attr, yr, D, D, rows)
            ctx.enqueue_function[qwen3p.p_add](xr, yr, grid_dim=Dim(D // 64, rows), block_dim=64)
            ctx.enqueue_function[qwen3p.p_rmsnorm](xr, self.floats[n + "post_norm"], xnr, grid_dim=Dim(1, rows),
                                                   block_dim=64)
            self.pproject(n + "gu", xnr, gur, 2 * F, D, rows)
            ctx.enqueue_function[qwen3p.p_swiglu](gur, actr, grid_dim=Dim(F // 64, rows), block_dim=64)
            self.pproject(n + "down", actr, yr, D, F, rows)
            ctx.enqueue_function[qwen3p.p_add](xr, yr, grid_dim=Dim(D // 64, rows), block_dim=64)
        ctx.enqueue_copy(self.x, xr.create_sub_buffer[DType.float32]((count - 1) * D, D))  # the last prompt row
        self.head()
