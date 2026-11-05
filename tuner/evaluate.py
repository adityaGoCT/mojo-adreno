"""How many measurements does the cost model save? An offline test on the measurements so far.

  python3 tuner/evaluate.py [--device KEY]

Leave one shape out: train on every other shape's measurements, rank the held-out shape's measured
candidates, and measure only the top k. Reported per k: the share of the best possible speedup that
those k measurements find (1.0: the true best is among them), averaged over the shapes. Rankers: the
analytic roofline alone, the ridge model, the gradient-boosted trees search.py uses, the same trees
from scikit-learn if it is installed (a check of ours), and random order (the mean over orders).
"""

import argparse
import math
import statistics

import numpy as np

import cost_model
import runner
from space import DEFAULT
from verifier import Profile


def medians(samples):
    by = {}
    for c, s, q in samples:
        by.setdefault((c, s), []).append(q)
    return {key: statistics.median(v) for key, v in by.items()}


def gbm(peaks):
    try:
        from sklearn.ensemble import GradientBoostingRegressor
    except ImportError:
        return None

    class Trees:
        def fit(self, samples):
            X = np.array([cost_model.features(c, s, peaks) + list(s) for c, s, _ in samples])
            y = np.log([q for _, _, q in samples])
            self.m = GradientBoostingRegressor(n_estimators=300, max_depth=3, learning_rate=0.05, subsample=0.8,
                                               random_state=0).fit(X, y)
            return self

        def ratio(self, c, s):
            return float(math.exp(self.m.predict(np.array([cost_model.features(c, s, peaks) + list(s)]))[0]))
    return Trees


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--device", default="SM-S948U-S948USQS4AZG3")
    a = ap.parse_args()
    db = runner.DB(a.device)
    peaks = Profile(a.device).data["peaks"]
    samples = db.samples()
    med = medians(samples)
    shapes = sorted({s for _, s in med})
    ks = [1, 2, 3, 4, 6, 8, 12]

    class Analytic:
        def fit(self, _):
            return self

        def ratio(self, c, s):
            return cost_model.analytic(c, s, peaks) / cost_model.analytic(DEFAULT, s, peaks)

    rankers = {"analytic": Analytic, "ridge": lambda: cost_model.Ridge(peaks), "trees": lambda: cost_model.Trees(peaks)}
    sk = gbm(peaks)
    if sk:
        rankers["sklearn"] = sk
    score = {name: {k: [] for k in ks} for name in [*rankers, "random"]}
    rho = {name: [] for name in rankers}
    for s in shapes:
        train = [x for x in samples if x[1] != s]
        cands = [c for c, t in med if t == s]
        true = {c: med[(c, s)] for c in cands}
        best = min(true.values())
        gain = lambda found: (1 / min(found) - 1) / (1 / best - 1) if best < 1 else 1.0  # noqa: E731
        for name, make in rankers.items():
            m = make().fit(train)
            order = sorted(cands, key=lambda c: m.ratio(c, s))
            rho[name].append(cost_model.spearman([m.ratio(c, s) for c in cands], [true[c] for c in cands]))
            for k in ks:
                score[name][k].append(gain([1.0] + [true[c] for c in order[:k]]))
        rng = np.random.default_rng(0)
        for k in ks:
            score["random"][k].append(statistics.mean(
                gain([1.0] + [true[c] for c in rng.permutation(cands)[:k]]) for _ in range(200)))
    print(f"{len(samples)} measurements, {len(shapes)} shapes, {len({c for c, _ in med})} candidates; "
          f"leave one shape out")
    print("share of the best speedup found by measuring the top k:")
    print("k".rjust(10) + "".join(f"{k:>7d}" for k in ks) + "   rank corr.")
    for name in score:
        r = f"{statistics.mean(rho[name]):.2f}" if name in rho else ""
        print(f"{name:>10s}" + "".join(f"{statistics.mean(score[name][k]):7.2f}" for k in ks) + f"   {r:>8s}")


if __name__ == "__main__":
    main()
