# ============================================================
# 05_ardl_analysis.R
# Estimate the structural-break ARDL model
# ============================================================

source("Scripts/00_setup.R")

library(ARDL)


# Analysis sample
ardl_data <- main_data |>
  filter(!is.na(Gini_WID)) |>
  transmute(
    Year = End_Year,
    Gini = Gini_WID,
    Education = Education_Share,
    Health = Health_Share,
    Economic_Affairs = Economic_Affairs_Share,
    Inflation = Inflation_Percent,
    GDP_Growth = GDP_Growth_Percent,
    
    Break_1993 = if_else(End_Year >= 1993, 1, 0),
    Break_2007 = if_else(End_Year >= 2007, 1, 0),
    Break_2019 = if_else(End_Year >= 2019, 1, 0)
  )


ardl_ts <- ts(
  ardl_data |>
    select(-Year),
  start = 1980,
  end = 2024,
  frequency = 1
)


# Lag selection
auto_model <- auto_ardl(
  Gini ~
    Education +
    Health +
    Economic_Affairs +
    Inflation +
    GDP_Growth |
    Break_1993 +
    Break_2007 +
    Break_2019,
  
  data = ardl_ts,
  
  max_order = c(
    2, 2, 2, 2, 2, 2
  ),
  
  selection = "AIC",
  grid = TRUE
)


ardl_model <- auto_model$best_model
selected_order <- auto_model$best_order


cat("\nSelected ARDL order\n")
print(selected_order)

cat(
  "\nObservations:",
  nobs(ardl_model),
  "\nAIC:",
  AIC(ardl_model),
  "\nBIC:",
  BIC(ardl_model),
  "\n"
)


# Top lag structures
top_orders <- auto_model$top_orders |>
  head(10)

cat("\nTop AIC lag structures\n")

print(
  top_orders,
  row.names = FALSE
)


# Error-correction coefficient
uecm_model <- uecm(
  ardl_model
)

uecm_summary <- summary(
  uecm_model
)

ect <- as.numeric(
  coef(uecm_model)["L(Gini, 1)"]
)

ect_p_value <- as.numeric(
  uecm_summary$coefficients[
    "L(Gini, 1)",
    "Pr(>|t|)"
  ]
)


cat(
  "\nECT:",
  ect,
  "\nECT p-value:",
  ect_p_value,
  "\n"
)


# Bounds tests
set.seed(2026)

f_test <- bounds_f_test(
  ardl_model,
  case = 3,
  alpha = 0.05,
  exact = TRUE,
  pvalue = TRUE,
  R = 40000
)


set.seed(2126)

t_test <- bounds_t_test(
  ardl_model,
  case = 3,
  alpha = 0.05,
  exact = TRUE,
  pvalue = TRUE,
  R = 40000
)


cat("\nBounds F-test\n")
print(f_test$tab)

cat("\nBounds t-test\n")
print(t_test$tab)


# Save selected order
order_table <- tibble(
  Variable = c(
    "Gini",
    "Education",
    "Health",
    "Economic_Affairs",
    "Inflation",
    "GDP_Growth"
  ),
  Lag_Order = as.integer(
    selected_order
  )
)


write_csv(
  order_table,
  "Outputs/ARDL/05_selected_ardl_order.csv"
)


write_csv(
  as.data.frame(top_orders),
  "Outputs/ARDL/05_top_aic_orders.csv"
)


# Save coefficients
coefficient_matrix <- summary(
  ardl_model
)$coefficients


coefficient_table <- tibble(
  Term = rownames(coefficient_matrix),
  Estimate = coefficient_matrix[, "Estimate"],
  Standard_Error = coefficient_matrix[, "Std. Error"],
  t_Statistic = coefficient_matrix[, "t value"],
  P_Value = coefficient_matrix[, "Pr(>|t|)"]
)


write_csv(
  coefficient_table,
  "Outputs/ARDL/05_ardl_coefficients.csv"
)


# Save bounds results
bounds_results <- bind_rows(
  
  as.data.frame(
    f_test$tab
  ) |>
    tibble::rownames_to_column("Test"),
  
  as.data.frame(
    t_test$tab
  ) |>
    tibble::rownames_to_column("Test")
)


write_csv(
  bounds_results,
  "Outputs/ARDL/05_bounds_tests.csv"
)


# Save model fit
model_summary <- summary(
  ardl_model
)


model_fit <- tibble(
  ARDL_Order = paste(
    selected_order,
    collapse = ","
  ),
  Observations = nobs(ardl_model),
  R_Squared = model_summary$r.squared,
  Adjusted_R_Squared = model_summary$adj.r.squared,
  Residual_SE = model_summary$sigma,
  AIC = AIC(ardl_model),
  BIC = BIC(ardl_model),
  ECT = ect,
  ECT_P_Value = ect_p_value
)


write_csv(
  model_fit,
  "Outputs/ARDL/05_model_fit.csv"
)


cat("\nARDL estimation completed.\n")