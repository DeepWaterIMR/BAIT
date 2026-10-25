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

Filter `indall` to `lange` on the Coastal survey (Kysttokt, **cruise-series code 23** — not
a `"coastal|kyst"` name grep, which also matches codes 28, 29 and 30), then fit with
`ggFishPlots::plot_maturity()`. `maturationstage` is an NMDreference **code** — decide which
stages count as "mature" for ling before fitting. Report `$params` (L50), not just the plot.

## Code

```r
library(tidyverse); library(DBI); library(duckdb); library(ggFishPlots)

config_path <- path.expand("~/.bait/config.json")
config <- if (file.exists(config_path)) jsonlite::fromJSON(config_path) else list()
db_path <- config$bes_db_path
if (is.null(db_path) || !nzchar(db_path)) {
  stop("Use biotic-connect to configure the local database before running this recipe.")
}

con <- dbConnect(duckdb::duckdb(), dbdir = db_path, read_only = TRUE)
indall  <- tbl(con, "indall")
csindex <- tbl(con, "csindex")   # cruise-series lookup (loaded as standard in biotic-connect)

# Coastal survey (Kysttokt) = cruise-series code 23. Grepping "coastal|kyst" would also
# pull codes 28, 29 and 30 — different surveys. See knowledge/species-and-surveys.md.
csFilt <- "23"
csindex |> distinct(cruiseseriescode, name) |> filter(cruiseseriescode == csFilt) |>
  collect()   # sanity-check the name before relying on the code
filtExp <- paste(sapply(csFilt, function(k) paste0(
  "cruiseseriescode %like% '", k, ",%' | cruiseseriescode %like% '%,", k,
  "' | cruiseseriescode %like% '%,", k, ",%' | cruiseseriescode %in% c('", k, "')")),
  collapse = " | ")

d <- indall |>
  filter(!!!rlang::parse_exprs(filtExp)) |>
  filter(commonname == "lange", !is.na(length), !is.na(maturationstage)) |>
  collect() |>
  mutate(length_cm = length * 100)

# Inspect stages, then fill these sets only after confirming a species-specific,
# authoritative definition. These placeholders intentionally do not guess a mapping.
d |> count(maturationstage)
mature_codes <- NULL # Fill from a verified species-specific source.
immature_codes <- NULL # Fill from the same source.
stopifnot(length(mature_codes) > 0, length(immature_codes) > 0,
          !anyNA(c(mature_codes, immature_codes)),
          length(intersect(mature_codes, immature_codes)) == 0)
d_l50 <- d |>
  mutate(mature = case_when(
    maturationstage %in% mature_codes ~ 1L,
    maturationstage %in% immature_codes ~ 0L,
    TRUE ~ NA_integer_
  )) |>
  filter(!is.na(mature))

fit <- plot_maturity(
  d_l50,
  length = "length_cm",
  maturity = "mature",
  sex = "sex",
  female.sex = "1", male.sex = "2", # NMD codes; verify codeindex for your source
  length.unit = "cm",
  split.by.sex = TRUE
)
fit$plot      # the ogive
fit$params    # L50 (and CI), sample sizes

dbDisconnect(con, shutdown = TRUE)
```

## Expected output

A logistic maturity curve (proportion mature vs length) and a parameters object giving
**L50** (length at 50% maturity, in the model's length unit) with a confidence interval and
sample size. (Exact value depends on the data and the mature/immature definition.)

## Notes & caveats

- `plot_maturity()` expects binary maturity (TRUE/FALSE or 1/0), uses `split.by.sex`, and
  returns a list with `$plot` and `$params`. Confirm current signatures in package help.
- Biotic `length` is in metres; this example converts it to centimetres before fitting.
- The mature/immature stage sets are intentionally placeholders. Confirm them for ling from an
  authoritative species-specific source; never apply a universal maturationstage threshold.
- Small samples → unstable L50; report n and CI.

## Related

- Skill: `../skills/biotic-lifehistory/SKILL.md`
- Knowledge: `../knowledge/species-and-surveys.md`, `../knowledge/field-glossary.md`
