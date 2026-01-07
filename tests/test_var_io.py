import pandas as pd
import pytest

from python.var_io import read_x_xlsx


def test_read_x_xlsx_returns_dataframe_not_dict(tmp_path):
    pytest.importorskip("openpyxl")

    x_path = tmp_path / "x.xlsx"
    df_x = pd.DataFrame(
        {
            "date": pd.date_range("2020-01-01", periods=4, freq="QS"),
            "p_xb_be_oe_base_q": [1.0, 2.0, 3.0, 4.0],
        }
    )

    with pd.ExcelWriter(x_path) as w:
        df_x.to_excel(w, sheet_name="data_x", index=False)
        pd.DataFrame({"dummy": [0]}).to_excel(w, sheet_name="other", index=False)

    out = read_x_xlsx(str(x_path))  # sheet_name=None on purpose
    assert isinstance(out, pd.DataFrame)
    assert "p_xb_be_oe_base_q" in out.columns
    assert len(out) == 4

