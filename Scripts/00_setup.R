# ============================================================
# PROJECT: Effect of Government Expenditure on Income Inequality
# SCRIPT: 00_setup.R
# PURPOSE: Project setup and import final WID master dataset
# ============================================================

setwd(
  "C:/Users/user/Desktop/02_Effect_of_govt_expenditure_on_income_inequality"
)

library(readr)
library(dplyr)
library(tidyr)
library(ggplot2)


main_data <- read_csv(
  "Data/Kenya_Sectoral_Public_Expenditure_and_WID_Income_Inequality_Dataset_1975_2025.csv",
  show_col_types = FALSE
)


cat(
  "Master dataset dimensions:",
  dim(main_data),
  "\n"
)

head(main_data)