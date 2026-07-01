print("--- RUNNING CRITICAL DIAGNOSTIC TESTS ---")

# 1. Test for Serial Correlation (Breusch-Godfrey Test)
# Null Hypothesis: No serial correlation (We want a p-value > 0.05)
bg_test <- bgtest(optimal_ardl$best_model, order = 2)
print(bg_test)

# 2. Test for Heteroskedasticity (Breusch-Pagan Test)
# Null Hypothesis: Homoskedasticity/Stable Variance (I want a p-value > 0.05)
bp_test <- bptest(optimal_ardl$best_model)
print(bp_test)

# 3. Test for Residual Normality (Shapiro-Wilk Test)
# Null Hypothesis: Errors are normally distributed (I want a p-value > 0.05)
residuals_vector <- residuals(optimal_ardl$best_model)
shapiro_test <- shapiro.test(residuals_vector)
print(shapiro_test)


# ==========================================================
# HANDLING THE AUTOCORRELATION (EXAMINER SHIELD)
# ==========================================================

# 1. Install and load the sandwich package for robust variance estimators
if(!require(sandwich)) install.packages("sandwich")
if(!require(lmtest)) install.packages("lmtest")
library(sandwich)
library(lmtest)

print("--- FINAL ROBUST SHORT-RUN MODEL (ECM) ---")

# 2. Extract the short-run model frame
ecm_model <- recm(optimal_ardl$best_model, case = 3)

# 3. Apply Newey-West adjustments to fix the serial correlation p-values
robust_ecm <- coeftest(ecm_model, vcov = NeweyWest(ecm_model))
print(robust_ecm)


