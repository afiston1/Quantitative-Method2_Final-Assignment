# ============================================================
# REPLICATION ANALYSIS
# The Effect of Productive Inclusion Interventions on Women's
# Business Participation in Niger
# ============================================================

suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(sandwich)
  library(lmtest)
  library(margins)
  library(modelsummary)
})

# ---------- paths ----------
dir.create("results/generated", recursive = TRUE, showWarnings = FALSE)
dir.create("data/derived", recursive = TRUE, showWarnings = FALSE)

zip_candidates <- c(
  "data/raw/NER_2017-2020_ASPIE_v01_M_CSV.zip",
  "NER_2017-2020_ASPIE_v01_M_CSV.zip"
)
zip_file <- zip_candidates[file.exists(zip_candidates)][1]
if (is.na(zip_file)) {
  stop(
    "Raw data ZIP not found. Download NER_2017-2020_ASPIE_v01_M_CSV.zip ",
    "from the World Bank Microdata Library and place it in data/raw/."
  )
}

hh_file <- "NER_2017-2020_ASPIE_v01_M_CSV/allrounds_NER_hh.csv"
out_dir <- "results/generated"
raw_output <- file.path(out_dir, "Final_Project_Raw_Output.txt")

# ---------- raw output log ----------
sink(raw_output, split = TRUE)
on.exit({
  while (sink.number() > 0) sink()
}, add = TRUE)

cat("FINAL PROJECT RAW OUTPUT\n")
cat("The Effect of Productive Inclusion Interventions on Women's Business Participation in Niger\n")
cat("Quantitative technique: Binary Logistic Regression\n\n")
cat("R version:\n")
print(R.version.string)
cat("\nSession information:\n")
print(sessionInfo())

# ---------- data import ----------
hh <- read_csv(unz(zip_file, hh_file), show_col_types = FALSE)

cat("\n-----------------------------\n")
cat("DATA AUDIT\n")
cat("-----------------------------\n")
cat("Rows in allrounds_NER_hh:", nrow(hh), "\n")
cat("Columns in allrounds_NER_hh:", ncol(hh), "\n")
cat("Unique villages/clusters:", n_distinct(hh$cluster), "\n")
cat("Unique randomization strata:", n_distinct(hh$strata), "\n\n")

# ---------- analytical sample ----------
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

analysis_export <- analysis %>%
  select(
    phase, phase_f, hhid, treatment, cluster, strata,
    bus2_ben_dum, bus2_ben_dum_bl, bus2_ben_dum_bl_bd,
    equiv_n
  )

write_csv(analysis_export, "data/derived/Final_Project_Analysis_Data.csv")

# ---------- descriptive statistics ----------
cat("\n-----------------------------\n")
cat("DESCRIPTIVE STATISTICS\n")
cat("-----------------------------\n")
cat("\nTreatment counts - all follow-up observations:\n")
print(table(analysis$treatment))
cat("\nOutcome distribution - all follow-up observations:\n")
print(table(analysis$bus2_ben_dum))
print(prop.table(table(analysis$bus2_ben_dum)))

business_desc <- analysis %>%
  group_by(phase_f, treatment) %>%
  summarise(
    N = n(),
    Business_Participation_Rate = mean(bus2_ben_dum, na.rm = TRUE),
    Baseline_Business_Rate = mean(bus2_ben_dum_bl, na.rm = TRUE),
    .groups = "drop"
  )

cat("\nBusiness participation rates by treatment and phase:\n")
print(business_desc)
write_csv(business_desc, file.path(out_dir, "Descriptive_Statistics_By_Treatment.csv"))

# Paper Table 1, percentages rather than proportions
paper_table1 <- business_desc %>%
  mutate(
    Business_Participation_Percent = 100 * Business_Participation_Rate,
    Baseline_Business_Percent = 100 * Baseline_Business_Rate
  ) %>%
  select(
    Survey_Round = phase_f,
    Treatment_Group = treatment,
    N,
    Business_Participation_Percent,
    Baseline_Business_Percent
  )
write_csv(paper_table1, file.path(out_dir, "Table1_Descriptive_Statistics.csv"))

# ---------- midline / endline ----------
midline <- analysis %>% filter(phase == 1)
endline <- analysis %>% filter(phase == 2)

cat("\nMidline N:", nrow(midline), "\n")
cat("Endline N:", nrow(endline), "\n")
cat("Endline villages/clusters:", n_distinct(endline$cluster), "\n")

# ---------- logit models ----------
m1_end_unadjusted <- glm(
  bus2_ben_dum ~ treatment,
  data = endline,
  family = binomial(link = "logit")
)

m2_end_adjusted <- glm(
  bus2_ben_dum ~ treatment +
    bus2_ben_dum_bl +
    bus2_ben_dum_bl_bd +
    strata_f,
  data = endline,
  family = binomial(link = "logit")
)

m3_mid_adjusted <- glm(
  bus2_ben_dum ~ treatment +
    bus2_ben_dum_bl +
    bus2_ben_dum_bl_bd +
    strata_f,
  data = midline,
  family = binomial(link = "logit")
)

# Cluster-robust variance-covariance matrices (village = randomization unit)
V1 <- vcovCL(m1_end_unadjusted, cluster = endline$cluster, type = "HC1")
V2 <- vcovCL(m2_end_adjusted, cluster = endline$cluster, type = "HC1")
V3 <- vcovCL(m3_mid_adjusted, cluster = midline$cluster, type = "HC1")

ct1 <- coeftest(m1_end_unadjusted, vcov. = V1)
ct2 <- coeftest(m2_end_adjusted, vcov. = V2)
ct3 <- coeftest(m3_mid_adjusted, vcov. = V3)

cat("\n-----------------------------\n")
cat("PRIMARY ENDLINE LOGIT MODEL\n")
cat("Cluster-robust SE at village level\n")
cat("-----------------------------\n")
print(ct2)

cat("\n-----------------------------\n")
cat("MIDLINE ROBUSTNESS LOGIT MODEL\n")
cat("Cluster-robust SE at village level\n")
cat("-----------------------------\n")
print(ct3)

# Save coefficient tables
coef_to_df <- function(ct, model_name) {
  data.frame(
    Model = model_name,
    Term = rownames(ct),
    Coefficient = ct[, 1],
    Cluster_Robust_SE = ct[, 2],
    z = ct[, 3],
    p = ct[, 4],
    row.names = NULL
  )
}
coef_all <- bind_rows(
  coef_to_df(ct1, "Endline: Unadjusted"),
  coef_to_df(ct2, "Endline: Adjusted"),
  coef_to_df(ct3, "Midline: Adjusted")
)
write_csv(coef_all, file.path(out_dir, "Model_Coefficients.csv"))

# ---------- odds ratios ----------
coef_end <- coef(m2_end_adjusted)
se_end <- sqrt(diag(V2))
p_end <- ct2[, 4]

odds_ratio_table <- data.frame(
  Term = names(coef_end),
  Coefficient = coef_end,
  Cluster_Robust_SE = se_end,
  p = p_end[names(coef_end)],
  Odds_Ratio = exp(coef_end),
  OR_CI_Lower_95 = exp(coef_end - 1.96 * se_end),
  OR_CI_Upper_95 = exp(coef_end + 1.96 * se_end),
  row.names = NULL
)

odds_ratio_main <- odds_ratio_table %>%
  filter(
    grepl("^treatment", Term) |
      Term == "bus2_ben_dum_bl" |
      Term == "bus2_ben_dum_bl_bd"
  )

cat("\n-----------------------------\n")
cat("PRIMARY MODEL ODDS RATIOS\n")
cat("-----------------------------\n")
print(odds_ratio_main)
write_csv(odds_ratio_main, file.path(out_dir, "Primary_Model_Odds_Ratios.csv"))

# ---------- average marginal effects ----------
ame_end <- margins(m2_end_adjusted, variables = "treatment", vcov = V2)
ame_end_df <- as.data.frame(summary(ame_end))

cat("\n-----------------------------\n")
cat("AVERAGE MARGINAL EFFECTS - ENDLINE\n")
cat("-----------------------------\n")
print(summary(ame_end))
write_csv(ame_end_df, file.path(out_dir, "Primary_Model_Average_Marginal_Effects.csv"))

ame_mid <- margins(m3_mid_adjusted, variables = "treatment", vcov = V3)
ame_mid_df <- as.data.frame(summary(ame_mid))

cat("\n-----------------------------\n")
cat("AVERAGE MARGINAL EFFECTS - MIDLINE\n")
cat("-----------------------------\n")
print(summary(ame_mid))
write_csv(ame_mid_df, file.path(out_dir, "Midline_Average_Marginal_Effects.csv"))

# ---------- paper Table 2 ----------
# Merge treatment/baseline coefficient information, ORs, and treatment AMEs.
term_labels <- c(
  treatmentCapital = "Capital",
  treatmentPsychosocial = "Psychosocial",
  treatmentFull = "Full",
  bus2_ben_dum_bl = "Baseline business participation",
  bus2_ben_dum_bl_bd = "Missing baseline indicator"
)

main_ct <- coef_to_df(ct2, "Endline: Adjusted") %>%
  filter(Term %in% names(term_labels)) %>%
  mutate(Predictor = unname(term_labels[Term]))

ame_lookup <- ame_end_df %>%
  transmute(
    Term = factor,
    Average_Marginal_Effect = AME,
    AME_SE = SE,
    AME_p = p,
    AME_CI_Lower_95 = lower,
    AME_CI_Upper_95 = upper
  )

paper_table2 <- main_ct %>%
  left_join(
    odds_ratio_main %>% select(Term, Odds_Ratio, OR_CI_Lower_95, OR_CI_Upper_95),
    by = "Term"
  ) %>%
  left_join(ame_lookup, by = "Term") %>%
  select(
    Predictor, Coefficient, Cluster_Robust_SE, p,
    Odds_Ratio, OR_CI_Lower_95, OR_CI_Upper_95,
    Average_Marginal_Effect, AME_SE, AME_p,
    AME_CI_Lower_95, AME_CI_Upper_95
  )
write_csv(paper_table2, file.path(out_dir, "Table2_Primary_Logit.csv"))

# ---------- regression table ----------
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
  output = file.path(out_dir, "Regression_Table.html"),
  title = "Logistic Regression Predicting Beneficiary Business Participation"
)

cat("\n-----------------------------\n")
cat("REGRESSION TABLE\n")
cat("-----------------------------\n")
print(modelsummary(
  models,
  vcov = vcovs,
  coef_omit = "strata_f",
  stars = c("*" = .05, "**" = .01, "***" = .001),
  gof_omit = "IC|Log.Lik.|RMSE",
  output = "data.frame"
))

# ---------- model fit ----------
fit <- data.frame(
  Metric = c(
    "AIC", "Residual deviance", "Null deviance",
    "Endline observations", "Endline clusters"
  ),
  Value = c(
    AIC(m2_end_adjusted),
    deviance(m2_end_adjusted),
    m2_end_adjusted$null.deviance,
    nobs(m2_end_adjusted),
    n_distinct(endline$cluster)
  )
)
write_csv(fit, file.path(out_dir, "Model_Fit.csv"))

cat("\n-----------------------------\n")
cat("MODEL FIT INFORMATION\n")
cat("-----------------------------\n")
cat("Primary endline model AIC:", AIC(m2_end_adjusted), "\n")
cat("Primary endline model residual deviance:", deviance(m2_end_adjusted), "\n")
cat("Primary endline model null deviance:", m2_end_adjusted$null.deviance, "\n")
cat("Primary endline model observations:", nobs(m2_end_adjusted), "\n")

cat("\nAnalysis completed successfully.\n")
cat("Generated outputs are in results/generated/.\n")

sink()
