# python/var_core.py
# Pure functions for HW2 Section 2 & 3 (VAR)
from __future__ import annotations

from dataclasses import dataclass
from typing import List, Tuple, Dict, Optional

import numpy as np
import pandas as pd


def compute_rmse(y_true: np.ndarray, y_pred: np.ndarray) -> float:
    if len(y_true) != len(y_pred):
        raise ValueError("compute_rmse: length mismatch.")
    mask = np.isfinite(y_true) & np.isfinite(y_pred)
    if not np.any(mask):
        raise ValueError("compute_rmse: no finite pairs.")
    return float(np.sqrt(np.mean((y_true[mask] - y_pred[mask]) ** 2)))


def trim_y_tail_na(df: pd.DataFrame, y_col: str) -> pd.DataFrame:
    if y_col not in df.columns:
        raise ValueError("trim_y_tail_na: y_col not found.")
    idx = df.index[df[y_col].notna()]
    if len(idx) == 0:
        raise ValueError("trim_y_tail_na: y is all NA.")
    last = idx.max()
    return df.loc[:last].copy()


def drop_leading_complete_rows(df: pd.DataFrame, cols: List[str]) -> pd.DataFrame:
    for c in cols:
        if c not in df.columns:
            raise ValueError("drop_leading_complete_rows: missing cols.")
    ok = df[cols].notna().all(axis=1)
    if not ok.any():
        raise ValueError("drop_leading_complete_rows: all rows incomplete.")
    first_ok = ok.idxmax()  # first True index
    return df.loc[first_ok:].copy()


def check_x_missing_only_last(df: pd.DataFrame, x_col: str, allow_last_missing: bool = True) -> None:
    if x_col not in df.columns:
        raise ValueError("check_x_missing_only_last: x_col not found.")
    na_idx = df.index[df[x_col].isna()].tolist()
    if len(na_idx) == 0:
        return

    if allow_last_missing and len(na_idx) == 1 and na_idx[0] == df.index[-1]:
        return

    raise ValueError(
        f"x has missing values not only at the last observation. Missing idx: {na_idx}"
    )


def build_level_panel(
    y_df: pd.DataFrame,
    x_df: pd.DataFrame,
    date_col: str,
    y_col: str,
    x_col: str,
) -> pd.DataFrame:
    need_y = [date_col, y_col]
    need_x = [date_col, x_col]
    for c in need_y:
        if c not in y_df.columns:
            raise ValueError("build_level_panel: y_df missing columns.")
    for c in need_x:
        if c not in x_df.columns:
            raise ValueError("build_level_panel: x_df missing columns.")

    y0 = y_df[need_y].copy()
    x0 = x_df[need_x].copy()

    y0[date_col] = pd.to_datetime(y0[date_col]).dt.date
    x0[date_col] = pd.to_datetime(x0[date_col]).dt.date

    panel = y0.merge(x0, on=date_col, how="left").sort_values(date_col).reset_index(drop=True)
    panel = trim_y_tail_na(panel, y_col)
    return panel


def prepare_var_level_data(
    y_df: pd.DataFrame,
    x_df: pd.DataFrame,
    date_col: str,
    y_col: str,
    x_col: str,
    allow_last_x_missing: bool = True,
) -> pd.DataFrame:
    panel = build_level_panel(y_df, x_df, date_col, y_col, x_col)
    panel = drop_leading_complete_rows(panel, [y_col, x_col])
    check_x_missing_only_last(panel, x_col, allow_last_missing=allow_last_x_missing)
    return panel.reset_index(drop=True)


def make_first_differences(
    level_df: pd.DataFrame,
    date_col: str,
    cols: List[str],
    diff_lag: int = 1,
) -> pd.DataFrame:
    if diff_lag < 1:
        raise ValueError("make_first_differences: diff_lag must be >= 1.")
    for c in [date_col] + cols:
        if c not in level_df.columns:
            raise ValueError("make_first_differences: missing columns.")
    if len(level_df) <= diff_lag:
        raise ValueError("make_first_differences: not enough rows.")

    out = level_df.loc[diff_lag:, [date_col] + cols].copy().reset_index(drop=True)
    for c in cols:
        out[f"d_{c}"] = (
            level_df[c].iloc[diff_lag:].to_numpy() - level_df[c].iloc[:-diff_lag].to_numpy()
        )
    return out


def make_expanding_folds_one_step(n: int, n_train: int) -> List[Tuple[int, int]]:
    """
    Return list of (t, est_end) in 0-based index of LEVEL series:
      est_end = t-1, forecast y[t] using data up to y[t-1].
    test t ranges from n_train .. n-1 (last 20% if n_train=floor(0.8*n)).
    """
    if n_train < 2:
        raise ValueError("make_expanding_folds_one_step: n_train too small.")
    if n <= n_train:
        raise ValueError("make_expanding_folds_one_step: n must be > n_train.")
    test_t = list(range(n_train, n))
    return [(t, t - 1) for t in test_t]


@dataclass(frozen=True)
class LagDiagRow:
    p: int
    aic: float
    bic: float
    hqic: float
    fpe: float
    whiteness_pvalue: float
    max_root_modulus: float
    is_stable: bool
    n_significant_terms: int


def _safe_float(x) -> float:
    try:
        return float(x)
    except Exception:
        return float("nan")


def _count_significant_terms(pvalues: pd.DataFrame, alpha: float = 0.05) -> int:
    """
    pvalues is a DataFrame with rows=terms, cols=equations.
    Exclude constant-like terms.
    """
    if pvalues is None or pvalues.empty:
        return 0
    exclude = {"const", "intercept", "trend"}
    mask_rows = [r not in exclude for r in pvalues.index.astype(str)]
    pv = pvalues.loc[mask_rows]
    return int((pv < alpha).to_numpy().sum())


def make_var_lag_diagnostics(
    train_df: pd.DataFrame,
    max_lag: int = 8,
    trend: str = "c",
    whiteness_lags: int = 12,
    alpha_sig: float = 0.05,
) -> pd.DataFrame:
    """
    train_df columns must be ['dy','dx'].
    """
    from statsmodels.tsa.api import VAR

    if not all(c in train_df.columns for c in ["dy", "dx"]):
        raise ValueError("make_var_lag_diagnostics: train_df must have columns ['dy','dx'].")

    model = VAR(train_df)

    rows: List[Dict[str, object]] = []
    for p in range(1, max_lag + 1):
        res = model.fit(p, trend=trend)

        # IC
        aic = _safe_float(res.aic)
        bic = _safe_float(res.bic)
        hqic = _safe_float(res.hqic)
        fpe = _safe_float(res.fpe)

        # residual autocorrelation test (multivariate)
        # statsmodels versions differ; handle robustly
        whiteness_p = float("nan")
        try:
            wt = res.test_whiteness(nlags=whiteness_lags)
            # wt may be a result object with .pvalue
            whiteness_p = _safe_float(getattr(wt, "pvalue", np.nan))
        except Exception:
            # fallback: NaN
            whiteness_p = float("nan")

        # stability (roots)
        roots = getattr(res, "roots", None)
        if roots is None:
            max_root = float("nan")
            stable = False
        else:
            max_root = float(np.max(np.abs(np.asarray(roots))))
            stable = bool(max_root < 1.0)

        # coefficient significance count
        pvals = getattr(res, "pvalues", None)
        n_sig = _count_significant_terms(pvals, alpha=alpha_sig)

        rows.append(
            dict(
                p=p,
                aic=aic,
                hq=hqic,
                sc=bic,        # keep same naming as R table (sc ~ BIC)
                fpe=fpe,
                serial_p_value=whiteness_p,   # same column name as R diag table
                max_root_modulus=max_root,
                is_stable=stable,
                n_significant_terms=n_sig,
            )
        )

    diag = pd.DataFrame(rows).sort_values("p").reset_index(drop=True)
    return diag


def choose_lag_from_diagnostics(diag_df: pd.DataFrame) -> int:
    """
    Transparent rule (same as R intent):
    1) Prefer stable + (serial_p_value > 0.05) if available
    2) Within candidates choose smallest SC (BIC)
    3) If serial_p_value missing (NaN), ignore that constraint
    4) If none stable, fallback to smallest SC
    """
    if "p" not in diag_df.columns or "sc" not in diag_df.columns:
        raise ValueError("choose_lag_from_diagnostics: missing required columns.")

    stable = diag_df["is_stable"].astype(bool)
    serial = diag_df["serial_p_value"]

    # serial ok only where finite
    serial_ok = serial.notna() & (serial > 0.05)

    cand = diag_df[stable & serial_ok].copy()
    if len(cand) == 0:
        # if serial not available, choose among stable only
        cand = diag_df[stable].copy()
    if len(cand) == 0:
        cand = diag_df.copy()

    p_star = int(cand.loc[cand["sc"].astype(float).idxmin(), "p"])
    return p_star


def extract_var_coef_table(res) -> pd.DataFrame:
    """
    Convert statsmodels VARResults params/pvalues to a long coefficient table.
    """
    params: pd.DataFrame = res.params
    bse: pd.DataFrame = res.stderr
    tvals: pd.DataFrame = res.tvalues
    pvals: pd.DataFrame = res.pvalues

    out_rows = []
    for eq in params.columns:
        for term in params.index:
            out_rows.append(
                dict(
                    equation=str(eq),
                    term=str(term),
                    estimate=float(params.loc[term, eq]),
                    std_error=float(bse.loc[term, eq]) if term in bse.index else float("nan"),
                    t_value=float(tvals.loc[term, eq]) if term in tvals.index else float("nan"),
                    p_value=float(pvals.loc[term, eq]) if term in pvals.index else float("nan"),
                )
            )
    return pd.DataFrame(out_rows)


def recursive_var_one_step_forecast_level(
    level_df: pd.DataFrame,
    date_col: str,
    y_col: str,
    x_col: str,
    p: int,
    train_ratio: float = 0.8,
    diff_lag: int = 1,
    trend: str = "c",
) -> pd.DataFrame:
    """
    Expanding-window one-step forecast on LEVEL y using VAR on differenced (dy, dx).
    """
    from statsmodels.tsa.api import VAR

    n = len(level_df)
    n_train = int(np.floor(train_ratio * n))
    folds = make_expanding_folds_one_step(n, n_train)

    diff_df = make_first_differences(level_df, date_col, [y_col, x_col], diff_lag=diff_lag)
    # align: diff row r corresponds to level index (diff_lag + r)
    dy_col = f"d_{y_col}"
    dx_col = f"d_{x_col}"

    mat_all = diff_df[[dy_col, dx_col]].copy()
    mat_all.columns = ["dy", "dx"]

    y_level = level_df[y_col].to_numpy()
    dates = level_df[date_col].to_numpy()

    out = []
    for (t, est_end) in folds:
        # need diffs up to est_end (= t-1)
        end_diff_row = est_end - diff_lag  # inclusive index in diff space
        if end_diff_row < (p + 2):
            raise ValueError("recursive forecast: not enough data for VAR fit.")

        train_mat = mat_all.iloc[: end_diff_row + 1].copy()  # include end_diff_row

        model = VAR(train_mat)
        res = model.fit(p, trend=trend)

        # Forecast dy,dx one step ahead: need last p observations
        last_obs = train_mat.values[-p:]
        fc = res.forecast(y=last_obs, steps=1)[0]
        dy_hat = float(fc[0])  # 'dy' is first column

        y_hat = float(y_level[t - 1] + dy_hat)

        out.append(
            dict(
                date=str(dates[t]),
                y_true=float(y_level[t]),
                y_pred=y_hat,
            )
        )

    return pd.DataFrame(out)


def _get_var_names(var_res) -> List[str]:
    """Extract endogenous variable names from statsmodels VARResults."""
    if hasattr(var_res, "names") and isinstance(var_res.names, (list, tuple)):
        return list(var_res.names)
    if hasattr(var_res, "model") and hasattr(var_res.model, "endog_names"):
        return list(var_res.model.endog_names)
    raise ValueError("Cannot infer variable names from VAR results object.")


def compute_orth_irf_table(var_res, impulse: str, response: str, steps: int = 12) -> pd.DataFrame:
    """
    Orthogonalized IRF (Cholesky) table.
    Returns columns: h, impulse, response, irf.
    Ordering depends on the VAR column ordering.
    """
    steps = int(steps)
    if steps < 1:
        raise ValueError("compute_orth_irf_table: steps must be >= 1.")

    names = _get_var_names(var_res)
    if impulse not in names or response not in names:
        raise ValueError(f"compute_orth_irf_table: impulse/response not in {names}")

    irf_obj = var_res.irf(steps)
    arr = np.asarray(irf_obj.orth_irfs, dtype=float)  # (steps+1, k, k)

    i_imp = names.index(impulse)
    i_res = names.index(response)

    vals = arr[:, i_res, i_imp]
    return pd.DataFrame(
        {
            "h": np.arange(vals.shape[0], dtype=int),
            "impulse": impulse,
            "response": response,
            "irf": vals,
        }
    )


def compute_granger_table(var_res, var_names: List[str], kind: str = "f") -> pd.DataFrame:
    """
    Pairwise Granger causality tests for ordered pairs in var_names (excluding self).
    Output columns: caused, causing, kind, test_stat, p_value, df_num, df_denom.
    """
    names = _get_var_names(var_res)
    for v in var_names:
        if v not in names:
            raise ValueError(f"compute_granger_table: {v} not in VAR names {names}")

    rows = []
    for caused in var_names:
        for causing in var_names:
            if caused == causing:
                continue
            try:
                test = var_res.test_causality(caused=caused, causing=[causing], kind=kind)
            except Exception:
                # fallback if this statsmodels build doesn't like kind="f"
                test = var_res.test_causality(caused=caused, causing=[causing], kind="wald")

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
