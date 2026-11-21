"""Print an A/B table from results/<prefix>_<cfg>.jsonl files: python3 ab_table.py <prefix> <base_cfg> <cfg> [...]"""
import json, math, sys
pre, base, cfgs = sys.argv[1], sys.argv[2], sys.argv[3:]
def load(t):
    d = {}
    for l in open(f"results/{pre}_{t}.jsonl"):
        r = json.loads(l); d[r['name']] = r
    return d
B = load(base); V = {c: load(c) for c in cfgs}
g = {c: 0.0 for c in cfgs}
print(f"{'kernel':26s} {base:>7s} " + " ".join(f"{c:>14s}" for c in cfgs))
for n in B:
    a = B[n]['tflops']; row = f"{n:26s} {a:7.3f} "; ok = B[n]['ok']
    for c in cfgs:
        b = V[c][n]['tflops']; ok = ok and V[c][n]['ok']; g[c] += math.log(b / a)
        row += f"{b:7.3f} {100*(b/a-1):+5.1f}% "
    print(row + ("" if ok else " FAIL"))
print("geomean: " + "  ".join(f"{c} {100*(math.exp(g[c]/len(B))-1):+.1f}%" for c in cfgs))
