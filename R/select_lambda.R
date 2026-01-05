select_lambda <- function(folds, lambda_vec) {
  # Returns min RMSE lambda
  n_folds <- length(folds)
  errors_grid <- matrix(NA, nrow = n_folds, ncol = length(lambda_vec))  # initialize errors matrix
  
  for (j in 1:length(lambda_vec)) { # loop over possible lambdas
    for (i in 1:n_folds) {          # loop over time-series folds
      
      # train data
      y_train <- folds[[i]]$train[, 1]
      X_train <- folds[[i]]$train[, -1]
      
      # estimate
      lasso_model <- glmnet(X_train, y_train, lambda = lambda_vec[j], alpha = 1)
      
      # test data
      X_test <- folds[[i]]$test[, -1]
      y_test <- folds[[i]]$test[, 1]
      
      # prediction error
      prediction <- predict(lasso_model, X_test)
      prediction_error <- prediction - y_test
      
      # save prediction error (MSE)
      errors_grid[i, j] <- mean((prediction_error)^2, na.rm = TRUE)
    }
  }
  
  # calculate RMSE for each lambda
  rmse_per_lambda <- apply(errors_grid, 2, function(col) sqrt(mean(col, na.rm = TRUE)))
  best_lambda_index <- which.min(rmse_per_lambda)
  
  return(lambda_vec[best_lambda_index])  # return the lambda with minimum RMSE
}
