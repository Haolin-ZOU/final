# scripts/30_var_estimation.R
# HW2 Section 2: VAR estimation + lag choice evidence

suppressPackageStartupMessages({
  library(readxl)
  library(dplyr)
  library(purrr)
  library(vars)
})

source("R/q1_io.R")     # your existing IO helpers :contentReference[oaicite:6]{index=6}
source("R/var_core.R")
source("R/var_plot.R")

date_col <- "date"
y_col <- "import_clv_qna_sa"

x_path <- "data/raw/x.xlsx"
y_path <- "data/raw/y.xlsx"

x_df <- read_x_strict_one_sheet(x_path)
y_df <- read_y_data_y_sheet(y_path, sheet = "data_y")

top5_path <- "output/tables/q1_top5_abs_corr_R.csv"
if (!file.exists(top5_path)) stop("Section2: missing Q1 output q1_top5_abs_corr_R.csv. Run Section1 first.", call. = FALSE)
top5 <- read.csv(top5_path, stringsAsFactors = FALSE)
x_code <- top5$code[1]
if (!(x_code %in% names(x_df))) stop(sprintf("Section2: selected x_code '%s' not found in x.xlsx.", x_code), call. = FALSE)

panel <- prepare_var_level_data(
  y_df = y_df,
  x_df = x_df,
  date_col = date_col,
  y_col = y_col,
  x_col = x_code,
  allow_last_x_missing = TRUE
)

n <- nrow(panel)
n_train <- floor(0.8 * n)

diff_df <- make_first_differences(panel, date_col, cols = c(y_col, x_code), diff_lag = 1L)

# train on first 80% of LEVELS => in diff space, use first (n_train-1) rows
diff_train <- diff_df[1:(n_train - 1L), , drop = FALSE]
dy <- diff_train[[paste0("d_", y_col)]]
dx <- diff_train[[paste0("d_", x_code)]]

# Evidence A: ACF/PACF
save_acf_pacf_png(dy, "output/figures/q2_acf_pacf_dy.png", title_prefix = paste0("d_", y_col))
save_acf_pacf_png(dx, "output/figures/q2_acf_pacf_dx.png", title_prefix = paste0("d_", x_code))

# Build VAR train matrix
mat_train <- as.matrix(diff_train[, c(paste0("d_", y_col), paste0("d_", x_code)), drop = FALSE])
colnames(mat_train) <- c("dy", "dx")

# Evidence B/D/E (+ coefficient significance summary): lag diagnostics table
diag_df <- make_var_lag_diagnostics(mat_train, max_lag = 8L, type = "const", serial_lags_pt = 12L)
write_csv_safe(diag_df, "output/tables/q2_var_lag_diagnostics.csv")

# Choose p* using transparent rule
p_star <- choose_lag_from_diagnostics(diag_df)
write_txt_safe(p_star, "output/tables/q2_var_selected_lag.txt")

# Fit final model and export coefficient table + serial test + roots
fit <- vars::VAR(mat_train, p = p_star, type = "const")

coef_tab <- extract_var_coef_table(fit)
write_csv_safe(coef_tab, "output/tables/q2_var_coef_table.csv")

serial <- vars::serial.test(fit, lags.pt = 12L, type = "PT.asymptotic")
capture.output(serial, file = "output/tables/q2_var_serial_test.txt")

roots_mod <- vars::roots(fit, modulus = TRUE)
write_csv_safe(data.frame(root_modulus = roots_mod), "output/tables/q2_var_roots.csv")

message(sprintf("Section2 done. Selected x=%s, p*=%d", x_code, p_star))

