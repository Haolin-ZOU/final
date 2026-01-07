context("q1-core")

test_that("trim_to_last_observed_y removes tail missing y", {
  df <- data.frame(
    date = as.Date("2020-01-01") + 0:4,
    y = c(1, 2, 3, NA, NA)
  )
  out <- trim_to_last_observed_y(df, date_col = "date", y_col = "y")
  expect_equal(nrow(out), 3)
})

test_that("q1_select_top_n_abs_corr returns top correlated x", {
  set.seed(1)
  date <- as.Date("2020-01-01") + 0:49

  inc <- seq(0, 1, length.out = 50) + rnorm(50, sd = 0.01)
  y <- cumsum(inc)
  x1 <- 2 * y + rnorm(50, sd = 0.01)
  x2 <- rep(1, 50)

  y_df <- data.frame(date = date, import_clv_qna_sa = y)
  x_df <- data.frame(date = date, x1 = x1, x2 = x2)

  top <- q1_select_top_n_abs_corr(
    y_df = y_df,
    x_df = x_df,
    date_col = "date",
    y_col = "import_clv_qna_sa",
    top_n = 1,
    min_obs = 10,
    train_ratio = 0.8,
    diff_lag = 1
  )

  expect_equal(nrow(top), 1)
  expect_equal(top$code[[1]], "x1")
})
