# python/var_plot.py
from __future__ import annotations

from pathlib import Path
from typing import Iterable

import numpy as np

import matplotlib
matplotlib.use("Agg")  # important for headless/CI
import matplotlib.pyplot as plt

from statsmodels.graphics.tsaplots import plot_acf, plot_pacf


def _to_finite_1d(x: Iterable[float]) -> np.ndarray:
    """Convert input to 1D float array and drop non-finite values."""
    arr = np.asarray(list(x), dtype=float).reshape(-1)
    arr = arr[np.isfinite(arr)]
    return arr


def save_acf_pacf_pair(
    series: Iterable[float],
    out_png: str | Path,
    title: str,
    nlags: int = 20,
) -> None:
    """
    Save ACF/PACF side-by-side plot.

    Notes
    -----
    - Drops nan/inf before plotting (prevents blank plots).
    - If series too short after cleaning, raises ValueError (fail fast).
    """
    x = _to_finite_1d(series)
    if x.size < 3:
        raise ValueError("Series too short after removing missing values.")

    # Make sure nlags is feasible
    max_lags = max(1, x.size - 1)
    nlags = int(min(nlags, max_lags))

    fig, axes = plt.subplots(1, 2, figsize=(12, 4))

    plot_acf(x, lags=nlags, ax=axes[0], zero=True)
    axes[0].set_title(f"{title} ACF")
    axes[0].set_xlabel("Lag")
    axes[0].set_ylabel("ACF")

    plot_pacf(x, lags=nlags, ax=axes[1], zero=True, method="ywm")
    axes[1].set_title(f"{title} PACF")
    axes[1].set_xlabel("Lag")
    axes[1].set_ylabel("PACF")

    fig.tight_layout()

    out_path = Path(out_png)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    fig.savefig(out_path, dpi=150)
    plt.close(fig)


# Backward compatible alias (if you used old name somewhere)
def save_acf_pacf_png(series: Iterable[float], out_png: str | Path, title_prefix: str = "", nlags: int = 20) -> None:
    title = title_prefix.strip() or "series"
    save_acf_pacf_pair(series=series, out_png=out_png, title=title, nlags=nlags)
