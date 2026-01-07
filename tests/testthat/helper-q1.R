# tests/testthat/helper-q1.R

core_path <- file.path("..", "..", "R", "q1_core.R")
if (!file.exists(core_path)) {
  stop(sprintf("Cannot find core file: %s. Run tests from project root.", core_path), call. = FALSE)
}
source(core_path)

