# Variables used in the replication

The analysis uses the World Bank/DIME `allrounds_NER_hh.csv` file.

| Variable | Role | Interpretation in this replication |
|---|---|---|
| `phase` | Survey round | 1 = midline (2019), 2 = endline (2020) |
| `hhid` | Identifier | Household/beneficiary identifier used in the source file |
| `treatment` | Main treatment | 0 = Control, 1 = Capital, 2 = Psychosocial, 3 = Full |
| `cluster` | Clustering variable | Village; the unit of randomization |
| `strata` | Design control | Randomization stratum |
| `bus2_ben_dum` | Dependent variable | 1 if the female beneficiary operated a business; 0 otherwise |
| `bus2_ben_dum_bl` | Baseline control | Baseline business-participation outcome |
| `bus2_ben_dum_bl_bd` | Missing-baseline indicator | Indicator for missing baseline business-participation information |
| `equiv_n` | Retained auxiliary variable | Household adult-equivalent size; exported for convenience but not used in the primary model |

## Primary specification

The primary endline Logit model is:

```text
logit[P(Business_i = 1)] =
  beta_0 + beta_1 Capital_i + beta_2 Psychosocial_i + beta_3 Full_i
  + delta BusinessBaseline_i + gamma_s
```

The Control arm is the reference treatment category. `gamma_s` denotes randomization-stratum fixed effects. Standard errors are clustered at the village level.
