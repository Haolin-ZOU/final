best_lasso_variables <- function(y_xx, y_name, k = 1, cut_date = NULL) {
  # This script performs lasso regression and returns the names of variables
  # that enter the model
  # INPUT:
  #       y        - data frame with the dependent variable and lags
  #       xx       - data frame with the regressors and their lags
  #       y_name   - target variable from y
  #       cut_date - cut those series that do not have observations at "cut_date" date
  #       k        - forecast horizon
  # OUTPUT: 
  #  selected_variables - list of variables selected by lasso model
  
  ######## DATA CHECKS START HERE ########

  # Ensure 'y_xx' is data frame and that it has a column named date of class Date
  if (!is.data.frame(y_xx) || !inherits(y_xx$date, "Date")) {
    stop("'y_xx' must be a data frame and 'y_xx$date' must be of class Date.")
  }
  
  # Ensure 'y_name' exists in y_xx
  if (!(y_name %in% names(y_xx))) {
    stop(paste0("Column '", y_name, "' not found in 'y_xx'."))
  }
  
  # If  cut date is not supplied by the user, create it
  if (is.null(cut_date)) {
    
    # find first not-NA date for each variable (excl. date)
    first_obs <- sapply(
      y_xx[ , !names(y_xx) %in% "date"],
      function(x) min(y_xx$date[!is.na(x)])
    )
    
    # choose the latest of these dates
    cut_date <- max(first_obs, na.rm = TRUE)
  }
  
  # Check if cut_date is in the "yyyy-mm-dd" format
  parsed_date <- as.Date(cut_date, format = "%Y-%m-%d")
  if (is.na(parsed_date)) {
    stop(paste("Error: '", cut_date, "' is not a valid date in the format 'yyyy-mm-dd'.", sep = ""))
  }
  ######## DATA CHECKS END HERE ########

  # data
  xx <- y_xx[ , !(names(y_xx) %in% c(y_name, "date")), drop = FALSE]            # regressors
  y  <- y_xx[,y_name,drop = FALSE]                                              # y
  
  # balance the data (drop those with missings) 
  target_date      <- as.Date(cut_date)
  non_missing_cols <- colnames(xx)[!is.na(xx[which(y_xx$date == target_date), -1])]
  xx_trimmed       <- xx[, non_missing_cols]
  combined_data    <- cbind(y,xx_trimmed)
  data_mat         <- as.matrix(combined_data[complete.cases(combined_data), ])
  
  # create time-series folds
  n           <- nrow(data_mat)
  train_start <- floor(0.7 * n)
  n_folds     <- n-train_start - (max(k)-1)
  folds       <- create_time_series_folds(data_mat,n, train_start,max(k))  # not really needed now but programmed for later

  # select lambda penalty (CV over folds)
  cv_lasso    <- cv.glmnet(folds[[n_folds]]$train[,-1], folds[[n_folds]]$train[,1], alpha = 1) # use built-in routines to get lambda grid
  lambda_vec  <- cv_lasso$lambda                                                               # possible lambdas
  lambda      <- select_lambda(folds,lambda_vec)                                               # use CV over folds to select lambda 
  lambda      <- lambda                                 # halve the penalty constant (this is just to select variables, not to select the best model)
  # run lasso over folds and return union of used variables
  selected_variables <- lasso_selected_variables(folds, lambda) # run lasso over all folds and return the union of variables selected by lasso  
  
  return(selected_variables)
  
}
