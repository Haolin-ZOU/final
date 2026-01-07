# python/q1_io.py
from __future__ import annotations

from pathlib import Path
import pandas as pd


def read_x_strict_one_sheet(path: Path) -> pd.DataFrame:
    xls = pd.ExcelFile(path)
    if len(xls.sheet_names) != 1:
        raise ValueError(
            f"{path.name} must have exactly 1 sheet, but got {len(xls.sheet_names)}: {xls.sheet_names}"
        )
    return xls.parse(xls.sheet_names[0])


def read_y_sheet_strict(path: Path, sheet_name: str = "data_y") -> pd.DataFrame:
    xls = pd.ExcelFile(path)
    if sheet_name not in xls.sheet_names:
        raise ValueError(f"{path.name} must contain sheet '{sheet_name}'. Available: {xls.sheet_names}")
    return xls.parse(sheet_name)


def read_desc_sheet_strict(path: Path, sheet_name: str = "descriptions") -> pd.DataFrame:
    xls = pd.ExcelFile(path)
    if sheet_name not in xls.sheet_names:
        raise ValueError(f"{path.name} must contain sheet '{sheet_name}'. Available: {xls.sheet_names}")
    df = xls.parse(sheet_name)
    if not {"CODE", "DESCRIPTION"}.issubset(df.columns):
        raise ValueError(f"Sheet '{sheet_name}' must contain CODE and DESCRIPTION. Got: {list(df.columns)}")
    return df[["CODE", "DESCRIPTION"]]


def require_columns(df: pd.DataFrame, required: list[str], context: str) -> None:
    missing = [c for c in required if c not in df.columns]
    if missing:
        raise ValueError(f"Missing columns in {context}: {missing}. Available: {list(df.columns)}")


def write_csv(df: pd.DataFrame, out_path: Path) -> None:
    out_path.parent.mkdir(parents=True, exist_ok=True)
    df.to_csv(out_path, index=False)
