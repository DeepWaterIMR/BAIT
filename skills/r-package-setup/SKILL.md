---
name: r-package-setup
description: Write the package-loading header of an R script, Quarto (.qmd) or R Markdown (.Rmd) document so missing packages install themselves automatically on Linux, macOS and Windows, including packages that only exist on GitHub. Use whenever you add, remove or reorder `library()` calls, scaffold a new analysis script, or a script fails with "there is no package called ...".
---

# Package setup header for R scripts

Every R script, `.qmd` or `.Rmd` that loads packages starts with **one** block: a named
vector of packages, an optional install step, and a load loop. A package is named **once**,
whether it is being installed or loaded — never once in an `install.packages()` list and
again in a `library()` call.

**Exception:** if the project uses **renv** (there is an `renv.lock` / `renv/` folder), do
*not* add the install step. renv owns the library; just `library()` the packages and let
`renv::restore()` handle installation.

## The block

Put this at the very top of the script, before anything else runs.

```r
# Packages, with the GitHub repository for those that are not on CRAN. Keeping
# them in one table means a package is named once, whether it is installed or
# loaded.
packages <- c(
  tidyverse = NA,
  sf = NA,
  ggOceanMaps = NA,
  RstoxUtils = "DeepWaterIMR/RstoxUtils",
  ggFishPlots = "DeepWaterIMR/ggFishPlots"
)

install_missing_packages <- TRUE

if (isTRUE(install_missing_packages)) {
  missing <- packages[
    !vapply(
      names(packages),
      requireNamespace,
      logical(1),
      quietly = TRUE
    )
  ]

  if (length(missing)) {
    # Rscript, knitr and Quarto sessions often start without a CRAN mirror and
    # without a writable user library. Both are needed before installing.
    repos <- getOption("repos")
    if (is.na(repos["CRAN"]) || repos["CRAN"] == "@CRAN@") {
      repos["CRAN"] <- "https://cloud.r-project.org"
      options(repos = repos)
    }

    lib <- strsplit(Sys.getenv("R_LIBS_USER"), .Platform$path.sep)[[1]][1]
    if (!is.na(lib) && nzchar(lib)) {
      if (!dir.exists(lib)) dir.create(lib, recursive = TRUE)
      .libPaths(c(lib, .libPaths()))
    }

    # Never fall into the interactive "install from sources?" question, which
    # hangs unattended runs on macOS and Windows.
    options(install.packages.compile.from.source = "never")

    if (any(!is.na(missing)) && !requireNamespace("remotes", quietly = TRUE)) {
      install.packages("remotes")
    }

    for (package in names(missing)) {
      if (is.na(missing[[package]])) {
        install.packages(package)
      } else {
        remotes::install_github(missing[[package]], upgrade = "never")
      }
    }
  }
}

invisible(lapply(names(packages), function(package) {
  suppressPackageStartupMessages(library(package, character.only = TRUE))
}))
```

The vector name is the **package** name (what `library()` takes); the value is the
**GitHub repo** (`owner/repo`) or `NA` for CRAN. When the repo name differs from the
package name — `MikkoVihtakari/ggOceanPlots` installing `ggOceanPlots` — the name side is
still what matters, so nothing special is needed.

## Why each line is there

| Line | Without it |
|---|---|
| `repos["CRAN"]` fallback | `Rscript` fails with *"trying to use CRAN without setting a mirror"* |
| `dir.create(lib)` + `.libPaths()` | A first-run Windows/macOS session has no personal library yet; the install prompt to create one errors out non-interactively |
| `compile.from.source = "never"` | macOS/Windows stop and ask whether to compile a newer source version, hanging renders |
| `upgrade = "never"` | `install_github()` opens an interactive "which packages to update?" menu |
| `requireNamespace(quietly = TRUE)` | Version conflicts and startup chatter leak into the log |
| The single `packages` vector | Package lists drift apart, and a package gets installed but never loaded |

This is portable as written: no `.Platform$OS.type` branching is needed, because
`install.packages()` already picks binaries on Windows/macOS and sources on Linux.

## Quarto / R Markdown variant

Expose the toggle as a parameter so a render can be run without touching the library:

````markdown
---
params:
  install_missing_packages: true
---

```{r setup, include = FALSE}
packages <- c(
  tidyverse = NA,
  knitr = NA,
  flextable = NA,
  ggOceanMaps = NA,
  RstoxUtils = "DeepWaterIMR/RstoxUtils"
)

if (isTRUE(params$install_missing_packages)) {
  # ... identical to the block above ...
}

invisible(lapply(names(packages), function(package) {
  suppressPackageStartupMessages(library(package, character.only = TRUE))
}))
```
````

In projects that carry their own settings list (e.g. `report_params` read from a YAML
config), read the toggle from there instead: `isTRUE(report_params$install_missing_packages)`.
Match whatever the surrounding document already uses.

## Extensions

**Non-CRAN, non-GitHub repositories** (Bioconductor, the StoX repo that serves `RstoxData`
and `RstoxFramework`). Add them to `repos` *before* the block, and leave those packages as
`NA` in the vector — `install.packages()` then finds them:

```r
options(repos = c(
  getOption("repos"),
  stox = "https://stoxproject.github.io/repo",
  inla = "https://inla.r-inla-download.org/R/stable"
))
```

Bioconductor packages need `BiocManager::install()` rather than `install.packages()`; give
them their own short branch if a script needs them.

**Faster startup.** `requireNamespace()` actually loads each namespace. To only test
whether a package is installed, use `nzchar(system.file(package = package))` in the
`vapply()` instead. Do this if the check is noticeably slow, not by default — a genuinely
broken install is worth surfacing early.

**GitHub rate limits.** Unauthenticated `install_github()` is capped at 60 requests/hour
and fails with HTTP 403. If a user hits it, have them set a `GITHUB_PAT`
(`usethis::create_github_token()`, then `usethis::edit_r_environ()`).

**Compilation on Windows.** Packages with no binary (common right after a CRAN release, and
for most GitHub packages) need **Rtools** matching the R version. If an install fails with
compiler errors, that is the first thing to check — the block cannot work around a missing
toolchain.

## Do not

- Repeat `if (!require(x)) install.packages(x); library(x)` once per package.
- Call `install.packages()` unconditionally at the top of a script — it re-downloads on
  every run and can break a working setup mid-analysis.
- Use `pacman::p_load()` or similar wrappers; they add a dependency to solve the problem
  the block above solves in plain base R.
- Install packages inside a function or loop that runs during the analysis. Installation
  belongs in the header only.
- Silently drop a package that is only used as `pkg::fun()`. It still has to be installed,
  so it still belongs in `packages`; the extra `library()` call is a cheap price for
  having one list.
