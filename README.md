# Productive Inclusion and Women's Business Ownership in Niger — Replication Package

This repository reproduces the calculations for the study:

> **The Effect of Productive Inclusion Interventions on Women's Business Ownership in Niger: Evidence From the World Bank-Funded Adaptive Safety Nets Programme**

The empirical analysis uses the World Bank/DIME Niger Adaptive Safety Nets Program impact-evaluation data and estimates binary logistic regression models with village-clustered robust standard errors.

## What this repository reproduces

The code reproduces:

- the data audit (rows, variables, clusters, and randomization strata);
- treatment-group and outcome counts;
- business-ownership rates by treatment arm at midline and endline;
- the primary adjusted endline Logit model;
- the unadjusted endline Logit model;
- the adjusted midline robustness model;
- village-clustered robust standard errors;
- odds ratios and 95% confidence intervals;
- average marginal effects (AMEs) and 95% confidence intervals;
- paper-ready Table 1 and Table 2 outputs;
- the full regression table and model-fit statistics;
- a raw R output log;
- automated checks against the archived reference results.

## Repository structure

```text
.
├── README.md
├── CITATION.cff
├── run_all.R
├── niger-business-ownership-replication.Rproj
├── R/
│   ├── 01_run_analysis.R
│   └── 02_validate_results.R
├── environment/
│   └── install_packages.R
├── data/
│   ├── README.md
│   ├── raw/                 # put World Bank ZIP here (not committed)
│   └── derived/             # generated locally (not committed)
├── results/
│   ├── generated/           # generated locally (not committed)
│   └── reference/           # archived expected/reference results
├── docs/
│   ├── METHODS.md
│   ├── VARIABLES.md
│   └── TROUBLESHOOTING.md
└── archive/original/
    └── Final_Project_Analysis.R
```

## Data

The raw data are not bundled in this repository. Download the World Bank public-use dataset:

- **Reference ID:** `NER_2017-2020_ASPIE_v01_M`
- **DOI:** https://doi.org/10.48529/0h1e-xt51
- **Catalog:** https://microdata.worldbank.org/catalog/4294

Place this file in `data/raw/`:

```text
NER_2017-2020_ASPIE_v01_M_CSV.zip
```

See `data/README.md` for details and citation requirements.

## Software environment

The archived reference run used:

- R 4.6.0 (2026-04-24)
- macOS arm64
- `readr` 2.2.0
- `dplyr` 1.2.1
- `sandwich` 3.1-3
- `lmtest` 0.9-40
- `margins` 0.3.28
- `modelsummary` 2.6.0

To install the direct package versions used in the reference run:

```r
source("environment/install_packages.R")
```

## One-command reproduction

From the repository root in R/RStudio:

```r
source("run_all.R")
```

This executes the analysis and then validates the main results against the archived reference values.

Successful completion ends with:

```text
Validation passed: generated results match the archived reference results within tolerance.
```

## Expected headline results

The primary endline analytical sample contains **4,252 observations from 320 villages**.

Endline business-ownership rates:

| Group | N | Business ownership |
|---|---:|---:|
| Control | 1,080 | 50.8% |
| Capital | 1,082 | 64.7% |
| Psychosocial | 1,022 | 63.1% |
| Full | 1,068 | 67.6% |

Primary adjusted endline Logit treatment results:

| Treatment vs. Control | Coefficient | Clustered SE | Odds ratio | AME |
|---|---:|---:|---:|---:|
| Capital | 0.6572 | 0.1144 | 1.9293 | 0.1414 |
| Psychosocial | 0.5517 | 0.1151 | 1.7363 | 0.1196 |
| Full | 0.7862 | 0.1119 | 2.1951 | 0.1674 |

The treatment coefficients and AMEs are statistically significant at `p < .001` in the archived reference run.

## Generated files

After a successful run, `results/generated/` contains:

```text
Final_Project_Raw_Output.txt
Descriptive_Statistics_By_Treatment.csv
Table1_Descriptive_Statistics.csv
Model_Coefficients.csv
Primary_Model_Odds_Ratios.csv
Primary_Model_Average_Marginal_Effects.csv
Midline_Average_Marginal_Effects.csv
Table2_Primary_Logit.csv
Regression_Table.html
Model_Fit.csv
```

A compact analysis dataset is also written locally to:

```text
data/derived/Final_Project_Analysis_Data.csv
```

Raw and derived survey data are excluded from Git by default.

## Reproducibility checks

`R/02_validate_results.R` compares the newly generated outputs with archived expected values. It checks, among other quantities:

- treatment-group sample sizes and business-ownership rates;
- primary Logit coefficients and clustered standard errors;
- odds ratios;
- average marginal effects;
- AIC and model deviances;
- the endline observation and cluster counts.

## Data citation

The World Bank catalog requires citation of the ASPIE dataset and the related paper. The dataset DOI is:

> https://doi.org/10.48529/0h1e-xt51

Related paper:

> Bossuroy et al. (2022). *Tackling psychosocial and capital constraints to alleviate poverty*. Nature. https://doi.org/10.1038/s41586-022-04647-8

Please consult the World Bank catalog for the current full dataset citation and access terms.

## Notes for GitHub publication

1. **Do not commit the raw ZIP unless you have independently confirmed that redistribution is permitted under the current World Bank terms.** The repository is designed to work without committing the raw data.
2. Replace the author placeholders in `CITATION.cff` before publishing.
3. Consider adding a code license (for example MIT) before making the repository public.
4. Keep `results/reference/Final_Project_Raw_Output.txt` as the audit trail from the original successful run.

## Troubleshooting

See `docs/TROUBLESHOOTING.md`, including the macOS/Homebrew `zstd` issue encountered when installing R binary packages.
