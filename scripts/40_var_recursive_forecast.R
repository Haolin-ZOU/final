# scripts/40_var_recursive_forecast.R
# HW2 Section 3: one-step-ahead recursive forecasts (last 20%) + RMSE

suppressPackageStartupMessages({
  library(readxl)
  library(dplyr)
  library(purrr)
  library(vars)
})

source("R/q1_io.R")
source("R/var_core.R")
source("R/var_plot.R")

date_col <- "date"
y_col <- "import_clv_qna_sa"

x_path <- "data/raw/x.xlsx"
y_path <- "data/raw/y.xlsx"

x_df <- read_x_strict_one_sheet(x_path)
y_df <- read_y_data_y_sheet(y_path, sheet = "data_y")

top5 <- read.csv("output/tables/q1_top5_abs_corr_R.csv", stringsAsFactors = FALSE)
x_code <- top5$code[1]
if (!(x_code %in% names(x_df))) stop(sprintf("Section3: selected x_code '%s' not found in x.xlsx.", x_code), call. = FALSE)

p_star <- as.integer(trimws(readLines("output/tables/q2_var_selected_lag.txt", warn = FALSE)))
if (!is.finite(p_star) || p_star < 1L) stop("Section3: invalid p* in q2_var_selected_lag.txt", call. = FALSE)

panel <- prepare_var_level_data(
  y_df = y_df,
  x_df = x_df,
  date_col = date_col,
  y_col = y_col,
  x_col = x_code,
  allow_last_x_missing = TRUE
)

pred <- recursive_var_one_step_forecast_level(
  level_df = panel,
  date_col = date_col,
  y_col = y_col,
  x_col = x_code,
  p = p_star,
  train_ratio = 0.8,
  diff_lag = 1L,
  type = "const"
)

rmse_val <- compute_rmse(pred$y_true, pred$y_pred)

write_csv_safe(pred, "output/tables/q3_var_recursive_forecasts.csv")
write_csv_safe(data.frame(rmse = rmse_val), "output/tables/q3_var_rmse.csv")

message(sprintf("Section3 done. VAR recursive RMSE = %.6f", rmse_val))

