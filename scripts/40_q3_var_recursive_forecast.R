# scripts/40_q3_var_recursive_forecast.R
# HW2 Section 3: one-step-ahead recursive forecasts (expanding window) + RMSE

suppressPackageStartupMessages({
  library(readxl)
  library(vars)
})

source("R/q1_io.R")
source("R/q23_var_core.R")

date_col <- "date"
y_col <- "import_clv_qna_sa"

x_path <- "data/raw/x.xlsx"
y_path <- "data/raw/y.xlsx"

# Read data
x_df <- read_x_strict_one_sheet(x_path)
y_df <- read_y_data_y_sheet(y_path, sheet = "data_y")

# Get selected x from Q1 output
top5 <- read.csv("output/tables/q1_top5_abs_corr_R.csv", stringsAsFactors = FALSE)
x_code <- top5$code[1]
if (!(x_code %in% names(x_df))) stop(sprintf("Selected x_code '%s' not in x.xlsx.", x_code), call. = FALSE)

# Load chosen lag p*
p_star <- as.integer(trimws(readLines("output/tables/q2_var_selected_lag.txt")))
if (!is.finite(p_star) || p_star < 1) stop("Invalid p* in output/tables/q2_var_selected_lag.txt", call. = FALSE)

panel <- prepare_var_levels(
  y_df = y_df,
  x_df = x_df,
  date_col = date_col,
  y_col = y_col,
  x_col = x_code,
  allow_missing_last_x = TRUE
)

n <- nrow(panel)
n_train <- q23_train_end(n, 0.8)

# build full differenced data
diff_df <- q23_first_difference(panel, date_col, cols = c(y_col, x_code), diff_lag = 1)
mat_all <- diff_df[, c(paste0("d_", y_col), paste0("d_", x_code)), drop = FALSE]
colnames(mat_all) <- c("dy", "dx")

# recursive forecasts for level y
y_level <- panel[[y_col]]
dates <- panel[[date_col]]

targets <- (n_train + 1):n

pred_list <- lapply(targets, function(t) {
  # use diffs up to (t-1) -> in diff space row (t-1)-1 = t-2
  end_diff <- t - 2
  train_mat <- mat_all[1:end_diff, , drop = FALSE]

  fit <- vars::VAR(train_mat, p = p_star, type = "const")
  fc <- predict(fit, n.ahead = 1)$fcst$dy[1, "fcst"]
  y_hat <- y_level[t - 1] + as.numeric(fc)

  data.frame(
    date = dates[t],
    y_true = y_level[t],
    y_hat = y_hat
  )
})

pred <- do.call(rbind, pred_list)
rmse <- q23_rmse(pred$y_true, pred$y_hat)

dir.create("output/tables", recursive = TRUE, showWarnings = FALSE)
utils::write.csv(pred, "output/tables/q3_var_recursive_forecasts.csv", row.names = FALSE)
utils::write.csv(data.frame(rmse = rmse), "output/tables/q3_var_rmse.csv", row.names = FALSE)

message(sprintf("VAR recursive RMSE (level y): %.6f", rmse))
message("Wrote: output/tables/q3_var_recursive_forecasts.csv")
message("Wrote: output/tables/q3_var_rmse.csv")
