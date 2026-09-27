# Validate generated results against the reference run.
# This script stops with an error if a key result differs beyond tolerance.

suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
})

out_dir <- "results/generated"
ref_dir <- "results/reference"

tol_coef <- 1e-5
tol_desc <- 5e-4   # reference descriptives were printed to three decimals

a <- read_csv(file.path(out_dir, "Descriptive_Statistics_By_Treatment.csv"), show_col_types = FALSE)
e <- read_csv(file.path(ref_dir, "expected_descriptive_statistics.csv"), show_col_types = FALSE)

a2 <- a %>%
  transmute(
    Survey_Round = as.character(phase_f),
    Treatment_Group = as.character(treatment),
    N,
    Business_Participation_Rate,
    Baseline_Business_Rate
  )

merged_desc <- inner_join(e, a2, by = c("Survey_Round", "Treatment_Group"), suffix = c("_expected", "_actual"))
stopifnot(nrow(merged_desc) == 8)
stopifnot(all(merged_desc$N_expected == merged_desc$N_actual))
stopifnot(max(abs(merged_desc$Business_Participation_Rate_expected - merged_desc$Business_Participation_Rate_actual)) < tol_desc)
stopifnot(max(abs(merged_desc$Baseline_Business_Rate_expected - merged_desc$Baseline_Business_Rate_actual)) < tol_desc)

# Primary model coefficients / odds ratios
p <- read_csv(file.path(out_dir, "Table2_Primary_Logit.csv"), show_col_types = FALSE)
r <- read_csv(file.path(ref_dir, "expected_primary_model.csv"), show_col_types = FALSE)

m <- inner_join(r, p, by = c("Term" = "Predictor"), suffix = c("_expected", "_actual"))
stopifnot(nrow(m) == 5)
stopifnot(max(abs(m$Coefficient_expected - m$Coefficient_actual), na.rm = TRUE) < tol_coef)
stopifnot(max(abs(m$Cluster_Robust_SE_expected - m$Cluster_Robust_SE_actual), na.rm = TRUE) < tol_coef)
stopifnot(max(abs(m$Odds_Ratio_expected - m$Odds_Ratio_actual), na.rm = TRUE) < tol_coef)

# AMEs are rounded to four decimals in the archived raw output.
treat <- m %>% filter(Term %in% c("Capital", "Psychosocial", "Full"))
stopifnot(max(abs(treat$AME - treat$Average_Marginal_Effect), na.rm = TRUE) < 5e-4)

fit <- read_csv(file.path(out_dir, "Model_Fit.csv"), show_col_types = FALSE)
get_fit <- function(x) fit$Value[fit$Metric == x]
stopifnot(abs(get_fit("AIC") - 5248.232) < 1e-3)
stopifnot(abs(get_fit("Residual deviance") - 5126.232) < 1e-3)
stopifnot(abs(get_fit("Null deviance") - 5666.61) < 1e-2)
stopifnot(get_fit("Endline observations") == 4252)
stopifnot(get_fit("Endline clusters") == 320)

cat("Validation passed: generated results match the archived reference results within tolerance.\n")
