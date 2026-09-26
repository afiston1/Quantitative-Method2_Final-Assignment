# Install the package versions used in the reference run.
# Reference R version: 4.6.0 (2026-04-24).
# Run once from the repository root:
#   source("environment/install_packages.R")

options(repos = c(CRAN = "https://cloud.r-project.org"))

if (!requireNamespace("remotes", quietly = TRUE)) {
  install.packages("remotes")
}

pinned <- c(
  readr = "2.2.0",
  dplyr = "1.2.1",
  sandwich = "3.1-3",
  lmtest = "0.9-40",
  margins = "0.3.28",
  modelsummary = "2.6.0"
)

for (pkg in names(pinned)) {
  target <- pinned[[pkg]]
  current <- if (requireNamespace(pkg, quietly = TRUE)) as.character(utils::packageVersion(pkg)) else NA_character_
  if (is.na(current) || current != target) {
    message(sprintf("Installing %s %s (current: %s)", pkg, target, current))
    remotes::install_version(pkg, version = target, upgrade = "never", dependencies = TRUE)
  } else {
    message(sprintf("%s %s already installed", pkg, target))
  }
}

message("Package setup complete.")
