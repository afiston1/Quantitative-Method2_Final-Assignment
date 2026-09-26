# Data acquisition

Raw survey data are intentionally **not included** in this repository.

The replication uses the World Bank Microdata Library public-use dataset:

- Study: *Adaptive Safety Nets Program 2017-2020, Baseline, Midline and Endline Impact Evaluation Surveys (ASPIE)*
- Country: Niger
- Reference ID: `NER_2017-2020_ASPIE_v01_M`
- DOI: `https://doi.org/10.48529/0h1e-xt51`
- Catalog: `https://microdata.worldbank.org/catalog/4294`

Download the CSV distribution named:

```text
NER_2017-2020_ASPIE_v01_M_CSV.zip
```

and place it at:

```text
data/raw/NER_2017-2020_ASPIE_v01_M_CSV.zip
```

The analysis reads this internal file directly from the ZIP:

```text
NER_2017-2020_ASPIE_v01_M_CSV/allrounds_NER_hh.csv
```

The World Bank catalog identifies the files as public-use data and provides required dataset and related-paper citations. Users should follow the World Bank's current access, copyright, and citation terms when obtaining or redistributing the data.
