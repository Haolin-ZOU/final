add_lags <- function(x,p, dep_var = FALSE, k = NULL) {
  # This functions creates lags up to p-th lag for x. It considers 
  # existing lags derived from variable name (skips L1 if L1.y).
  # INPUT:
  #    x         - (Txn) data frame with date in the first column
  #    p         - number of lags
  #    k         - forecast horizon
  # OUTPUT:
  #   result_df  - x with lagged values of x attached
  
    stopifnot(is.data.frame(x), p >= 1)
    
    # Extract date and variable columns
    date_col <- x[[1]]
    var_names <- colnames(x)[-1]
    x_vars <- x[, -1, drop = FALSE]
    
    # Container for lagged variables
    lagged_vars <- list()
    
    for (var in var_names) {
    
      check_dots(var)
      
      split_name <- strsplit(var, "\\.")[[1]]
      
      # Determine base name and existing lag
      
      if (length(split_name) == 1) { # no existing lags
        base_name <- split_name[1]
        existing_lag <- 0
      } else {                       # existing leads or lags 
        
        prefix <- split_name[1]
        base_name <- split_name[2]
       
        if (grepl("^L[0-9]+$", prefix)) {
          existing_lag <- as.integer(sub("L", "", prefix))
        } else {
          existing_lag <- 0
          base_name <- var
        }
        
      }
      
   
      
      # Add base variable
      browser
      lagged_vars[[var]] <- x_vars[[var]]
   
      # Add additional lags
      if (existing_lag > 0) {            # a) if the variable is already lagged
        
        for (l in (existing_lag+1):(existing_lag+p-1)) {
          lagged_name <- paste0("L", l, ".", base_name)
          lagged_vars[[lagged_name]] <- c(rep(NA, (l-existing_lag)), x_vars[[var]][1:(nrow(x) - (l-existing_lag))])
        }
        
      } else {                           # b) if the variable is not already lagged
        if (dep_var) { # if y
        
          for (l in k:(p+(k-1)) ) {
            lagged_name <- paste0("L", l, ".", base_name)
            lagged_vars[[lagged_name]] <- c(rep(NA, l), x_vars[[var]][1:(nrow(x) - l)])
          }
                  
          
        } else {       # if x
          
          for (l in 1:(p-1)) {
            lagged_name <- paste0("L", l, ".", base_name)
            lagged_vars[[lagged_name]] <- c(rep(NA, l), x_vars[[var]][1:(nrow(x) - l)])
          }
          
        }
      }
    }
    
    # Combine into a data frame
    result_df <- data.frame(date = date_col, lagged_vars, check.names = FALSE)
    return(result_df)
  }
  