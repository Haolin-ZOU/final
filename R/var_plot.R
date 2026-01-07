# R/var_plot.R
# Small deterministic IO wrappers for figures/tables

save_acf_pacf_png <- function(x, out_png, title_prefix = "", max_lag = 20) {
  dir.create(dirname(out_png), recursive = TRUE, showWarnings = FALSE)

  grDevices::png(out_png, width = 1400, height = 700, res = 150)
  old <- par(no.readonly = TRUE)
  on.exit({ par(old); grDevices::dev.off() }, add = TRUE)

  par(mfrow = c(1, 2))
  stats::acf(x, lag.max = max_lag, main = paste0(title_prefix, " ACF"))
  stats::pacf(x, lag.max = max_lag, main = paste0(title_prefix, " PACF"))
}

write_csv_safe <- function(df, out_csv) {
  dir.create(dirname(out_csv), recursive = TRUE, showWarnings = FALSE)
  utils::write.csv(df, out_csv, row.names = FALSE)
}

write_txt_safe <- function(lines, out_txt) {
  dir.create(dirname(out_txt), recursive = TRUE, showWarnings = FALSE)
  base::writeLines(as.character(lines), con = out_txt)
}

