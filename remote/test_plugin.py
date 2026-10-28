"""Drive the remote-device plugin through MAX's HAL C interface, the way MAX's runtime does, with
MAX's own kernels: allocate and copy through the plugin, load a kernel's SPIR-V, launch it with
CUDA-style arguments (a pointer to each argument's bytes), read the result back, check it.

  python3 remote/test_plugin.py

Starts remote/vk_server.c on the phone and forwards its port. Kernels come from
max_kernels/test_max_kernels.py --compile (build/max_kernels/spv).
"""

import ctypes as C
import json
import math
import os
import pathlib
import subprocess
import sys
import time

import numpy as np

HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parent
BUILD = ROOT / "build/remote"
SPV = ROOT / "build/max_kernels/spv"
MOJO_SRC = pathlib.Path(os.environ.get("MOJO_SRC", ROOT.parent / "modular"))
NDK = pathlib.Path(os.environ.get("ANDROID_NDK", "/opt/homebrew/share/android-ndk"))
CC = NDK / "toolchains/llvm/prebuilt/darwin-x86_64/bin/aarch64-linux-android34-clang"
DEV = "/data/local/tmp/mojo/remote"
PORT = int(os.environ.get("VK_REMOTE_PORT", "7788"))
os.environ.setdefault("ANDROID_SERIAL", os.environ.get("ADB_WIFI", "192.168.1.7:5555"))
rng = np.random.default_rng(0)


def sh(*cmd, check=True):
    r = subprocess.run([str(c) for c in cmd], capture_output=True, text=True, stdin=subprocess.DEVNULL)
    if check and r.returncode:
        sys.exit(f"$ {' '.join(map(str, cmd))}\n{r.stdout}{r.stderr}")
    return r


def build_and_start():
    """Builds the plugin and the server, and starts the server on the phone. It runs as long as
    the returned `adb shell` process (adb keeps a shell session open while its command runs)."""
    BUILD.mkdir(parents=True, exist_ok=True)
    sh("clang++", "-std=c++17", "-O1", "-shared", "-fPIC", f"-I{MOJO_SRC}/SDK/include", "-o",
       BUILD / "libM_driver_vulkan_remote.dylib", HERE / "vulkan_remote_plugin.cpp")
    sh(CC, "-O2", "-o", BUILD / "vk_server", HERE / "vk_server.c", "-ldl")
    sh("adb", "shell", "pkill -x vk_server", check=False)  # -x: not this shell, whose command names it
    sh("adb", "shell", f"mkdir -p {DEV}")
    sh("adb", "push", BUILD / "vk_server", f"{DEV}/")
    server = subprocess.Popen(["adb", "shell", f"cd {DEV} && LD_LIBRARY_PATH=/data/local/tmp/turnip exec ./vk_server {PORT}"],
                              stdin=subprocess.DEVNULL, stdout=open(BUILD / "server.log", "w"), stderr=subprocess.STDOUT)
    sh("adb", "forward", f"tcp:{PORT}", f"tcp:{PORT}")
    for _ in range(50):
        if "listening" in (BUILD / "server.log").read_text():
            return server
        time.sleep(0.1)
    sys.exit(f"vk_server did not start:\n{(BUILD / 'server.log').read_text()}")


# --- the HAL C interface -------------------------------------------------------------------

class Version(C.Structure):
    _fields_ = [("major", C.c_uint32), ("minor", C.c_uint32), ("patch", C.c_uint32)]


class View(C.Structure):  # M_driver_memory_view
    _fields_ = [("memory", C.c_void_p), ("offset", C.c_uint64), ("size", C.c_uint64)]


class Slice(C.Structure):
    _fields_ = [("data", C.c_char_p), ("size", C.c_uint64)]


class StaticBundle(C.Structure):
    _fields_ = [("mapped_data", Slice), ("file_type", C.c_char_p), ("file_type_len", C.c_uint64)]


class Dim(C.Structure):
    _fields_ = [("x", C.c_uint32), ("y", C.c_uint32), ("z", C.c_uint32)]


class GPUConfig(C.Structure):
    _fields_ = [("grid", Dim), ("block", Dim), ("shared_mem_bytes", C.c_uint32), ("attributes", C.c_void_p),
                ("num_attributes", C.c_uint32)]


class ExecuteConfig(C.Structure):
    _fields_ = [("mode", C.c_int), ("gpu", GPUConfig)]


class HAL:
    def __init__(self, path):
        self.lib = C.CDLL(str(path))
        self.driver, self.device, self.context, self.queue = C.c_void_p(), C.c_void_p(), C.c_void_p(), C.c_void_p()
        self.check("create", C.byref(Version(0, 1, 0)), C.byref(self.driver))
        self.check("device_get", self.driver, C.c_int64(0), C.byref(self.device))
        name = C.create_string_buffer(257)
        self.check("device_property", self.device, b"arch", name)
        self.arch = name.value.decode()
        self.check("context_create", self.device, C.byref(self.context))
        self.check("queue_create", self.context, C.byref(self.queue))

    def check(self, fn, *args):
        status = getattr(self.lib, f"M_driver_{fn}")(*args)
        if status:
            message = C.create_string_buffer(512)
            self.lib.M_driver_status_message(None, C.c_int64(status), message, C.c_int64(512))
            sys.exit(f"M_driver_{fn}: {message.value.decode()}")

    def alloc(self, nbytes):
        memory = C.c_void_p()
        self.check("memory_alloc_sync", self.context, C.c_uint64(nbytes), C.byref(memory))
        address = C.c_void_p()
        self.check("memory_property", memory, b"address", C.byref(address))
        return memory, address.value

    def upload(self, array):
        data = np.ascontiguousarray(array)
        memory, address = self.alloc(data.nbytes)
        self.check("queue_copy_to_device", self.queue, C.byref(View(memory, 0, data.nbytes)),
                   data.ctypes.data_as(C.c_void_p))
        return memory, address

    def download(self, memory, like):
        out = np.empty_like(like)
        self.check("queue_copy_from_device", self.queue, out.ctypes.data_as(C.c_void_p),
                   C.byref(View(memory, 0, out.nbytes)))
        self.check("queue_synchronize", self.queue)
        return out

    def load(self, spv):
        data = spv.read_bytes()
        self._keep = data
        bundle = StaticBundle(Slice(data, len(data)), b"spirv", 5)
        runtime, function = C.c_void_p(), C.c_void_p()
        self.check("bundle_load", self.context, C.byref(bundle), None, C.byref(runtime))
        self.check("function_load", self.context, runtime, b"main", C.c_uint64(4), C.byref(function))
        return function

    def launch(self, function, args, grid, block):
        """`args`: one bytes object per kernel argument, as MAX passes them."""
        buffers = [C.create_string_buffer(a, len(a)) for a in args]
        pointers = (C.c_void_p * len(args))(*[C.cast(b, C.c_void_p) for b in buffers])
        sizes = (C.c_uint64 * len(args))(*[len(a) for a in args])
        config = ExecuteConfig(0, GPUConfig(Dim(*grid), Dim(*block), 0, None, 0))
        self.check("queue_execute", self.queue, function, C.byref(config), pointers, sizes, C.c_uint32(len(args)))


def description(spv):
    words = np.frombuffer(spv.read_bytes(), dtype="<u4")
    at = 5
    while at < len(words):
        count, opcode = int(words[at]) >> 16, int(words[at]) & 0xFFFF
        if opcode == 330:
            text = words[at + 1:at + count].tobytes().split(b"\0", 1)[0].decode()
            if text.startswith("mojo.vulkan.abi "):
                return json.loads(text[16:])
        at += count
    sys.exit(f"{spv}: no launch description")


FORMATS = {"i1": "<B", "i8": "<b", "i16": "<h", "i32": "<i", "i64": "<q", "half": "<e", "float": "<f"}


def pack_args(desc, leaf_values):
    """Lays out the arguments' bytes as the host would: each leaf (in argument order) at its
    offset. Pointer leaves get device addresses."""
    import struct
    args = [bytearray(a["bytes"]) for a in desc["args"]]
    entries = [("ptr", b) for b in desc["buffers"]]
    entries += [("scalar", s) for s in (desc["params"] or {"slots": []})["slots"] if "arg" in s]
    entries.sort(key=lambda e: (e[1]["arg"], e[1]["offset"]))
    assert len(entries) == len(leaf_values), (len(entries), len(leaf_values))
    for (kind, e), value in zip(entries, leaf_values):
        data = struct.pack("<Q", value) if kind == "ptr" else struct.pack(FORMATS[e["type"]], value)
        args[e["arg"]][e["offset"]:e["offset"] + len(data)] = data
    return [bytes(a) for a in args]


def main():
    server = build_and_start()
    try:
        run_tests()
    finally:
        server.terminate()


def run_tests():
    hal = HAL(BUILD / "libM_driver_vulkan_remote.dylib")
    print(f"plugin: device arch {hal.arch}")
    results = []

    # MAX's naive matmul: (c, a, b, m, n, k), 16x16 blocks.
    for name, (m, n, k) in [("matmul_f32_256x256", (256, 256, 256)), ("matmul__gemv__1x2048x2048", (1, 2048, 2048))]:
        spv = next((SPV / name).glob("*matmul_kernel_naive*.spv"))
        a = rng.standard_normal((m, k)).astype(np.float32)
        b = rng.standard_normal((k, n)).astype(np.float32)
        (ma, pa), (mb, pb) = hal.upload(a), hal.upload(b)
        mc, pc = hal.upload(np.full((m, n), np.nan, np.float32))
        f = hal.load(spv)
        args = pack_args(description(spv), [pc, pa, pb, m, n, k])
        t = time.time()
        hal.launch(f, args, (-(-m // 16), -(-n // 16), 1), (16, 16, 1))
        c = hal.download(mc, np.empty((m, n), np.float32))
        err = float(np.max(np.abs(c - a.astype(np.float64) @ b)))
        results.append((name, err < 1e-3 * math.sqrt(k), err, time.time() - t))

    # MAX's elementwise kernel (add), every compiled variant.
    for spv in sorted((SPV / "add").glob("*mogg.foreach*.spv")):
        desc = description(spv)
        nn = 1024
        x, y = rng.standard_normal(nn).astype(np.float32), rng.standard_normal(nn).astype(np.float32)
        (mx, px), (my, py) = hal.upload(x), hal.upload(y)
        mo, po = hal.upload(np.full(nn, np.nan, np.float32))
        inputs = iter([px, py])
        ptrs = [po if b["access"] in ("write", "read_write") else next(inputs) for b in desc["buffers"]]
        values = []
        for p in ptrs:
            values += [p, nn, 1]
        values += [nn, nn // 4, 0, nn]
        f = hal.load(spv)
        t = time.time()
        hal.launch(f, pack_args(desc, values), (1, 1, 1), (256, 1, 1))
        out = hal.download(mo, np.empty(nn, np.float32))
        err = float(np.max(np.abs(out - (x + y))))
        results.append((f"add {spv.name.split('-', 1)[1][:40]}", err == 0, err, time.time() - t))

    for name, ok, err, seconds in results:
        print(f"{name:52s} {'PASS' if ok else 'FAIL'}  max error {err:.2e}  {seconds * 1e3:.0f} ms incl. transfer")
    print(f"\n{sum(r[1] for r in results)}/{len(results)} passed")


if __name__ == "__main__":
    main()
