# ============================================================
# 01_data_audit.R
# Check the structure and completeness of the master dataset
# ============================================================

source("Scripts/00_setup.R")


# Dataset dimensions
cat("\nDataset dimensions\n")
cat("Rows:", nrow(main_data), "\n")
cat("Columns:", ncol(main_data), "\n")


# Column names
cat("\nColumn names\n")
print(names(main_data))


# Check year coverage
cat("\nYear coverage\n")
cat(
  "From",
  min(main_data$End_Year),
  "to",
  max(main_data$End_Year),
  "\n"
)


# Check duplicate years
duplicate_years <- main_data |>
  filter(
    duplicated(End_Year) |
      duplicated(End_Year, fromLast = TRUE)
  )

cat(
  "\nDuplicate years:",
  nrow(duplicate_years),
  "\n"
)


# Missing values by variable
missing_summary <- main_data |>
  summarise(
    across(
      everything(),
      ~ sum(is.na(.))
    )
  ) |>
  pivot_longer(
    cols = everything(),
    names_to = "Variable",
    values_to = "Missing_Values"
  )

cat("\nMissing values\n")
print(missing_summary)


# Years without WID Gini
missing_gini_years <- main_data |>
  filter(
    is.na(Gini_WID)
  ) |>
  select(
    Financial_Year,
    End_Year,
    Gini_WID
  )

cat("\nYears with missing WID Gini\n")
print(missing_gini_years)


# Numeric variable summary
variable_summary <- main_data |>
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
        Observations = ~ sum(!is.na(.)),
        Missing = ~ sum(is.na(.)),
        Mean = ~ mean(., na.rm = TRUE),
        SD = ~ sd(., na.rm = TRUE),
        Minimum = ~ min(., na.rm = TRUE),
        Maximum = ~ max(., na.rm = TRUE)
      )
    )
  ) |>
  pivot_longer(
    cols = everything(),
    names_to = c("Variable", ".value"),
    names_pattern =
      "(.*)_(Observations|Missing|Mean|SD|Minimum|Maximum)"
  )

cat("\nVariable summary\n")
print(
  variable_summary,
  n = Inf
)


# Check expenditure shares
invalid_shares <- main_data |>
  filter(
    Education_Share < 0 |
      Education_Share > 100 |
      Health_Share < 0 |
      Health_Share > 100 |
      Economic_Affairs_Share < 0 |
      Economic_Affairs_Share > 100
  )

cat(
  "\nInvalid expenditure-share rows:",
  nrow(invalid_shares),
  "\n"
)


# Check Gini range
invalid_gini <- main_data |>
  filter(
    !is.na(Gini_WID) &
      (Gini_WID < 0 | Gini_WID > 1)
  )

cat(
  "Invalid WID Gini rows:",
  nrow(invalid_gini),
  "\n"
)


# Final dataset checks
stopifnot(
  nrow(main_data) == 51,
  length(unique(main_data$End_Year)) == 51,
  all(main_data$End_Year == 1975:2025),
  sum(is.na(main_data$Gini_WID)) == 6,
  nrow(invalid_shares) == 0,
  nrow(invalid_gini) == 0
)


# Save audit outputs
write_csv(
  missing_summary,
  "Outputs/Descriptive/01_missing_values_summary.csv"
)

write_csv(
  variable_summary,
  "Outputs/Descriptive/01_variable_summary.csv"
)

write_csv(
  missing_gini_years,
  "Outputs/Descriptive/01_missing_wid_gini_years.csv"
)


cat("\nData audit completed successfully.\n")