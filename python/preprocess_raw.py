from __future__ import annotations
from dataclasses import dataclass
from pathlib import Path
import pandas as pd


@dataclass(frozen=True)
class PreprocessConfig:
    raw_data_xlsx: Path
    raw_hw1_xlsx: Path
    out_dir: Path
    y_col: str = "import_clv_qna_sa"
    date_col: str = "date"


def _ensure_datetime(df: pd.DataFrame, date_col: str) -> pd.DataFrame:
    out = df.copy()
    out[date_col] = pd.to_datetime(out[date_col])
    return out


def load_x_from_data_x(path: Path, date_col: str = "date") -> pd.DataFrame:
    df = pd.read_excel(path, sheet_name="data_x")
    return _ensure_datetime(df, date_col)


def load_y_from_hw1(path: Path, y_col: str, date_col: str = "date") -> pd.DataFrame:
    df = pd.read_excel(path, sheet_name="data_y")
    df = _ensure_datetime(df, date_col)
    if y_col not in df.columns:
        raise ValueError(f"y_col='{y_col}' not found in HW1 data_y sheet columns={list(df.columns)}")
    return df[[date_col, y_col]].rename(columns={y_col: "y"})


def load_descriptions(path: Path) -> pd.DataFrame:
    df = pd.read_excel(path, sheet_name="descriptions")
    df.columns = [c.strip() for c in df.columns]
    if not {"CODE", "DESCRIPTION"}.issubset(df.columns):
        raise ValueError("descriptions sheet must contain columns: CODE, DESCRIPTION")
    return df[["CODE", "DESCRIPTION"]]


def write_csv(df: pd.DataFrame, out_path: Path) -> None:
    out_path.parent.mkdir(parents=True, exist_ok=True)
    df.to_csv(out_path, index=False)


def run(cfg: PreprocessConfig) -> None:
    x = load_x_from_data_x(cfg.raw_data_xlsx, cfg.date_col)
    y = load_y_from_hw1(cfg.raw_hw1_xlsx, cfg.y_col, cfg.date_col)
    desc = load_descriptions(cfg.raw_hw1_xlsx)

    write_csv(x, cfg.out_dir / "x.csv")
    write_csv(y, cfg.out_dir / "y.csv")
    write_csv(desc, cfg.out_dir / "descriptions.csv")
