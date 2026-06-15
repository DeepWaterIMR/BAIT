---
title: Maturity ogive (L50) for ling from the Coastal survey
questions:
  - "Make a maturity ogive for ling using Coastal survey data."
  - "What is the L50 of lange on the Kysttokt?"
tables: [mission, indall, csindex]
packages: [tidyverse, duckdb, ggFishPlots]
tags: [lifehistory, query]
---

# Maturity ogive (L50) for ling from the Coastal survey

**Answers:** a 50%-maturity-at-length (L50) ogive for ling (`lange`) using fish measured on
the Coastal survey (Kysttokt), plus the fitted L50 parameter.

## Approach

Filter `indall` to `lange` on the Coastal cruise series, then fit with
`ggFishPlots::plot_maturity()`. `maturationstage` is an NMDreference **code** — decide which
stages count as "mature" for ling before fitting. Report `$params` (L50), not just the plot.

## Code

```r
library(tidyverse); library(DBI); library(duckdb); library(ggFishPlots)

con <- dbConnect(duckdb::duckdb(),
                 dbdir = path.expand("~/IMR_biotic_BES_database/bioticexplorer.duckdb"),
                 read_only = TRUE)
indall  <- tbl(con, "indall")
csindex <- tbl(con, "csindex")   # cruise-series lookup (loaded as standard in biotic-connect)

# Coastal-survey cruise-series code(s)
csList <- csindex |> distinct(cruiseseriescode, name) |> collect()
selCS  <- csList[grepl("coastal|kyst", csList$name, ignore.case = TRUE), ]
csFilt <- selCS$cruiseseriescode
filtExp <- paste(sapply(csFilt, function(k) paste0(
  "cruiseseriescode %like% '", k, ",%' | cruiseseriescode %like% '%,", k,
  "' | cruiseseriescode %like% '%,", k, ",%' | cruiseseriescode %in% c('", k, "')")),
  collapse = " | ")

d <- indall |>
  filter(!!!rlang::parse_exprs(filtExp)) |>
  filter(commonname == "lange", !is.na(length), !is.na(maturationstage)) |>
  collect()

# Inspect maturity coding before deciding the mature/immature split:
# d |> count(maturationstage)

fit <- plot_maturity(d, length = "length", maturity = "maturationstage")  # check ?plot_maturity
fit$plot      # the ogive
fit$params    # L50 (and CI), sample sizes

dbDisconnect(con, shutdown = TRUE)
```

## Expected output

A logistic maturity curve (proportion mature vs length) and a parameters object giving
**L50** (length at 50% maturity, in the model's length unit) with a confidence interval and
sample size. (Exact value depends on the data and the mature/immature definition.)

## Notes & caveats

- **Confirm `plot_maturity()`'s argument names/coding** with `?ggFishPlots::plot_maturity` —
  it may want a binary maturity column or a specific stage threshold.
- `length` is in metres; if the function or labels expect cm, pass `length * 100` or set the
  axis accordingly.
- Split by sex (`split.by = "sex"`) if the user wants male/female ogives.
- Small samples → unstable L50; report n and CI.

## Related

- Skill: `../skills/biotic-lifehistory/SKILL.md`
- Knowledge: `../knowledge/species-and-surveys.md`, `../knowledge/field-glossary.md`
