# Computational methods

## Analysis sequence

1. Read the World Bank public-use household follow-up file directly from the downloaded ZIP archive.
2. Recode treatment and survey-round indicators as factors.
3. Retain observations with non-missing business ownership, treatment, village cluster, randomization stratum, baseline business ownership, and baseline-missing indicator.
4. Produce treatment-by-round descriptive statistics.
5. Estimate three binary Logit models:
   - Endline, unadjusted: treatment indicators only.
   - Endline, adjusted (primary): treatment + baseline outcome + baseline-missing indicator + randomization-strata fixed effects.
   - Midline, adjusted: same adjustment set, used as a robustness check.
6. Compute HC1 cluster-robust variance-covariance matrices clustered by village using `sandwich::vcovCL()`.
7. Report Logit coefficients and clustered standard errors with `lmtest::coeftest()`.
8. Exponentiate coefficients to obtain odds ratios and Wald 95% confidence intervals.
9. Compute average marginal effects for treatment indicators using `margins::margins()` with the clustered variance-covariance matrix.
10. Export paper-ready descriptive and primary-model tables, a full regression table, model-fit information, and the complete raw output log.

## Interpretation

- Logit coefficients are changes in log-odds relative to the Control arm.
- Odds ratios above 1 indicate higher odds of business ownership relative to Control.
- Average marginal effects are changes in predicted probability and are most easily communicated as percentage points.
- The primary model tests each treatment arm against Control; it does not by itself test pairwise differences among Capital, Psychosocial, and Full.

## Reference results

The archived reference run was executed in R 4.6.0 on macOS arm64. Exact package versions are listed in `environment/install_packages.R` and the archived raw output is in `results/reference/Final_Project_Raw_Output.txt`.
