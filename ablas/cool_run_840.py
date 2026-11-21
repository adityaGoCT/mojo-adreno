"""Run ablas_test on the Samsung RTL Adreno 840 one shape at a time, cooled (the RTL bridge allows no shell loops,
so the loop and the thermal gate run here; see ../asm/mesa/run.py). Driver: stock, or turnip (Mesa Turnip with
the bank-aware RA, ../asm/mesa run.py pushbank).
  RTL_SERIAL=localhost:<port> python3 cool_run_840.py stock "T N 2048 2048 2048" "P P 512 2048 2048" ...
"""
import pathlib, sys
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent.parent / "asm" / "mesa"))
import run  # noqa: E402

drv, shapes = sys.argv[1], sys.argv[2:]
env = f"LD_LIBRARY_PATH={run.DEV}/turnip_bank " if drv == "turnip" else ""
for s in shapes:
    lvl, temp = run.cool()
    out = f"ablas840_{drv}_one.txt"
    run.sh(f"cd {run.DEV}; {env}./ablas_test_840 {s} > {out} 2>&1")
    lines = [l for l in run.sh(f"cat {run.DEV}/{out}", check=False).stdout.splitlines()
             if l.strip() and not l.startswith(("device:", "Date:", "Compiler", "Driver", ")"))]
    print(f"{' | '.join(lines)}   [{drv}, start {temp:.0f} C]", flush=True)
