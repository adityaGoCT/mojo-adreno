"""Client for graph_tool serve (npu/graph.cpp): a chain of compiled graphs kept open on the laptop's NPU, reached
through an SSH tunnel. SET fills an input slot (fp32 / int32 as the graph takes it, fp16 for an fp32 input, or camera
frames as PNG that the server normalizes itself: a tenth of the bytes through the tunnel, and exact); RUN runs the
chain once and returns the last graph's outputs (fp32); GET reads a slot back."""

import io
import socket
import struct
import time

import numpy as np


class NPUChain:
    def __init__(self, port, host="127.0.0.1"):
        self.s = socket.create_connection((host, port))
        self.s.setsockopt(socket.IPPROTO_TCP, socket.TCP_NODELAY, 1)

    def _recv(self, n):
        buf = bytearray()
        while len(buf) < n:
            chunk = self.s.recv(n - len(buf))
            if not chunk:
                raise ConnectionError("graph_tool serve closed the connection")
            buf += chunk
        return bytes(buf)

    def _request(self, op, slot=0, fmt=0, payload=b""):
        self.s.sendall(struct.pack("<IIIIQ", op, slot, fmt, 0, len(payload)) + payload)
        status, n, ms = struct.unpack("<iId", self._recv(16))
        data = self._recv(n) if n else b""
        if status:
            raise RuntimeError(data.decode(errors="replace"))
        return data, ms

    def set(self, slot, array, half=False):
        """An input slot's content: an fp32 array (sent as fp16 when half) or an int32 one."""
        a = np.ascontiguousarray(array)
        if half:
            self._request(1, slot, 1, a.astype(np.float16).tobytes())
        else:
            self._request(1, slot, 0, a.astype(a.dtype).tobytes())

    def get(self, slot):
        """A slot's current bytes."""
        return self._request(3, slot)[0]

    @staticmethod
    def png_frames(images, mean, std):
        """SET format 2's payload: H x W x 3 uint8 frames as PNG (fast compression, lossless), and the per-channel
        mean and std the server normalizes x / 255 with."""
        from PIL import Image
        body = struct.pack("<I6f", len(images), *mean, *std)
        for im in images:
            buf = io.BytesIO()
            Image.fromarray(np.ascontiguousarray(im, np.uint8)).save(buf, format="PNG", compress_level=1)
            body += struct.pack("<I", buf.tell()) + buf.getvalue()
        return body

    def run(self, sets=()):
        """The chain once, after setting `sets` ((slot, array, half) each, or (slot, png_frames(...), "png")): all the
        requests sent back to back, then their answers read, one tunnel round trip in all. Returns (the last graph's
        outputs as one fp32 array, the chain's time on the laptop in ms, the round trip in ms)."""
        t0 = time.perf_counter()
        msg = b""
        for slot, array, half in sets:
            if half == "png":
                body, fmt = array, 2
            else:
                a = np.ascontiguousarray(array)
                body, fmt = (a.astype(np.float16).tobytes(), 1) if half else (a.tobytes(), 0)
            msg += struct.pack("<IIIIQ", 1, slot, fmt, 0, len(body)) + body
        msg += struct.pack("<IIIIQ", 2, 0, 0, 0, 0)
        self.s.sendall(msg)
        for _ in range(len(sets)):
            status, n, _ = struct.unpack("<iId", self._recv(16))
            data = self._recv(n) if n else b""
            if status:
                raise RuntimeError(data.decode(errors="replace"))
        status, n, ms = struct.unpack("<iId", self._recv(16))
        data = self._recv(n) if n else b""
        if status:
            raise RuntimeError(data.decode(errors="replace"))
        return np.frombuffer(data, np.float32), ms, (time.perf_counter() - t0) * 1e3
