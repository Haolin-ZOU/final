lasso_selected_variables <- function(folds, lambda) {
  n_folds <- length(folds)
  selected_vars_per_fold <- vector("list", n_folds)
  
  for (i in 1:n_folds) {
    # Combine training and test data for full-fold model
    y <- c(folds[[i]]$train[, 1], folds[[i]]$test[, 1])
    X <- rbind(folds[[i]]$train[, -1], folds[[i]]$test[, -1])
    
    # Fit lasso
    fit <- glmnet(X, y, lambda = lambda, alpha = 1)
    
    # Extract coefficients
    coef_i <- coef(fit)
    selected_names <- rownames(coef_i)[which(coef_i != 0)]
    
    # Remove intercept
    selected_names <- setdiff(selected_names, "(Intercept)")
    
    # Store selected variable names
    selected_vars_per_fold[[i]] <- selected_names
  }
 
  # Unlist all selected variables across folds and count
  all_selected <- unlist(selected_vars_per_fold)
  counts <- table(all_selected)
  sorted_counts <- sort(counts, decreasing = TRUE)

  # Convert to data.frame
  result_df <- as.data.frame(as.data.frame(as.list(sorted_counts)))
  
  return(result_df)
}