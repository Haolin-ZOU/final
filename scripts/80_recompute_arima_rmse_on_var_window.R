# scripts/80_recompute_arima_rmse_on_var_window.R
suppressPackageStartupMessages({
  library(forecast)
})

rmse <- function(y_true, y_pred) {
  sqrt(mean((y_true - y_pred)^2))
}

expanding_one_step_arima <- function(y_train, y_test, order = c(0,1,0)) {
  history <- as.numeric(y_train)
  preds <- numeric(length(y_test))

  for (t in seq_along(y_test)) {
    fit <- forecast::Arima(history, order = order, include.drift = FALSE)
    preds[t] <- as.numeric(forecast::forecast(fit, h = 1)$mean[1])
    history <- c(history, as.numeric(y_test[t]))
  }
  preds
}

ROOT <- normalizePath(".")

eval_path <- file.path(ROOT, "output", "metadata", "eval_window.csv")
df_path   <- file.path(ROOT, "data", "processed", "var_dataset.csv")

if (!file.exists(eval_path)) stop("Missing output/metadata/eval_window.csv")
if (!file.exists(df_path))   stop("Missing data/processed/var_dataset.csv")

df <- read.csv(df_path)
df$date <- as.Date(df$date)

ew <- read.csv(eval_path)
ew$date <- as.Date(ew$date)

m <- merge(df, ew, by = "date")
m <- m[order(m$date), ]

y_train <- m$y[m$set == "train"]
y_test  <- m$y[m$set == "test"]

preds <- expanding_one_step_arima(y_train, y_test, order = c(0,1,0))
score <- rmse(y_test, preds)

out <- file.path(ROOT, "output", "tables", "rmse_baseline_arima_on_var_window.csv")
dir.create(dirname(out), recursive = TRUE, showWarnings = FALSE)
write.csv(data.frame(model="ARIMA(0,1,0) baseline", rmse=score, n_test=length(y_test)),
          out, row.names = FALSE)

cat("✅ wrote:", out, "\n")
cat(sprintf("ARIMA(0,1,0) RMSE on VAR test window: %.4f (n_test=%d)\n", score, length(y_test)))

