# R/q1_core.R
# Pure functions for HW2 Q1 (data-driven series selection)
# No file I/O. No setwd(). No printing.

suppressWarnings({
  library(dplyr)
})

trim_to_last_observed_y <- function(y_df, date_col, y_col) {
  if (!all(c(date_col, y_col) %in% names(y_df))) {
    stop("trim_to_last_observed_y: y_df missing date_col or y_col.", call. = FALSE)
  }
  idx <- which(!is.na(y_df[[y_col]]))
  if (length(idx) == 0) stop("trim_to_last_observed_y: y has no observed values.", call. = FALSE)
  last_i <- max(idx)
  y_df[seq_len(last_i), , drop = FALSE]
}

split_train_80_20 <- function(df, train_ratio = 0.8) {
  n <- nrow(df)
  if (n < 5) stop("split_train_80_20: not enough rows.", call. = FALSE)
  n_train <- floor(n * train_ratio)
  list(
    train = df[seq_len(n_train), , drop = FALSE],
    test  = df[(n_train + 1L):n, , drop = FALSE]
  )
}

first_diff_vec <- function(x, lag = 1L) {
  if (lag < 1L) stop("first_diff_vec: lag must be >= 1.", call. = FALSE)
  x <- as.numeric(x)
  c(rep(NA_real_, lag), diff(x, lag = lag))
}

safe_corr <- function(a, b, min_obs = 30L) {
  ok <- stats::complete.cases(a, b)
  n_obs <- sum(ok)
  if (n_obs < min_obs) return(list(corr = NA_real_, n_obs = n_obs))

  aa <- a[ok]
  bb <- b[ok]

  if (stats::sd(aa) == 0 || stats::sd(bb) == 0) {
    return(list(corr = NA_real_, n_obs = n_obs))
  }
  list(corr = as.numeric(stats::cor(aa, bb)), n_obs = n_obs)
}

# ---- THE ONE STANDARD API ----
q1_select_top_n_abs_corr <- function(y_df,
                                     x_df,
                                     date_col = "date",
                                     y_col,
                                     top_n = 5L,
                                     min_obs = 30L,
                                     train_ratio = 0.8,
                                     diff_lag = 1L,
                                     desc_df = NULL) {
  if (!all(c(date_col, y_col) %in% names(y_df))) {
    stop("q1_select_top_n_abs_corr: y_df missing date_col or y_col.", call. = FALSE)
  }
  if (!(date_col %in% names(x_df))) {
    stop("q1_select_top_n_abs_corr: x_df missing date_col.", call. = FALSE)
  }

  # 1) trim y to last observed
  y_use <- trim_to_last_observed_y(y_df, date_col, y_col)

  # 2) align by date
  merged <- dplyr::inner_join(y_use, x_df, by = date_col) %>%
    dplyr::arrange(.data[[date_col]])

  # 3) use same estimation window as VAR (first 80%)
  sp <- split_train_80_20(merged, train_ratio = train_ratio)
  train <- sp$train

  # 4) choose numeric candidates (exclude date and y)
  cand_cols <- setdiff(names(train), c(date_col, y_col))
  cand_cols <- cand_cols[sapply(train[cand_cols], is.numeric)]
  if (length(cand_cols) == 0) stop("q1_select_top_n_abs_corr: no numeric X columns.", call. = FALSE)

  # 5) first differences
  dy <- first_diff_vec(train[[y_col]], lag = diff_lag)

  rows <- lapply(cand_cols, function(code) {
    dx <- first_diff_vec(train[[code]], lag = diff_lag)
    res <- safe_corr(dy, dx, min_obs = min_obs)
    data.frame(
      code = code,
      corr = res$corr,
      n_obs = res$n_obs,
      abs_corr = abs(res$corr),
      stringsAsFactors = FALSE
    )
  })

  out <- dplyr::bind_rows(rows) %>%
    dplyr::filter(!is.na(corr)) %>%
    dplyr::arrange(dplyr::desc(abs_corr)) %>%
    dplyr::slice_head(n = top_n)

  if (!is.null(desc_df)) {
    if (!all(c("CODE", "DESCRIPTION") %in% names(desc_df))) {
      stop("q1_select_top_n_abs_corr: desc_df must have CODE and DESCRIPTION.", call. = FALSE)
    }
    out <- dplyr::left_join(out, desc_df, by = c("code" = "CODE"))
  }

  out
}
