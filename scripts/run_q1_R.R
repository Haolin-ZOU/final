# scripts/run_q1_R.R
source("R/preprocess_raw.R")
source("R/q1_selection.R")

raw_x <- "data/raw/x.xlsx"
raw_y <- "data/raw/y.xlsx"
out_dir <- "data/processed"

preprocess_raw(
  raw_data_xlsx = raw_x,
  raw_hw1_xlsx  = raw_y,
  out_dir       = out_dir,
  y_col         = "import_clv_qna_sa",
  date_col      = "date"
)

x <- read.csv(file.path(out_dir, "x.csv"))
y <- read.csv(file.path(out_dir, "y.csv"))
desc <- read.csv(file.path(out_dir, "descriptions.csv"))

df <- align_by_date(y, x, date_col = "date")
candidate_cols <- setdiff(names(df), c("date", "y"))

df_d <- diff_columns(df, cols = c("y", candidate_cols), date_col = "date", lag = 1)

top5 <- rank_by_abs_corr(df_d, y_col = "y", candidate_cols = candidate_cols, top_n = 5, min_obs = 30)
top5 <- add_descriptions(top5, desc) %>%
  dplyr::select(code, DESCRIPTION, corr, abs_corr, n_obs)

dir.create("output/tables", recursive = TRUE, showWarnings = FALSE)
dir.create("output/figures", recursive = TRUE, showWarnings = FALSE)

write.csv(top5, "output/tables/q1_data_driven_top5.csv", row.names = FALSE)
save_barh_abs_corr(top5, "output/figures/q1_data_driven_top5_corr.png")

cat("✅ Q1 done (R): processed + top5 + figure\n")
print(top5)
