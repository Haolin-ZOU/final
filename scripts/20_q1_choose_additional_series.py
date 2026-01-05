import sys
from pathlib import Path
import pandas as pd

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from python.series_selection import align_by_date, diff_columns, rank_by_abs_corr, add_descriptions
from python.plotting import barh_abs_corr

if __name__ == "__main__":
    x = pd.read_csv(ROOT / "data" / "processed" / "x.csv")
    y = pd.read_csv(ROOT / "data" / "processed" / "y.csv")
    desc = pd.read_csv(ROOT / "data" / "processed" / "descriptions.csv")

    df = align_by_date(y, x, date_col="date")
    candidate_cols = [c for c in df.columns if c not in ("date", "y")]

    df_d = diff_columns(df, cols=["y"] + candidate_cols, date_col="date", lag=1)

    top5 = rank_by_abs_corr(df_d, y_col="y", candidate_cols=candidate_cols, top_n=5, min_obs=30)
    top5 = add_descriptions(top5, desc)
    top5 = top5[["code", "DESCRIPTION", "corr", "abs_corr", "n_obs"]]

    out_table = ROOT / "output" / "tables" / "q1_data_driven_top5.csv"
    out_fig = ROOT / "output" / "figures" / "q1_data_driven_top5_corr.png"
    out_table.parent.mkdir(parents=True, exist_ok=True)
    out_fig.parent.mkdir(parents=True, exist_ok=True)

    top5.to_csv(out_table, index=False)
    barh_abs_corr(
        top5,
        code_col="code",
        value_col="abs_corr",
        title="Top 5 candidates by |corr| with Δy (first differences)",
        out_path=out_fig,
    )

    print("✅ wrote:", out_table)
    print("✅ wrote:", out_fig)
    print(top5.to_string(index=False))
