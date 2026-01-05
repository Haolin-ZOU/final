shift_variables <- function(xx, lag_xx_by) {
  # This functions shifts the variables in xx by the corresponding lead/lag
  # entries in lag_xx_by.
  # INPUT:
  #    xx     - (Txn) data frame with date in the first column
  #    lag_xx_by - ((n-y) x 1) atomic vector with leads (+1) or lags(-1) corresponding 
  #                 columns in xx
  # OUTPUT:
  #   xx_shifted - shifted data frame

  # Create an empty data frame to store shifted variables
  xx_shifted           <- as.data.frame(matrix(NA, nrow = nrow(xx), ncol = ncol(xx)))
  xx_shifted[1]        <- xx[1]
  colnames(xx_shifted) <- colnames(xx)
  
  # Iterate through all columns except the first (date column)
  for (var in colnames(xx)[-1]) {
    
    # Get the current variable and the lag/lead value from lag_xx_by 
    x            <- xx[[var]]
    lag_value    <- lag_xx_by[var]
    
    # Shift the variable based on the lag_value
    if (lag_value == 0) {
      
      xx_shifted[[var]] <- x  # No change if lag_value is 0
      
    } else {
      
      xx_shifted[[var]] <- c(rep(NA, lag_value), head(x, length(x) - lag_value))
      colnames(xx_shifted)[colnames(xx_shifted) == var] <- paste0("L", lag_value, ".", var)    # rename (L1.oldname)
      
    }
  }
  
  
  # Return the shifted data frame
  return(xx_shifted)
}