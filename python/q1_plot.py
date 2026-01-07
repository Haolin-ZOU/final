# python/q1_plot.py
from __future__ import annotations

from pathlib import Path
import pandas as pd
import matplotlib.pyplot as plt


def save_top5_barh(top5: pd.DataFrame, out_path: Path, title: str = "Top 5 by |corr| (first differences)") -> None:
    plot_df = top5.sort_values("abs_corr", ascending=True)

    plt.figure(figsize=(10, 4))
    plt.barh(plot_df["code"], plot_df["abs_corr"])
    plt.title(title)
    plt.xlabel("|Pearson correlation|")
    plt.ylabel("Candidate series code")
    plt.grid(True, axis="x")
    plt.tight_layout()

    out_path.parent.mkdir(parents=True, exist_ok=True)
    plt.savefig(out_path, dpi=200)
    plt.close()