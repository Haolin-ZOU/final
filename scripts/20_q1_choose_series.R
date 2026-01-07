# scripts/20_q1_choose_series.R
# HW2 Q1: choose an additional series (data-driven) using |corr| on first differences.
# Run from project root: ~/RAP4MADS/HW2

# ---- Load project functions (explicit dependencies) ----
source("R/q1_io.R")
source("R/q1_core.R")
source("R/q1_plot.R")

# ---- Config (keep consistent with HW1/HW2) ----
date_col <- "date"
y_col <- "import_clv_qna_sa"

x_path <- "data/raw/x.xlsx"
y_path <- "data/raw/y.xlsx"

out_table <- "output/tables/q1_top5_abs_corr_R.csv"
out_fig <- "output/figures/q1_top5_abs_corr_R.png"

# ---- Read data ----
x_df <- read_x_strict_one_sheet(x_path)
y_df <- read_y_data_y_sheet(y_path, sheet = "data_y")
desc_df <- read_descriptions_sheet(y_path, sheet = "descriptions")

require_columns(x_df, c(date_col), "x.xlsx")
require_columns(y_df, c(date_col, y_col), "y.xlsx (data_y sheet)")

# ---- Select top 5 by |corr| ----
top <- q1_select_top_n_abs_corr(
  y_df = y_df[, c(date_col, y_col)],
  x_df = x_df,
  date_col = date_col,
  y_col = y_col,
  top_n = 5,
  min_obs = 30,
  train_ratio = 0.8,
  diff_lag = 1,
  desc_df = desc_df
)

print(top)

# ---- Save outputs ----
write_csv_strict(top, out_table)

p <- plot_top_corr_barh(top, title = "Top 5 by |corr| (first differences)")
save_plot_png(p, out_fig)

message(sprintf("Wrote: %s", out_table))
message(sprintf("Wrote: %s", out_fig))
