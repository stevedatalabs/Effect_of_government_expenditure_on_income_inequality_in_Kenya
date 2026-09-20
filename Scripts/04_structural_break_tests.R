# ============================================================
# 04_structural_break_tests.R
# Structural break tests for the WID Gini series
# ============================================================

source("Scripts/00_setup.R")

library(strucchange)
library(urca)


# WID sample
gini_data <- main_data |>
  filter(!is.na(Gini_WID)) |>
  transmute(
    Year = End_Year,
    Gini = Gini_WID
  )


# ============================================================
# 1. Sup-F test
# ============================================================

fstats_model <- Fstats(
  Gini ~ Year,
  data = gini_data,
  from = 0.15,
  to = 0.85
)

supf_test <- sctest(
  fstats_model
)

cat("\nSup-F structural break test\n")
print(supf_test)


# ============================================================
# 2. Bai-Perron multiple breaks
# ============================================================

break_model <- breakpoints(
  Gini ~ Year,
  data = gini_data,
  h = 0.15
)

max_breaks <- as.integer(
  ncol(break_model$RSS.table) / 2
)

candidate_breaks <- 0:max_breaks

bic_values <- AIC(
  break_model,
  breaks = candidate_breaks,
  k = log(break_model$nobs)
)

bic_table <- tibble(
  Number_of_Breaks = candidate_breaks,
  BIC = as.numeric(bic_values)
)

optimal_breaks <- bic_table |>
  slice_min(
    BIC,
    n = 1,
    with_ties = FALSE
  ) |>
  pull(Number_of_Breaks)


cat("\nBIC comparison\n")

print(
  bic_table,
  n = Inf
)

cat(
  "\nSelected number of breaks:",
  optimal_breaks,
  "\n"
)


# Extract break dates
selected_breaks <- breakpoints(
  break_model,
  breaks = optimal_breaks
)

break_indices <- selected_breaks$breakpoints

break_years <- gini_data$Year[
  break_indices
]

regime_start_years <- gini_data$Year[
  break_indices + 1
]

break_table <- tibble(
  Break = seq_along(break_years),
  Break_Year = break_years,
  New_Regime_Start = regime_start_years
)


cat("\nBai-Perron break dates\n")

print(
  break_table,
  n = Inf
)


# ============================================================
# 3. Zivot-Andrews test
# ============================================================

za_test <- ur.za(
  gini_data$Gini,
  model = "both",
  lag = 4
)

za_statistic <- as.numeric(
  za_test@teststat
)

za_critical <- za_test@cval

za_break_year <- gini_data$Year[
  za_test@bpoint
]

za_result <- tibble(
  Break_Year = za_break_year,
  Test_Statistic = za_statistic,
  Critical_1pct = as.numeric(za_critical[1]),
  Critical_5pct = as.numeric(za_critical[2]),
  Critical_10pct = as.numeric(za_critical[3]),
  Stationary_5pct =
    za_statistic < as.numeric(za_critical[2])
)


cat("\nZivot-Andrews test\n")

print(
  za_result,
  n = Inf
)


# ============================================================
# 4. Save results
# ============================================================

write_csv(
  bic_table,
  "Outputs/Stationarity/04_bai_perron_bic.csv"
)

write_csv(
  break_table,
  "Outputs/Stationarity/04_structural_break_dates.csv"
)

write_csv(
  za_result,
  "Outputs/Stationarity/04_zivot_andrews_test.csv"
)


supf_result <- tibble(
  Statistic = as.numeric(supf_test$statistic),
  P_Value = supf_test$p.value
)

write_csv(
  supf_result,
  "Outputs/Stationarity/04_supf_test.csv"
)


# ============================================================
# 5. Structural break plot
# ============================================================

break_plot <- ggplot(
  gini_data,
  aes(
    x = Year,
    y = Gini
  )
) +
  geom_line(
    linewidth = 0.9
  ) +
  geom_vline(
    xintercept = break_years,
    linetype = "dashed",
    linewidth = 0.7
  ) +
  geom_vline(
    xintercept = za_break_year,
    linetype = "dotted",
    linewidth = 0.9
  ) +
  labs(
    title = "Structural Breaks in Kenya's Income Inequality",
    subtitle = "WID Gini coefficient, 1980-2024",
    x = "Year",
    y = "Gini coefficient"
  ) +
  theme_classic()


print(break_plot)


ggsave(
  "Outputs/Plots/04_wid_structural_breaks.png",
  break_plot,
  width = 9,
  height = 5,
  dpi = 300
)


cat("\nStructural break analysis completed.\n")