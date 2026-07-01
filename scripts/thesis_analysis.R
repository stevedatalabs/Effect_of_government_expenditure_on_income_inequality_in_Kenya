# ==========================================
# MASTER THESIS ANALYSIS: 
# ==========================================

# 1. Install and load necessary econometric testing packages
if(!require(tseries)) install.packages("tseries")
if(!require(lmtest)) install.packages("lmtest")
if(!require(car)) install.packages("car")

library(tidyverse)
library(tseries)
library(lmtest)
library(car)

# 2. Load your master dataset
# Ensure the file path matches MY current workspace
data_path <- "C:/Users/user/Desktop/R Projects/Effect_of_government_expenditure_on_income_inequality_in_Kenya/data/Kenya_Fiscal_Inequality_Data.csv"
thesis_data <- read.csv(data_path)

# Clean up column names just in case they have spaces or special characters
colnames(thesis_data) <- c("Year", "Inequality", "Social_Welfare", "Education", "Infrastructure", "Inflation", "GDP_Growth")

# 3. Step 4.2: Summary Statistics (Getting to know your data structure)
print("--- SUMMARY STATISTICS ---")
summary_stats <- summary(thesis_data %>% select(-Year))
print(summary_stats)

# 4. Step 5.1: STATIONARITY TESTING (Augmented Dickey-Fuller Test)
# I test every single variable at Level to see if they contain a Unit Root.
print("--- ADF STATIONARITY TEST RESULTS (AT LEVEL) ---")

vars_to_test <- c("Inequality", "Social_Welfare", "Education", "Infrastructure", "Inflation", "GDP_Growth")

for (var in vars_to_test) {
  adf_result <- adf.test(thesis_data[[var]], alternative = "stationary")
  cat("\nVariable:", var, 
      "\n  ADF Statistic:", round(adf_result$statistic, 4), 
      "\n  p-value:", round(adf_result$p.value, 4))
  
  if(adf_result$p.value < 0.05) {
    cat("\n  Result: STATIONARY (Reject Null Hypothesis of Unit Root)\n")
  } else {
    cat("\n  Result: NON-STATIONARY (Fail to Reject Null. Needs Differencing!)\n")
  }
}