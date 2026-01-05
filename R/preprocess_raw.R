suppressPackageStartupMessages({
  library(readxl)
  library(dplyr)
})

coerce_excel_date <- function(x) {
  if (inherits(x, "Date")) return(x)
  if (is.numeric(x)) return(as.Date(x, origin = "1899-12-30"))
  as.Date(x)
}

write_csv_base <- function(df, path) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  utils::write.csv(df, path, row.names = FALSE)
}

preprocess_raw <- function(raw_data_xlsx, raw_hw1_xlsx, out_dir,
                           y_col = "import_clv_qna_sa", date_col = "date") {
  x <- read_excel(raw_data_xlsx, sheet = "data_x") %>%
    mutate(!!date_col := coerce_excel_date(.data[[date_col]]))

  y_all <- read_excel(raw_hw1_xlsx, sheet = "data_y") %>%
    mutate(!!date_col := coerce_excel_date(.data[[date_col]]))

  if (!(y_col %in% names(y_all))) {
    stop(sprintf("y_col='%s' not found in HW1 data_y sheet.", y_col))
  }

  y <- y_all %>%
    select(all_of(date_col), all_of(y_col)) %>%
    rename(y = all_of(y_col))

  desc <- read_excel(raw_hw1_xlsx, sheet = "descriptions") %>%
    rename_with(~ trimws(.x)) %>%
    select(CODE, DESCRIPTION)

  dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
  write_csv_base(x, file.path(out_dir, "x.csv"))
  write_csv_base(y, file.path(out_dir, "y.csv"))
  write_csv_base(desc, file.path(out_dir, "descriptions.csv"))
}
