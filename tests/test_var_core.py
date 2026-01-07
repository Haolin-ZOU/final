# tests/test_var_core.py
import numpy as np
import pandas as pd
import pytest

from python.var_core import (
    prepare_var_level_data,
    make_first_differences,
    recursive_var_one_step_forecast_level,
)


def test_prepare_var_level_data_allows_last_x_missing_only():
    y_df = pd.DataFrame({"date": pd.date_range("2020-01-01", periods=5), "y": [1, 2, 3, 4, 5]})
    x_df = pd.DataFrame({"date": pd.date_range("2020-01-01", periods=5), "x": [np.nan, 10, 11, 12, np.nan]})

    out = prepare_var_level_data(y_df, x_df, "date", "y", "x", allow_last_x_missing=True)
    assert out.loc[0, "x"] == 10
    assert np.isnan(out.loc[len(out) - 1, "x"])


def test_prepare_var_level_data_errors_if_x_missing_in_middle():
    y_df = pd.DataFrame({"date": pd.date_range("2020-01-01", periods=5), "y": [1, 2, 3, 4, 5]})
    x_df = pd.DataFrame({"date": pd.date_range("2020-01-01", periods=5), "x": [10, np.nan, 11, 12, 13]})

    with pytest.raises(ValueError, match="not only at the last"):
        prepare_var_level_data(y_df, x_df, "date", "y", "x", allow_last_x_missing=True)


def test_make_first_differences_n_minus_1_rows():
    df = pd.DataFrame(
        {"date": pd.date_range("2020-01-01", periods=5), "a": [1, 2, 3, 4, 5], "b": [11, 12, 13, 14, 15]}
    )
    out = make_first_differences(df, "date", ["a", "b"], diff_lag=1)
    assert len(out) == 4
    assert "d_a" in out.columns and "d_b" in out.columns


def test_recursive_forecast_returns_last_20_percent_length():
    np.random.seed(1)
    n = 30
    df = pd.DataFrame(
        {
            "date": pd.date_range("2020-01-01", periods=n),
            "y": np.cumsum(np.random.normal(size=n)),
            "x": np.cumsum(np.random.normal(size=n)),
        }
    )

    pred = recursive_var_one_step_forecast_level(
        level_df=df,
        date_col="date",
        y_col="y",
        x_col="x",
        p=1,
        train_ratio=0.8,
        diff_lag=1,
        trend="c",
    )
    assert len(pred) == n - int(np.floor(0.8 * n))

