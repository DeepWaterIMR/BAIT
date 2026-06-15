---
title: Largest cod in the database
questions:
  - "What is the largest cod recorded in the database?"
  - "Biggest torsk ever measured?"
tables: [indall]
packages: [tidyverse, duckdb]
tags: [query]
---

# Largest cod in the database

**Answers:** the single longest measured Atlantic cod (`commonname == "torsk"`), with its
length in cm and its weight.

## Approach

Use `indall` (one row per measured fish). Filter to `torsk`, drop missing lengths, take the
maximum length. `length` is stored in **metres**, so multiply by 100 for cm. Optionally also
report the heaviest by `individualweight`.

## Code

```r
library(tidyverse); library(DBI); library(duckdb)

con <- dbConnect(duckdb::duckdb(),
                 dbdir = path.expand("~/IMR_biotic_BES_database/bioticexplorer.duckdb"),
                 read_only = TRUE)
indall <- tbl(con, "indall")

biggest <- indall |>
  filter(commonname == "torsk", !is.na(length)) |>
  slice_max(length, n = 1, with_ties = FALSE) |>
  collect() |>
  mutate(length_cm = length * 100)

biggest |> select(startyear, cruise, serialnumber, length_cm, individualweight, age, sex)

dbDisconnect(con, shutdown = TRUE)
```

## Expected output

A one-row tibble: year, cruise, station (`serialnumber`), `length_cm` (a large cod is
~130–150 cm, i.e. `length` ≈ 1.3–1.5 m), `individualweight` in kg, plus `age`/`sex` if
recorded. (Numbers here are illustrative, not real records.)

## Notes & caveats

- "Largest" is ambiguous — confirm whether the user means **longest** (`length`) or
  **heaviest** (`individualweight`). Swap `slice_max(length, …)` for
  `slice_max(individualweight, …)` for the latter.
- Watch for data-entry outliers (an impossible 3 m cod). Sanity-check the top few:
  `slice_max(length, n = 5)`.
- Restrict to surveys with `missiontype %in% c(4, 5)` if commercial records should be excluded.

## Related

- Skill: `../skills/biotic-query/SKILL.md`
- Glossary: `../knowledge/field-glossary.md`
