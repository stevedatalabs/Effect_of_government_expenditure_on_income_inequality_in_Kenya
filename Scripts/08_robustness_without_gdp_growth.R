# ============================================================
# 08_robustness_without_gdp_growth.R
# Re-estimate the model without GDP growth
# ============================================================

source("Scripts/00_setup.R")

library(ARDL)
library(lmtest)
library(tseries)


# Analysis sample
robust_data <- main_data |>
  filter(!is.na(Gini_WID)) |>
  transmute(
    Year = End_Year,
    Gini = Gini_WID,
    Education = Education_Share,
    Health = Health_Share,
    Economic_Affairs = Economic_Affairs_Share,
    Inflation = Inflation_Percent,
    
    Break_1993 = if_else(End_Year >= 1993, 1, 0),
    Break_2007 = if_else(End_Year >= 2007, 1, 0),
    Break_2019 = if_else(End_Year >= 2019, 1, 0)
  )


robust_ts <- ts(
  robust_data |>
    select(-Year),
  start = 1980,
  end = 2024,
  frequency = 1
)


# ============================================================
# 1. Lag selection
# ============================================================

auto_robust <- auto_ardl(
  
  Gini ~
    Education +
    Health +
    Economic_Affairs +
    Inflation |
    Break_1993 +
    Break_2007 +
    Break_2019,
  
  data = robust_ts,
  
  max_order = c(
    2, 2, 2, 2, 2
  ),
  
  selection = "AIC",
  grid = TRUE
)


robust_model <- auto_robust$best_model
robust_order <- auto_robust$best_order


cat("\nSelected robustness ARDL order\n")

print(
  robust_order
)


cat(
  "\nObservations:",
  nobs(robust_model),
  "\nAIC:",
  AIC(robust_model),
  "\nBIC:",
  BIC(robust_model),
  "\n"
)


# ============================================================
# 2. Error-correction term
# ============================================================

robust_uecm <- uecm(
  robust_model
)

uecm_matrix <- summary(
  robust_uecm
)$coefficients


ect <- as.numeric(
  coef(robust_uecm)["L(Gini, 1)"]
)

ect_p <- as.numeric(
  uecm_matrix[
    "L(Gini, 1)",
    "Pr(>|t|)"
  ]
)


cat(
  "\nECT:",
  ect,
  "\nECT p-value:",
  ect_p,
  "\n"
)


# ============================================================
# 3. Bounds tests
# ============================================================

set.seed(2026)

f_test <- bounds_f_test(
  robust_model,
  case = 3,
  alpha = 0.05,
  exact = TRUE,
  pvalue = TRUE,
  R = 40000
)


set.seed(2126)

t_test <- bounds_t_test(
  robust_model,
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


# ============================================================
# 4. Short-run and long-run effects
# ============================================================

variables <- c(
  "Education",
  "Health",
  "Economic_Affairs",
  "Inflation"
)


long_run <- multipliers(
  robust_model,
  type = "lr"
) |>
  as_tibble() |>
  filter(
    Term %in% variables
  ) |>
  mutate(
    Horizon = "Long run",
    Effect_Gini_Points = Estimate * 100
  )


short_run <- multipliers(
  robust_model,
  type = "sr"
) |>
  as_tibble() |>
  filter(
    Term %in% variables
  ) |>
  mutate(
    Horizon = "Short run",
    Effect_Gini_Points = Estimate * 100
  )


robust_effects <- bind_rows(
  short_run,
  long_run
)


cat("\nRobustness effects\n")

print(
  robust_effects,
  n = Inf,
  width = Inf
)


# ============================================================
# 5. Diagnostic checks
# ============================================================

bg_test <- bgtest(
  robust_model,
  order = 2
)

bp_test <- bptest(
  robust_model
)

jb_test <- jarque.bera.test(
  residuals(robust_model)
)

reset_test <- resettest(
  robust_model,
  power = 2:3,
  type = "fitted"
)


diagnostics <- tibble(
  Test = c(
    "Breusch-Godfrey LM(2)",
    "Breusch-Pagan",
    "Jarque-Bera",
    "Ramsey RESET"
  ),
  
  Statistic = c(
    as.numeric(bg_test$statistic),
    as.numeric(bp_test$statistic),
    as.numeric(jb_test$statistic),
    as.numeric(reset_test$statistic)
  ),
  
  P_Value = c(
    bg_test$p.value,
    bp_test$p.value,
    jb_test$p.value,
    reset_test$p.value
  )
) |>
  mutate(
    Result = if_else(
      P_Value > 0.05,
      "Pass",
      "Review"
    )
  )


cat("\nRobustness diagnostics\n")

print(
  diagnostics,
  n = Inf
)


# ============================================================
# 6. Compare with the main model
# ============================================================

main_effects <- read_csv(
  "Outputs/ARDL/07_long_short_run_effects.csv",
  show_col_types = FALSE
) |>
  filter(
    Term %in% variables
  ) |>
  select(
    Horizon,
    Term,
    Main_Estimate = Estimate,
    Main_P_Value = `Pr(>|t|)`,
    Main_Gini_Points = Effect_Gini_Points
  )


comparison <- robust_effects |>
  select(
    Horizon,
    Term,
    Robust_Estimate = Estimate,
    Robust_P_Value = `Pr(>|t|)`,
    Robust_Gini_Points = Effect_Gini_Points
  ) |>
  left_join(
    main_effects,
    by = c(
      "Horizon",
      "Term"
    )
  ) |>
  select(
    Horizon,
    Term,
    Main_Estimate,
    Robust_Estimate,
    Main_P_Value,
    Robust_P_Value,
    Main_Gini_Points,
    Robust_Gini_Points
  )


cat("\nMain model versus robustness model\n")

print(
  comparison,
  n = Inf,
  width = Inf
)


# ============================================================
# 7. Save results
# ============================================================

order_table <- tibble(
  Variable = names(robust_order),
  Lag_Order = as.integer(robust_order)
)


write_csv(
  order_table,
  "Outputs/ARDL/08_selected_ardl_order.csv"
)


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
  "Outputs/ARDL/08_bounds_tests.csv"
)


write_csv(
  robust_effects,
  "Outputs/ARDL/08_long_short_run_effects.csv"
)


write_csv(
  diagnostics,
  "Outputs/ARDL/08_diagnostic_tests.csv"
)


write_csv(
  comparison,
  "Outputs/ARDL/08_main_vs_no_gdp_growth.csv"
)


cat("\nRobustness analysis completed.\n")