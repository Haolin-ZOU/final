# scripts/80_recompute_arima_rmse_on_var_window.py
import sys
from pathlib import Path
import numpy as np
import pandas as pd
from statsmodels.tsa.arima.model import ARIMA

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

def rmse(y_true, y_pred) -> float:
    y_true = np.asarray(y_true, dtype=float)
    y_pred = np.asarray(y_pred, dtype=float)
    return float(np.sqrt(np.mean((y_true - y_pred) ** 2)))

def expanding_one_step_arima(y_train: pd.Series, y_test: pd.Series, order=(0,1,0)) -> np.ndarray:
    history = list(y_train.astype(float).values)
    preds = []
    for t in range(len(y_test)):
        model = ARIMA(history, order=order)
        fit = model.fit()
        yhat = float(fit.forecast()[0])
        preds.append(yhat)
        history.append(float(y_test.iloc[t]))
    return np.array(preds, dtype=float)

if __name__ == "__main__":
    eval_path = ROOT / "output" / "metadata" / "eval_window.csv"
    df_path   = ROOT / "data" / "processed" / "var_dataset.csv"  # 你后面 VAR 数据集建议固化成这个名字

    if not eval_path.exists():
        raise FileNotFoundError(f"Missing {eval_path}. Create it when you split VAR train/test.")
    if not df_path.exists():
        raise FileNotFoundError(f"Missing {df_path}. Create it when you build the VAR dataset (y + chosen x).")

    df = pd.read_csv(df_path, parse_dates=["date"])
    ew = pd.read_csv(eval_path, parse_dates=["date"])

    m = df.merge(ew, on="date", how="inner").sort_values("date")
    y_train = m.loc[m["set"] == "train", "y"]
    y_test  = m.loc[m["set"] == "test", "y"]

    preds = expanding_one_step_arima(y_train, y_test, order=(0,1,0))
    score = rmse(y_test.values, preds)

    out = ROOT / "output" / "tables" / "rmse_baseline_arima_on_var_window.csv"
    out.parent.mkdir(parents=True, exist_ok=True)
    pd.DataFrame({"model":["ARIMA(0,1,0) baseline"], "rmse":[score], "n_test":[len(y_test)]}).to_csv(out, index=False)

    print("✅ wrote:", out)
    print(f"ARIMA(0,1,0) RMSE on VAR test window: {score:.4f} (n_test={len(y_test)})")

