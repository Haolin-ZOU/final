# tests/testthat/test-var-core.R

testthat::test_that("prepare_var_level_data drops leading NA and allows last x missing only", {
  y_df <- data.frame(date = as.Date("2020-01-01") + 0:4, y = 1:5)
  x_df <- data.frame(date = as.Date("2020-01-01") + 0:4, x = c(NA, 10, 11, 12, NA))

  out <- prepare_var_level_data(y_df, x_df, "date", "y", "x", allow_last_x_missing = TRUE)
  testthat::expect_equal(out$x[1], 10)
  testthat::expect_true(is.na(out$x[nrow(out)]))
})

testthat::test_that("prepare_var_level_data errors if x missing in the middle", {
  y_df <- data.frame(date = as.Date("2020-01-01") + 0:4, y = 1:5)
  x_df <- data.frame(date = as.Date("2020-01-01") + 0:4, x = c(10, NA, 11, 12, 13))

  testthat::expect_error(
    prepare_var_level_data(y_df, x_df, "date", "y", "x", allow_last_x_missing = TRUE),
    "not only at the last"
  )
})

testthat::test_that("make_first_differences returns n-1 rows for diff_lag=1", {
  df <- data.frame(date = as.Date("2020-01-01") + 0:4, a = 1:5, b = 11:15)
  out <- make_first_differences(df, "date", cols = c("a", "b"), diff_lag = 1L)
  testthat::expect_equal(nrow(out), 4)
  testthat::expect_true(all(c("d_a", "d_b") %in% names(out)))
})

testthat::test_that("recursive forecast returns last 20% length", {
  set.seed(1)
  n <- 30
  df <- data.frame(
    date = as.Date("2020-01-01") + 0:(n - 1),
    y = cumsum(rnorm(n)),
    x = cumsum(rnorm(n))
  )

  pred <- recursive_var_one_step_forecast_level(
    level_df = df,
    date_col = "date",
    y_col = "y",
    x_col = "x",
    p = 1,
    train_ratio = 0.8,
    diff_lag = 1L
  )

  testthat::expect_equal(nrow(pred), n - floor(0.8 * n))
})

