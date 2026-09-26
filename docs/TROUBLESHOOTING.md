# Troubleshooting

## macOS: `zstd` error while installing R binary packages

If R reports an error similar to:

```text
Can't initialize filter; unable to run program "zstd -d -qq"
```

install `zstd` with Homebrew:

```bash
brew install zstd
which zstd
```

On Apple Silicon, the usual path is `/opt/homebrew/bin/zstd`. In R, verify with:

```r
Sys.which("zstd")
```

If RStudio does not see Homebrew, add `/opt/homebrew/bin` to the R process PATH or launch RStudio after configuring Homebrew in `~/.zprofile`.

## Raw data ZIP not found

Place the downloaded file here:

```text
data/raw/NER_2017-2020_ASPIE_v01_M_CSV.zip
```

The runner also accepts the ZIP in the repository root, but `data/raw/` is preferred.

## Package-version differences

Run:

```r
source("environment/install_packages.R")
```

The script pins the six direct package versions used in the archived reference run. R itself was version 4.6.0 in that run.
