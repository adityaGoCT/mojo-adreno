"""The verifier: which candidates may run on a device, before any of them is built.

Static rules come from the device's profile (tuner/devices/<model>-<build>.json): its limits, and
rules learned on the device, each with the evidence that found it. The dynamic check runs on the
phone (gemm_bench.mojo): a candidate's output must match the reference kernel's on random data to
1e-5 of the largest value, and one the driver rejects or that mismatches is recorded here, so later
rounds skip it and a pattern of failures can become a rule.
"""

import json
import pathlib

from space import DEFAULT, Cand, everything

DEVICES = pathlib.Path(__file__).resolve().parent / "devices"

BASE = {
    "max_threads": 512,  # what we search; the 840 allows 1024
    "shared_bytes": 32768,  # VkPhysicalDeviceLimits.maxComputeSharedMemorySize
    "shared_strict": False,  # True: a workgroup must use less than shared_bytes
    "max_accumulators": 4,  # 64 x 64 fp32 accumulators a subgroup
    "rules": [],
    "failed": {},
}


class Profile:
    def __init__(self, key):
        self.key = key
        self.path = DEVICES / f"{key}.json"
        self.data = dict(BASE)
        if self.path.exists():
            self.data.update(json.loads(self.path.read_text()))

    def save(self):
        DEVICES.mkdir(exist_ok=True)
        self.path.write_text(json.dumps(self.data, indent=2, sort_keys=True) + "\n")

    def check(self, c: Cand):
        """None if the candidate may run here, else why not."""
        d = self.data
        if c.threads > d["max_threads"]:
            return f"{c.threads} threads > {d['max_threads']}"
        if c.shared > d["shared_bytes"] or (d["shared_strict"] and c.shared == d["shared_bytes"]):
            return f"{c.shared} bytes of shared memory"
        if c.tm * c.tn > d["max_accumulators"]:
            return f"{c.tm * c.tn} accumulators a subgroup > {d['max_accumulators']}"
        if c.name in d["failed"]:
            return "failed on the device: " + d["failed"][c.name]
        return None

    def legal(self, shape=None):
        out = [c for c in everything() if self.check(c) is None]
        if shape:
            out = [c for c in out if c.fits(*shape)]
        return sorted(out, key=lambda c: (c != DEFAULT, c))

    def record_failure(self, c: Cand, why):
        if c == DEFAULT:
            raise RuntimeError(f"the reference kernel failed: {why}")
        self.data["failed"][c.name] = why
        self.save()
