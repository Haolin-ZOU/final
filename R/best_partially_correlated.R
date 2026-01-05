best_partially_correlated <- function(y_xx, y_name, z, corr_threshold = .5) {
  # Calculates partial correlation coefficients between y and data in xx, 
  # controlling for variables in z. 
  # Returns best correlated (in absolute value) variable names and correlation 
  # coefficients that are greater than the threshold.
  
  # Ensure 'y_xx' is data frame and the first column is of class Date
  if (!is.data.frame(y_xx) || !inherits(y_xx$date, "Date")) {
    stop("'y_xx' must be a data frame and 'y_xx$date' must be of class Date.")
  }
  
  # Ensure 'y_name' exists in y_xx
  if (!(y_name %in% names(y_xx))) {
    stop(paste0("Column '", y_name, "' not found in 'y_xx'."))
  }
  
  # Get balanced y and XX
  y  <- y_xx[,y_name, drop  =FALSE ]
  xx <- y_xx[, !(grepl(y_name, names(y_xx)) | names(y_xx) == "date"), drop = FALSE]
  
  # Find the last observable value for 'y' (no NA values)
  last_observable_index <- max(which(!is.na(y)))
  
  # Subset 'y', 'xx', and 'z' up to the last observable index
  y_sub <- y[1:last_observable_index, ,drop = FALSE]
  xx_sub <- xx[1:last_observable_index, ]  # Drop the date column from 'xx'
  z_sub <- z[1:last_observable_index, ]
 
  # Calculate partial correlation coefficients between 'y' and each variable in 'xx'
  correlations <- sapply(names(xx_sub), function(var) {
    yzx          <- cbind(y_sub, z_sub,xx_sub[var])
    yzx_complete <- yzx[complete.cases(yzx), ]
    pcor_results <- pcor(yzx_complete)
    pcor_x       <- pcor_results$estimate[1,ncol(pcor_results$estimate)]
    return(pcor_x)  # Extract the partial correlation coefficient
  })

  # Rank by absolute partial correlation coefficients
  abs_corrs <- abs(correlations)
  ranked_vars <- names(abs_corrs)[order(-abs_corrs)]
  
  # Filter variables with correlation above the threshold
  significant_vars <- ranked_vars[abs_corrs[ranked_vars] > corr_threshold]
  
  # Create a data frame with variables as column names and correlations as values
  result <- data.frame(t(correlations[significant_vars]))
  colnames(result) <- significant_vars
  
  # Return names and partial correlation coefficients for significant variables
  return(result)
}
