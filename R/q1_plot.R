# R/q1_plot.R

suppressWarnings({
  library(ggplot2)
})

plot_top_corr_barh <- function(top_df, title = "Top 5 by |corr| (first differences)") {
  # Expect columns: code, abs_corr
  ggplot(top_df, aes(x = abs_corr, y = reorder(code, abs_corr))) +
    geom_col() +
    labs(
      title = title,
      x = "|Pearson correlation|",
      y = "Candidate series code"
    ) +
    theme_minimal()
}

save_plot_png <- function(p, path, width = 10, height = 4, dpi = 200) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  ggsave(filename = path, plot = p, width = width, height = height, dpi = dpi)
}
