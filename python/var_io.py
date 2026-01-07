# python/var_io.py
from __future__ import annotations

from pathlib import Path
from typing import Optional, Sequence
import numpy as np
import pandas as pd

def ensure_parent_dir(path: str | Path) -> None:
    Path(path).parent.mkdir(parents=True, exist_ok=True)


def _read_excel_one_sheet(
    path: str,
    sheet_name: Optional[str],
    preferred_names: Sequence[str],
) -> pd.DataFrame:
    """
    Always return ONE DataFrame (never a dict).
    If sheet_name is None, pick the first match in preferred_names,
    otherwise fallback to the first sheet in the workbook.
    """
    xls = pd.ExcelFile(path)
    if sheet_name is None:
        for name in preferred_names:
            if name in xls.sheet_names:
                sheet_name = name
                break
        if sheet_name is None:
            sheet_name = xls.sheet_names[0]

    df = pd.read_excel(path, sheet_name=sheet_name)

    # Safety: if someone passes sheet_name=None to pandas directly, it can return dict.
    if isinstance(df, dict):
        df = list(df.values())[0]

    if "date" in df.columns:
        df["date"] = pd.to_datetime(df["date"])

    return df


def read_x_xlsx(path: str, sheet_name: Optional[str] = None) -> pd.DataFrame:
    # Prefer HW2 convention
    return _read_excel_one_sheet(path, sheet_name, preferred_names=("data_x", "x", "Sheet1"))


def read_y_xlsx(path: str, sheet_name: Optional[str] = "data_y") -> pd.DataFrame:
    return _read_excel_one_sheet(path, sheet_name, preferred_names=("data_y", "y", "Sheet1"))


def read_top1_x_code_from_q1_csv(path: str) -> str:
    df = pd.read_csv(path)
    if "code" not in df.columns:
        raise ValueError("Q1 csv must contain column 'code'.")
    if len(df) == 0:
        raise ValueError("Q1 csv is empty, cannot read top-1 x code.")
    return str(df["code"].iloc[0]).strip()


def write_csv(df: pd.DataFrame, out_path: str) -> None:
    ensure_parent_dir(out_path)
    df.to_csv(out_path, index=False)


def write_txt(text: str | int | float, out_path: str) -> None:
    ensure_parent_dir(out_path)
    Path(out_path).write_text(str(text).strip() + "\n", encoding="utf-8")


def read_txt_int(path: str) -> int:
    s = Path(path).read_text(encoding="utf-8").strip()
    return int(s)


def compute_orth_irf_table(
    var_res,
    impulse: str,
    response: str,
    steps: int = 12,
) -> pd.DataFrame:
    """
    Pure function: compute orthogonalized IRF (Cholesky) table.
    Note: ordering depends on column order in the fitted VAR.
    """
    if steps < 1:
        raise ValueError("steps must be >= 1")

    irf = var_res.irf(steps)
    names = list(var_res.names)
    if impulse not in names or response not in names:
        raise ValueError("impulse/response not found in VAR endogenous names.")

    i_imp = names.index(impulse)
    i_resp = names.index(response)

    vals = irf.orth_irfs[:, i_resp, i_imp]  # (steps+1,)
    return pd.DataFrame({"h": np.arange(steps + 1, dtype=int), "irf": vals})


def compute_granger_table(var_res, var_names: list[str]) -> pd.DataFrame:
    """
    Pure function: compute pairwise Granger causality (Wald) within a fitted VAR.
    Returns a small table with p-values.
    """
    rows: list[dict] = []
    for caused in var_names:
        for causing in var_names:
            if caused == causing:
                continue
            test = var_res.test_causality(caused=caused, causing=[causing], kind="wald")
            rows.append(
                {
                    "caused": caused,
                    "causing": causing,
                    "test_statistic": float(test.test_statistic),
                    "df": int(test.df),
                    "p_value": float(test.pvalue),
                }
            )
    return pd.DataFrame(rows)
