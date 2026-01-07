# scripts/50_bonus_irf_granger.R


suppressWarnings({
  library(dplyr)
  library(vars)
})

source("R/q1_io.R")
source("R/var_core.R")
source("R/var_bonus.R")

find_first_existing <- function(paths) {
  hit <- paths[file.exists(paths)][1]
  if (length(hit) == 0 || is.na(hit)) return(NULL)
  hit
}

main <- function() {
  # --- Robust paths ---
  x_path <- find_first_existing(c("data/raw/x.xlsx", "data/x.xlsx", "x.xlsx"))
  y_path <- find_first_existing(c("data/raw/y.xlsx", "data/y.xlsx", "y.xlsx"))
  if (is.null(x_path)) stop("Cannot find x.xlsx. Expected under data/raw/ (preferred) or data/.", call. = FALSE)
  if (is.null(y_path)) stop("Cannot find y.xlsx. Expected under data/raw/ (preferred) or data/.", call. = FALSE)

  # --- Selected x from section1 output ---
  top_corr_path <- "output/tables/q1_top5_abs_corr_R.csv"
  if (!file.exists(top_corr_path)) stop("Missing output/tables/q1_top5_abs_corr_R.csv. Run section1 first.", call. = FALSE)
  top_tbl <- read.csv(top_corr_path, stringsAsFactors = FALSE)
  if (!("code" %in% names(top_tbl)) || nrow(top_tbl) < 1) stop("q1_top5_abs_corr_R.csv must contain column 'code'.", call. = FALSE)
  x_code <- top_tbl$code[1]

  # --- Selected lag from section2 output ---
  p_path <- "output/tables/q2_var_selected_lag.txt"
  if (!file.exists(p_path)) stop("Missing output/tables/q2_var_selected_lag.txt. Run section2 first.", call. = FALSE)
  p_star <- as.integer(trimws(readLines(p_path, warn = FALSE)))
  if (!is.finite(p_star) || p_star < 1L) stop("Invalid p* in output/tables/q2_var_selected_lag.txt", call. = FALSE)

  # --- Load data ---
  x_df <- read_x_strict_one_sheet(x_path)
  y_df <- read_y_data_y_sheet(y_path, sheet = "data_y")

  # Main variable: HW1 target
  y_code <- "import_clv_qna_sa"

  if (!(y_code %in% names(y_df))) stop(sprintf("y_code '%s' not found in y data.", y_code), call. = FALSE)
  if (!(x_code %in% names(x_df))) stop(sprintf("x_code '%s' not found in x data.", x_code), call. = FALSE)

  # --- Build level panel (y + x aligned) ---
  level_df <- prepare_var_level_data(
    y_df = y_df,
    x_df = x_df,
    date_col = "date",
    y_col = y_code,
    x_col = x_code,
    allow_last_x_missing = TRUE
  )

  # --- Stationary: first differences ---
  diff_df <- make_first_differences(
    level_df,
    date_col = "date",
    cols = c(y_code, x_code),
    diff_lag = 1L
  )

  # Drop NA rows after differencing (important: last dx can be NA)
  diff_df <- diff_df[complete.cases(diff_df), , drop = FALSE]

  dy_name <- paste0("d_", y_code)
  dx_name <- paste0("d_", x_code)
  require_columns(diff_df, c("date", dy_name, dx_name), where = "diff_df")

  diff_df <- diff_df %>%
    transmute(
      date = date,
      dy = .data[[dy_name]],
      dx = .data[[dx_name]]
    )

  n <- nrow(diff_df)
  n_train <- floor(0.8 * n)
  if (n_train <= (p_star + 5L)) stop("Not enough training rows for VAR with chosen p*.", call. = FALSE)
  train_df <- diff_df[seq_len(n_train), , drop = FALSE]

  # Ensure output dirs exist
  dir.create("output/tables", recursive = TRUE, showWarnings = FALSE)
  dir.create("output/figures", recursive = TRUE, showWarnings = FALSE)

  # --- IRF: show both orderings ---
  fit_dx_dy <- vars::VAR(train_df %>% dplyr::select(dx, dy), p = p_star, type = "const")
  fit_dy_dx <- vars::VAR(train_df %>% dplyr::select(dy, dx), p = p_star, type = "const")

  irf_dx_dy <- compute_orth_irf_table(fit_dx_dy, impulse = "dx", response = "dy", n_ahead = 12L)
  irf_dy_dx <- compute_orth_irf_table(fit_dy_dx, impulse = "dx", response = "dy", n_ahead = 12L)

  write_csv_strict(irf_dx_dy, "output/tables/bonus_irf_order_dx_dy_R.csv")
  write_csv_strict(irf_dy_dx, "output/tables/bonus_irf_order_dy_dx_R.csv")

  save_irf_lineplot(
    irf_dx_dy,
    out_png = "output/figures/bonus_irf_order_dx_dy_R.png",
    main_title = "IRF: dy response to dx shock (order: dx, dy)"
  )
  save_irf_lineplot(
    irf_dy_dx,
    out_png = "output/figures/bonus_irf_order_dy_dx_R.png",
    main_title = "IRF: dy response to dx shock (order: dy, dx)"
  )

  # --- Granger causality (pairwise) ---
  gr_tbl <- compute_granger_table(fit_dy_dx, var_a = "dx", var_b = "dy")
  write_csv_strict(gr_tbl, "output/tables/bonus_granger_R.csv")

  message("Bonus (R) done.")
  message("Wrote: output/tables/bonus_irf_order_*_R.csv, output/figures/bonus_irf_order_*_R.png, output/tables/bonus_granger_R.csv")
}

main()
