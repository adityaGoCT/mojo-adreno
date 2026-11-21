"""Cut the ir3 disassembly of every compiled shader out of a Mesa log (IR3_SHADER_DEBUG=cs MESA_LOG_FILE=...).

  python3 extract_asm.py <mesa.log> <outdir>

Writes <outdir>/<blake3>.asm (the variant's hash, i.e. the file name IR3_SHADER_OVERRIDE_PATH looks for)
and prints one line per shader: hash, overridden?, instruction count.
"""
import pathlib, re, sys

PFX = re.compile(r"^MESA: (info|warning|error|debug): ?")
HDR = re.compile(r"Native code( \(overridden\))? for .* with blake3 ([0-9a-f]{64}):")


def extract(log):
    lines = [PFX.sub("", l.rstrip("\n")) for l in open(log, errors="replace")]
    out, cur = [], None
    for l in lines:
        m = HDR.search(l)
        if m:
            cur = {"hash": m.group(2), "overridden": bool(m.group(1)), "body": []}
            out.append(cur)
            continue
        if cur is None:
            continue
        if l.strip() == "" and any(b.startswith("; ") and "max_waves" in b for b in cur["body"]):
            cur = None
            continue
        cur["body"].append(l)
    return out


def main():
    log, outdir = sys.argv[1], pathlib.Path(sys.argv[2])
    outdir.mkdir(parents=True, exist_ok=True)
    for s in extract(log):
        (outdir / f"{s['hash']}.asm").write_text("\n".join(s["body"]) + "\n")
        stats = next((b for b in s["body"] if " instr, " in b), "")
        print(s["hash"], "overridden" if s["overridden"] else "compiled", stats.split(":", 1)[-1].strip())


if __name__ == "__main__":
    main()
