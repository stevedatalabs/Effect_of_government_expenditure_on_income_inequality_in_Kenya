# ============================================================
# 03_stationarity_tests.R
# Test the integration order of the model variables
# ============================================================

source("Scripts/00_setup.R")

library(urca)


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
    GDP_Growth = GDP_Growth_Percent
  )


cat(
  "\nStationarity sample:",
  min(analysis_data$Year),
  "-",
  max(analysis_data$Year),
  "\nObservations:",
  nrow(analysis_data),
  "\n"
)


# ADF test
run_adf <- function(x, transformation) {
  
  if (transformation == "Level") {
    type <- "trend"
    tau <- "tau3"
  } else if (transformation == "First Difference") {
    type <- "drift"
    tau <- "tau2"
  } else {
    type <- "none"
    tau <- "tau1"
  }
  
  test <- ur.df(
    x,
    type = type,
    lags = 4,
    selectlags = "AIC"
  )
  
  statistic <- as.numeric(
    test@teststat[1, tau]
  )
  
  critical <- as.numeric(
    test@cval[tau, "5pct"]
  )
  
  tibble(
    ADF_Statistic = statistic,
    ADF_Critical_5pct = critical,
    ADF_Stationary = statistic < critical
  )
}


# Phillips-Perron test
run_pp <- function(x, transformation) {
  
  model <- ifelse(
    transformation == "Level",
    "trend",
    "constant"
  )
  
  test <- ur.pp(
    x,
    type = "Z-tau",
    model = model,
    lags = "short"
  )
  
  statistic <- as.numeric(
    test@teststat
  )
  
  critical <- as.numeric(
    test@cval[1, "5pct"]
  )
  
  tibble(
    PP_Statistic = statistic,
    PP_Critical_5pct = critical,
    PP_Stationary = statistic < critical
  )
}


# KPSS test
run_kpss <- function(x, transformation) {
  
  type <- ifelse(
    transformation == "Level",
    "tau",
    "mu"
  )
  
  test <- ur.kpss(
    x,
    type = type,
    lags = "short"
  )
  
  statistic <- as.numeric(
    test@teststat
  )
  
  critical <- as.numeric(
    test@cval[1, "5pct"]
  )
  
  tibble(
    KPSS_Statistic = statistic,
    KPSS_Critical_5pct = critical,
    KPSS_Stationary = statistic < critical
  )
}


# Run all three tests
test_series <- function(x, variable) {
  
  series <- list(
    "Level" = x,
    "First Difference" = diff(x),
    "Second Difference" = diff(x, differences = 2)
  )
  
  bind_rows(
    lapply(
      names(series),
      function(transformation) {
        
        values <- na.omit(
          series[[transformation]]
        )
        
        bind_cols(
          tibble(
            Variable = variable,
            Transformation = transformation,
            Observations = length(values)
          ),
          run_adf(values, transformation),
          run_pp(values, transformation),
          run_kpss(values, transformation)
        ) |>
          mutate(
            Stationarity_Score =
              ADF_Stationary +
              PP_Stationary +
              KPSS_Stationary,
            
            Consensus_Stationary =
              Stationarity_Score >= 2
          )
      }
    )
  )
}


variables <- c(
  "Gini",
  "Education",
  "Health",
  "Economic_Affairs",
  "Inflation",
  "GDP_Growth"
)


stationarity_results <- bind_rows(
  lapply(
    variables,
    function(variable) {
      test_series(
        analysis_data[[variable]],
        variable
      )
    }
  )
)


cat("\nUnit root test results\n")

print(
  stationarity_results,
  n = Inf,
  width = Inf
)


# Integration order
integration_summary <- stationarity_results |>
  select(
    Variable,
    Transformation,
    Consensus_Stationary
  ) |>
  pivot_wider(
    names_from = Transformation,
    values_from = Consensus_Stationary
  ) |>
  mutate(
    Integration_Order = case_when(
      Level ~ "I(0)",
      !Level & `First Difference` ~ "I(1)",
      !Level &
        !`First Difference` &
        `Second Difference` ~ "Possible I(2)",
      TRUE ~ "Inconclusive"
    )
  )


cat("\nIntegration summary\n")

print(
  integration_summary,
  n = Inf,
  width = Inf
)


# Save results
write_csv(
  stationarity_results,
  "Outputs/Stationarity/03_unit_root_tests.csv"
)

write_csv(
  integration_summary,
  "Outputs/Stationarity/03_integration_summary.csv"
)


if (
  any(
    integration_summary$Integration_Order ==
    "Possible I(2)"
  )
) {
  
  cat(
    "\nPossible I(2) variable detected.\n"
  )
  
} else {
  
  cat(
    "\nNo I(2) variables detected.\n"
  )
}


cat("\nStationarity testing completed.\n")