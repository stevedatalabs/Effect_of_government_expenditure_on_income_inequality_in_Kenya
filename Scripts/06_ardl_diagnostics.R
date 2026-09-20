# ============================================================
# 06_ardl_diagnostics.R
# Diagnostic and stability tests for the selected ARDL model
# ============================================================

source("Scripts/00_setup.R")

library(ARDL)
library(lmtest)
library(tseries)
library(strucchange)


# Analysis sample
diagnostic_data <- main_data |>
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


diagnostic_ts <- ts(
  diagnostic_data |>
    select(-Year),
  start = 1980,
  end = 2024,
  frequency = 1
)


# Selected model from script 05
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
  
  data = diagnostic_ts,
  
  order = c(
    1, 1, 0, 0, 1, 1
  )
)


# ============================================================
# 1. Residual diagnostics
# ============================================================

bg_1 <- bgtest(
  ardl_model,
  order = 1
)

bg_2 <- bgtest(
  ardl_model,
  order = 2
)

bp_test <- bptest(
  ardl_model
)

jb_test <- jarque.bera.test(
  residuals(ardl_model)
)

reset_test <- resettest(
  ardl_model,
  power = 2:3,
  type = "fitted"
)


cat("\nBreusch-Godfrey LM(1)\n")
print(bg_1)

cat("\nBreusch-Godfrey LM(2)\n")
print(bg_2)

cat("\nBreusch-Pagan test\n")
print(bp_test)

cat("\nJarque-Bera test\n")
print(jb_test)

cat("\nRamsey RESET test\n")
print(reset_test)


# ============================================================
# 2. Equivalent OLS model for CUSUM tests
# ============================================================

cusum_data <- diagnostic_data |>
  mutate(
    Gini_L1 = lag(Gini),
    Education_L1 = lag(Education),
    Inflation_L1 = lag(Inflation),
    GDP_Growth_L1 = lag(GDP_Growth)
  ) |>
  filter(!is.na(Gini_L1))


cusum_model <- lm(
  Gini ~
    Gini_L1 +
    Education +
    Education_L1 +
    Health +
    Economic_Affairs +
    Inflation +
    Inflation_L1 +
    GDP_Growth +
    GDP_Growth_L1 +
    Break_1993 +
    Break_2007 +
    Break_2019,
  data = cusum_data
)


replication_difference <- max(
  abs(
    as.numeric(coef(ardl_model)) -
      as.numeric(coef(cusum_model))
  )
)


cat(
  "\nMaximum ARDL-OLS coefficient difference:",
  replication_difference,
  "\n"
)


# ============================================================
# 3. Stability tests
# ============================================================

recursive_cusum <- efp(
  formula(cusum_model),
  data = cusum_data,
  type = "Rec-CUSUM"
)

recursive_test <- sctest(
  recursive_cusum
)


ols_cusum <- efp(
  formula(cusum_model),
  data = cusum_data,
  type = "OLS-CUSUM"
)

ols_test <- sctest(
  ols_cusum
)


cat("\nRecursive CUSUM test\n")
print(recursive_test)

cat("\nOLS-CUSUM test\n")
print(ols_test)


# ============================================================
# 4. Save diagnostic summary
# ============================================================

diagnostic_summary <- tibble(
  Test = c(
    "Breusch-Godfrey LM(1)",
    "Breusch-Godfrey LM(2)",
    "Breusch-Pagan",
    "Jarque-Bera",
    "Ramsey RESET",
    "Recursive CUSUM",
    "OLS-CUSUM"
  ),
  
  Statistic = c(
    as.numeric(bg_1$statistic),
    as.numeric(bg_2$statistic),
    as.numeric(bp_test$statistic),
    as.numeric(jb_test$statistic),
    as.numeric(reset_test$statistic),
    as.numeric(recursive_test$statistic),
    as.numeric(ols_test$statistic)
  ),
  
  P_Value = c(
    bg_1$p.value,
    bg_2$p.value,
    bp_test$p.value,
    jb_test$p.value,
    reset_test$p.value,
    recursive_test$p.value,
    ols_test$p.value
  )
) |>
  mutate(
    Result = if_else(
      P_Value > 0.05,
      "Pass",
      "Review"
    )
  )


cat("\nDiagnostic summary\n")

print(
  diagnostic_summary,
  n = Inf
)


write_csv(
  diagnostic_summary,
  "Outputs/ARDL/06_diagnostic_tests.csv"
)


# ============================================================
# 5. Residual and fitted values
# ============================================================

model_years <- tail(
  diagnostic_data$Year,
  nobs(ardl_model)
)


residual_data <- tibble(
  Year = model_years,
  Actual = as.numeric(
    ardl_model$model$Gini
  ),
  Fitted = as.numeric(
    fitted(ardl_model)
  ),
  Residual = as.numeric(
    residuals(ardl_model)
  )
)


write_csv(
  residual_data,
  "Outputs/ARDL/06_residuals_and_fitted.csv"
)


# ============================================================
# 6. Actual and fitted values
# ============================================================

fit_plot <- ggplot(
  residual_data,
  aes(x = Year)
) +
  geom_line(
    aes(
      y = Actual,
      linetype = "Actual"
    ),
    linewidth = 0.9
  ) +
  geom_line(
    aes(
      y = Fitted,
      linetype = "Fitted"
    ),
    linewidth = 0.9
  ) +
  labs(
    title = "Actual and Fitted WID Gini",
    subtitle = "ARDL(1,1,0,0,1,1)",
    x = "Year",
    y = "Gini coefficient",
    linetype = NULL
  ) +
  theme_classic()


ggsave(
  "Outputs/Plots/06_actual_vs_fitted.png",
  fit_plot,
  width = 9,
  height = 5,
  dpi = 300
)


# ============================================================
# 7. Residual plot
# ============================================================

residual_plot <- ggplot(
  residual_data,
  aes(
    x = Year,
    y = Residual
  )
) +
  geom_hline(
    yintercept = 0,
    linetype = "dashed"
  ) +
  geom_line(
    linewidth = 0.8
  ) +
  geom_point(
    size = 1.8
  ) +
  labs(
    title = "ARDL Model Residuals",
    x = "Year",
    y = "Residual"
  ) +
  theme_classic()


ggsave(
  "Outputs/Plots/06_residuals.png",
  residual_plot,
  width = 9,
  height = 5,
  dpi = 300
)


# ============================================================
# 8. Q-Q plot
# ============================================================

qq_plot <- ggplot(
  residual_data,
  aes(
    sample = Residual
  )
) +
  stat_qq() +
  stat_qq_line() +
  labs(
    title = "Q-Q Plot of ARDL Residuals",
    x = "Theoretical quantiles",
    y = "Sample quantiles"
  ) +
  theme_classic()


ggsave(
  "Outputs/Plots/06_residual_qq_plot.png",
  qq_plot,
  width = 7,
  height = 5,
  dpi = 300
)


# ============================================================
# 9. Residual ACF
# ============================================================

png(
  "Outputs/Plots/06_residual_acf.png",
  width = 1600,
  height = 1000,
  res = 200
)

acf(
  residuals(ardl_model),
  main = "ACF of ARDL Residuals"
)

dev.off()


# ============================================================
# 10. CUSUM plots
# ============================================================

png(
  "Outputs/Plots/06_recursive_cusum.png",
  width = 1800,
  height = 1000,
  res = 200
)

plot(
  recursive_cusum,
  main = "Recursive CUSUM Test"
)

dev.off()


png(
  "Outputs/Plots/06_ols_cusum.png",
  width = 1800,
  height = 1000,
  res = 200
)

plot(
  ols_cusum,
  main = "OLS-CUSUM Test"
)

dev.off()


cat("\nARDL diagnostic testing completed.\n")