# Qwen3-30B-A3B (Qwen/Qwen3-30B-A3B-Instruct-2507) decode as MAX DeviceContext launches: 48 layers of grouped-query
# attention (32 query and 4 KV heads of 128, QK norm, RoPE theta 1e7) and a mixture of 128 experts (top-8, SwiGLU of
# 768), int4 projections and experts (export.py's qwen3moe.bin: 15.7 GB on the GPU), fp32 activations and KV cache.
#
# The weights never cross to the host program: export.py's manifest names each tensor's place in qwen3moe.bin, a file
# on the device that runs the executor (the X2 Elite laptop, behind the remote driver plugin), and the plugin's
# M_driver_remote_file has the executor read it into the device buffer. The fp32 embedding stays in the file: each step
# has the executor copy the row of its token, which it reads from the GPU's token list (the prompt, then each argmax),
# with M_driver_remote_gather. So a whole generation is enqueued without the host waiting for any token.
from std.collections import Dict
from std.ffi import OwnedDLHandle
from std.math import cos, sin
from std.os import getenv
from max.gpu.host import DeviceBuffer, DeviceContext, Dim

import gemv_add_q4
import gemv_q4
import moek

comptime D = 2048
comptime L = 48
comptime H = 32
comptime KVH = 4
comptime HD = 128
comptime QKV = (H + 2 * KVH) * HD  # 5120
comptime E = 128
comptime TOPK = 8
comptime FE = 768
comptime V = 151936
comptime CAP = 512  # positions a KV cache holds
comptime THETA: Float64 = 10000000.0


def groups(n: Int, per: Int) -> Int:
    return (n + per - 1) // per


def plugin_path() raises -> String:
    """The driver plugin MAX loaded: MODULAR_DRIVER_PLUGINS=vulkan@<path>."""
    var spec = getenv("MODULAR_DRIVER_PLUGINS")
    var at = spec.find("@")
    if at < 0:
        raise Error("MODULAR_DRIVER_PLUGINS=vulkan@<path of libM_driver_vulkan_remote> is needed")
    return String(spec[byte=at + 1:])


struct Qwen3Moe(Movable):
    var ctx: DeviceContext
    var lib: OwnedDLHandle  # the driver plugin, for M_driver_remote_file and M_driver_remote_gather
    var path: String  # qwen3moe.bin on the executor's side
    var embed_offset: Int
    var words: Dict[String, DeviceBuffer[DType.uint32]]
    var halves: Dict[String, DeviceBuffer[DType.float16]]
    var floats: Dict[String, DeviceBuffer[DType.float32]]
    var bytes: Int
    var kc: List[DeviceBuffer[DType.float32]]
    var vc: List[DeviceBuffer[DType.float32]]
    var table: DeviceBuffer[DType.float32]  # RoPE: cos | sin rows of 64 per position
    var tokens: DeviceBuffer[DType.int32]  # the prompt, then the generated tokens
    var x: DeviceBuffer[DType.float32]
    var xn: DeviceBuffer[DType.float32]
    var qkv: DeviceBuffer[DType.float32]
    var att: DeviceBuffer[DType.float32]
    var scores: DeviceBuffer[DType.float32]
    var rlog: DeviceBuffer[DType.float32]
    var ids: DeviceBuffer[DType.int32]
    var wts: DeviceBuffer[DType.float32]
    var a: DeviceBuffer[DType.float32]
    var logits: DeviceBuffer[DType.float32]

    def __init__(out self, ctx: DeviceContext, manifest: String, weights: String) raises:
        """manifest: export.py's manifest.txt (a copy on this side); weights: qwen3moe.bin's path on the executor's
        side."""
        self.ctx = ctx
        self.lib = OwnedDLHandle(plugin_path())
        self.path = weights
        self.embed_offset = -1
        self.words = Dict[String, DeviceBuffer[DType.uint32]]()
        self.halves = Dict[String, DeviceBuffer[DType.float16]]()
        self.floats = Dict[String, DeviceBuffer[DType.float32]]()
        self.bytes = 0
        self.kc = List[DeviceBuffer[DType.float32]]()
        self.vc = List[DeviceBuffer[DType.float32]]()
        for _ in range(L):
            self.kc.append(ctx.enqueue_create_buffer[DType.float32](CAP * KVH * HD))
            self.vc.append(ctx.enqueue_create_buffer[DType.float32](CAP * KVH * HD))
        self.table = ctx.enqueue_create_buffer[DType.float32](CAP * HD)
        self.tokens = ctx.enqueue_create_buffer[DType.int32](CAP + 1)
        self.x = ctx.enqueue_create_buffer[DType.float32](D)
        self.xn = ctx.enqueue_create_buffer[DType.float32](D)
        self.qkv = ctx.enqueue_create_buffer[DType.float32](QKV)
        self.att = ctx.enqueue_create_buffer[DType.float32](H * HD)
        self.scores = ctx.enqueue_create_buffer[DType.float32](H * CAP)
        self.rlog = ctx.enqueue_create_buffer[DType.float32](E)
        self.ids = ctx.enqueue_create_buffer[DType.int32](TOPK)
        self.wts = ctx.enqueue_create_buffer[DType.float32](TOPK)
        self.a = ctx.enqueue_create_buffer[DType.float32](TOPK * FE)
        self.logits = ctx.enqueue_create_buffer[DType.float32](V)
        self.load(manifest)
        self.rope_table()

    def load(mut self, manifest: String) raises:
        var lines = open(manifest, "r").read().splitlines()
        for i in range(1, len(lines)):
            var f = lines[i].split(" ")
            if len(f) < 4:
                continue
            var name = String(f[0])
            var off = Int(f[1])
            var n = Int(f[2])
            var kind = String(f[3])
            if name == "embed":  # stays in the file: step() gathers its rows
                self.embed_offset = off
                continue
            var addr: Int
            if kind == "u32":
                var b = self.ctx.enqueue_create_buffer[DType.uint32](n // 4)
                addr = Int(b.unsafe_ptr())
                self.words[name] = b
            elif kind == "f16":
                var b = self.ctx.enqueue_create_buffer[DType.float16](n // 2)
                addr = Int(b.unsafe_ptr())
                self.halves[name] = b
            else:
                var b = self.ctx.enqueue_create_buffer[DType.float32](n // 4)
                addr = Int(b.unsafe_ptr())
                self.floats[name] = b
            if self.lib.call["M_driver_remote_file", Int32](UInt64(addr), UInt64(n),
                                                           self.path.as_c_string_span().unsafe_ptr(), UInt64(off)) != 0:
                raise Error("M_driver_remote_file failed for " + name)
            self.bytes += n
        if self.embed_offset < 0:
            raise Error(manifest + ": no embed")
        self.ctx.synchronize()  # a read's error arrives here

    def rope_table(mut self) raises:
        """cos | sin of position * inv_freq, as transformers' default RoPE computes them in fp32."""
        var host = List[Float32](length=CAP * HD, fill=0)
        for i in range(HD // 2):
            var inv = Float32(1.0) / (Float32(THETA) ** (Float32(2 * i) / Float32(HD)))
            for p in range(CAP):
                var f = Float32(p) * inv
                host[p * HD + i] = Float32(cos(Float64(f)))
                host[p * HD + HD // 2 + i] = Float32(sin(Float64(f)))
        self.ctx.enqueue_copy(self.table, host.unsafe_ptr())
        self.ctx.synchronize()

    def set_prompt(self, prompt: List[Int32]) raises:
        var host = List[Int32](length=CAP + 1, fill=0)
        for i in range(len(prompt)):
            host[i] = prompt[i]
        self.ctx.enqueue_copy(self.tokens, host.unsafe_ptr())

    def step(mut self, pos: Int, write: Bool) raises:
        """The token at `pos` (from the token list) through the model; its argmax into tokens[pos + 1] if `write`."""
        var ctx = self.ctx
        var p = Int32(pos)
        if self.lib.call["M_driver_remote_gather", Int32](UInt64(Int(self.x.unsafe_ptr())),
                                                          UInt64(Int(self.tokens.unsafe_ptr()) + 4 * pos),
                                                          self.path.as_c_string_span().unsafe_ptr(),
                                                          UInt64(self.embed_offset), UInt64(4 * D)) != 0:
            raise Error("M_driver_remote_gather failed")
        for l in range(L):
            var n = "l" + String(l) + "."
            ctx.enqueue_function[moek.rmsnorm](self.x, self.floats[n + "in_norm"], self.xn, Int32(D), grid_dim=1,
                                               block_dim=64)
            ctx.enqueue_function[gemv_q4.gemv_q4](self.words[n + "qkv.q"], self.halves[n + "qkv.s"], self.xn, self.qkv,
                                                  Int64(D), grid_dim=QKV, block_dim=64)
            ctx.enqueue_function[moek.qk_norm_rope](self.qkv, self.floats[n + "q_norm"], self.floats[n + "k_norm"],
                                                    self.table, self.kc[l], self.vc[l], p, grid_dim=H + 2 * KVH,
                                                    block_dim=64)
            ctx.enqueue_function[moek.attn_scores](self.qkv, self.kc[l], self.scores, p, Int32(CAP),
                                                   grid_dim=groups(KVH * (pos + 1), 64), block_dim=64)
            ctx.enqueue_function[moek.attn_values](self.scores, self.vc[l], self.att, p, Int32(CAP),
                                                   grid_dim=2 * H, block_dim=64)
            ctx.enqueue_function[gemv_add_q4.gemv_add_q4](self.words[n + "o.q"], self.halves[n + "o.s"], self.att,
                                                          self.x, Int64(H * HD), grid_dim=D, block_dim=64)
            ctx.enqueue_function[moek.rmsnorm](self.x, self.floats[n + "post_norm"], self.xn, Int32(D), grid_dim=1,
                                               block_dim=64)
            ctx.enqueue_function[moek.gemv_f32](self.floats[n + "router"], self.xn, self.rlog, Int32(D), grid_dim=E,
                                                block_dim=64)
            ctx.enqueue_function[moek.route](self.rlog, self.ids, self.wts, grid_dim=1, block_dim=64)
            ctx.enqueue_function[moek.moe_gate_up](self.words[n + "gu.q"], self.halves[n + "gu.s"], self.ids, self.xn,
                                                   self.a, grid_dim=Dim(FE, TOPK), block_dim=64)
            ctx.enqueue_function[moek.moe_down](self.words[n + "down.q"], self.halves[n + "down.s"], self.ids, self.wts,
                                                self.a, self.x, grid_dim=D, block_dim=64)
        ctx.enqueue_function[moek.rmsnorm](self.x, self.floats["final_norm"], self.xn, Int32(D), grid_dim=1,
                                           block_dim=64)
        ctx.enqueue_function[gemv_q4.gemv_q4](self.words["head.q"], self.halves["head.s"], self.xn, self.logits,
                                              Int64(D), grid_dim=V, block_dim=64)
        ctx.enqueue_function[moek.argmax](self.logits, Int32(V), self.tokens, p, Int32(1 if write else 0), grid_dim=1,
                                          block_dim=256)
