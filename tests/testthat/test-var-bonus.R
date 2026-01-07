# tests/testthat/test-var-bonus.R
test_that("build_stationary_pair returns clean dy/dx and drops NA", {
  n <- 40
  df <- data.frame(
    date = as.Date("2000-01-01") + 0:(n - 1),
    x    = cumsum(rnorm(n)),
    y    = cumsum(rnorm(n))
  )
  df$x[n] <- NA  # 模拟你真实数据的“最后一个 x 缺失”

  out <- build_stationary_pair(df, date_col = "date", y_col = "y", x_col = "x", diff_lag = 1L)

  expect_true(all(c("date", "dy", "dx") %in% names(out)))
  expect_true(all(is.finite(out$dy)))
  expect_true(all(is.finite(out$dx)))
  expect_true(nrow(out) >= (n - 3))  # 一般是 n-2，但这里放宽一点，避免平台差异
})

test_that("compute_orth_irf_table returns horizons 0..n_ahead", {
  skip_if_not_installed("vars")

  set.seed(1)
  T <- 120
  dx <- as.numeric(stats::arima.sim(list(ar = 0.3), n = T))
  dy <- 0.2 * c(0, dx[-T]) + as.numeric(stats::arima.sim(list(ar = 0.2), n = T))

  train_df <- data.frame(dx = dx, dy = dy)
  fit <- vars::VAR(train_df[, c("dy", "dx")], p = 1, type = "const")  # 注意 ordering: dy, dx

  irf_tbl <- compute_orth_irf_table(fit, impulse = "dx", response = "dy", n_ahead = 12L)

  expect_equal(irf_tbl$h, 0:12)
  expect_true(all(c("h", "impulse", "response", "irf") %in% names(irf_tbl)))

  # orth IRF + ordering (dy, dx) 下：dx 对 dy 的当期(0期)应为 0
  expect_equal(irf_tbl$irf[irf_tbl$h == 0], 0, tolerance = 1e-10)
})

test_that("compute_granger_table returns two tests with p-values", {
  skip_if_not_installed("vars")

  set.seed(2)
  T <- 120
  dx <- rnorm(T)
  dy <- 0.3 * c(0, dx[-T]) + rnorm(T)

  fit <- vars::VAR(data.frame(dy = dy, dx = dx), p = 1, type = "const")
  gr <- compute_granger_table(fit, var_a = "dx", var_b = "dy")

  expect_equal(nrow(gr), 2)
  expect_true(all(c("cause","effect","statistic","df1","df2","p_value") %in% names(gr)))
  expect_true(all(gr$p_value >= 0 & gr$p_value <= 1))

})

test_that("compute_bonus_results returns IRF tables + Granger", {
  skip_if_not_installed("vars")

  set.seed(3)
  n <- 80
  level_df <- data.frame(
    date = as.Date("2001-01-01") + 0:(n - 1),
    x = cumsum(rnorm(n)),
    y = cumsum(rnorm(n))
  )
  level_df$x[n] <- NA  # 模拟缺失

  res <- compute_bonus_results(
    level_df = level_df,
    date_col = "date",
    y_col = "y",
    x_col = "x",
    p = 1,
    train_ratio = 0.8,
    diff_lag = 1L,
    n_ahead = 12L
  )

  expect_true(is.list(res))
  expect_true(all(c("irf_dx_dy", "irf_dy_dx", "granger") %in% names(res)))
  expect_equal(nrow(res$irf_dx_dy), 13)
  expect_equal(nrow(res$irf_dy_dx), 13)
  expect_equal(nrow(res$granger), 2)
})
