best_correlated <- function(y_xx ,y_name , corr_threshold = .5) {
  # Calculates correlation coefficients between y and data in xx
  # Returns best correlated (in absolutes) variable names and correlation
  # coefficients.
  
  # Ensure 'y_xx' is data frame and that it has a column named date of class Date
  if (!is.data.frame(y_xx) || !inherits(y_xx$date, "Date")) {
    stop("'y_xx' must be a data frame and 'y_xx$date' must be of class Date.")
  }
  
  # Ensure 'y_name' exists in y_xx
  if (!(y_name %in% names(y_xx))) {
    stop(paste0("Column '", y_name, "' not found in 'y_xx'."))
  }
  
 
  # Find the last observable value for 'y' (no NA values)
  last_observable_index <- max(which(!is.na(y_xx[, y_name])))

  # Subset 'y' and 'xx' up to the last observable index
  y_sub  <- y_xx[1:last_observable_index, y_name]                               # Take y
  xx_sub <- y_xx[1:last_observable_index, !(names(y_xx) %in% y_name)]           # Drop y from 'xx'
  xx_sub <- xx_sub[, -1]                                                        # Drop the date column from 'xx'
  
  # # Calculate correlation coefficients between 'y' and each variable in 'xx'
  # correlations <- sapply(names(xx_sub), function(var) {
  #   cor(y_sub, xx_sub[[var]], use = "complete.obs")  # Use only complete cases
  # })
  correlations <- sapply(names(xx_sub), function(var) {
    complete_idx <- complete.cases(y_sub, xx_sub[[var]])
    if (sum(complete_idx) >= 2) {
      cor(y_sub[complete_idx], xx_sub[[var]][complete_idx])
    } else {
      NA  # not enough data to compute correlation
    }
  })
  correlations <- correlations[!is.na(correlations)]
  
  # Rank by absolute correlation coefficients
  abs_corrs <- abs(correlations)
  ranked_vars <- names(abs_corrs)[order(-abs_corrs)]
  
  # Filter variables with correlation above the threshold
  significant_vars <- ranked_vars[abs_corrs[ranked_vars] > corr_threshold]
  
  # Create a data frame with variables as column names and correlations as values
  result <- data.frame(t(correlations[significant_vars]))
  colnames(result) <- significant_vars
  
  # Return names and correlation coefficients for significant variables
  return(result)
  
}