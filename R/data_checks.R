data_checks <- function(df, y_name) {

# Check that y_name is provided and is a single character string
if (missing(y_name) || !is.character(y_name) || length(y_name) != 1) {
  stop("Argument 'y_name' must be provided as a single character string.")
}

# Check that y_name exists in df
if (!(y_name %in% names(df))) {
  stop(paste0("'", y_name, "' not found in data frame columns."))
}

# Check that the first column is Date
if (!inherits(df[[1]], "Date")) {
  stop("The first column must be of class 'Date'.")
}

# Check that all other columns are numeric
if (!all(sapply(df[ , -1], is.numeric))) {
  stop("All columns except the first must be numeric.")
}
  
}