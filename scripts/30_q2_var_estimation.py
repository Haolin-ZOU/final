# scripts/30_q2_var_estimation.py
from __future__ import annotations
import pandas as pd
import numpy as np
from pathlib import Path
import sys

# Allow running: python scripts/30_q2_var_estimation.py from repo root
PROJECT_ROOT = Path(__file__).resolve().parents[1]
if str(PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(PROJECT_ROOT))

import pandas as pd

from python.var_core import (
    prepare_var_level_data,
    make_first_differences,
    make_var_lag_diagnostics,
    choose_lag_from_diagnostics,
    extract_var_coef_table,
)
from python.var_plot import save_acf_pacf_pair
from python.var_io import (
    read_x_xlsx,
    read_y_xlsx,
    read_top1_x_code_from_q1_csv,
    write_csv,
    write_txt,
)


def main() -> None:
    date_col = "date"
    y_col = "import_clv_qna_sa"

    x_path = "data/raw/x.xlsx"
    y_path = "data/raw/y.xlsx"

    # Use R Q1 output to guarantee same x choice as your R pipeline
    q1_csv = "output/tables/q1_top5_abs_corr_R.csv"
    x_code = read_top1_x_code_from_q1_csv(q1_csv)

    # IMPORTANT: x.xlsx sheet is "data_x" (otherwise pandas may return dict)
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

    diff_df = make_first_differences(panel, date_col, cols=[y_col, x_code], diff_lag=1)
    dy = f"d_{y_col}"
    dx = f"d_{x_code}"
    
    print("dx finite count =", np.isfinite(diff_df[dx].to_numpy()).sum(), " / ", len(diff_df))
    print("dx tail =", diff_df[dx].to_numpy()[-5:])

    # ACF/PACF figures (stationary series evidence)
    save_acf_pacf_pair(diff_df[dy].to_numpy(), "output/figures_py/q2_acf_pacf_dy_py.png", title=dy)
    save_acf_pacf_pair(diff_df[dx].to_numpy(), "output/figures_py/q2_acf_pacf_dx_py.png", title=dx)

    # Use first 80% of the stationary sample (HW2 requirement)
    n = len(diff_df)
    n_train = int((0.8 * n) // 1)
    train_mat = diff_df.iloc[:n_train][[dy, dx]].copy()
    train_mat.columns = ["dy", "dx"]

    diag = make_var_lag_diagnostics(train_mat, max_lag=8, trend="c", whiteness_lags=12)
    write_csv(diag, "output/tables_py/q2_var_lag_diagnostics_py.csv")

    p_star = choose_lag_from_diagnostics(diag)
    write_txt(p_star, "output/tables_py/q2_var_selected_lag_py.txt")

    # Fit final model for coef / roots / serial test
    from statsmodels.tsa.api import VAR

    res = VAR(train_mat).fit(p_star, trend="c")

    coef_tab = extract_var_coef_table(res)
    write_csv(coef_tab, "output/tables_py/q2_var_coef_table_py.csv")

    roots = getattr(res, "roots", [])
    roots_abs = [abs(complex(r)) for r in roots]
    write_csv(pd.DataFrame({"root_modulus": roots_abs}), "output/tables_py/q2_var_roots_py.csv")

    serial_p = float("nan")
    try:
        wt = res.test_whiteness(nlags=12)
        serial_p = float(getattr(wt, "pvalue", float("nan")))
    except Exception:
        pass
    write_txt(f"whiteness_pvalue={serial_p}", "output/tables_py/q2_var_serial_test_py.txt")

    # Optional consistency check (do NOT hard fail if R output not present)
    r_lag_path = Path("output/tables/q2_var_selected_lag.txt")
    if r_lag_path.exists():
        r_p = int(r_lag_path.read_text(encoding="utf-8").strip())
        if p_star != r_p:
            raise RuntimeError(f"Python p*={p_star} != R p*={r_p}. Align settings/sample.")

    print(f"Section2 (Python) done. Selected x={x_code}, p*={p_star}")


if __name__ == "__main__":
    main()
