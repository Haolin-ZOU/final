# tests/testthat/helper-var-bonus.R
find_repo_root <- function(start = getwd(), max_up = 10) {
  cur <- normalizePath(start)
  for (i in 1:max_up) {
    if (file.exists(file.path(cur, "R", "var_core.R")) &&
        file.exists(file.path(cur, "R", "var_bonus.R"))) {
      return(cur)
    }
    parent <- dirname(cur)
    if (identical(parent, cur)) break
    cur <- parent
  }
  stop("helper-var-bonus.R: cannot locate repo root containing R/var_core.R and R/var_bonus.R", call. = FALSE)
}

root <- find_repo_root()
source(file.path(root, "R", "var_core.R"))
source(file.path(root, "R", "var_bonus.R"))

