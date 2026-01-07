# tests/testthat/helper-var.R
# Load VAR functions for unit tests (Section 2 & 3)

project_root <- normalizePath(file.path("..", ".."), mustWork = TRUE)

var_core_path <- file.path(project_root, "R", "var_core.R")
var_plot_path <- file.path(project_root, "R", "var_plot.R")

if (!file.exists(var_core_path)) stop(paste("Missing file:", var_core_path), call. = FALSE)
if (!file.exists(var_plot_path)) stop(paste("Missing file:", var_plot_path), call. = FALSE)

source(var_core_path)
source(var_plot_path)
