#' Prepare lagged dataset for direct forecasting using AR terms and optional differencing
#'
#' This function takes a data frame, optionally computes first differences on known variables,
#' drops specified columns, aligns the dependent variable for forecasting, and adds 
#' autoregressive lags to both y and x variables.
#'
#' @param df_in   Data frame containing the original time series data.
#' @param k       Forecast horizon (integer), required.
#' @param p_max   Maximum number of lags to include (integer), required.
#' @param y_name  Name of the dependent variable to forecast (character), required.
#' @param x_drop  (Optional) Vector of column names to drop before processing.
#'
#' @return A data frame (df_out) with lagged features for y and x, ready for forecasting models.

prepare_y_xx <- function(df_in, k, p_max, y_name, x_drop = NULL) {
  
  # Check that y_name is provided
  if (is.null(y_name) || y_name == "") {
    stop("Please provide y_name (name of the dependent variable).")
  }
  
  # Compute first differences for selected variables [V: delete for others...]
  if ("opcnet" %in% names(df_in)) {
    df_in$opcnet_diff <- c(NA, diff(df_in$opcnet))
  }
  if ("ticteur_oe_base_q" %in% names(df_in)) {
    df_in$ticteur_oe_base_q_diff <- c(NA, diff(df_in$ticteur_oe_base_q))
  }
  if ("tilteur_oe_base_q" %in% names(df_in)) {
    df_in$tilteur_oe_base_q_diff <- c(NA, diff(df_in$tilteur_oe_base_q))
  }
  
  # Drop specified variables (if any)
  if (!is.null(x_drop) && length(x_drop) > 0) {
    df_in <- df_in[ , !(names(df_in) %in% x_drop)]
  }
  
  # If k is a vector align by max(k) (forecasts for multiple horizons)
  k   <- max(k)

  # Align data for direct forecasting
  y_x <- align_data_for_direct_forecasting(df_in, y_name, k)
  
  # Add AR lags to y and x
  dep_var <- TRUE
  yly <- add_lags(y_x$y, p_max, dep_var, k)
  xlx <- add_lags(y_x$xx, p_max)
  
  # Drop lags greater than p_max
  drop_idx <- which(grepl(paste0("^L[" ,(p_max+1),  "-9][0-9]*\\."), names(xlx)))
  if (length(drop_idx) > 0) {
    xlx <- xlx[, -drop_idx]
  }
  drop_idy <- which(grepl(paste0("^L[" ,(p_max+1),  "-9][0-9]*\\."), names(yly)))
  if (length(drop_idy) > 0) {
    yly <- yly[, -drop_idy]
  }
 
  # Combine into final output
  df_out <- merge(yly, xlx, by = "date", all = FALSE)
  
  
  return(df_out)
}
