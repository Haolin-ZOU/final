#!/usr/bin/env bash
set -euo pipefail
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

PYTHONPATH="$REPO_ROOT" python scripts/20_q1_choose_series.py
PYTHONPATH="$REPO_ROOT" python scripts/30_q2_var_estimation.py
PYTHONPATH="$REPO_ROOT" python scripts/40_q3_var_recursive_forecast.py
PYTHONPATH="$REPO_ROOT" python scripts/50_bonus_irf_granger.py

pytest -q 
