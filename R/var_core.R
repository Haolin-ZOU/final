# R/var_core.R
# Pure functions for HW2 Section 2 & 3 (VAR on two stationary series)

compute_rmse <- function(actual, pred) {
  if (length(actual) != length(pred)) stop("compute_rmse: length mismatch.", call. = FALSE)
  ok <- is.finite(actual) & is.finite(pred)
  if (!any(ok)) stop("compute_rmse: no finite pairs.", call. = FALSE)
  sqrt(mean((actual[ok] - pred[ok])^2))
}

trim_y_tail_na <- function(df, y_col) {
  if (!(y_col %in% names(df))) stop("trim_y_tail_na: y_col not found.", call. = FALSE)
  idx <- which(!is.na(df[[y_col]]))
  if (length(idx) == 0) stop("trim_y_tail_na: y is all NA.", call. = FALSE)
  df[seq_len(max(idx)), , drop = FALSE]
}

drop_leading_complete_rows <- function(df, cols) {
  if (!all(cols %in% names(df))) stop("drop_leading_complete_rows: missing cols.", call. = FALSE)
  ok <- stats::complete.cases(df[, cols, drop = FALSE])
  if (!any(ok)) stop("drop_leading_complete_rows: all rows incomplete.", call. = FALSE)
  first_ok <- which(ok)[1]
  df[first_ok:nrow(df), , drop = FALSE]
}

check_x_missing_only_last <- function(df, x_col, allow_last_missing = TRUE) {
  if (!(x_col %in% names(df))) stop("check_x_missing_only_last: x_col not found.", call. = FALSE)
  na_idx <- which(is.na(df[[x_col]]))
  if (length(na_idx) == 0) return(invisible(TRUE))

  n <- nrow(df)
  if (allow_last_missing && length(na_idx) == 1 && na_idx == n) return(invisible(TRUE))

  stop(
    sprintf("x has missing values not only at the last observation. Missing idx: %s",
            paste(na_idx, collapse = ",")),
    call. = FALSE
  )
}

build_level_panel <- function(y_df, x_df, date_col, y_col, x_col) {
  need_y <- c(date_col, y_col)
  need_x <- c(date_col, x_col)
  if (!all(need_y %in% names(y_df))) stop("build_level_panel: y_df missing columns.", call. = FALSE)
  if (!all(need_x %in% names(x_df))) stop("build_level_panel: x_df missing columns.", call. = FALSE)

  y0 <- y_df[, need_y, drop = FALSE]
  x0 <- x_df[, need_x, drop = FALSE]

  y0[[date_col]] <- as.Date(y0[[date_col]])
  x0[[date_col]] <- as.Date(x0[[date_col]])

  panel <- dplyr::left_join(y0, x0, by = date_col) |>
    dplyr::arrange(.data[[date_col]])

  # HW1 logic: drop trailing NA in y (keep sample consistent)
  panel <- trim_y_tail_na(panel, y_col)

  panel
}

prepare_var_level_data <- function(y_df, x_df, date_col, y_col, x_col, allow_last_x_missing = TRUE) {
  panel <- build_level_panel(y_df, x_df, date_col, y_col, x_col)
  panel <- drop_leading_complete_rows(panel, cols = c(y_col, x_col))
  check_x_missing_only_last(panel, x_col, allow_last_missing = allow_last_x_missing)
  panel
}

make_first_differences <- function(level_df, date_col, cols, diff_lag = 1L, df = NULL) {
  # Allow alias df= for robustness
  if (missing(level_df) || is.null(level_df)) level_df <- df
  if (is.null(level_df)) stop("make_first_differences: provide level_df (or df).", call. = FALSE)

  if (!all(c(date_col, cols) %in% names(level_df))) {
    stop("make_first_differences: missing columns.", call. = FALSE)
  }
  if (!is.numeric(diff_lag) || diff_lag < 1) {
    stop("make_first_differences: diff_lag must be >=1.", call. = FALSE)
  }

  n <- nrow(level_df)
  if (n <= diff_lag) stop("make_first_differences: not enough rows.", call. = FALSE)

  # Base aligned frame (rows diff_lag+1..n)
  base_df <- level_df[(diff_lag + 1):n, c(date_col, cols), drop = FALSE]

  # Compute diffs as a list, then bind (pure functional style)
  diff_list <- lapply(cols, function(cc) {
    x_now <- level_df[[cc]][(diff_lag + 1):n]
    x_lag <- level_df[[cc]][1:(n - diff_lag)]
    x_now - x_lag
  })
  names(diff_list) <- paste0("d_", cols)

  diff_df <- as.data.frame(diff_list, check.names = FALSE)
  out <- cbind(base_df, diff_df)
  rownames(out) <- NULL
  out
}

extract_var_coef_table <- function(var_model) {
  eqs <- names(var_model$varresult)
  purrr::map_dfr(eqs, function(eq) {
    sm <- summary(var_model$varresult[[eq]])
    cf <- sm$coefficients
    data.frame(
      equation = eq,
      term = rownames(cf),
      estimate = cf[, 1],
      std_error = cf[, 2],
      t_value = cf[, 3],
      p_value = cf[, 4],
      row.names = NULL,
      stringsAsFactors = FALSE
    )
  })
}

safe_serial_pvalue <- function(serial_test_obj) {
  # vars::serial.test returns an object with $serial being an htest
  if (!is.null(serial_test_obj$serial) && !is.null(serial_test_obj$serial$p.value)) {
    return(as.numeric(serial_test_obj$serial$p.value))
  }
  NA_real_
}

make_var_lag_diagnostics <- function(train_mat, max_lag = 8L, type = "const",
                                     serial_lags_pt = 12L, alpha_sig = 0.05) {
  sel <- vars::VARselect(train_mat, lag.max = max_lag, type = type)
  ic <- sel$criteria

  ic_df <- data.frame(
    p = as.integer(colnames(ic)),
    aic = as.numeric(ic["AIC(n)", ]),
    hq  = as.numeric(ic["HQ(n)", ]),
    sc  = as.numeric(ic["SC(n)", ]),
    fpe = as.numeric(ic["FPE(n)", ]),
    stringsAsFactors = FALSE
  )

  extra <- purrr::map_dfr(ic_df$p, function(p) {
    fit <- vars::VAR(train_mat, p = p, type = type)

    serial <- vars::serial.test(fit, lags.pt = serial_lags_pt, type = "PT.asymptotic")
    serial_p <- safe_serial_pvalue(serial)

    roots_mod <- vars::roots(fit, modulus = TRUE)
    max_root <- max(roots_mod)

    coef_tab <- extract_var_coef_table(fit)
    n_sig <- sum(coef_tab$p_value < alpha_sig & coef_tab$term != "const", na.rm = TRUE)

    data.frame(
      p = p,
      serial_p_value = serial_p,
      max_root_modulus = max_root,
      is_stable = (max_root < 1),
      n_significant_terms = n_sig,
      stringsAsFactors = FALSE
    )
  })

  dplyr::left_join(ic_df, extra, by = "p") |>
    dplyr::arrange(.data$p)
}

choose_lag_from_diagnostics <- function(diag_df) {
  # Rule (transparent for report):
  # 1) Prefer stable + no residual autocorr (serial p > 0.05)
  # 2) Within that set, choose smallest SC (BIC)
  # 3) If none satisfy, fallback to smallest SC
  ok <- diag_df$is_stable & is.finite(diag_df$serial_p_value) & diag_df$serial_p_value > 0.05
  cand <- diag_df[ok, , drop = FALSE]
  if (nrow(cand) == 0) cand <- diag_df

  cand$p[which.min(cand$sc)]
}

make_expanding_folds_one_step <- function(n, n_train) {
  # This follows the same indexing idea as create_time_series_folds() in 可复用函数.txt :contentReference[oaicite:5]{index=5}
  if (n_train < 2) stop("make_expanding_folds_one_step: n_train too small.", call. = FALSE)
  if (n <= n_train) stop("make_expanding_folds_one_step: n must be > n_train.", call. = FALSE)

  test_idx <- (n_train + 1L):n
  # For each test t, estimation uses 1..(t-1)
  purrr::map(test_idx, \(t) list(t = t, est_end = t - 1L))
}

recursive_var_one_step_forecast_level <- function(level_df, date_col, y_col, x_col,
                                                  p, train_ratio = 0.8, diff_lag = 1L,
                                                  type = "const") {
  n <- nrow(level_df)
  n_train <- floor(train_ratio * n)
  folds <- make_expanding_folds_one_step(n, n_train)

  # Precompute full diff matrix (aligned to level time index = diff_lag+1..n)
  diff_df <- make_first_differences(level_df, date_col, cols = c(y_col, x_col), diff_lag = diff_lag)
  mat_all <- diff_df[, c(paste0("d_", y_col), paste0("d_", x_col)), drop = FALSE]
  colnames(mat_all) <- c("dy", "dx")

  y_level <- level_df[[y_col]]
  dates <- level_df[[date_col]]

  purrr::map_dfr(folds, function(fd) {
    t <- fd$t
    est_end <- fd$est_end

    # Need diffs up to est_end (which is t-1). In diff space:
    # diff row index r corresponds to level index (diff_lag + r)
    end_diff_row <- est_end - diff_lag
    if (end_diff_row <= p + 2L) stop("recursive_var_one_step_forecast_level: not enough data.", call. = FALSE)

    train_mat <- as.matrix(mat_all[1:end_diff_row, , drop = FALSE])

    fit <- vars::VAR(train_mat, p = p, type = type)
    dy_hat <- as.numeric(predict(fit, n.ahead = 1)$fcst$dy[1, "fcst"])

    y_hat <- y_level[t - 1L] + dy_hat

    data.frame(
      date = dates[t],
      y_true = y_level[t],
      y_pred = y_hat,
      stringsAsFactors = FALSE
    )
  })
}

