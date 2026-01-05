check_dots <- function(txt) {

  dot_counts <- sapply(strsplit(txt, "\\."), length) - 1
  if (dot_counts > 1) {

    stop(paste0("Error: ", txt," name contain more than one '.'. It can cause bugs in add_lags() function."))
  }
}


