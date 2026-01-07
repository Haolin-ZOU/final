# RAP4MADS — HW2 (VAR) Reproducible Pipeline (R + Python)

This repository implements **HW2 Section 1–3 + Bonus** using **both R and Python**, with a **pinned Nix environment** so that a grader can clone and run everything with minimal effort.

- **Main target series (y):** `import_clv_qna_sa` (from HW1)
- **Candidate predictors (x):** provided in HW2 `x.xlsx`
- **Selected predictor (x\*):** written by Section 1 into `output/tables/q1_top5_abs_corr_R.csv`
- **Selected lag (p\*):** written by Section 2 into `output/tables/q2_var_selected_lag.txt`
- **Forecasting:** one-step-ahead recursive forecasts over last 20% (same split logic as HW1)
- **Bonus:** IRF (both orderings) + Granger causality

---
# introduction
Project Title: Luxembourg Macroeconomic Indicator Forecast - Import and Export Trade Analysis Based on VAR Model

Project Overview: In previous tasks, we constructed a univariate ARIMA model as a baseline using Luxembourg's actual import data (import_clv_qna_sa). The goal of this phase is to introduce multivariate time series analysis, constructing a Vector Autoregression (VAR) model to further improve forecast accuracy by utilizing the dynamic relationships between variables.

Task Objectives:

Feature Engineering and Variable Selection: From the macroeconomic dataset (data_x), using economic theory and data-driven correlation analysis, select the auxiliary variables (such as exports, GDP, or consumption index) most relevant to the target variable (import value).

VAR Model Construction and Evaluation: Difference the non-stationary series, determine the optimal lag order (Lags) based on the AIC/BIC criterion, and rigorously test the significance of model coefficients, autocorrelation of residual series, and model stability.

Recursive Forecast: Using the Expanding Window method, a one-step forward forecast is performed on the last 20% of the samples. The RMSE is calculated and compared with the HW1 ARIMA model.

Structural Analysis (Bonus): The impulse response function (IRF) and Granger causality test are used to analyze the impulse transmission mechanism and causal relationship between variables.

Key Conclusion Preview: This project successfully constructed a VAR(1) model. Although the model showed mild statistical significance (Granger causality was not significant), the RMSE obtained through recursive forecasting was 1153.72. This value is used to evaluate the change in predictive performance after introducing auxiliary variables (needs to be compared with HW1 results).



---

## 0) Quickstart (one command)

### Run the full pipeline in **R** (Section 1–3 + Bonus)
```
nix-shell --run "Rscript scripts/20_q1_choose_series.R && Rscript scripts/30_var_estimation.R && Rscript scripts/40_var_recursive_forecast.R && Rscript scripts/50_bonus_irf_granger.R"
```
### Run the full pipeline in Python (Section 1–3 + Bonus)
```
nix-shell --run "python scripts/20_q1_choose_series.py && python scripts/30_q2_var_estimation.py && python scripts/40_q3_var_recursive_forecast.py && python scripts/50_bonus_irf_granger.py"
```
If your machine is slow or you prefer interactive usage:

```
nix-shell
# then run the same Rscript/python commands one by one
```
1) Prerequisites (what the grader needs)
Required
Nix installed (this repo provides default.nix, so Nix will fetch/install all dependencies automatically).

Optional (quality-of-life)
direnv (auto-load Nix shell on cd)

2) What gets produced (outputs)
```
R outputs:

output/tables/q1_top5_abs_corr_R.csv

output/figures/q1_top5_abs_corr_R.png

output/tables/q2_var_selected_lag.txt (contains p*)

output/tables/q2_var_*.csv / output/tables/q2_var_*.txt (VAR diagnostics)

output/tables/q3_var_recursive_forecasts.csv

output/tables/q3_var_rmse.csv (or .txt depending on script version)

Bonus:

output/tables/bonus_irf_order_dx_dy_R.csv

output/tables/bonus_irf_order_dy_dx_R.csv

output/figures/bonus_irf_order_dx_dy_R.png

output/figures/bonus_irf_order_dy_dx_R.png

output/tables/bonus_granger_R.csv

Python outputs (mirrors the R logic, for users who prefer Python):

output/tables_py/*

output/figures_py/*
```

3) Data location (IMPORTANT)
This repo includes the raw Excel files in the repository:


data/raw/x.xlsx
data/raw/y.xlsx
Scripts search these paths robustly (so the grader does not need to rename files).

4) Tests (unit testing = safety net)
Run R tests (testthat)
```
nix-shell --run "R -q -e \"library(testthat); testthat::test_dir('tests/testthat')\""
```
Run Python tests (pytest)
```
nix-shell --run "pytest -q"
```
Expected: all tests pass.

5) Repository structure (high level)
```
R/                  # R pure functions (q1 + VAR + bonus)
python/             # Python pure functions (q1 + VAR + bonus)
scripts/            # executable scripts (section1/2/3/bonus)
tests/              # pytest + testthat tests
data/raw/           # raw Excel inputs (x.xlsx, y.xlsx)
output/             # generated outputs (tables + figures)
default.nix         # pinned environment (do not hand-edit)
gen-env.R           # environment generator (rix)
```
6) Reproducibility notes (answering common questions)
“Can others run this with nix-shell --run ...?”
Yes. nix-shell --run "<command>" is the intended one-liner mode for grading.

“If someone’s computer is missing packages, will it fail?”
With Nix: usually no. Dependencies are declared in default.nix.
When the grader runs nix-shell, Nix downloads/builds exactly what is needed.

“Does git clone also clone my environment?”
It clones the environment definition (default.nix, gen-env.R), not the binaries.
Nix will reproduce the environment by reading default.nix.

“Do I need to update default.nix?”
Normally no for grading. It is already pinned.
Only update/regenerate if you intentionally change dependencies.

7) Grading checklist (RAP4MADS course)
✅ Code is on GitHub and documented in this README.md

✅ Data and functions are included and tested (R testthat + Python pytest)

✅ Dependencies are reproducible via Nix (default.nix)

✅ Pipeline can be executed in one command (R path and Python path)

