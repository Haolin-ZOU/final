# R/q1_io.R

suppressWarnings({
  library(readxl)
  library(dplyr)
})

require_columns <- function(df, cols, where = "") {
  missing <- setdiff(cols, names(df))
  if (length(missing) > 0) {
    stop(
      sprintf(
        "Missing columns in %s: %s. Available: %s",
        where,
        paste(missing, collapse = ", "),
        paste(names(df), collapse = ", ")
      ),
      call. = FALSE
    )
  }
  invisible(df)
}

read_x_strict_one_sheet <- function(path) {
  sheets <- readxl::excel_sheets(path)
  if (length(sheets) != 1) {
    stop(sprintf("x.xlsx must have exactly 1 sheet, found: %s", paste(sheets, collapse = ", ")))
  }
  readxl::read_excel(path, sheet = sheets[1]) %>%
    mutate(date = as.Date(date))
}

read_y_data_y_sheet <- function(path, sheet = "data_y") {
  sheets <- readxl::excel_sheets(path)
  if (!(sheet %in% sheets)) {
    stop(sprintf("y.xlsx missing sheet '%s'. Found: %s", sheet, paste(sheets, collapse = ", ")))
  }
  readxl::read_excel(path, sheet = sheet) %>%
    mutate(date = as.Date(date))
}

read_descriptions_sheet <- function(path, sheet = "descriptions") {
  sheets <- readxl::excel_sheets(path)
  if (!(sheet %in% sheets)) {
    return(NULL)  # not an error, but then DESCRIPTION will be NA
  }
  readxl::read_excel(path, sheet = sheet) %>%
    rename(CODE = 1, DESCRIPTION = 2)
}

write_csv_strict <- function(df, path) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  write.csv(df, path, row.names = FALSE)
}
