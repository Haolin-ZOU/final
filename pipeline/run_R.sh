#!/usr/bin/env bash
set -euo pipefail
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

Rscript scripts/20_q1_choose_series.R
Rscript scripts/30_var_estimation.R
Rscript scripts/40_var_recursive_forecast.R
Rscript scripts/50_bonus_irf_granger.R

R -q -e "library(testthat); testthat::test_dir('tests/testthat')"

