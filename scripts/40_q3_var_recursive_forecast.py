# scripts/40_q3_var_recursive_forecast.py
from __future__ import annotations

from pathlib import Path
import sys

PROJECT_ROOT = Path(__file__).resolve().parents[1]
if str(PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(PROJECT_ROOT))

import pandas as pd

from python.var_core import (
    prepare_var_level_data,
    recursive_var_one_step_forecast_level,
    compute_rmse,
)
from python.var_io import (
    read_x_xlsx,
    read_y_xlsx,
    read_top1_x_code_from_q1_csv,
    read_txt_int,
    write_csv,
    write_txt,
)


def main() -> None:
    date_col = "date"
    y_col = "import_clv_qna_sa"

    x_path = "data/raw/x.xlsx"
    y_path = "data/raw/y.xlsx"

    q1_csv = "output/tables/q1_top5_abs_corr_R.csv"
    x_code = read_top1_x_code_from_q1_csv(q1_csv)

    x_df = read_x_xlsx(x_path, sheet_name="data_x")
    y_df = read_y_xlsx(y_path, sheet_name="data_y")

    if x_code not in x_df.columns:
        raise ValueError(f"Selected x_code '{x_code}' not found in x.xlsx (data_x).")

    panel = prepare_var_level_data(
        y_df=y_df,
        x_df=x_df,
        date_col=date_col,
        y_col=y_col,
        x_col=x_code,
        allow_last_x_missing=True,
    )

    # Prefer Python-selected lag; fallback to R if needed
    py_lag_path = Path("output/tables_py/q2_var_selected_lag_py.txt")
    if py_lag_path.exists():
        p_star = read_txt_int(str(py_lag_path))
    else:
        p_star = read_txt_int("output/tables/q2_var_selected_lag.txt")

    pred = recursive_var_one_step_forecast_level(
        level_df=panel,
        date_col=date_col,
        y_col=y_col,
        x_col=x_code,
        p=p_star,
        train_ratio=0.8,
        diff_lag=1,
        trend="c",
    )

    rmse_val = compute_rmse(pred["y_true"].to_numpy(), pred["y_pred"].to_numpy())
    write_csv(pred, "output/tables_py/q3_var_recursive_forecasts_py.csv")
    write_txt(f"{rmse_val:.6f}", "output/tables_py/q3_var_rmse_py.txt")

    # Optional consistency check with R (do not hard fail on tiny float diffs)
    r_rmse_path = Path("output/tables/q3_var_rmse.csv")
    if r_rmse_path.exists():
        r_rmse = float(pd.read_csv(r_rmse_path)["rmse"].iloc[0])
        if abs(r_rmse - rmse_val) > 1e-3:
            raise RuntimeError(f"Python RMSE={rmse_val} differs from R RMSE={r_rmse} (>1e-3).")

    print(f"Section3 (Python) done. VAR recursive RMSE = {rmse_val:.6f}")


if __name__ == "__main__":
    main()
