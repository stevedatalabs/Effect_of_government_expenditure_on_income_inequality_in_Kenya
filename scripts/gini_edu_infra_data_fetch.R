library(WDI)
library(tidyverse)
library(zoo)

# 1. Pull Inequality and Public Expenditure indicators together
raw_data <- WDI(
  country = "KE",
  indicator = c(
    "Gini" = "SI.POV.GINI",          # Income Inequality Index
    "Education" = "SE.XPD.TOTL.GD.ZS", # Education Spending (% of GDP)
    "Infra" = "NE.GDI.FTOT.ZS"       # Capital/Infrastructure Investment (% of GDP)
  ),
  start = 1975,
  end = 2024
) %>% 
  rename(Year = year) %>%
  select(Year, Gini, Education, Infra)

# 2. Build our explicit 50-Year skeletal frame
timeline <- data.frame(Year = 1975:2024)

# 3. Left Join by "Year" ensures perfect dimensional mapping (50 rows)
clean_thesis_data <- timeline %>%
  left_join(raw_data, by = "Year") %>%
  arrange(Year)

# 4. Apply explicit statistical interpolation directly to the columns
clean_thesis_data <- clean_thesis_data %>%
  mutate(
    # Bounded interpolation to smooth gaps between actual data collection cycles
    Estimated_Gini = na.approx(Gini, na.rm = FALSE),
    Estimated_Edu  = na.approx(Education, na.rm = FALSE),
    Estimated_Infra = na.approx(Infra, na.rm = FALSE)
  ) %>%
  # Apply directional padding to clear out early baseline periods and the modern 2023-2024 margins
  mutate(
    Estimated_Gini  = na.locf(na.locf(Estimated_Gini, fromLast = TRUE, na.rm = FALSE), fromLast = FALSE, na.rm = FALSE),
    Estimated_Edu   = na.locf(na.locf(Estimated_Edu, fromLast = TRUE, na.rm = FALSE), fromLast = FALSE, na.rm = FALSE),
    Estimated_Infra = na.locf(na.locf(Estimated_Infra, fromLast = TRUE, na.rm = FALSE), fromLast = FALSE, na.rm = FALSE)
  ) %>%
  # Round everything cleanly to 2 decimal places
  mutate(
    Estimated_Gini  = round(Estimated_Gini, 2),
    Estimated_Edu   = round(Estimated_Edu, 2),
    Estimated_Infra = round(Estimated_Infra, 2)
  ) %>%
  select(Year, Estimated_Gini, Estimated_Edu, Estimated_Infra)

# 5. Open the final matrix
View(clean_thesis_data)