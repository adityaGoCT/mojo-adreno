# Llama 3.2 1B decode on the Adreno as MAX DeviceContext launches of the kernels in llama/kernels:
# llama_vk.c's forward pass, in Mojo. Weights from llama/run.py's export (manifest.txt, weights.bin),
# fp16 or int4; fp32 activations and KV cache. Through MAX's HAL DeviceContext and the Vulkan driver
# plugin, each launch binds its buffers and scalars as llama_vk.c's dispatches do.
from std.collections import Dict
from max.gpu.host import DeviceBuffer, DeviceContext

import attention
import embed
import gemv
import gemv_add
import gemv_add_q4
import gemv_q4
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


struct Llama(Movable):
    var ctx: DeviceContext
    var halves: Dict[String, DeviceBuffer[DType.float16]]  # fp16 tensors and int4 scales
    var words: Dict[String, DeviceBuffer[DType.uint32]]  # int4 weights, 8 a word
    var floats: Dict[String, DeviceBuffer[DType.float32]]  # the RoPE tables
    var q4: Bool
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
        ctx.enqueue_function[rmsnorm.rmsnorm](self.x, self.halves["final_norm"], self.xn, grid_dim=1, block_dim=256)
        for c in range(CHUNKS):  # lm_head: the (tied) embedding, a chunk at a time; int4: its own copy
            self.proj(False, CHUNK_ROWS, ("lm." if self.q4 else "embed.") + String(c), self.xn, self.logit_chunks[c], D)
