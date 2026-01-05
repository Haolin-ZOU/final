library(rix)

# 定义 HW2 所需的 R 包
# 根据你上传的 R 代码文件分析，我们需要以下包：
# - vars: VAR模型
# - glmnet: Lasso 回归 (best_lasso_variables.R)
# - lars: Stepwise/Lars 回归 (best_stepwise_variables.R)
# - ppcor: 偏相关系数 (best_partially_correlated.R)
# - tseries, forecast: 时间序列基础
# - readxl: 读取 Excel 数据
# - rixpress: 构建管道
r_pkgs_hw2 <- c(
  "tidyverse", 
  "readxl", 
  "vars", 
  "tseries", 
  "forecast", 
  "glmnet", 
  "lars", 
  "ppcor", 
  "testthat", 
  "quarto", 
  "reticulate", 
  "jsonlite", 
  "igraph", 
  "rixpress"
)

# 定义 HW2 所需的 Python 包 (用于 polyglot pipeline)
# 包含 pandas, statsmodels (用于潜在的 Python 验证), matplotlib
py_pkgs_hw2 <- c(
  "pandas", 
  "numpy", 
  "statsmodels", 
  "matplotlib", 
  "polars", 
  "pyarrow"
)

# 生成 default.nix
rix(
  date = "2025-10-14", # 使用与你样本一致的日期以确保复现性
  r_pkgs = r_pkgs_hw2,
  py_conf = list(
    py_version = "3.13",
    py_pkgs = py_pkgs_hw2
  ),
  # 按照 rap4mads 教程推荐，包含 Git
  system_pkgs = c("git"), 
  ide = "none", # 我们在终端运行
  project_path = ".",
  overwrite = TRUE
)
