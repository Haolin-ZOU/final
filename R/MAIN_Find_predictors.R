# This script users stationary data and selects a subset of variables to be 
# considered for forecasting regressions.
# by 'vasja.sivec@statec.etat.lu' on 09/04/2025

# Clean everything
rm(list = ls(envir = .GlobalEnv), envir = .GlobalEnv)                           # Remove all variables, functions...
graphics.off()                                                                  # Closes all open graphics devices
par(mfrow = c(1, 1))                                                            # Resets layout to default (1 plot per window)

# Load packages
suppressMessages(library(ppcor))                                                # for partial correlations
suppressMessages(library(glmnet))                                               # for lasso regression
suppressMessages(library(lars))                                                 # for least angular regression model (similar to lasso)
suppressMessages(library(readxl))

# Declare name of the dependent variable
y_name = "gdp_r_sa"                                                             #### <---- change this

# Set wd and source functions
setwd("C:/Users/xct385/Desktop/MADS/MADS_win25/HW/HWII/Example Code")           # declare working directory   #### <---- change this
functions_path       <- file.path(getwd(), "2_FUNCTIONS")                       # functions path  
invisible(lapply(list.files(functions_path, pattern = "\\.R$",                  # source functions
                              full.names = TRUE), source))         
    
####################### 1. DATA ################################################
# Import data
p_max                          <- 3                                             # maximum lag to add
k                              <- 1                                             # forecast horizon (series will be lagged for direct forecasting at max k),
file_path <- file.path(getwd(), "1_DATA", "PROCESSED", "data_mod.xlsx")
data <- read_excel(file_path)                                                   # load data
  
# balance the data
# BY DATE
data[[1]]      <- as.Date(data[[1]])                                            # Converts first column to date-type 
ind_start      <- which(data[[1]] == as.Date("2007-04-01"))                     # Cuts data at selected date
data           <- data[ind_start:nrow(data), ]

# Prepare data 
y_xx                           <- prepare_y_xx(data, k, p_max, y_name)          # aligns data for k-steps ahead direct forecasting, adds lags of y and X, optionaly drops data

####################### 2. CHECK POT. PREDICTORS    ############################

# a) best correlated variables
corr_threshold  <- .3                                                           # threshold for correlation coeff (drop less correlated variables)
names_include_1 <- best_correlated(y_xx,y_name,corr_threshold)                  # returns best variables
print(names_include_1)

# b) best partially correlated variables
corr_threshold    <- .2                                                         # threshold for partial correlation coeff (drop less correlated variables) 
reg_models_ranked <- rank_regression_models_by_ic(y_xx,y_name, "aicc")
best_ar           <- strsplit(reg_models_ranked$Regressors[1], ",\\s*")[[1]]
names_include_2   <- best_partially_correlated(y_xx,y_name,y_xx[best_ar],corr_threshold)  # returns best partially y-correlated variables
print(names_include_2)

# c) LASSO regressors
cut_date = "2008-01-01"
names_include_3 <- best_lasso_variables(y_xx, y_name , k, cut_date)
print(names_include_3)

# d) LARS regressors
cut_date = "2008-01-01"
names_include_4 <- best_lars_variables(y_xx, y_name,cut_date)
print(names_include_4)

# e) STEPWISE regressors
cut_date = "2008-01-01"
names_include_5 <- best_stepwise_variables(y_xx, y_name,cut_date)
print(names_include_5)  
  
