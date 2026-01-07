# scripts/20_q1_choose_series.py
from __future__ import annotations

# --- Glue for reproducible imports when running as a script ---
import sys
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from python.q1_io import (
    read_x_strict_one_sheet,
    read_y_sheet_strict,
    read_desc_sheet_strict,
    require_columns,
    write_csv,
)
from python.q1_core import Q1Config, q1_select_top5
from python.q1_plot import save_top5_barh


def main() -> None:
    x_path = ROOT / "data" / "raw" / "x.xlsx"
    y_path = ROOT / "data" / "raw" / "y.xlsx"

    cfg = Q1Config(date_col="date", y_col="import_clv_qna_sa", top_n=5, min_obs=30, train_ratio=0.8, diff_lag=1)

    x = read_x_strict_one_sheet(x_path)
    y = read_y_sheet_strict(y_path, sheet_name="data_y")
    desc = read_desc_sheet_strict(y_path, sheet_name="descriptions")

    require_columns(x, [cfg.date_col], context=f"{x_path.name} (only sheet)")
    require_columns(y, [cfg.date_col, cfg.y_col], context=f"{y_path.name} (sheet=data_y)")

    top5 = q1_select_top5(y_df=y[[cfg.date_col, cfg.y_col]], x_df=x, cfg=cfg)

    # Optional: attach descriptions for report table
    top5 = top5.merge(desc, left_on="code", right_on="CODE", how="left").drop(columns=["CODE"], errors="ignore")

    out_table = ROOT / "output" / "tables" / "q1_top5_abs_corr.csv"
    out_fig = ROOT / "output" / "figures" / "q1_top5_abs_corr.png"

    write_csv(top5, out_table)
    save_top5_barh(top5, out_fig)

    print(top5.to_string(index=False))
    print(f"Wrote: {out_table}")
    print(f"Wrote: {out_fig}")


if __name__ == "__main__":
    main()
