# Llama 3.2 1B decode on the Adreno as MAX DeviceContext launches of the kernels in llama/kernels:
# llama_vk.c's forward pass, in Mojo. Weights from llama/run.py's export (manifest.txt, weights.bin),
# fp16 or int4; fp32 activations and KV cache. Through MAX's HAL DeviceContext and the Vulkan driver
# plugin, each launch binds its buffers and scalars as llama_vk.c's dispatches do. prefill() runs a
# whole prompt at once with the kernels of llama/kernels/prefill: the matmuls on cooperative matrices.
from std.collections import Dict
from max.gpu.host import DeviceBuffer, DeviceContext, Dim

import attention
import embed
import gemv
import gemv_add
import gemv_add_q4
import gemv_q4
import lkh
import lk850
import p_add
import p_attention
import p_attention_scalar
import p_gemm
import p_gemm_q4
import p_rmsnorm
import p_rope_kv
import p_silu_mul
import rmsnorm
import rope_kv
import silu_mul

# Llama 3.2 1B; must match llama/kernels and the manifest header
comptime D = 2048
comptime L = 16
comptime H = 32
comptime KVH = 8
comptime HD = 64
comptime F = 8192
comptime V = 128256
comptime MAXPOS = 512
comptime CHUNKS = 4  # the embedding (and lm_head) in 4 tensors of <= 128 MB, the stock driver's largest binding
comptime QKV = (H + 2 * KVH) * HD
comptime CHUNK_ROWS = V // CHUNKS
# LLAMA_GEMM=q: prefill projections on fp16 cooperative matrices (lfm2/kernels/lkh.mojo) instead of p_gemm_q4 /
# p_gemm's fp32 ones: X packed into fp16 R tiles (pack_x), the int4 or fp16 rows unpacked into fp16 shared memory
# inside the product (gemm_hq: 2 x 1 subgroups, 128 rows x 64 columns a workgroup), K in chunks of GCH whose fp16
# partial products are added in fp32 (sum_parts). The 840 rounds every partial sum of an fp16 product to fp16: with
# chunks of 2048, the 431-token prompt's logits moved by up to 0.39 (KL 5.7e-3) and a near-tied first token flipped;
# with 1024, 0.18 (KL 4.5e-4) for 5% more time.
comptime GCH = 1024


struct Llama(Movable):
    var ctx: DeviceContext
    var halves: Dict[String, DeviceBuffer[DType.float16]]  # fp16 tensors and int4 scales
    var words: Dict[String, DeviceBuffer[DType.uint32]]  # int4 weights, 8 a word
    var floats: Dict[String, DeviceBuffer[DType.float32]]  # the RoPE tables
    var q4: Bool
    var fused_attention: Bool  # p_attention, until a driver cannot create it
    var gemmq: Bool  # LLAMA_GEMM=q: prefill projections on lkh's fp16 cooperative matrices
    var xa: DeviceBuffer[DType.float16]  # lkh's X: fp16 R tiles of up to MAXPOS rows of the widest k (F)
    var part: DeviceBuffer[DType.float16]  # lkh's fp16 partial products, a K chunk each
    var x: DeviceBuffer[DType.float32]
    var xn: DeviceBuffer[DType.float32]
    var qkv: DeviceBuffer[DType.float32]
    var att: DeviceBuffer[DType.float32]
    var gu: DeviceBuffer[DType.float32]
    var act: DeviceBuffer[DType.float32]
    var logits: DeviceBuffer[DType.float32]
    var logit_chunks: List[DeviceBuffer[DType.float32]]
    var kc: List[DeviceBuffer[DType.float32]]
    var vc: List[DeviceBuffer[DType.float32]]

    def __init__(out self, ctx: DeviceContext, dir: String) raises:
        self.ctx = ctx
        self.halves = Dict[String, DeviceBuffer[DType.float16]]()
        self.words = Dict[String, DeviceBuffer[DType.uint32]]()
        self.floats = Dict[String, DeviceBuffer[DType.float32]]()
        self.q4 = False
        self.fused_attention = True
        self.gemmq = False
        self.xa = ctx.enqueue_create_buffer[DType.float16](MAXPOS * F)
        self.part = ctx.enqueue_create_buffer[DType.float16](
            MAXPOS * max((D + GCH - 1) // GCH * 2 * F, (F + GCH - 1) // GCH * D))
        self.x = ctx.enqueue_create_buffer[DType.float32](D)
        self.xn = ctx.enqueue_create_buffer[DType.float32](D)
        self.qkv = ctx.enqueue_create_buffer[DType.float32](QKV)
        self.att = ctx.enqueue_create_buffer[DType.float32](D)
        self.gu = ctx.enqueue_create_buffer[DType.float32](2 * F)
        self.act = ctx.enqueue_create_buffer[DType.float32](F)
        self.logits = ctx.enqueue_create_buffer[DType.float32](V)
        self.logit_chunks = List[DeviceBuffer[DType.float32]]()
        for c in range(CHUNKS):
            self.logit_chunks.append(self.logits.create_sub_buffer[DType.float32](c * CHUNK_ROWS, CHUNK_ROWS))
        self.kc = List[DeviceBuffer[DType.float32]]()
        self.vc = List[DeviceBuffer[DType.float32]]()
        for _ in range(L):
            self.kc.append(ctx.enqueue_create_buffer[DType.float32](KVH * MAXPOS * HD))
            self.vc.append(ctx.enqueue_create_buffer[DType.float32](KVH * MAXPOS * HD))
        self.load(dir)

    def load(mut self, dir: String) raises:
        """weights.bin's tensors, as manifest.txt lists them ("<name> <offset> <bytes>" after the header
        "llama D L H KVH HD F V MAXPOS CHUNKS"), each in a device buffer of its element type."""
        var lines = open(dir + "/manifest.txt", "r").read().split("\n")
        var header = lines[0].split(" ")
        var want: List[Int] = [D, L, H, KVH, HD, F, V, MAXPOS, CHUNKS]
        if len(header) != 10 or header[0] != "llama":
            raise Error("manifest.txt: not a llama manifest")
        for i in range(9):
            if Int(header[i + 1]) != want[i]:
                raise Error("manifest.txt does not match the compiled model shape")
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
            if name.endswith(".q"):
                var b = self.ctx.enqueue_create_buffer[DType.uint32](bytes // 4)
                self.ctx.enqueue_copy(b, data.unsafe_ptr().unsafe_bitcast[UInt32]())
                self.words[name] = b
                self.q4 = True
            elif name.startswith("rope."):
                var b = self.ctx.enqueue_create_buffer[DType.float32](bytes // 4)
                self.ctx.enqueue_copy(b, data.unsafe_ptr().unsafe_bitcast[Float32]())
                self.floats[name] = b
            else:
                var b = self.ctx.enqueue_create_buffer[DType.float16](bytes // 2)
                self.ctx.enqueue_copy(b, data.unsafe_ptr().unsafe_bitcast[Float16]())
                self.halves[name] = b
            self.ctx.synchronize()  # `data` goes away
            total += bytes
        print("weights:", len(self.halves) + len(self.words) + len(self.floats), "tensors,",
              Float64(total) / 1e9, "GB", "(int4 projections and lm_head)" if self.q4 else "")

    def proj(self, add: Bool, rows: Int, name: String, x: DeviceBuffer[DType.float32],
             y: DeviceBuffer[DType.float32], cols: Int) raises:
        """y = W x (add: y += W x), with W the tensor `name` in fp16 or int4: a 64-lane workgroup a row."""
        if self.q4:
            var q = self.words[name + ".q"]
            var s = self.halves[name + ".s"]
            if add:
                self.ctx.enqueue_function[gemv_add_q4.gemv_add_q4](q, s, x, y, Int64(cols), grid_dim=rows, block_dim=64)
            else:
                self.ctx.enqueue_function[gemv_q4.gemv_q4](q, s, x, y, Int64(cols), grid_dim=rows, block_dim=64)
        elif add:
            self.ctx.enqueue_function[gemv_add.gemv_add](self.halves[name], x, y, Int64(cols), grid_dim=rows, block_dim=64)
        else:
            self.ctx.enqueue_function[gemv.gemv](self.halves[name], x, y, Int64(cols), grid_dim=rows, block_dim=64)

    def forward(self, token: Int, pos: Int) raises:
        """Enqueues one token at position `pos`; its logits end in `self.logits`."""
        var ctx = self.ctx
        ctx.enqueue_function[embed.embed](self.halves["embed." + String(token // CHUNK_ROWS)], self.x,
                                          Int64(token % CHUNK_ROWS), grid_dim=D // 256, block_dim=256)
        var cos = self.floats["rope.cos"]
        var sin = self.floats["rope.sin"]
        for l in range(L):
            var p = "l" + String(l) + "."
            ctx.enqueue_function[rmsnorm.rmsnorm](self.x, self.halves[p + "attn_norm"], self.xn, grid_dim=1, block_dim=256)
            self.proj(False, QKV, p + "wqkv", self.xn, self.qkv, D)
            ctx.enqueue_function[rope_kv.rope_kv](self.qkv, cos, sin, self.kc[l], self.vc[l], Int64(pos),
                                                  grid_dim=(H + KVH) * HD // 2 // 256, block_dim=256)
            ctx.enqueue_function[attention.attention](self.qkv, self.kc[l], self.vc[l], self.att, Int64(pos),
                                                      grid_dim=H, block_dim=HD)
            self.proj(True, D, p + "wo", self.att, self.x, D)
            ctx.enqueue_function[rmsnorm.rmsnorm](self.x, self.halves[p + "mlp_norm"], self.xn, grid_dim=1, block_dim=256)
            self.proj(False, 2 * F, p + "wgu", self.xn, self.gu, D)
            ctx.enqueue_function[silu_mul.silu_mul](self.gu, self.act, grid_dim=F // 256, block_dim=256)
            self.proj(True, D, p + "wdown", self.act, self.x, F)
        self.head()

    def head(self) raises:
        """The logits of `self.x`: the final norm, then the lm_head."""
        self.ctx.enqueue_function[rmsnorm.rmsnorm](self.x, self.halves["final_norm"], self.xn, grid_dim=1,
                                                   block_dim=256)
        for c in range(CHUNKS):  # lm_head: the (tied) embedding, a chunk at a time; int4: its own copy
            self.proj(False, CHUNK_ROWS, ("lm." if self.q4 else "embed.") + String(c), self.xn, self.logit_chunks[c], D)

    def pproj(self, n: Int, k: Int, name: String, x: DeviceBuffer[DType.float32], y: DeviceBuffer[DType.float32],
              rows: Int) raises:
        """Y = X W^T for `rows` rows, with W the tensor `name` (n x k) in fp16 or int4: 128 x 128 tiles of Y
        on cooperative matrices, 256 threads each (LLAMA_GEMM=q: lkh's, below)."""
        if self.gemmq:
            var chunks = (k + GCH - 1) // GCH
            if rows * k > len(self.xa) or chunks * rows * n > len(self.part):
                raise Error("lkh: a buffer is too small")
            self.ctx.enqueue_function[lkh.pack_x](x, self.xa.create_sub_buffer[DType.uint32](0, rows * k // 2),
                                                  Int32(k), Int32(rows * k // 8),
                                                  grid_dim=(rows * k // 8 + 255) // 256, block_dim=256)
            var g = Dim(n // 64, rows // 128, chunks)
            if lk850.on850() and self.q4:
                chunks = lk850.gemm[64, lkh.Q4](self.ctx, self.xa, self.words[name + ".q"], self.halves[name + ".s"],
                                               self.part, n, k, rows)
            elif lk850.on850():
                var w = self.halves[name]
                chunks = lk850.gemm[64, lkh.FP16](self.ctx, self.xa, w.create_sub_buffer[DType.uint32](0, n * k // 2), w,
                                                 self.part, n, k, rows)
            elif self.q4:
                self.ctx.enqueue_function[lkh.gemm_hq[2, 1, GCH, 64, 4, False, 64, lkh.Q4]](
                    self.xa, self.words[name + ".q"], self.halves[name + ".s"], self.part, Int32(n), Int32(k),
                    Int32(rows), grid_dim=g, block_dim=128)
            else:  # the fp16 rows as pairs of halves; no scales
                var w = self.halves[name]
                self.ctx.enqueue_function[lkh.gemm_hq[2, 1, GCH, 64, 4, False, 64, lkh.FP16]](
                    self.xa, w.create_sub_buffer[DType.uint32](0, n * k // 2), w, self.part, Int32(n), Int32(k),
                    Int32(rows), grid_dim=g, block_dim=128)
            self.ctx.enqueue_function[lkh.sum_parts](self.part, y, Int32(rows * n), Int32(chunks),
                                                     grid_dim=(rows * n // 8 + 255) // 256, block_dim=256)
            return
        var grid = Dim(n // 128, rows // 128)
        if self.q4:
            self.ctx.enqueue_function[p_gemm_q4.p_gemm_q4](self.words[name + ".q"], self.halves[name + ".s"], x, y,
                                                           Int64(n), Int64(k), grid_dim=grid, block_dim=256)
        else:
            self.ctx.enqueue_function[p_gemm.p_gemm](self.halves[name], x, y, Int64(n), Int64(k), grid_dim=grid,
                                                     block_dim=256)

    def prefill(mut self, tokens: List[Int]) raises:
        """Enqueues the whole prompt at once, at positions 0 .. len(tokens) - 1: per layer the decode steps
        for all rows (the prompt padded to the matmul tile), then the last row's logits in `self.logits`."""
        var ctx = self.ctx
        var n = len(tokens)
        var rows = (n + 127) // 128 * 128
        if rows > MAXPOS:
            raise Error("prefill: " + String(rows) + " padded prompt rows > " + String(MAXPOS))
        var xr = ctx.enqueue_create_buffer[DType.float32](rows * D)
        var xnr = ctx.enqueue_create_buffer[DType.float32](rows * D)
        var qkvr = ctx.enqueue_create_buffer[DType.float32](rows * QKV)
        var attr = ctx.enqueue_create_buffer[DType.float32](rows * D)
        var gur = ctx.enqueue_create_buffer[DType.float32](rows * 2 * F)
        var actr = ctx.enqueue_create_buffer[DType.float32](rows * F)
        var yr = ctx.enqueue_create_buffer[DType.float32](rows * D)
        ctx.enqueue_memset(xr, Float32(0))  # the padding rows
        for t in range(n):  # the embedding rows, each by the decode path's embed kernel
            ctx.enqueue_function[embed.embed](self.halves["embed." + String(tokens[t] // CHUNK_ROWS)],
                                              xr.create_sub_buffer[DType.float32](t * D, D),
                                              Int64(tokens[t] % CHUNK_ROWS), grid_dim=D // 256, block_dim=256)
        var cos = self.floats["rope.cos"]
        var sin = self.floats["rope.sin"]
        for l in range(L):
            var p = "l" + String(l) + "."
            ctx.enqueue_function[p_rmsnorm.p_rmsnorm](xr, self.halves[p + "attn_norm"], xnr, grid_dim=rows,
                                                      block_dim=256)
            self.pproj(QKV, D, p + "wqkv", xnr, qkvr, rows)
            ctx.enqueue_function[p_rope_kv.p_rope_kv](qkvr, cos, sin, self.kc[l], self.vc[l],  # row r: position r
                                                      grid_dim=Dim((H + KVH) * HD // 2 // 256, rows), block_dim=256)
            if self.fused_attention:
                try:  # a 64-row block of queries a workgroup
                    ctx.enqueue_function[p_attention.p_attention](qkvr, self.kc[l], self.vc[l], attr,
                                                                  grid_dim=Dim(H, rows // 64), block_dim=64)
                except e:
                    # The 840's Android 16 driver build cannot link it.
                    print("prefill: fused attention not available on this driver (" + String(e) +
                          "), using p_attention_scalar")
                    self.fused_attention = False
            if not self.fused_attention:  # one workgroup a query row
                ctx.enqueue_function[p_attention_scalar.p_attention_scalar](qkvr, self.kc[l], self.vc[l], attr,
                                                                            grid_dim=Dim(H, rows), block_dim=64)
            self.pproj(D, D, p + "wo", attr, yr, rows)
            ctx.enqueue_function[p_add.p_add](xr, yr, grid_dim=Dim(D // 256, rows), block_dim=256)
            ctx.enqueue_function[p_rmsnorm.p_rmsnorm](xr, self.halves[p + "mlp_norm"], xnr, grid_dim=rows,
                                                      block_dim=256)
            self.pproj(2 * F, D, p + "wgu", xnr, gur, rows)
            ctx.enqueue_function[p_silu_mul.p_silu_mul](gur, actr, grid_dim=Dim(F // 256, rows), block_dim=256)
            self.pproj(D, F, p + "wdown", actr, yr, rows)
            ctx.enqueue_function[p_add.p_add](xr, yr, grid_dim=Dim(D // 256, rows), block_dim=256)
        ctx.enqueue_copy(self.x, xr.create_sub_buffer[DType.float32]((n - 1) * D, D))  # the last prompt row
        self.head()
