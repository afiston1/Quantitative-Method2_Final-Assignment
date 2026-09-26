# ============================================================
# FINAL PROJECT - QUANTITATIVE RESEARCH
# Productive Inclusion and Women's Entrepreneurship in Niger
# Method: Binary Logistic Regression (Logit)
# Data: World Bank / DIME Niger Adaptive Safety Nets Program
# ============================================================

# ---------------------------
# 0. Packages
# ---------------------------
required_packages <- c(
  "readr", "dplyr", "sandwich", "lmtest",
  "margins", "modelsummary"
)

installed <- rownames(installed.packages())
to_install <- setdiff(required_packages, installed)

if (length(to_install) > 0) {
  install.packages(to_install, dependencies = TRUE)
}

library(readr)
library(dplyr)
library(sandwich)
library(lmtest)
library(margins)
library(modelsummary)

# ---------------------------
# 1. Start raw-output capture
# ---------------------------
sink("Final_Project_Raw_Output.txt", split = TRUE)

cat("FINAL PROJECT RAW OUTPUT\n")
cat("Productive Inclusion and Women's Entrepreneurship in Niger\n")
cat("Quantitative technique: Binary Logistic Regression\n\n")
cat("R version:\n")
print(R.version.string)
cat("\nSession information:\n")
print(sessionInfo())

# ---------------------------
# 2. Import data directly from ZIP
# ---------------------------
zip_file <- "NER_2017-2020_ASPIE_v01_M_CSV.zip"
hh_file <- "NER_2017-2020_ASPIE_v01_M_CSV/allrounds_NER_hh.csv"

hh <- read_csv(
  unz(zip_file, hh_file),
  show_col_types = FALSE
)

cat("\n-----------------------------\n")
cat("DATA AUDIT\n")
cat("-----------------------------\n")
cat("Rows in allrounds_NER_hh:", nrow(hh), "\n")
cat("Columns in allrounds_NER_hh:", ncol(hh), "\n")
cat("Unique villages/clusters:", n_distinct(hh$cluster), "\n")
cat("Unique randomization strata:", n_distinct(hh$strata), "\n\n")

# ---------------------------
# 3. Prepare analysis variables
# ---------------------------
analysis <- hh %>%
  mutate(
    treatment = factor(
      treatment,
      levels = c(0, 1, 2, 3),
      labels = c("Control", "Capital", "Psychosocial", "Full")
    ),
    phase_f = factor(
      phase,
      levels = c(1, 2),
      labels = c("Midline", "Endline")
    ),
    strata_f = factor(strata)
  ) %>%
  filter(
    !is.na(bus2_ben_dum),
    !is.na(treatment),
    !is.na(cluster),
    !is.na(strata_f),
    !is.na(bus2_ben_dum_bl),
    !is.na(bus2_ben_dum_bl_bd)
  )

# Save a compact analysis dataset for submission/reproducibility
analysis_export <- analysis %>%
  select(
    phase, phase_f, hhid, treatment, cluster, strata,
    bus2_ben_dum, bus2_ben_dum_bl, bus2_ben_dum_bl_bd,
    equiv_n
  )

write_csv(analysis_export, "Final_Project_Analysis_Data.csv")

# ---------------------------
# 4. Descriptive statistics
# ---------------------------
cat("\n-----------------------------\n")
cat("DESCRIPTIVE STATISTICS\n")
cat("-----------------------------\n")

cat("\nTreatment counts - all follow-up observations:\n")
print(table(analysis$treatment))

cat("\nOutcome distribution - all follow-up observations:\n")
print(table(analysis$bus2_ben_dum))
print(prop.table(table(analysis$bus2_ben_dum)))

cat("\nBusiness ownership rates by treatment and phase:\n")
desc <- analysis %>%
  group_by(phase_f, treatment) %>%
  summarise(
    N = n(),
    Business_Ownership_Rate = mean(bus2_ben_dum, na.rm = TRUE),
    Baseline_Business_Rate = mean(bus2_ben_dum_bl, na.rm = TRUE),
    .groups = "drop"
  )

print(desc)
write_csv(desc, "Descriptive_Statistics_By_Treatment.csv")

# ---------------------------
# 5. Create midline and endline samples
# ---------------------------
midline <- analysis %>% filter(phase == 1)
endline <- analysis %>% filter(phase == 2)

cat("\nMidline N:", nrow(midline), "\n")
cat("Endline N:", nrow(endline), "\n")
cat("Endline villages/clusters:", n_distinct(endline$cluster), "\n")

# ---------------------------
# 6. Primary Logit models
# ---------------------------

# Model 1: Endline, treatment only
m1_end_unadjusted <- glm(
  bus2_ben_dum ~ treatment,
  data = endline,
  family = binomial(link = "logit")
)

# Model 2: PRIMARY MODEL
# Endline + baseline outcome + missing-baseline indicator + randomization strata
m2_end_adjusted <- glm(
  bus2_ben_dum ~ treatment +
    bus2_ben_dum_bl +
    bus2_ben_dum_bl_bd +
    strata_f,
  data = endline,
  family = binomial(link = "logit")
)

# Model 3: Robustness / earlier follow-up
m3_mid_adjusted <- glm(
  bus2_ben_dum ~ treatment +
    bus2_ben_dum_bl +
    bus2_ben_dum_bl_bd +
    strata_f,
  data = midline,
  family = binomial(link = "logit")
)

# ---------------------------
# 7. Cluster-robust standard errors
#    Cluster at village, the unit of randomization
# ---------------------------
V1 <- vcovCL(m1_end_unadjusted, cluster = endline$cluster, type = "HC1")
V2 <- vcovCL(m2_end_adjusted, cluster = endline$cluster, type = "HC1")
V3 <- vcovCL(m3_mid_adjusted, cluster = midline$cluster, type = "HC1")

cat("\n-----------------------------\n")
cat("PRIMARY ENDLINE LOGIT MODEL\n")
cat("Cluster-robust SE at village level\n")
cat("-----------------------------\n")
print(coeftest(m2_end_adjusted, vcov. = V2))

cat("\n-----------------------------\n")
cat("MIDLINE ROBUSTNESS LOGIT MODEL\n")
cat("Cluster-robust SE at village level\n")
cat("-----------------------------\n")
print(coeftest(m3_mid_adjusted, vcov. = V3))

# ---------------------------
# 8. Odds ratios for primary model
# ---------------------------
coef_end <- coef(m2_end_adjusted)
se_end <- sqrt(diag(V2))

odds_ratio_table <- data.frame(
  Term = names(coef_end),
  Coefficient = coef_end,
  Cluster_Robust_SE = se_end,
  Odds_Ratio = exp(coef_end),
  OR_CI_Lower_95 = exp(coef_end - 1.96 * se_end),
  OR_CI_Upper_95 = exp(coef_end + 1.96 * se_end),
  row.names = NULL
)

odds_ratio_main <- odds_ratio_table %>%
  filter(grepl("^treatment", Term) |
           Term == "bus2_ben_dum_bl" |
           Term == "bus2_ben_dum_bl_bd")

cat("\n-----------------------------\n")
cat("PRIMARY MODEL ODDS RATIOS\n")
cat("-----------------------------\n")
print(odds_ratio_main)

write_csv(odds_ratio_main, "Primary_Model_Odds_Ratios.csv")

# ---------------------------
# 9. Average marginal effects
# ---------------------------
ame_end <- margins(
  m2_end_adjusted,
  variables = "treatment",
  vcov = V2
)

cat("\n-----------------------------\n")
cat("AVERAGE MARGINAL EFFECTS - ENDLINE\n")
cat("-----------------------------\n")
print(summary(ame_end))

write_csv(
  as.data.frame(summary(ame_end)),
  "Primary_Model_Average_Marginal_Effects.csv"
)

ame_mid <- margins(
  m3_mid_adjusted,
  variables = "treatment",
  vcov = V3
)

cat("\n-----------------------------\n")
cat("AVERAGE MARGINAL EFFECTS - MIDLINE\n")
cat("-----------------------------\n")
print(summary(ame_mid))

# ---------------------------
# 10. Regression table for paper/appendix
# ---------------------------
models <- list(
  "Endline: Unadjusted" = m1_end_unadjusted,
  "Endline: Adjusted" = m2_end_adjusted,
  "Midline: Adjusted" = m3_mid_adjusted
)

vcovs <- list(V1, V2, V3)

modelsummary(
  models,
  vcov = vcovs,
  coef_omit = "strata_f",
  stars = c("*" = .05, "**" = .01, "***" = .001),
  gof_omit = "IC|Log.Lik.|RMSE",
  output = "Regression_Table.html",
  title = "Logistic Regression Predicting Beneficiary Business Ownership"
)

# Also save a plain-text/markdown-style table in the raw output
cat("\n-----------------------------\n")
cat("REGRESSION TABLE\n")
cat("-----------------------------\n")
print(
  modelsummary(
    models,
    vcov = vcovs,
    coef_omit = "strata_f",
    stars = c("*" = .05, "**" = .01, "***" = .001),
    gof_omit = "IC|Log.Lik.|RMSE",
    output = "data.frame"
  )
)

# ---------------------------
# 11. Model diagnostics / fit information
# ---------------------------
cat("\n-----------------------------\n")
cat("MODEL FIT INFORMATION\n")
cat("-----------------------------\n")

cat("Primary endline model AIC:", AIC(m2_end_adjusted), "\n")
cat("Primary endline model residual deviance:", deviance(m2_end_adjusted), "\n")
cat("Primary endline model null deviance:", m2_end_adjusted$null.deviance, "\n")
cat("Primary endline model observations:", nobs(m2_end_adjusted), "\n")

# ---------------------------
# 12. End raw-output capture
# ---------------------------
cat("\nAnalysis completed successfully.\n")
cat("Files created:\n")
cat("- Final_Project_Raw_Output.txt\n")
cat("- Final_Project_Analysis_Data.csv\n")
cat("- Descriptive_Statistics_By_Treatment.csv\n")
cat("- Primary_Model_Odds_Ratios.csv\n")
cat("- Primary_Model_Average_Marginal_Effects.csv\n")
cat("- Regression_Table.html\n")

sink()
