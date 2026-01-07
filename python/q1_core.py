# python/q1_core.py
from __future__ import annotations

from dataclasses import dataclass
from typing import Sequence

import numpy as np
import pandas as pd

@dataclass(frozen=True)
class Q1Config:
    date_col: str = "date"
    y_col: str = "import_clv_qna_sa"
    top_n: int = 5
    min_obs: int = 30
    train_ratio: float = 0.8
    diff_lag: int = 1  # keep consistent with HW1 stationarity treatment idea


def to_datetime_strict(df: pd.DataFrame, date_col: str) -> pd.DataFrame:
    out = df.copy()
    out[date_col] = pd.to_datetime(out[date_col], errors="coerce")
    if out[date_col].isna().any():
        raise ValueError(f"Some values in '{date_col}' cannot be parsed as datetime.")
    return out


def align_on_date(y: pd.DataFrame, x: pd.DataFrame, date_col: str) -> pd.DataFrame:
    y2 = to_datetime_strict(y, date_col)
    x2 = to_datetime_strict(x, date_col)
    merged = pd.merge(y2, x2, on=date_col, how="inner")
    return merged.sort_values(date_col).reset_index(drop=True)


def trim_to_last_observed_y(df: pd.DataFrame, y_col: str) -> pd.DataFrame:
    idx = df[y_col].last_valid_index()
    if idx is None:
        raise ValueError("Target y is fully missing.")
    return df.loc[:idx].reset_index(drop=True)


def split_train_test_80_20_by_y(df: pd.DataFrame, y_col: str, train_ratio: float) -> tuple[pd.DataFrame, pd.DataFrame]:
    """
    Define split ONLY after trimming to last observed y.
    This is the safest way to keep HW1/HW2 forecast window consistent.
    """
    n = len(df)
    n_train = int(np.floor(n * train_ratio))
    if n_train < 5 or n_train >= n:
        raise ValueError(f"Bad split: n={n}, n_train={n_train}.")
    train = df.iloc[:n_train].reset_index(drop=True)
    test = df.iloc[n_train:].reset_index(drop=True)
    return train, test


def first_difference(df: pd.DataFrame, cols: Sequence[str], lag: int) -> pd.DataFrame:
    out = df.copy()
    out[list(cols)] = out[list(cols)].apply(pd.to_numeric, errors="coerce").diff(lag)
    return out


def _corr_and_n(a: np.ndarray, b: np.ndarray) -> tuple[float, int]:
    mask = np.isfinite(a) & np.isfinite(b)
    n = int(mask.sum())
    if n < 3:
        return (np.nan, n)
    if np.std(a[mask]) == 0 or np.std(b[mask]) == 0:
        return (np.nan, n)
    r = float(np.corrcoef(a[mask], b[mask])[0, 1])
    return (r, n)


def rank_by_abs_corr(df: pd.DataFrame, y_col: str, x_cols: list[str], top_n: int, min_obs: int) -> pd.DataFrame:
    y = df[y_col].to_numpy(dtype=float)

    # functional style: map -> rows
    rows = list(
        map(
            lambda c: {
                "code": c,
                "corr": _corr_and_n(y, df[c].to_numpy(dtype=float))[0],
                "n_obs": _corr_and_n(y, df[c].to_numpy(dtype=float))[1],
            },
            x_cols,
        )
    )
    out = pd.DataFrame(rows).dropna(subset=["corr"])
    out["abs_corr"] = out["corr"].abs()
    out = out[out["n_obs"] >= int(min_obs)]
    out = out.sort_values(["abs_corr", "n_obs"], ascending=[False, False]).head(int(top_n)).reset_index(drop=True)
    return out


def q1_select_top5(y_df: pd.DataFrame, x_df: pd.DataFrame, cfg: Q1Config) -> pd.DataFrame:
    """
    Pure end-to-end computation for Q1 data-driven candidates.
    - align by date
    - trim tail missing y
    - compute split (use train only)
    - difference (Δy and Δx)
    - rank by |corr|
    """
    merged = align_on_date(y_df, x_df, cfg.date_col)
    merged = trim_to_last_observed_y(merged, cfg.y_col)

    train_df, _ = split_train_test_80_20_by_y(merged, cfg.y_col, cfg.train_ratio)

    x_cols = [c for c in train_df.columns if c not in [cfg.date_col, cfg.y_col]]
    diffed = first_difference(train_df, [cfg.y_col] + x_cols, lag=cfg.diff_lag)

    top5 = rank_by_abs_corr(diffed, y_col=cfg.y_col, x_cols=x_cols, top_n=cfg.top_n, min_obs=cfg.min_obs)
    return top5




def _get_var_names(var_res) -> list[str]:
    """Best-effort extraction of endogenous variable names from statsmodels VARResults."""
    if hasattr(var_res, "names") and isinstance(var_res.names, (list, tuple)):
        return list(var_res.names)
    if hasattr(var_res, "model") and hasattr(var_res.model, "endog_names"):
        return list(var_res.model.endog_names)
    raise ValueError("Cannot infer variable names from VAR results object.")


def compute_orth_irf_table(
    var_res,
    impulse: str,
    response: str,
    steps: int = 12,
) -> pd.DataFrame:
    """
    Orthogonalized impulse response (Cholesky) table.

    Returns a tidy table with columns:
    - h: horizon (0..steps)
    - impulse: shocked variable name
    - response: responding variable name
    - irf: response value

    Important: ordering depends on the column ordering used in VAR estimation.
    """
    names = _get_var_names(var_res)
    if impulse not in names or response not in names:
        raise ValueError(f"impulse/response must be in VAR names: {names}")

    irf_obj = var_res.irf(int(steps))
    # shape: (steps+1, k, k) where [h, response_index, impulse_index]
    arr = np.asarray(irf_obj.orth_irfs, dtype=float)

    i_imp = names.index(impulse)
    i_res = names.index(response)

    values = arr[:, i_res, i_imp]
    return pd.DataFrame(
        {
            "h": np.arange(values.shape[0], dtype=int),
            "impulse": impulse,
            "response": response,
            "irf": values,
        }
    )


def compute_granger_table(
    var_res,
    var_names: Sequence[str],
    kind: str = "f",
) -> pd.DataFrame:
    """
    Pairwise Granger causality table for all ordered pairs in var_names (excluding self).

    Output columns:
    - caused, causing, test_stat, p_value, df_num, df_denom
    """
    names = _get_var_names(var_res)
    for v in var_names:
        if v not in names:
            raise ValueError(f"{v} not found in VAR names: {names}")

    rows: list[dict] = []
    for caused in var_names:
        for causing in var_names:
            if causing == caused:
                continue
            test = var_res.test_causality(caused=caused, causing=[causing], kind=kind)
            rows.append(
                {
                    "caused": caused,
                    "causing": causing,
                    "kind": kind,
                    "test_stat": float(getattr(test, "test_statistic", np.nan)),
                    "p_value": float(getattr(test, "pvalue", np.nan)),
                    "df_num": float(getattr(test, "df_num", np.nan)) if getattr(test, "df_num", None) is not None else np.nan,
                    "df_denom": float(getattr(test, "df_denom", np.nan)) if getattr(test, "df_denom", None) is not None else np.nan,
                }
            )
    return pd.DataFrame(rows)
