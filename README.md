# Effect of Disaggregated Sectoral Public Expenditure on Income Inequality in Kenya

**Economic Analysis | R | Time-Series Modelling | Public Policy Analytics**

This independent portfolio project studies how Kenya's spending priorities in **Education**, **Health** and **Economic Affairs** are associated with national income inequality over time. It combines a cleaned multi-decade dataset, a full research paper, reproducible R scripts, diagnostic checks and visual outputs so that a reader can move from the headline question to the evidence behind it.

The project was developed by **Isaac Steve Njuguna** as part of an independent portfolio in economic analysis, data analytics and quantitative research.

## Research Question

Kenya has continued to invest public resources in social services and productive sectors, yet income inequality remains a major policy concern. This project asks:

> How are changes in Kenya's Education, Health and Economic Affairs expenditure shares associated with income inequality in the short term and over the longer term?

The focus is not simply whether government spends more. The project looks at whether the **composition of spending** matters, and whether spending in different sectors appears to move together with inequality in different ways.

## Data

The master dataset covers **1975-2025** and contains 51 annual observations. The final modelling sample uses **45 observations from 1980-2024**, because that is the period with consistent World Inequality Database Gini data.

| Area | Measure |
|---|---|
| Income inequality | WID Gini coefficient |
| Public spending | Education, Health and Economic Affairs shares of total government expenditure |
| Wider economy | Inflation and GDP growth |
| Main sources | WID Gini data, Kenya National Bureau of Statistics historical expenditure publications, and macroeconomic series used in the study |

Key files: [master dataset](data/Kenya_Sectoral_Public_Expenditure_and_WID_Income_Inequality_Dataset_1975_2025.csv), [data audit](Outputs/Descriptive/01_variable_summary.csv), [summary statistics](Outputs/Descriptive/02_summary_statistics.csv).

## Workflow

The analysis follows a clear, numbered R workflow:

| Step | Script | What it does |
|---|---|---|
| 00 | [setup](Scripts/00_setup.R) | Loads packages and imports the master dataset |
| 01 | [data audit](Scripts/01_data_audit.R) | Checks coverage, missing values, duplicates and variable ranges |
| 02 | [descriptive analysis](Scripts/02_descriptive_analysis.R) | Creates summary tables, correlations and trend charts |
| 03 | [stationarity tests](Scripts/03_stationarity_test.R) | Checks whether each series can be used in the time-based model |
| 04 | [structural breaks analysis](Scripts/04_structural_break_tests.R) | Finds major shifts in the inequality series |
| 05 | [main ARDL model](Scripts/05_ardl_analysis.R) | Selects and estimates the main ARDL model |
| 06 | [diagnostics](Scripts/06_ardl_diagnostics.R) | Tests model fit, residuals and stability |
| 07 | [long/short run effects summary](Scripts/07_long_short_run_effects.R) | Saves short-term and longer-term result tables |
| 08 | [robustness model](Scripts/08_robustness_without_gdp_growth.R) | Repeats the model without GDP growth |

In plain terms, the workflow cleans and checks the data, explores historical trends, tests whether the data are suitable for time-based modelling thru stationarity tests, identifies major shifts in the inequality series, estimates the main model, checks whether the model behaves reliably thru diagnostics, then repeats the analysis without GDP growth for robustness check.

The selected main model is **ARDL(1,1,0,0,1,1)** with break indicators for new inequality regimes beginning in **1993**, **2007** and **2019**. Its adjustment estimate is approximately **-0.577**, meaning around **57.7%** of a short-term gap from the longer-term pattern is corrected within one year.

## Key Findings

The structural-break-adjusted ARDL model identifies a **stable long-run relationship** between income inequality, sectoral public expenditure and Kenya's wider macroeconomic conditions. The results are interpreted as **statistical associations rather than causal effects**.

### Econometric Evidence

- **Cointegration confirmed:** the bounds test produced an F-statistic of **23.287** and t-statistic of **-6.010** (`p < 0.001`), providing strong evidence of a long-run relationship among the variables.
- **Rapid long-run adjustment:** the error-correction coefficient was **-0.577** (`p < 0.001`), implying that approximately **57.7% of a short-run deviation from long-run equilibrium is corrected within one year**.
- **Structural change matters:** inequality regime shifts beginning in **1993, 2007 and 2019** were incorporated into the final model rather than treating the entire 1980-2024 period as structurally unchanged.

| Variable | Short-Run Effect | Long-Run Effect | Main Interpretation |
|---|---:|---:|---|
| **Education expenditure** | **+0.180** (`p = 0.0167`) | **+0.571** (`p = 0.0003`) | The strongest and most robust sectoral result. A larger Education share was associated with higher inequality in both horizons. The relationship remained positive and statistically significant when GDP growth was excluded. |
| **Health expenditure** | +0.255 (`p = 0.132`) | +0.442 (`p = 0.137`) | Not statistically significant in the main model. However, the long-run coefficient increased to approximately **+0.812 and became statistically significant** when GDP growth was excluded, indicating specification sensitivity. |
| **Economic Affairs expenditure** | -0.032 (`p = 0.473`) | -0.056 (`p = 0.480`) | Consistently inequality-reducing in direction, but not statistically significant. Without GDP growth, the long-run coefficient strengthened to approximately **-0.224**, although it remained below conventional significance. |
| **Inflation** | +0.024 (`p = 0.341`) | -0.053 (`p = 0.369`) | No statistically reliable independent relationship with inequality was identified in either horizon. |
| **GDP growth** | +0.020 (`p = 0.756`) | **-0.353** (`p = 0.0296`) | No immediate distributional effect was detected, but stronger growth was associated with lower inequality in the long run. |

> **Interpretation:** Expenditure variables are measured as shares of total government expenditure. Their coefficients therefore capture changes in the **composition of public spending**, not changes in absolute expenditure. Effects are reported in Gini index points.

### What the Results Suggest

The central finding is that **larger sectoral budget shares do not automatically translate into lower inequality**.

Education produced the clearest result: its positive association with inequality remained statistically significant across both the main and robustness specifications. This does not imply that education itself increases inequality. Instead, it points to the importance of **who benefits from expenditure, how resources are distributed within the sector, institutional efficiency and whether educational investment translates into broad-based labour-market opportunities**.

Health was more sensitive to model specification, while Economic Affairs maintained an inequality-reducing direction without reaching statistical significance. GDP growth, by contrast, showed no measurable short-run distributional effect but was associated with lower inequality over the longer term.

Taken together, the evidence suggests that the distributional impact of public expenditure depends not only on **how much is allocated**, but also on **targeting, accessibility, implementation quality, institutional efficiency and the ability of public investment to generate broad-based productivity, employment and income gains**.




## Skills Demonstrated

- **R programming:** an end-to-end workflow using `readr`, `dplyr`, `tidyr`, `ggplot2`, `urca`, `strucchange`, `ARDL`, `lmtest` and `tseries`.
- **Econometrics & Statistical Inference:** applied time-series econometric methods including stationarity testing, structural-break analysis, ARDL modelling, bounds testing, error-correction modelling, coefficient interpretation, p-values and significance testing.

- **Hypothesis Testing:** formulated and tested sector-specific null hypotheses for Education, Health and Economic Affairs expenditure, evaluating short-run and long-run relationships separately using estimated coefficients, test statistics and p-values at the 5% significance level.

- **Model Diagnostics & Robustness:** assessed serial correlation, heteroskedasticity, residual normality, functional form and parameter stability, and conducted a robustness specification excluding GDP growth to test the sensitivity of the main findings.

- **Economic & Public Policy Analysis:** interpreted econometric results in the context of public expenditure composition, income inequality, economic growth and policy effectiveness, while distinguishing statistical association from causal inference.

- **Reproducible Research:** organised the analysis into a structured R workflow linking data preparation, estimation, diagnostics, robustness checks, saved outputs and supporting documentation, allowing the analytical process to be traced from source data to final results.

## Repository Guide

| Item | Link |
|---|---|
| Full research paper | [PDF](Effect%20of%20Disaggregated%20Sectoral%20Public%20Expenditure%20on%20Income%20Inequality%20in%20Kenya.pdf) |
| Editable report | [DOCX](Effect%20of%20Disaggregated%20Sectoral%20Public%20Expenditure%20on%20Income%20Inequality%20in%20Kenya.docx) |
| Master dataset | [CSV](data/Kenya_Sectoral_Public_Expenditure_and_WID_Income_Inequality_Dataset_1975_2025.csv) |
| R scripts | [Scripts folder](Scripts/) |
| Output tables | [Outputs folder](Outputs/) |
| Plots | [Plots folder](Outputs/Plots/) |
| Main model results | [Short-run and long-run effects](Outputs/ARDL/07_long_short_run_effects.csv) |
| Robustness comparison | [Main model versus no GDP growth](Outputs/ARDL/08_main_vs_no_gdp_growth.csv) |
| Diagnostics | [Diagnostic tests](Outputs/ARDL/06_diagnostic_tests.csv) |

## Reproducibility

Open the repository in RStudio, confirm the local path in [`Scripts/00_setup.R`](Scripts/00_setup.R), then run the numbered scripts from `00` to `08`. The scripts recreate the descriptive tables, plots, model outputs, diagnostics and robustness tables stored in `Outputs/`.

## Limitations

The final model uses 45 annual observations, so the analysis is intentionally compact. The expenditure categories are broad, especially Economic Affairs. Spending shares do not directly measure service quality, efficiency, leakage or who actually benefits. The national Gini coefficient also cannot show county-level, household-level or demographic differences. For that reason, the project is careful to report associations rather than claim definitive cause-and-effect results.
