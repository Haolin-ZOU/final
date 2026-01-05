create_time_series_folds <- function(data,n, n_train, k) {


  # Initialize a list to store fold IDs
  n_folds <- n - n_train - (k-1) 
  folds <- vector("list", n_folds)
  
  for (i in 1:n_folds) {
 
    # Create the training set for fold i: all data up to the (i * fold_size)
    # Create the test set for fold i: all data after that point
    train_indices <- 1:(n_train +(i -1))
    test_indices <- n_train +(i -1) +k
    
    # Assign insample and outsample
    folds[[i]] <- list(
      train       = as.matrix(data[train_indices,]),
      test        = t(as.matrix(data[test_indices,]))
      )
  }
  
  return(folds)
}