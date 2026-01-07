# pipeline/run_r.R
# One-command pipeline (R path)

steps <- c(
  "scripts/20_q1_choose_series.R",
  "scripts/30_var_estimation.R",
  "scripts/40_var_recursive_forecast.R",
  "scripts/50_bonus_irf_granger.R"
)

for (s in steps) {
  if (!file.exists(s)) stop(sprintf("Missing step: %s", s), call. = FALSE)
  message("Running: ", s)
  status <- system2("Rscript", args = c(s))
  if (!identical(status, 0L)) stop(sprintf("Step failed: %s", s), call. = FALSE)
}

message("R pipeline done.")

