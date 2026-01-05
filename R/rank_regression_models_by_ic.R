rank_regression_models_by_ic <- function(y_xx, y_name, ic_type = "bic") {
  
  # Ensure 'y_xx' is data frame and the first column is of class Date
  if (!is.data.frame(y_xx) || !inherits(y_xx$date, "Date")) {
    stop("'y_xx' must be a data frame and 'y_xx$date' must be of class Date.")
  }
  
  # Ensure 'y_name' exists in y_xx
  if (!(y_name %in% names(y_xx))) {
    stop(paste0("'", y_name, "' not found in 'y_xx'."))
  }
  
  # Validate ic_type input
  ic_type <- tolower(ic_type)
  if (!ic_type %in% c("aic", "bic", "aicc")) {
    stop("ic_type must be one of 'aic', 'bic', or 'aicc'.")
  }
  
  
  
  # Align y and xx by removing rows with NAs in either y or xx
  y_xx_balanced  <- y_xx[complete.cases(y_xx), ]
  y_all          <- y_xx_balanced[, grep(y_name,names(y_xx)), drop = FALSE]
  y              <- y_all[,names(y_all) %in% y_name,drop = FALSE]
  xx             <- y_all[,!(names(y_all) %in% y_name), drop = FALSE]

  
  # Store results here
  results <- data.frame(
    Regressors = character(0),
    AIC = numeric(0),
    AICC = numeric(0),
    BIC = numeric(0),
    stringsAsFactors = FALSE
  )
  
  variable_combinations <- lapply(1:ncol(xx), function(i) combn(names(xx), i, simplify = FALSE))
  variable_combinations <- unlist(variable_combinations, recursive = FALSE)
  
  # Run regressions for all combinations and calculate criteria
  for (vars in variable_combinations) {
    # Create a formula for the regression model
    formula <- as.formula(paste(names(y),"~", paste(vars, collapse = " + ")))
    
    # Fit the regression model
    data_in   <- cbind(y, xx[, unlist(vars), drop = FALSE])
    model     <- lm(formula, data = data_in)
    
    # Calculate AIC, HQIC, and BIC
    aic_value  <- AIC(model)
    k          <- length(coef(model))
    n          <- dim(y)[1]
    aicc_value <- aic_value + (2*k^2 + 2*k)/(n - k - 1)
    bic_value  <- BIC(model)
    
    # Store results
    results <- rbind(results, data.frame(
      Regressors = paste(vars, collapse = ", "),
      AIC = aic_value,
      AICC = aicc_value,
      BIC = bic_value
    ))
  }
  
  # Rank based on the selected information criterion
  if (ic_type == "aic") {
    results <- results[order(results$AIC), ]
  } else if (ic_type == "bic") {
    results <- results[order(results$BIC), ]
  } else if (ic_type == "hqic") {
    results <- results[order(results$AICC), ]
  }
  
  return(results)
}

# Example Usage:
# Assuming 'y' and 'xx' are your data frames
# result <- rank_regression_models_by_ic(y, xx, ic_type = "bic")
# View(result)
