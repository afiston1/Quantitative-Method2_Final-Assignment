# One-command replication runner.
# From the repository root, run:
#   source("run_all.R")

required <- c("readr", "dplyr", "sandwich", "lmtest", "margins", "modelsummary")
missing <- required[!vapply(required, requireNamespace, quietly = TRUE, FUN.VALUE = logical(1))]

if (length(missing) > 0) {
  stop(
    "Missing R packages: ", paste(missing, collapse = ", "),
    "\nRun source('environment/install_packages.R') first."
  )
}

source("R/01_run_analysis.R", echo = FALSE)
source("R/02_validate_results.R", echo = FALSE)
