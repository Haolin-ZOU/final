# HW2/gen-env.R
library(rix)

# 建议：如果你不确定哪个日期可用，先在临时 R 里跑 available_dates()
# 然后选一个最接近作业日期(2025-12-12)的可用日期来 pin。:contentReference[oaicite:4]{index=4}

rix(
  date = "2026-01-05",  # 如不可用：用 available_dates() 换成存在的日期
  r_pkgs = c(
    # 数据与整理
    "readxl", "dplyr", "tidyr", "purrr",

    # 画图（HW 风格后面我们会统一 theme，但包先装好）
    "ggplot2", "scales", "patchwork",

    # HW2 VAR + 检验常用
    "vars", "forecast", "tseries", "urca", "lmtest",

    # 你提供的可复用脚本明确用到的包
    "ppcor", "glmnet", "lars",

    # 报告/测试（后面要用）
    "knitr", "rmarkdown", "testthat",

    # 如果你希望 R 调 Python（可选，但加上不亏）
    "reticulate"
  ),
  py_conf = list(
    py_version = "3.11",
    py_pkgs = c(
      "pandas", "numpy", "matplotlib",
      "statsmodels", "scikit-learn",
      "openpyxl", "pytest"
    )
  ),
  # 关键：不要用 ide="other"；它已被废弃，应该用 ide="none" :contentReference[oaicite:5]{index=5}
  ide = "none",

  # 额外系统工具：后面 rixpress / Quarto / Git 都会用到
  system_pkgs = c("git", "quarto"),

  project_path = ".",
  overwrite = TRUE
)
