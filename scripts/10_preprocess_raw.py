# scripts/10_preprocess_raw.py
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))  

from python.preprocess_raw import PreprocessConfig, run

if __name__ == "__main__":
    cfg = PreprocessConfig(
        raw_data_xlsx=ROOT / "data" / "raw" / "x.xlsx",   
        raw_hw1_xlsx=ROOT / "data" / "raw" / "y.xlsx",   
        out_dir=ROOT / "data" / "processed",
        y_col="import_clv_qna_sa",
        date_col="date",
    )
    run(cfg)
    print("wrote data/processed/{x.csv,y.csv,descriptions.csv}")

