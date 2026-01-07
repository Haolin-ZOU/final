import numpy as np
import pandas as pd
from statsmodels.tsa.api import VAR

from python.var_core import compute_orth_irf_table, compute_granger_table


def test_compute_orth_irf_table_shape_and_finite():
    rng = np.random.default_rng(0)
    n = 120
    e = rng.standard_normal((n, 2))

    x = np.zeros(n)
    y = np.zeros(n)
    for t in range(1, n):
        x[t] = 0.4 * x[t - 1] + e[t, 1]
        y[t] = 0.5 * y[t - 1] + 0.2 * x[t - 1] + e[t, 0]

    df = pd.DataFrame({"dy": y, "dx": x})
    res = VAR(df).fit(1)

    steps = 8
    out = compute_orth_irf_table(res, impulse="dx", response="dy", steps=steps)

    assert list(out.columns) == ["h", "impulse", "response", "irf"]
    assert len(out) == steps + 1
    assert out["h"].iloc[0] == 0
    assert out["h"].iloc[-1] == steps
    assert np.isfinite(out["irf"].to_numpy()).all()


def test_compute_granger_table_two_directions():
    rng = np.random.default_rng(1)
    n = 150
    e = rng.standard_normal((n, 2))

    x = np.zeros(n)
    y = np.zeros(n)
    for t in range(1, n):
        x[t] = 0.6 * x[t - 1] + e[t, 1]
        y[t] = 0.5 * y[t - 1] + 0.3 * x[t - 1] + e[t, 0]

    df = pd.DataFrame({"dy": y, "dx": x})
    res = VAR(df).fit(1)

    g = compute_granger_table(res, var_names=["dy", "dx"], kind="f")
    assert set(g.columns) == {"caused", "causing", "kind", "test_stat", "p_value", "df_num", "df_denom"}
    assert len(g) == 2  # dy<-dx and dx<-dy
