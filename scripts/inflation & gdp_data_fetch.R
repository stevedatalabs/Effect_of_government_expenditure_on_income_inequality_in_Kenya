library(WDI)
library(tidyverse)

# Fetching the data
raw_wb_data <- WDI(
  country = "KE", 
  indicator = c("NY.GDP.MKTP.KD.ZG", "FP.CPI.TOTL.ZG"), 
  start = 1975, 
  end = 2024
)

# Formatting the columns
wb_controls <- raw_wb_data %>%
  select(
    Year = year, 
    GDP_Growth = NY.GDP.MKTP.KD.ZG, 
    Inflation_Rate = FP.CPI.TOTL.ZG
  ) %>%
  arrange(Year)

# View the dataset in a nice interactive grid window
View(wb_controls)
