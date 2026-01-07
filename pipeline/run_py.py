# pipeline/run_py.py
# One-command pipeline (Python path)

from __future__ import annotations

import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

steps = [
    "scripts/20_q1_choose_series.py",
    "scripts/30_q2_var_estimation.py",
    "scripts/40_q3_var_recursive_forecast.py",
    "scripts/50_bonus_irf_granger.py",
]

for s in steps:
    p = ROOT / s
    if not p.exists():
        raise FileNotFoundError(f"Missing step: {s}")
    print(f"Running: {s}")
    r = subprocess.run([sys.executable, str(p)], cwd=str(ROOT))
    if r.returncode != 0:
        raise RuntimeError(f"Step failed: {s}")

print("Python pipeline done.")

