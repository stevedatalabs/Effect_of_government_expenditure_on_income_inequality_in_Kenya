# ==========================================
# MASTER THESIS ANALYSIS: 
# ==========================================

# 1. Install and load the ARDL package
if(!require(ARDL)) install.packages("ARDL")
library(ARDL)

print("--- RUNNING ARDL BOUNDS TESTING FRAMEWORK ---")

# 1. Automatically find the best lag structure using your EXACT CSV column names
optimal_ardl <- auto_ardl(
  formula = Inequality ~ Social_Welfare + Education + Infrastructure + Inflation + GDP_Growth,
  data = thesis_data,
  max_order = c(2, 2, 2, 2, 2, 2)
)

print("--- OPTIMAL LAG SELECTION RESULTS ---")
# TARGETS THE WINNING MODEL OBJECT DIRECTLY TO PREVENT NULL ERRORS
print(optimal_ardl$best_model)

cat("\nThe selected optimal lag order is:", optimal_ardl$best_order, "\n")

# 2. Run the Bounds Test for Cointegration using the correct model property
bounds_test <- bounds_f_test(optimal_ardl$best_model, case = 3)

print("--- ARDL BOUNDS TEST (F-STATISTIC) ---")
print(bounds_test)


print("--- EXTRACTING LONG-RUN COEFFICIENTS & ECM ---")

# 1. Extract the Long-Run Relationships
long_run_results <- multipliers(optimal_ardl$best_model, type = "lr")
print("--- LONG RUN MULTIPLIERS ---")
print(long_run_results)

# 2. Extract the Short-Run Shocks and Speed of Adjustment (ECM)
ecm_model <- recm(optimal_ardl$best_model, case = 3)
print("--- ERROR CORRECTION MODEL SUMMARY ---")
summary(ecm_model)

# ==============================================================================
# MODEL FIT & EXAMINER SHIELD DIAGNOSTICS
# ==============================================================================

print("--- MODEL EXPLANATORY POWER (R-SQUARED) ---")
# Extracts MY 0.8080375 explanatory score dynamically
print(summary(ecm_model)$r.squared)

print("--- FINAL ROBUST SHORT-RUN MODEL (ECM) WITH NEWEY-WEST CORRECTION ---")
# This applies the Newey-West adjustments to fix the serial correlation p-values
# THIS IS THE MASTER TABLE TO COPY AND PASTE INTO CHAPTER 4 OF MY THESIS
robust_ecm <- coeftest(ecm_model, vcov = NeweyWest(ecm_model))
print(robust_ecm)