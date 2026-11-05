"""The search: propose -> verify -> rank with the cost model -> build -> measure on the phone -> learn.

  python3 tuner/search.py run [--model qwen3] [--rows 128,512,1024] [--rounds 4] [--per-round 24]
  python3 tuner/search.py confirm      # re-measure each shape's finalists, interleaved, and pick
  python3 tuner/search.py tune --top 6 # from the learned model alone: time each shape's top 6 and pick
  python3 tuner/search.py table        # write qwen3/gemm_table.mojo from the confirmed choices
  python3 tuner/search.py report

`tune` is the cheap path once the model has data from this GPU and driver: it trains the trees on
every measurement so far and times only each shape's best predictions and the reference, once,
in interleaved rounds. evaluate.py found that a shape's top 6 always held its best candidate when
the model had never seen that shape.

Each round fits the cost model on every measurement so far, then builds one gemm_bench with the
candidates it ranks best for each shape plus a few it has not tried at random (so the model sees
more than its own favourites), and times them all on every shape they fit. The reference kernel
runs in every round: times are compared within a run, which cancels the phone's clock and
temperature between runs. Failures (the driver rejects a pipeline, or a result is wrong) go to the
device's profile and are not tried again. `confirm` then times each shape's three best candidates
and the reference again, in interleaved rounds, and its choice is what `table` writes.
"""

import argparse
import json
import math
import random
import time

import cost_model
import runner
from space import DEFAULT, Cand, shapes as model_shapes
from verifier import Profile

LAYERS = {"qwen3": 36}
ROW_MULTIPLE = 128  # Qwen3.prefill pads the prompt's rows to a multiple of this


def predicted_best(model, legal, db, shape, k):
    todo = [c for c in legal if c.fits(*shape) and c.name not in db.measured(shape)]
    return sorted(todo, key=lambda c: model.ratio(c, shape))[:k]


def summary(db, shapes, log):
    """Best measured ratio per shape (median over runs), and the prefill time it implies."""
    by = {}
    for c, s, q in db.samples():
        by.setdefault(s, {}).setdefault(c, []).append(q)
    ref_ms = {}
    for r in db.ok():
        if r["cand"] == DEFAULT.name:
            ref_ms.setdefault(tuple(r["shape"]), []).append(r["ms"])
    total_ref = total_best = 0.0
    best = {}
    for s in shapes:
        cands = {c: sorted(q)[len(q) // 2] for c, q in by.get(s, {}).items()}
        if not cands:
            continue
        c = min(cands, key=cands.get)
        base = sorted(ref_ms[s])[len(ref_ms[s]) // 2]
        best[s] = (c, cands[c])
        total_ref += base
        total_best += base * cands[c]
        log(f"  n {s[0]:5d} k {s[1]:5d} rows {s[2]:4d}: reference {base:7.2f} ms, best {c.name:24s} "
            f"{base * cands[c]:7.2f} ms ({1 / cands[c]:.2f}x), {len(cands)} measured")
    if total_ref:
        log(f"  all shapes: {total_ref:.1f} -> {total_best:.1f} ms ({total_ref / total_best:.2f}x)")
    return best


def search(a):
    key = runner.device_key()
    profile, db = Profile(key), runner.DB(key)
    shapes = model_shapes(a.model, [int(r) for r in a.rows.split(",")])
    legal = profile.legal()
    rng = random.Random(a.seed)
    log = lambda m: print(m, flush=True)  # noqa: E731
    log(f"device {key}: {len(legal)} legal candidates, {len(shapes)} shapes, {len(db.rows)} measurements so far")
    for rnd in range(a.rounds):
        model = cost_model.Model(profile.data["peaks"]).fit(db.samples())
        legal = profile.legal()
        pick = []
        per_shape = max(1, math.ceil((a.per_round - a.explore) / len(shapes)))
        for s in shapes:
            for c in predicted_best(model, legal, db, s, per_shape):
                if c not in pick:
                    pick.append(c)
        untried = [c for c in legal if c not in pick and all(c.name not in db.measured(s) for s in shapes)]
        pick += rng.sample(untried, min(a.explore, len(untried)))
        if not pick:
            log("every legal candidate is measured")
            break
        pred = {(c, s): model.ratio(c, s) for c in pick for s in shapes if c.fits(*s)}
        log(f"round {rnd + 1}: {len(pick)} candidates ({'fitted' if model.beta is not None else 'analytic'} model)")
        secs = runner.build(pick)
        run_id = f"r{int(time.time())}"
        recs = runner.run(shapes, a.timing, run_id, log)
        db.add(recs)
        for r in recs:
            if r["status"] != "ok":
                profile.record_failure(Cand.parse(r["cand"]), f"{r['status']}: {r.get('why', '')}")
        # how well the model ranked this round's candidates before seeing them
        got = {(c, s): q for c, s, q in db.samples(run_id)}
        rho = []
        for s in shapes:
            pairs = [(pred[(c, s)], got[(c, s)]) for c in pick if (c, s) in pred and (c, s) in got]
            if len(pairs) >= 3:
                rho.append(cost_model.spearman([p for p, _ in pairs], [q for _, q in pairs]))
        log(f"  built in {secs:.0f} s; model's rank correlation on them: "
            f"{sum(rho) / len(rho) if rho else float('nan'):.2f} (mean over shapes)")
        summary(db, shapes, log)


def confirm(a):
    """Each shape's three best measured candidates and the reference, timed again together."""
    key = runner.device_key()
    db = runner.DB(key)
    shapes = model_shapes(a.model, [int(r) for r in a.rows.split(",")])
    by = {}
    for c, s, q in db.samples():
        by.setdefault(s, {}).setdefault(c, []).append(q)
    pick = [DEFAULT]
    for s in shapes:
        ranked = sorted(by.get(s, {}), key=lambda c: sorted(by[s][c])[len(by[s][c]) // 2])
        for c in ranked[:3]:
            if c not in pick:
                pick.append(c)
    finish(a, key, db, shapes, pick, "c")


def tune(a):
    """Each shape's `top` best predictions of the learned model and the reference, timed together."""
    key = runner.device_key()
    profile, db = Profile(key), runner.DB(key)
    shapes = model_shapes(a.model, [int(r) for r in a.rows.split(",")])
    model = cost_model.Model(profile.data["peaks"]).fit(db.samples())
    if model.trees is None:
        raise SystemExit("too few measurements for the learned model on this device: run `search.py run` first")
    pick = [DEFAULT]
    for s in shapes:
        ranked = sorted((c for c in profile.legal() if c.fits(*s)), key=lambda c: model.ratio(c, s))
        for c in ranked[:a.top]:
            if c not in pick:
                pick.append(c)
    finish(a, key, db, shapes, pick, "t")


def finish(a, key, db, shapes, pick, tag):
    print(f"timing {len(pick)} candidates on {len(shapes)} shapes, {a.confirm} interleaved rounds", flush=True)
    runner.build(pick)
    run_id = f"{tag}{int(time.time())}"
    recs = runner.run(shapes, a.confirm, run_id)
    db.add(recs)
    final = {}
    for s in shapes:
        rs = sorted((r for r in recs if tuple(r["shape"]) == s and r["status"] == "ok"), key=lambda r: r["ms"])
        ref = next(r["ms"] for r in rs if r["cand"] == DEFAULT.name)
        final[",".join(map(str, s))] = {"reference_ms": ref, "ranked": [[r["cand"], r["ms"]] for r in rs]}
        print(f"  {s}: reference {ref:.2f} ms, best {rs[0]['cand']} {rs[0]['ms']:.2f} ms ({ref / rs[0]['ms']:.2f}x)")
    path = runner.OUT / key / f"final-{a.model}.json"
    path.write_text(json.dumps({"device": key, "model": a.model, "run": run_id, "shapes": final}, indent=1) + "\n")
    print("->", path)


def table(a):
    """qwen3/gemm_table.mojo: per projection and prompt length, the confirmed candidates in order,
    each guarded by whether the padded rows divide its blocks; the reference kernel last."""
    key = runner.device_key() if not a.device else a.device
    final = json.loads((runner.OUT / key / f"final-{a.model}.json").read_text())
    tuned = sorted({int(s.split(",")[2]) for s in final["shapes"]})
    # each tuned prompt length serves the rows nearest it (geometric midpoints between them)
    bounds = [math.sqrt(x * y) for x, y in zip(tuned, tuned[1:])]
    used, lines = {DEFAULT}, []
    for skey, entry in sorted(final["shapes"].items(), key=lambda kv: tuple(map(int, kv[0].split(",")))):
        n, k, rows = map(int, skey.split(","))
        i = tuned.index(rows)
        lo = 0 if i == 0 else math.ceil(bounds[i - 1])
        hi = None if i == len(tuned) - 1 else math.ceil(bounds[i])
        cond = f"n == {n} and k == {k}" + (f" and rows >= {lo}" if lo else "") + (f" and rows < {hi}" if hi else "")
        lines.append(f"    if {cond}:  # tuned at {rows} rows: reference {entry['reference_ms']:.2f} ms")
        for cname, ms in entry["ranked"]:
            c = Cand.parse(cname)
            if c == DEFAULT:
                break  # anything slower than the reference: use the reference
            used.add(c)
            if ROW_MULTIPLE % c.bm == 0:  # the prompt's padded rows always divide it: the last choice
                lines.append(f"        _launch[{c.mojo()}](ctx, x, w, s, y, n, k, rows)  # {ms:.2f} ms")
                lines.append("        return")
                break
            lines.append(f"        if rows % {c.bm} == 0:  # {ms:.2f} ms")
            lines.append(f"            _launch[{c.mojo()}](ctx, x, w, s, y, n, k, rows)")
            lines.append("            return")
    src = f'''# Generated by tuner/search.py table from build/tuner/{key}/final-{a.model}.json: the tile shape of
# bonsai/kernels/prefill.mojo's p_gemm_t2v for each of {a.model}'s projections and prompt lengths, as
# confirmed on {key}. Regenerate it for another phone or driver build (tuner/README.md).
from max.gpu.host import DeviceBuffer, DeviceContext, Dim

import prefill


def gemm_t2(ctx: DeviceContext, x: DeviceBuffer[DType.float32], w: DeviceBuffer[DType.uint32],
            s: DeviceBuffer[DType.float16], y: DeviceBuffer[DType.float32], n: Int, k: Int, rows: Int) raises:
    """Y = X W^T as prefill.p_gemm_t2 computes it, in the fastest confirmed shape for (n, k, rows)."""
''' + "\n".join(lines) + f'''
    _launch[{DEFAULT.mojo()}](ctx, x, w, s, y, n, k, rows)


def _launch[WM: Int, WN: Int, TM: Int, TN: Int, BK: Int, PAD: Int, STAGES: Int, PF: Bool, XG: Bool](
    ctx: DeviceContext, x: DeviceBuffer[DType.float32], w: DeviceBuffer[DType.uint32], s: DeviceBuffer[DType.float16],
    y: DeviceBuffer[DType.float32], n: Int, k: Int, rows: Int
) raises:
    ctx.enqueue_function[prefill.p_gemm_t2v[WM, WN, TM, TN, BK, PAD, STAGES, PF, XG]](
        x, w, s, y, Int32(n), Int32(k), grid_dim=Dim(n // (WN * TN * 64), rows // (WM * TM * 64)),
        block_dim=WM * WN * 64)
'''
    out = runner.ROOT / a.model / "gemm_table.mojo"
    out.write_text(src)
    print(f"-> {out}: {len(final['shapes'])} shapes, {len(used)} kernels")


def report(a):
    key = runner.device_key() if not a.device else a.device
    db = runner.DB(key)
    shapes = model_shapes(a.model, [int(r) for r in a.rows.split(",")])
    print(f"device {key}: {len(db.rows)} measurements, {len({r['cand'] for r in db.rows})} candidates, "
          f"{sum(r['status'] != 'ok' for r in db.rows)} failures")
    summary(db, shapes, print)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("step", choices=["run", "confirm", "tune", "table", "report"])
    ap.add_argument("--model", default="qwen3")
    ap.add_argument("--rows", default="128,512,1024")
    ap.add_argument("--rounds", type=int, default=4)
    ap.add_argument("--per-round", type=int, default=24)
    ap.add_argument("--explore", type=int, default=6)
    ap.add_argument("--timing", type=int, default=3, help="interleaved timing rounds a search run")
    ap.add_argument("--confirm", type=int, default=7, help="interleaved timing rounds when confirming")
    ap.add_argument("--seed", type=int, default=0)
    ap.add_argument("--top", type=int, default=6, help="tune: candidates per shape, from the model")
    ap.add_argument("--device", help="table/report for this device key instead of the connected phone")
    a = ap.parse_args()
    {"run": search, "confirm": confirm, "tune": tune, "table": table, "report": report}[a.step](a)


if __name__ == "__main__":
    main()
