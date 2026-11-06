"""Where a TurboVLA chunk's time goes on the laptop: pairs turbovla's profile marks (TURBOVLA_PROFILE=1: each operation
synchronized alone) with vk_server's segments (VK_SERVER_SEGMENTS=1, the laptop's clock), in order, and sums them.

  python3 turbovla/profile.py <turbovla's output> <vk_server's log>
"""
import collections
import re
import sys

marks = [l.split("mark ", 1)[1].strip() for l in open(sys.argv[1]) if l.startswith("mark ")]
segs = [(int(m.group(1)), float(m.group(2))) for l in open(sys.argv[2])
        if (m := re.match(r"segment: (\d+) launches.*?, ([\d.]+) ms", l))]
segs = segs[-len(marks):]
by_stage = collections.OrderedDict()
by_kind = collections.OrderedDict()
for mk, (n, ms) in zip(marks, segs):
    stage, what = [x.strip() for x in mk.split("|")]
    kind = re.sub(r" \d+x\d+(x\d+)?", "", what)
    by_stage[stage] = by_stage.get(stage, 0) + ms
    by_kind[(stage, kind)] = by_kind.get((stage, kind), 0) + ms
total = sum(ms for _, ms in segs)
print(f"{len(marks)} operations, each waited for alone: {total:.1f} ms")
for st, ms in by_stage.items():
    print(f"  {st:12s} {ms:7.1f} ms")
    for (s2, kind), m2 in sorted(by_kind.items(), key=lambda kv: -kv[1]):
        if s2 == st:
            print(f"      {kind:28s} {m2:7.1f} ms")
