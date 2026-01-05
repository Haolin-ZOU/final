align_data_for_direct_forecasting <- function(df, y_name,k) {

  # Perform basic data checks
  data_checks(df,y_name)
  
  # get target 
  y_df <- df[ , c(1, which(names(df) == y_name)), drop = FALSE]
  
  # get data without the target 
  xx_df <- df[ , !(names(df) %in% y_name), drop = FALSE]
  
  # align the data with y in a way that allows you to use direct forecasts for k-steps ahead
  
  # index for last observable y value
  last_observable_y_index  <- which(!is.na(y_df[[y_name]]))[length(which(!is.na(y_df[[y_name]])))]
  last_observable_xx_index <- apply(xx_df[, -1], 2, function(x) max(which(!is.na(x))))
 
  diff                     <- (last_observable_xx_index - last_observable_y_index)
  lag_xx_by                <- pmax(0, k - diff)
  names(lag_xx_by)         <- names(diff) 
  xx_df_shifted            <- shift_variables(xx_df, lag_xx_by)
  
  
  # Return as list
  ret <- list(y = y_df, xx = xx_df_shifted)
  return(ret)
}
