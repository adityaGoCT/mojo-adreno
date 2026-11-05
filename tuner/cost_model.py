"""The cost model: ranks verified candidates before any of them is built.

analytic(c, shape)  a roofline estimate: the matrix units' fp32 work at the device's measured peak,
                    the memory traffic the tiling implies (W's 2-bit codes re-read for every block of
                    rows, X for every block of columns) at its measured bandwidth, shared-memory
                    traffic, and the per-step costs the pipeline options change: barriers (two a step,
                    one with two buffers) and memory latency a step (mostly hidden by prefetch).
Learned             the log of a candidate's time relative to the reference kernel in the same run
                    (which cancels the phone's clock and temperature between runs), from the analytic
                    terms' ratios, the candidate's options and the shape. Two learners: Trees,
                    gradient-boosted regression trees (numpy, no scikit-learn), which search.py uses
                    once it has 30 measurements; and Ridge, a linear model, for comparison. Both are
                    refitted on every measurement, across shapes, so a new shape starts from what the
                    others taught. evaluate.py measures how well each ranks a shape it has not seen.
"""

import math

import numpy as np

from space import DEFAULT, Cand

# Rough constants of the analytic part; the learned part corrects their errors.
SMEM_TBS = 2.0  # aggregate shared-memory bandwidth, TB/s
CONC = 24  # workgroups in flight on the GPU
BARRIER_US = 0.4  # one barrier of one workgroup
LATENCY_US = 1.0  # one step's global loads, not overlapped


def terms(c: Cand, shape, peaks):
    n, k, rows = shape
    steps = k // c.bk
    groups = (n // c.bn) * (rows // c.bm)
    mma = 2.0 * rows * n * k / (peaks["fp32_mma_tflops"] * 1e12) * 1e3
    w = (n * k / 4 + n * k / 64) * (rows // c.bm)  # codes and scales, once a block of rows
    x = rows * k * 4 * (n // c.bn) * (1 + 0.25 * (c.wn - 1) if c.xg else 1)
    mem = (w + x + rows * n * 4) / (peaks["dram_gbs"] * 1e9) * 1e3
    stores = ((0 if c.xg else c.bm) + c.bn) * c.bk * 4
    loads = c.wm * c.wn * (c.bk // 8) * (((0 if c.xg else c.tm) + c.tn) * 64 * 8 * 4)
    smem = groups * steps * (stores + loads) / (SMEM_TBS * 1e12) * 1e3
    sync = groups * steps * (2 if c.stages == 1 else 1) * BARRIER_US * 1e-3 / CONC
    lat = groups * steps * LATENCY_US * (0.3 if c.pf else 1.0) * 1e-3 / CONC
    return {"mma": mma, "mem": mem, "smem": smem, "sync": sync, "lat": lat, "groups": groups, "steps": steps}


def analytic(c: Cand, shape, peaks):
    t = terms(c, shape, peaks)
    return max(t["mma"], t["mem"], t["smem"]) + t["sync"] + t["lat"]


def features(c: Cand, shape, peaks):
    t, t0 = terms(c, shape, peaks), terms(DEFAULT, shape, peaks)
    n, k, rows = shape
    r = lambda key: math.log(t[key] / t0[key])  # noqa: E731
    return [
        math.log(analytic(c, shape, peaks) / analytic(DEFAULT, shape, peaks)),
        r("mem"), r("smem"), r("sync"), r("lat"), r("groups"), r("steps"),
        c.bk / 16, c.pad / 4, c.stages - 1, float(c.pf), float(c.xg), float(c.pf and c.xg),
        math.log2(c.threads / 256), math.log2(c.bm / 128), math.log2(c.bn / 128),
        math.log2(c.bm / 128) * math.log2(rows / 512), math.log2(c.bn / 128) * math.log2(n / 4096),
        float(c.xg) * math.log2(c.wn),
    ]


class Ridge:
    """log(time / reference time) = features . beta, ridge-regularised on standardised features."""

    def __init__(self, peaks, ridge=1.0):
        self.peaks, self.ridge, self.beta = peaks, ridge, None

    def fit(self, samples):
        """samples: (Cand, shape, ratio to the reference in the same run)."""
        if len(samples) < 8:
            self.beta = None
            return self
        X = np.array([features(c, s, self.peaks) for c, s, _ in samples])
        y = np.log(np.array([q for _, _, q in samples]))
        self.mu, self.sd = X.mean(0), X.std(0) + 1e-9
        Z = np.hstack([np.ones((len(X), 1)), (X - self.mu) / self.sd])
        reg = self.ridge * np.eye(Z.shape[1])
        reg[0, 0] = 0
        self.beta = np.linalg.solve(Z.T @ Z + reg, Z.T @ y)
        return self

    def ratio(self, c, shape):
        """Predicted time relative to the reference kernel; the analytic ratio until fitted."""
        if self.beta is None:
            return analytic(c, shape, self.peaks) / analytic(DEFAULT, shape, self.peaks)
        z = (np.array(features(c, shape, self.peaks)) - self.mu) / self.sd
        return float(math.exp(self.beta[0] + z @ self.beta[1:]))


def spearman(a, b):
    """Rank correlation of two equal-length lists."""
    if len(a) < 3:
        return float("nan")
    ra, rb = np.argsort(np.argsort(a)), np.argsort(np.argsort(b))
    return float(np.corrcoef(ra, rb)[0, 1])


class Trees:
    """Gradient-boosted regression trees on log(time / reference time): `rounds` trees of depth `depth`,
    each fitted to the residuals of the ones before on a random `subsample` of the measurements, scaled
    by `rate`. Features: features() plus the shape itself. With too few measurements to learn from, it
    ranks by the analytic estimate."""

    def __init__(self, peaks, rounds=300, depth=3, rate=0.05, subsample=0.8, seed=0, least=30):
        self.peaks, self.rounds, self.depth, self.rate = peaks, rounds, depth, rate
        self.subsample, self.seed, self.least = subsample, seed, least
        self.trees = None

    def _x(self, c, shape):
        return features(c, shape, self.peaks) + [math.log2(v) for v in shape]

    def fit(self, samples):
        if len(samples) < self.least:
            self.trees = None
            return self
        X = np.array([self._x(c, s) for c, s, _ in samples])
        y = np.log(np.array([q for _, _, q in samples]))
        rng = np.random.default_rng(self.seed)
        self.base = float(y.mean())
        pred = np.full(len(y), self.base)
        self.trees = []
        for _ in range(self.rounds):
            idx = rng.choice(len(y), max(2, int(self.subsample * len(y))), replace=False)
            tree = self._grow(X[idx], (y - pred)[idx], self.depth)
            self.trees.append(tree)
            pred += self.rate * self._apply(tree, X)
        return self

    def _grow(self, X, r, depth):
        """A node: a leaf value, or (feature, threshold, left, right) at the split that most reduces
        the squared error of the residuals r."""
        if depth == 0 or len(r) < 4:
            return float(r.mean())
        best = None
        total, n = r.sum(), len(r)
        for j in range(X.shape[1]):
            order = np.argsort(X[:, j], kind="stable")
            xs, rs = X[order, j], r[order]
            left = np.cumsum(rs)[:-1]
            cnt = np.arange(1, n)
            ok = xs[1:] > xs[:-1]  # split only between distinct values
            if not ok.any():
                continue
            gain = left ** 2 / cnt + (total - left) ** 2 / (n - cnt)
            gain[~ok] = -np.inf
            i = int(np.argmax(gain))
            if best is None or gain[i] > best[0]:
                best = (gain[i], j, (xs[i] + xs[i + 1]) / 2)
        if best is None:
            return float(r.mean())
        _, j, t = best
        m = X[:, j] <= t
        return (j, t, self._grow(X[m], r[m], depth - 1), self._grow(X[~m], r[~m], depth - 1))

    def _apply(self, tree, X):
        if not isinstance(tree, tuple):
            return np.full(len(X), tree)
        j, t, left, right = tree
        m = X[:, j] <= t
        out = np.empty(len(X))
        out[m] = self._apply(left, X[m])
        out[~m] = self._apply(right, X[~m])
        return out

    def ratio(self, c, shape):
        if self.trees is None:
            return analytic(c, shape, self.peaks) / analytic(DEFAULT, shape, self.peaks)
        x = np.array([self._x(c, shape)])
        return float(math.exp(self.base + self.rate * sum(self._apply(t, x)[0] for t in self.trees)))


Model = Trees  # what search.py uses
