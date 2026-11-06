"""The Mac's copy of a Gemma 4 checkpoint: model.safetensors at its full size, but sparse, holding only the byte ranges
that something here reads (by HTTP range request from the pinned revision). The disk keeps what was fetched; the
holes cost nothing. The phone downloads the whole file instead.

  build/vla/venv/bin/python gemma4/fetch.py --model e2b      # every range recipe.txt reads (convert.c's input), which
                                                             # are also every bf16 weight reference.py --bf16 reads

Rows of the two embedding tables (`table` lines of the manifest) are fetched when reference.py asks for them.
Fetched ranges are listed in model.safetensors.ranges, so a run picks up where the last one stopped.
"""

import argparse
import concurrent.futures
import json
import os
import pathlib
import threading
import urllib.request

ROOT = pathlib.Path(__file__).resolve().parents[1]
import sys

sys.path.insert(0, str(ROOT / "gemma4"))
from export import MODELS, url  # noqa: E402

CHUNK = 32 << 20


class Sparse:
    def __init__(self, model):
        self.model = model
        repo, rev = MODELS[model]
        self.url = url(repo, rev, "model.safetensors")
        self.dir = ROOT / "build/gemma4" / model
        self.path = self.dir / "hf/model.safetensors"
        self.path.parent.mkdir(parents=True, exist_ok=True)
        h = json.loads((self.dir / "header.json").read_text())
        ends = [v["data_offsets"][1] for v in h.values() if isinstance(v, dict) and "data_offsets" in v]
        self.size = h["__base__"] + max(ends)
        self.ranges_path = self.path.with_suffix(".safetensors.ranges")
        self.lock = threading.Lock()
        if not self.path.exists():
            with open(self.path, "wb") as f:
                f.truncate(self.size)
            self.ranges_path.unlink(missing_ok=True)
        self.done = [tuple(r) for r in json.loads(self.ranges_path.read_text())] if self.ranges_path.exists() else []
        # the header itself, so the file is a valid safetensors file for anything that reads one
        self.fetch([(0, h["__base__"])], workers=1, quiet=True)

    def _get(self, off, n):
        req = urllib.request.Request(self.url, headers={"Range": f"bytes={off}-{off + n - 1}"})
        for attempt in range(5):
            try:
                data = urllib.request.urlopen(req, timeout=120).read()
                if len(data) == n:
                    break
            except Exception as e:  # noqa: BLE001
                if attempt == 4:
                    raise
                print(f"retry {off}+{n}: {e}", flush=True)
        else:
            raise RuntimeError(f"short read at {off}")
        fd = os.open(self.path, os.O_WRONLY)
        try:
            os.pwrite(fd, data, off)
        finally:
            os.close(fd)

    def have(self, off, n):
        return any(a <= off and off + n <= b for a, b in self.done)

    def fetch(self, ranges, workers=8, quiet=False):
        """Fetch every (offset, length) not yet held, in chunks, `workers` requests at a time."""
        todo = []
        for off, n in sorted(ranges):
            if not self.have(off, n):
                for o in range(off, off + n, CHUNK):
                    todo.append((o, min(CHUNK, off + n - o)))
        total = sum(n for _, n in todo)
        if not todo:
            return
        got = 0
        with concurrent.futures.ThreadPoolExecutor(workers) as ex:
            futs = {ex.submit(self._get, o, n): (o, n) for o, n in todo}
            for fu in concurrent.futures.as_completed(futs):
                fu.result()
                o, n = futs[fu]
                with self.lock:
                    self.done.append((o, o + n))
                    got += n
                    if not quiet and (got * 20 // total) != ((got - n) * 20 // total):
                        print(f"{self.model}: {got / 1e9:.2f} of {total / 1e9:.2f} GB", flush=True)
                    self._save()

    def _save(self):
        merged = []
        for a, b in sorted(self.done):
            if merged and a <= merged[-1][1]:
                merged[-1][1] = max(merged[-1][1], b)
            else:
                merged.append([a, b])
        self.done = [tuple(m) for m in merged]
        self.ranges_path.write_text(json.dumps(merged))

    def read(self, off, n):
        if not self.have(off, n):
            self.fetch([(off, n)], workers=1, quiet=True)
        with open(self.path, "rb") as f:
            f.seek(off)
            return f.read(n)


def recipe_ranges(recipe):
    """The input byte ranges convert.c reads for recipe.txt."""
    out = []
    for line in recipe.read_text().splitlines():
        f = line.split()
        if f[0] == "f32":
            out.append((int(f[2]), int(f[3]) * 2))
        elif f[0] == "q4":
            out.append((int(f[3]), int(f[4]) * int(f[5]) * 2))
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--model", choices=MODELS, default="e2b")
    ap.add_argument("--workers", type=int, default=8)
    a = ap.parse_args()
    s = Sparse(a.model)
    s.fetch(recipe_ranges(s.dir / "recipe.txt"), a.workers)
    print(f"{s.path}: {sum(b - a for a, b in s.done) / 1e9:.2f} GB held of {s.size / 1e9:.2f}")


if __name__ == "__main__":
    main()
