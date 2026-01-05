import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

if __name__ == "__main__":
    subprocess.check_call(["python", str(ROOT / "scripts" / "10_preprocess_raw.py")])
    subprocess.check_call(["python", str(ROOT / "scripts" / "20_q1_choose_additional_series.py")])
    print("✅ Q1 done (Python): processed + top5 + figure")
