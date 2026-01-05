suppressPackageStartupMessages({
  library(dplyr)
  library(purrr)
  library(ggplot2)
})


align_by_date <- function(y, x, date_col = "date") {
  y %>%
    mutate(!!date_col := as.Date(.data[[date_col]])) %>%
    inner_join(x %>% mutate(!!date_col := as.Date(.data[[date_col]])), by = date_col) %>%
    arrange(.data[[date_col]])
}

diff_columns <- function(df, cols, date_col = "date", lag = 1) {
  df %>%
    arrange(.data[[date_col]]) %>%
    mutate(across(all_of(cols), ~ .x - dplyr::lag(.x, lag)))
}

corr_one <- function(df, y_col, x_col) {
  sub <- df[, c(y_col, x_col)]
  sub <- stats::na.omit(sub)
  n <- nrow(sub)
  if (n < 3) return(data.frame(code = x_col, corr = NA_real_, n_obs = n))

  r <- suppressWarnings(stats::cor(sub[[y_col]], sub[[x_col]]))
  data.frame(code = x_col, corr = r, n_obs = n)
}


rank_by_abs_corr <- function(df, y_col, candidate_cols, top_n = 5, min_obs = 30) {
  map_dfr(candidate_cols, ~ corr_one(df, y_col, .x)) %>%
    mutate(abs_corr = abs(corr)) %>%
    filter(!is.na(corr), n_obs >= min_obs) %>%
    arrange(desc(abs_corr)) %>%
    slice_head(n = top_n)
}

add_descriptions <- function(top, desc) {
  top %>% left_join(desc, by = c("code" = "CODE"))
}

save_barh_abs_corr <- function(top5, out_fig) {
  p <- ggplot(top5, aes(x = reorder(code, abs_corr), y = abs_corr)) +
    geom_col() +
    coord_flip() +
    labs(
      title = "Top 5 candidates by |corr| with Δy (first differences)",
      x = "Candidate series (code)",
      y = "|Pearson correlation|"
    ) +
    theme_minimal(base_size = 12)
  ggsave(out_fig, p, width = 8, height = 4.5, dpi = 200)
}
