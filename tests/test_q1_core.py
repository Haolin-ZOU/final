# tests/test_q1_core.py
import numpy as np
import pandas as pd

from python.q1_core import Q1Config, trim_to_last_observed_y, split_train_test_80_20_by_y, first_difference, q1_select_top5


def test_trim_to_last_observed_y():
    df = pd.DataFrame(
        {
            "date": pd.date_range("2020-01-01", periods=5, freq="D"),
            "import_clv_qna_sa": [1.0, 2.0, 3.0, np.nan, np.nan],
            "x1": [10, 11, 12, 13, 14],
        }
    )
    out = trim_to_last_observed_y(df, "import_clv_qna_sa")
    assert len(out) == 3
    assert out["import_clv_qna_sa"].isna().sum() == 0


def test_split_train_test_80_20_by_y():
    df = pd.DataFrame(
        {
            "date": pd.date_range("2020-01-01", periods=10, freq="D"),
            "import_clv_qna_sa": range(10),
        }
    )
    train, test = split_train_test_80_20_by_y(df, "import_clv_qna_sa", 0.8)
    assert len(train) == 8
    assert len(test) == 2


def test_first_difference():
    df = pd.DataFrame(
        {"date": pd.date_range("2020-01-01", periods=4, freq="D"), "import_clv_qna_sa": [1, 3, 6, 10], "x": [0, 1, 1, 2]}
    )
    d = first_difference(df, ["import_clv_qna_sa", "x"], lag=1)
    assert np.isnan(d.loc[0, "import_clv_qna_sa"])
    assert d.loc[1, "import_clv_qna_sa"] == 2
    assert d.loc[3, "import_clv_qna_sa"] == 4


def test_q1_select_top5_returns_expected_column():
    import numpy as np
    import pandas as pd

    rng = np.random.default_rng(0)

    # Make y so that first-difference is NOT constant
    increments = np.linspace(0.0, 1.0, 50) + rng.normal(scale=0.01, size=50)
    y_vals = np.cumsum(increments)

    # x1 is strongly related to y (and thus Δx1 related to Δy)
    x1_vals = 2.0 * y_vals + rng.normal(scale=0.01, size=50)

    y = pd.DataFrame(
        {"date": pd.date_range("2020-01-01", periods=50, freq="D"),
         "import_clv_qna_sa": y_vals}
    )
    x = pd.DataFrame(
        {"date": pd.date_range("2020-01-01", periods=50, freq="D"),
         "x1": x1_vals,
         "x2": np.ones(50)}  # constant column, should be dropped
    )

    cfg = Q1Config(top_n=1, min_obs=10, train_ratio=0.8, diff_lag=1)
    top = q1_select_top5(y, x, cfg)

    assert len(top) == 1
    assert top.iloc[0]["code"] == "x1"


