# ============================================================
# 07_long_short_run_effects.R
# Estimate short-run and long-run effects
# ============================================================

source("Scripts/00_setup.R")

library(ARDL)


# Analysis sample
analysis_data <- main_data |>
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


analysis_ts <- ts(
  analysis_data |>
    select(-Year),
  start = 1980,
  end = 2024,
  frequency = 1
)


# Selected ARDL model
ardl_model <- ardl(
  Gini ~
    Education +
    Health +
    Economic_Affairs +
    Inflation +
    GDP_Growth |
    Break_1993 +
    Break_2007 +
    Break_2019,
  
  data = analysis_ts,
  
  order = c(
    1, 1, 0, 0, 1, 1
  )
)


variables <- c(
  "Education",
  "Health",
  "Economic_Affairs",
  "Inflation",
  "GDP_Growth"
)


# ============================================================
# 1. Long-run effects
# ============================================================

long_run <- multipliers(
  ardl_model,
  type = "lr"
) |>
  as_tibble() |>
  filter(
    Term %in% variables
  ) |>
  mutate(
    Effect_Gini_Points = Estimate * 100,
    Horizon = "Long run"
  )


cat("\nLong-run effects\n")

print(
  long_run,
  n = Inf,
  width = Inf
)


# ============================================================
# 2. Short-run effects
# ============================================================

short_run <- multipliers(
  ardl_model,
  type = "sr"
) |>
  as_tibble() |>
  filter(
    Term %in% variables
  ) |>
  mutate(
    Effect_Gini_Points = Estimate * 100,
    Horizon = "Short run"
  )


cat("\nShort-run effects\n")

print(
  short_run,
  n = Inf,
  width = Inf
)


# ============================================================
# 3. Error-correction model
# ============================================================

ecm_model <- recm(
  ardl_model,
  case = 3
)


cat("\nError-correction model\n")

print(
  summary(ecm_model)
)


ecm_matrix <- summary(
  ecm_model
)$coefficients


ecm_results <- tibble(
  Term = rownames(ecm_matrix),
  Estimate = ecm_matrix[, "Estimate"],
  Standard_Error = ecm_matrix[, "Std. Error"],
  t_Statistic = ecm_matrix[, "t value"],
  P_Value = ecm_matrix[, "Pr(>|t|)"]
)


ect <- ecm_results |>
  filter(
    Term == "ect"
  )


cat("\nError-correction term\n")

print(ect)


# ============================================================
# 4. Combined results
# ============================================================

combined_results <- bind_rows(
  short_run,
  long_run
) |>
  select(
    Horizon,
    Term,
    Estimate,
    `Std. Error`,
    `t value`,
    `Pr(>|t|)`,
    Effect_Gini_Points
  )


cat("\nShort-run and long-run comparison\n")

print(
  combined_results,
  n = Inf,
  width = Inf
)


# ============================================================
# 5. Save results
# ============================================================

write_csv(
  long_run,
  "Outputs/ARDL/07_long_run_effects.csv"
)

write_csv(
  short_run,
  "Outputs/ARDL/07_short_run_effects.csv"
)

write_csv(
  combined_results,
  "Outputs/ARDL/07_long_short_run_effects.csv"
)

write_csv(
  ecm_results,
  "Outputs/ARDL/07_error_correction_model.csv"
)


cat("\nLong-run and short-run analysis completed.\n")