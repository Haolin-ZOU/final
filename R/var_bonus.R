# R/var_bonus.R
# Bonus helpers (R): Orthogonal IRF + Granger causality
# Design: pure compute functions + one plotting helper (side-effect isolated)

# ---- small local assert (avoid cross-file dependency) ----
.require_columns <- function(df, cols, where = "data") {
  miss <- setdiff(cols, names(df))
  if (length(miss) > 0) {
    stop(sprintf("%s: missing columns: %s", where, paste(miss, collapse = ", ")), call. = FALSE)
  }
}

# ---- 1) Build stationary dy/dx pair (PURE) ----
build_stationary_pair <- function(level_df, date_col, y_col, x_col, diff_lag = 1L) {
  if (!is.data.frame(level_df)) stop("build_stationary_pair: level_df must be a data.frame.", call. = FALSE)
  if (!is.numeric(diff_lag) || diff_lag < 1) stop("build_stationary_pair: diff_lag must be >= 1.", call. = FALSE)

  .require_columns(level_df, c(date_col, y_col, x_col), where = "level_df")

  # expects make_first_differences(level_df, date_col, cols, diff_lag)
  diff_df <- make_first_differences(level_df, date_col, cols = c(y_col, x_col), diff_lag = diff_lag)

  dy_name <- paste0("d_", y_col)
  dx_name <- paste0("d_", x_col)
  .require_columns(diff_df, c(date_col, dy_name, dx_name), where = "diff_df")

  out <- data.frame(
    date = diff_df[[date_col]],
    dy   = diff_df[[dy_name]],
    dx   = diff_df[[dx_name]]
  )

  keep <- is.finite(out$dy) & is.finite(out$dx) & !is.na(out$date)
  out <- out[keep, , drop = FALSE]
  rownames(out) <- NULL

  if (nrow(out) < 2) stop("build_stationary_pair: too few rows after cleaning.", call. = FALSE)
  out
}

# ---- 2) Fit VAR under both orderings (PURE) ----
fit_var_two_orderings <- function(train_df, p) {
  if (!requireNamespace("vars", quietly = TRUE)) {
    stop("fit_var_two_orderings: package 'vars' is required.", call. = FALSE)
  }
  .require_columns(train_df, c("dx", "dy"), where = "train_df")

  p <- as.integer(p)
  if (!is.finite(p) || p < 1) stop("fit_var_two_orderings: p must be >= 1.", call. = FALSE)

  fit_dx_dy <- vars::VAR(train_df[, c("dx", "dy"), drop = FALSE], p = p, type = "const")
  fit_dy_dx <- vars::VAR(train_df[, c("dy", "dx"), drop = FALSE], p = p, type = "const")

  list(dx_dy = fit_dx_dy, dy_dx = fit_dy_dx)
}

# ---- 3) Orthogonal IRF table (PURE) ----
compute_orth_irf_table <- function(fit, impulse, response, n_ahead = 12L) {
  if (!requireNamespace("vars", quietly = TRUE)) {
    stop("compute_orth_irf_table: package 'vars' is required.", call. = FALSE)
  }

  n_ahead <- as.integer(n_ahead)
  if (!is.finite(n_ahead) || n_ahead < 0) stop("compute_orth_irf_table: n_ahead must be >= 0.", call. = FALSE)

  ir <- vars::irf(
    fit,
    impulse  = impulse,
    response = response,
    n.ahead  = n_ahead,
    ortho    = TRUE,
    boot     = FALSE
  )

  # ir$irf[[impulse]] is a matrix: rows = horizons, cols = responses
  mat <- ir$irf[[impulse]]
  if (is.null(dim(mat))) stop("compute_orth_irf_table: unexpected irf structure.", call. = FALSE)
  if (!(response %in% colnames(mat))) stop("compute_orth_irf_table: response not found in irf matrix.", call. = FALSE)

  vec <- as.numeric(mat[, response])
  data.frame(
    h        = 0:n_ahead,
    impulse  = impulse,
    response = response,
    irf      = vec
  )
}

# ---- 4) Granger causality table (PURE) ----
compute_granger_table <- function(fit, var_a, var_b) {
  if (!requireNamespace("vars", quietly = TRUE)) {
    stop("compute_granger_table: package 'vars' is required.", call. = FALSE)
  }

  extract_one <- function(fit, cause, effect) {
    g <- vars::causality(fit, cause = cause)$Granger

    # parameter is often c(df1, df2)
    par <- unname(g$parameter)
    df1 <- as.numeric(par[1])
    df2 <- if (length(par) >= 2) as.numeric(par[2]) else NA_real_

    data.frame(
      cause     = cause,
      effect    = effect,
      statistic = as.numeric(unname(g$statistic)),
      df1       = df1,
      df2       = df2,
      p_value   = as.numeric(unname(g$p.value)),
      stringsAsFactors = FALSE
    )
  }

  rbind(
    extract_one(fit, cause = var_a, effect = var_b),
    extract_one(fit, cause = var_b, effect = var_a)
  )
}


# ---- 5) One-call bonus compute (PURE) ----
compute_bonus_results <- function(level_df, date_col, y_col, x_col,
                                  p, train_ratio = 0.8, diff_lag = 1L, n_ahead = 12L) {
  if (!is.numeric(train_ratio) || train_ratio <= 0 || train_ratio >= 1) {
    stop("compute_bonus_results: train_ratio must be in (0,1).", call. = FALSE)
  }

  pair <- build_stationary_pair(level_df, date_col, y_col, x_col, diff_lag = diff_lag)

  n <- nrow(pair)
  n_train <- floor(train_ratio * n)
  p <- as.integer(p)
  if (n_train <= (p + 5L)) stop("compute_bonus_results: not enough training rows for VAR(p).", call. = FALSE)

  train_df <- pair[seq_len(n_train), , drop = FALSE]

  fits <- fit_var_two_orderings(train_df, p = p)

  irf_dx_dy <- compute_orth_irf_table(fits$dx_dy, impulse = "dx", response = "dy", n_ahead = n_ahead)
  irf_dy_dx <- compute_orth_irf_table(fits$dy_dx, impulse = "dx", response = "dy", n_ahead = n_ahead)

  granger <- compute_granger_table(fits$dy_dx, var_a = "dx", var_b = "dy")

  list(
    stationary_pair = pair,
    train_df        = train_df,
    p               = p,
    irf_dx_dy       = irf_dx_dy,
    irf_dy_dx       = irf_dy_dx,
    granger         = granger
  )
}

# ---- plotting helper (SIDE EFFECT; keep isolated) ----
save_irf_lineplot <- function(irf_tbl, out_png, main_title = "") {
  .require_columns(irf_tbl, c("h", "irf"), where = "irf_tbl")
  dir.create(dirname(out_png), recursive = TRUE, showWarnings = FALSE)

  grDevices::png(out_png, width = 1200, height = 800, res = 150)
  on.exit(grDevices::dev.off(), add = TRUE)

  graphics::plot(irf_tbl$h, irf_tbl$irf, type = "b",
                 xlab = "Horizon", ylab = "IRF", main = main_title)
  graphics::abline(h = 0)

  invisible(out_png)
}
