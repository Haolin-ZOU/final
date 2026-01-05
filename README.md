# HW2 — Reproducible Analytical Pipeline (R + Python + Nix)

## Goal
This repository implements the HW2 pipeline with a fully reproducible environment (Nix + {rix}), version control (Git/GitHub), and a reproducible pipeline (later with {rixpress}, Docker, and GitHub Actions CI).

## Data
- `data/raw/hw2_x/`: HW2 input data (x)
- `data/raw/hw1_y/`: HW1-derived target series (y)

> For maximum reproducibility (grading), the preferred option is to keep the required raw data inside `data/raw/` if licensing/size allows.

## Quick start
1) Enter the pinned environment:
```bash
nix-shell
(placeholder) Run pipeline in one command (will be implemented):

bash
复制代码
./scripts/run.sh
Repo structure
R/: pure R functions (functional programming style)

python/: pure Python functions

tests/: unit tests (testthat + pytest)

reports/: report / figures generation

pipeline/: rixpress pipeline definitions (to be added)
