"""The search space: tile shapes and pipeline options of bonsai/kernels/prefill.mojo's p_gemm_t2v, the
ternary matrix kernel of the prefills, and the matrix shapes each model needs."""

import dataclasses
import itertools


@dataclasses.dataclass(frozen=True, order=True)
class Cand:
    wm: int  # subgroups of 64 threads down the block
    wn: int  # and across
    tm: int  # 64 x 64 tiles a subgroup, down
    tn: int  # and across
    bk: int  # k a step
    pad: int  # floats between shared rows beyond bk
    stages: int  # shared buffers: 2 alternates them, one barrier a step
    pf: bool  # fetch the next step's slices into registers before this step's products
    xg: bool  # X's tiles straight from memory, not staged in shared memory

    @property
    def bm(self):
        return self.wm * self.tm * 64

    @property
    def bn(self):
        return self.wn * self.tn * 64

    @property
    def threads(self):
        return self.wm * self.wn * 64

    @property
    def shared(self):
        """Bytes of shared memory a workgroup."""
        return self.stages * ((0 if self.xg else self.bm) + self.bn) * (self.bk + self.pad) * 4

    @property
    def name(self):
        return (f"{self.wm}x{self.wn}-{self.tm}x{self.tn}-k{self.bk}-p{self.pad}-s{self.stages}"
                + ("-pf" if self.pf else "") + ("-xg" if self.xg else ""))

    def mojo(self):
        """p_gemm_t2v's parameters."""
        b = lambda v: "True" if v else "False"  # noqa: E731
        return (f"{self.wm}, {self.wn}, {self.tm}, {self.tn}, {self.bk}, {self.pad}, {self.stages}, "
                f"{b(self.pf)}, {b(self.xg)}")

    @staticmethod
    def parse(name):
        f = name.split("-")
        wm, wn = map(int, f[0].split("x"))
        tm, tn = map(int, f[1].split("x"))
        return Cand(wm, wn, tm, tn, int(f[2][1:]), int(f[3][1:]), int(f[4][1:]), "pf" in f, "xg" in f)

    def fits(self, n, k, rows):
        return rows % self.bm == 0 and n % self.bn == 0 and k % self.bk == 0


DEFAULT = Cand(2, 2, 1, 1, 16, 0, 1, False, False)  # p_gemm_t2, checked against PyTorch and MLX end to end


def everything():
    """The whole space, before any device's rules."""
    for wm, wn, tm, tn, bk, pad, stages, pf, xg in itertools.product(
            (1, 2, 4), (1, 2, 4), (1, 2), (1, 2), (16, 32, 64), (0, 4), (1, 2), (False, True), (False, True)):
        c = Cand(wm, wn, tm, tn, bk, pad, stages, pf, xg)
        if c.bm <= 256 and c.bn <= 256:
            yield c


# (n, k) of every projection a prefill runs through p_gemm_t2: q/k/v fused, o, gate/up fused, down
MODELS = {
    "qwen3": [(6144, 4096), (4096, 4096), (24576, 4096), (4096, 12288)],
}


def shapes(model, rows):
    return [(n, k, r) for r in rows for n, k in MODELS[model]]
