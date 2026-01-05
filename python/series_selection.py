from __future__ import annotations
from dataclasses import dataclass
from functools import reduce
from typing import Iterable, List
import numpy as np
import pandas as pd


def align_by_date(y: pd.DataFrame, x: pd.DataFrame, date_col: str = "date") -> pd.DataFrame:
    y2 = y.copy()
    x2 = x.copy()
    y2[date_col] = pd.to_datetime(y2[date_col])
    x2[date_col] = pd.to_datetime(x2[date_col])
    return pd.merge(y2, x2, on=date_col, how="inner").sort_values(date_col)


def diff_columns(df: pd.DataFrame, cols: Iterable[str], date_col: str = "date", lag: int = 1) -> pd.DataFrame:
    out = df.sort_values(date_col).copy()
    # vectorized diff (no loops needed)
    out[list(cols)] = out[list(cols)].diff(lag)
    return out


def corr_one(df: pd.DataFrame, y_col: str, x_col: str) -> dict:
    sub = df[[y_col, x_col]].dropna()
    n = len(sub)
    if n < 3:
        return {"code": x_col, "corr": np.nan, "n_obs": n}
    r = np.corrcoef(sub[y_col].to_numpy(), sub[x_col].to_numpy())[0, 1]
    return {"code": x_col, "corr": float(r), "n_obs": int(n)}


def rank_by_abs_corr(df: pd.DataFrame, y_col: str, candidate_cols: List[str],
                     top_n: int = 5, min_obs: int = 30) -> pd.DataFrame:
    # functional style: map -> list of dict -> DataFrame
    rows = list(map(lambda c: corr_one(df, y_col, c), candidate_cols))
    res = pd.DataFrame(rows)
    res["abs_corr"] = res["corr"].abs()

    # filter style
    res = res.dropna(subset=["corr"])
    res = res[res["n_obs"] >= min_obs]

    # rank
    res = res.sort_values("abs_corr", ascending=False).head(top_n).reset_index(drop=True)
    return res


def add_descriptions(top: pd.DataFrame, desc: pd.DataFrame) -> pd.DataFrame:
    # reduce demo: merge as a reduce of one merge (overkill but shows concept)
    # We keep it simple and deterministic.
    merged = reduce(
        lambda left, right: pd.merge(left, right, left_on="code", right_on="CODE", how="left"),
        [top, desc],
    )
    out = merged.drop(columns=["CODE"], errors="ignore")
    return out
