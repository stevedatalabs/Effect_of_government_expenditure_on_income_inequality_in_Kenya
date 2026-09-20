# ============================================================
# 02_descriptive_analysis.R
# Descriptive statistics, correlations and variable trends
# ============================================================

source("Scripts/00_setup.R")


# ============================================================
# 1. Summary statistics
# ============================================================

summary_statistics <- main_data |>
  summarise(
    across(
      c(
        Gini_WID,
        Education_Share,
        Health_Share,
        Economic_Affairs_Share,
        Inflation_Percent,
        GDP_Growth_Percent
      ),
      list(
        N = ~ sum(!is.na(.)),
        Mean = ~ mean(., na.rm = TRUE),
        SD = ~ sd(., na.rm = TRUE),
        Min = ~ min(., na.rm = TRUE),
        Max = ~ max(., na.rm = TRUE)
      )
    )
  ) |>
  pivot_longer(
    cols = everything(),
    names_to = c("Variable", ".value"),
    names_pattern = "(.*)_(N|Mean|SD|Min|Max)"
  )


cat("\nSummary statistics\n")

print(
  summary_statistics,
  n = Inf
)


write_csv(
  summary_statistics,
  "Outputs/Descriptive/02_summary_statistics.csv"
)


# ============================================================
# 2. Econometric sample
# ============================================================

analysis_sample <- main_data |>
  filter(
    !is.na(Gini_WID)
  ) |>
  select(
    End_Year,
    Gini_WID,
    Education_Share,
    Health_Share,
    Economic_Affairs_Share,
    Inflation_Percent,
    GDP_Growth_Percent
  )


cat(
  "\nAnalysis sample:",
  min(analysis_sample$End_Year),
  "-",
  max(analysis_sample$End_Year),
  "\n"
)

cat(
  "Observations:",
  nrow(analysis_sample),
  "\n"
)


# ============================================================
# 3. Correlation matrix
# ============================================================

correlation_data <- analysis_sample |>
  select(
    -End_Year
  )


correlation_matrix <- cor(
  correlation_data,
  use = "complete.obs"
)


cat("\nCorrelation matrix: 1980-2024\n")

print(
  round(
    correlation_matrix,
    3
  )
)


correlation_output <- as.data.frame(
  round(
    correlation_matrix,
    3
  )
) |>
  tibble::rownames_to_column(
    "Variable"
  )


write_csv(
  correlation_output,
  "Outputs/Descriptive/02_correlation_matrix_1980_2024.csv"
)


# ============================================================
# 4. WID Gini trend
# ============================================================

gini_plot <- main_data |>
  filter(
    !is.na(Gini_WID)
  ) |>
  ggplot(
    aes(
      x = End_Year,
      y = Gini_WID
    )
  ) +
  geom_line(
    linewidth = 0.9
  ) +
  geom_point(
    size = 1.8
  ) +
  labs(
    title = "Income Inequality in Kenya",
    subtitle = "WID Gini coefficient, 1980-2024",
    x = "Year",
    y = "Gini coefficient"
  ) +
  theme_classic()


print(
  gini_plot
)


ggsave(
  "Outputs/Plots/02_wid_gini_trend.png",
  gini_plot,
  width = 9,
  height = 5,
  dpi = 300
)


# ============================================================
# 5. Sectoral expenditure trends
# ============================================================

sector_data <- main_data |>
  select(
    End_Year,
    Education_Share,
    Health_Share,
    Economic_Affairs_Share
  ) |>
  pivot_longer(
    cols = -End_Year,
    names_to = "Sector",
    values_to = "Share"
  ) |>
  mutate(
    Sector = recode(
      Sector,
      Education_Share = "Education",
      Health_Share = "Health",
      Economic_Affairs_Share = "Economic Affairs"
    )
  )


sector_plot <- ggplot(
  sector_data,
  aes(
    x = End_Year,
    y = Share,
    linetype = Sector
  )
) +
  geom_line(
    linewidth = 0.9
  ) +
  labs(
    title = "Sectoral Government Expenditure in Kenya",
    subtitle = "Share of total government expenditure, 1975-2025",
    x = "Year",
    y = "Share of total expenditure (%)",
    linetype = "Sector"
  ) +
  theme_classic()


print(
  sector_plot
)


ggsave(
  "Outputs/Plots/02_sectoral_expenditure_trends.png",
  sector_plot,
  width = 10,
  height = 5.5,
  dpi = 300
)


# ============================================================
# 6. Individual sector trends
# ============================================================

sector_facet_plot <- ggplot(
  sector_data,
  aes(
    x = End_Year,
    y = Share
  )
) +
  geom_line(
    linewidth = 0.8
  ) +
  facet_wrap(
    ~ Sector,
    ncol = 1,
    scales = "free_y"
  ) +
  labs(
    title = "Trends in Sectoral Government Expenditure",
    x = "Year",
    y = "Share of total expenditure (%)"
  ) +
  theme_classic()


print(
  sector_facet_plot
)


ggsave(
  "Outputs/Plots/02_sectoral_expenditure_facets.png",
  sector_facet_plot,
  width = 9,
  height = 8,
  dpi = 300
)


# ============================================================
# 7. Inflation and GDP growth
# ============================================================

macro_data <- main_data |>
  select(
    End_Year,
    Inflation_Percent,
    GDP_Growth_Percent
  ) |>
  pivot_longer(
    cols = -End_Year,
    names_to = "Indicator",
    values_to = "Percent"
  ) |>
  mutate(
    Indicator = recode(
      Indicator,
      Inflation_Percent = "Inflation",
      GDP_Growth_Percent = "GDP Growth"
    )
  )


macro_plot <- ggplot(
  macro_data,
  aes(
    x = End_Year,
    y = Percent
  )
) +
  geom_hline(
    yintercept = 0,
    linetype = "dashed"
  ) +
  geom_line(
    linewidth = 0.8
  ) +
  facet_wrap(
    ~ Indicator,
    ncol = 1,
    scales = "free_y"
  ) +
  labs(
    title = "Inflation and GDP Growth in Kenya",
    subtitle = "Annual percentage rates, 1975-2025",
    x = "Year",
    y = "Percent"
  ) +
  theme_classic()


print(
  macro_plot
)


ggsave(
  "Outputs/Plots/02_macro_controls_trends.png",
  macro_plot,
  width = 9,
  height = 7,
  dpi = 300
)


# ============================================================
# 8. Gini and sector correlations
# ============================================================

gini_correlations <- tibble(
  Variable = c(
    "Education",
    "Health",
    "Economic Affairs",
    "Inflation",
    "GDP Growth"
  ),
  
  Correlation_with_Gini = c(
    cor(
      analysis_sample$Gini_WID,
      analysis_sample$Education_Share
    ),
    
    cor(
      analysis_sample$Gini_WID,
      analysis_sample$Health_Share
    ),
    
    cor(
      analysis_sample$Gini_WID,
      analysis_sample$Economic_Affairs_Share
    ),
    
    cor(
      analysis_sample$Gini_WID,
      analysis_sample$Inflation_Percent
    ),
    
    cor(
      analysis_sample$Gini_WID,
      analysis_sample$GDP_Growth_Percent
    )
  )
)


cat("\nCorrelation with WID Gini\n")

print(
  gini_correlations
)


write_csv(
  gini_correlations,
  "Outputs/Descriptive/02_gini_correlations.csv"
)


cat("\nDescriptive analysis completed successfully.\n")