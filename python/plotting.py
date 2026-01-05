from __future__ import annotations
from pathlib import Path
import pandas as pd
import matplotlib.pyplot as plt


def barh_abs_corr(df: pd.DataFrame, code_col: str = "code", value_col: str = "abs_corr",
                  title: str = "", out_path: Path | None = None) -> None:
    plot_df = df.sort_values(value_col, ascending=True)
    plt.figure()
    plt.barh(plot_df[code_col], plot_df[value_col])
    plt.title(title)
    plt.xlabel("|Pearson correlation|")
    plt.ylabel("Candidate series (code)")
    plt.tight_layout()
    if out_path is not None:
        out_path.parent.mkdir(parents=True, exist_ok=True)
        plt.savefig(out_path, dpi=200)
    plt.close()
