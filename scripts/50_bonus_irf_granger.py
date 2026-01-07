# scripts/50_bonus_irf_granger.py
from __future__ import annotations

from pathlib import Path
import sys

import numpy as np
import pandas as pd

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

PROJECT_ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(PROJECT_ROOT))

from statsmodels.tsa.api import VAR

from python.var_core import (
    prepare_var_level_data,
    make_first_differences,
    compute_orth_irf_table,
    compute_granger_table,
)
from python.var_io import (
    read_x_xlsx,
    read_y_xlsx,
    read_top1_x_code_from_q1_csv,
    read_txt_int,
    write_csv,
)


def find_first_existing(candidates: list[str]) -> str:
    for p in candidates:
        if Path(p).exists():
            return p
    # fallback: search a few folders
    for folder in ["data", "hw1", "data/hw1", "data/raw"]:
        base = Path(folder)
        if base.exists():
            for f in base.rglob("*.xlsx"):
                name = f.name.lower()
                if name in {"x.xlsx", "y.xlsx"}:
                    # we only use this fallback if candidates fail
                    pass
    raise FileNotFoundError(
        "Cannot find required Excel file. Tried:\n  - " + "\n  - ".join(candidates)
    )


def save_irf_png(irf_df: pd.DataFrame, out_png: str, title: str) -> None:
    Path(out_png).parent.mkdir(parents=True, exist_ok=True)
    h = irf_df["h"].to_numpy()
    y = irf_df["irf"].to_numpy()

    fig, ax = plt.subplots(figsize=(7, 4))
    ax.axhline(0.0)
    ax.plot(h, y, marker="o")
    ax.set_xlabel("Horizon")
    ax.set_ylabel("IRF")
    ax.set_title(title)
    fig.tight_layout()
    fig.savefig(out_png, dpi=150)
    plt.close(fig)


def main() -> None:
    date_col = "date"
    y_col = "import_clv_qna_sa"
    train_ratio = 0.8
    diff_lag = 1
    steps = 12

    # Use SAME x choice as R (from Q1 output)
    q1_csv = "output/tables/q1_top5_abs_corr_R.csv"
    x_code = read_top1_x_code_from_q1_csv(q1_csv)

    # Use SAME p* as R (from Section2 output)
    p_star = read_txt_int("output/tables/q2_var_selected_lag.txt")
    if p_star < 1:
        raise ValueError("Invalid p* read from output/tables/q2_var_selected_lag.txt")

    # Robust file locations (do NOT hardcode a non-existing path)
    x_path = find_first_existing([
        "data/raw/x.xlsx",
        "data/x.xlsx",
        "data/hw2/x.xlsx",
        "hw2/x.xlsx",
    ])
    y_path = find_first_existing([
        "data/raw/y.xlsx",
        "data/y.xlsx",
        "data/hw1/y.xlsx",
        "hw1/y.xlsx",
    ])

    x_df = read_x_xlsx(x_path, sheet_name=None)
    y_df = read_y_xlsx(y_path, sheet_name=None)

    panel = prepare_var_level_data(
        y_df=y_df,
        x_df=x_df,
        date_col=date_col,
        y_col=y_col,
        x_col=x_code,
        allow_last_x_missing=True,
    )

    # Match Section2: first 80% of LEVEL sample
    n_level = len(panel)
    n_train_level = int(np.floor(train_ratio * n_level))

    diff_df = make_first_differences(
        level_df=panel,
        date_col=date_col,
        cols=[y_col, x_code],
        diff_lag=diff_lag,
    )

    # In diff space, the first diff row corresponds to level t=2
    # So "first 80% of levels" => first (n_train_level - diff_lag) rows in diff
    n_train_diff = max(1, n_train_level - diff_lag)
    train_df = diff_df.iloc[:n_train_diff].copy()

    dy = f"d_{y_col}"
    dx = f"d_{x_code}"

    # Drop NA just in case
    train_df = train_df[[dy, dx]].dropna()

    # ---------- IRF with both orderings (orth IRF depends on ordering) ----------
    # ordering 1: (dy, dx)
    train1 = train_df[[dy, dx]].copy()
    train1.columns = ["dy", "dx"]
    res1 = VAR(train1).fit(p_star, trend="c")

    irf1 = compute_orth_irf_table(res1, impulse="dx", response="dy", steps=steps)
    write_csv(irf1, "output/tables_py/bonus_irf_order_dy_dx.csv")
    save_irf_png(irf1, "output/figures_py/bonus_irf_order_dy_dx.png",
                 "IRF: dy response to dx shock (order: dy, dx)")

    # ordering 2: (dx, dy)
    train2 = train_df[[dx, dy]].copy()
    train2.columns = ["dx", "dy"]
    res2 = VAR(train2).fit(p_star, trend="c")

    irf2 = compute_orth_irf_table(res2, impulse="dx", response="dy", steps=steps)
    write_csv(irf2, "output/tables_py/bonus_irf_order_dx_dy.csv")
    save_irf_png(irf2, "output/figures_py/bonus_irf_order_dx_dy.png",
                 "IRF: dy response to dx shock (order: dx, dy)")

    # ---------- Granger causality (ordering-invariant) ----------
    gtab = compute_granger_table(res1, var_names=["dy", "dx"])
    write_csv(gtab, "output/tables_py/bonus_granger.csv")

    print("Bonus (Python) done.")
    print("Wrote: output/tables_py/bonus_irf_order_*.csv, output/figures_py/bonus_irf_order_*.png, output/tables_py/bonus_granger.csv")


if __name__ == "__main__":
    main()
