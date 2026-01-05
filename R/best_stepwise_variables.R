best_stepwise_variables <- function(y_xx, y_name, cut_date = NULL, use_if_corr = NULL) {
  
  
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
    cut_date <- min(y_xx$date, na.rm = TRUE)
  }
  
  # Check if cut_date is in the "yyyy-mm-dd" format
  parsed_date <- as.Date(cut_date, format = "%Y-%m-%d")
  if (is.na(parsed_date)) {
    stop(paste("Error: '", cut_date, "' is not a valid date in the format 'yyyy-mm-dd'.", sep = ""))
  }
  
  cut_date <- as.Date(cut_date)
  if (!(cut_date %in% y_xx$date)) {
    stop(paste("Error: '", cut_date, "' is not found in xx$date.", sep = ""))
  }
  
  ######## DATA CHECKS END HERE ########
  
  
  # Filter y and yy to include only observations on or after cut_date
  y_cut  <- y_xx[y_xx$date >= cut_date, y_name, drop = FALSE]
  xx_cut <- y_xx[y_xx$date >= cut_date, , drop = FALSE]
  complete_rows <- complete.cases(y_cut)                    # index for observed y
  y_cut  <- y_cut[complete_rows, , drop = FALSE]            # drop nans from y
  xx_cut <- xx_cut[complete_rows, ]                         # align x with y
  xx_cut <- xx_cut[, colSums(is.na(xx_cut)) == 0]           # remove from x all cols with missings
  
  # Merge the two data frames on the "date" column
  combined_data <- cbind(y_cut, xx_cut[, !(names(xx_cut) == "date"), drop = FALSE])
 
  
  # reduce the number of features
  if (!is.null(use_if_corr)) {
    # Remove 'date' and 'y_name' from combined_data for correlation calculation
    data_for_corr <- combined_data[, !(colnames(combined_data) %in% c("date", y_name))]
    # Calculate correlation between target variable and predictors
    corr_with_target <- cor(data_for_corr,combined_data[[y_name]])
    # Get names of predictors with correlation greater than or equal to use_if_corr
    index_keep          <- which(abs(corr_with_target) >= use_if_corr)
    selected_predictors <- rownames(corr_with_target)[index_keep]
    # Create a new combined_data without the predictors with low correlation
    combined_data <- combined_data[, c("date", y_name, selected_predictors)]
  }
  
  # run 
  predictor_names <- setdiff(names(combined_data), y_name)
  y   <- as.matrix(combined_data[, y_name, drop = FALSE])
  X   <- as.matrix(combined_data[,predictor_names])
  fit <- lars(X,y, type = "stepwise", use.Gram=FALSE)
  
  # prepare return object
  index_selected <- (fit$entry!=0)
  rank_selected  <- fit$entry[index_selected]
  name_selected  <- colnames(X)[index_selected]   
  ret_df <- data.frame(matrix(rank_selected, nrow = 1))
  colnames(ret_df) <- name_selected
  sorted_order <- order(as.numeric(ret_df[1, ]))
  ret_df <- ret_df[, sorted_order]
  
  # Return the combined data frame
  return(ret_df)
  
}