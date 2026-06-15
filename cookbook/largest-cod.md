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

**Answers:** the largest Atlantic cod (`commonname == "torsk"`) — reported **both ways**:
the **longest** (`length`) and the **heaviest** (`individualweight`), since "largest" is
ambiguous.

## Approach

Use `indall` (one row per measured fish). **Do the max in DuckDB** — filter to `torsk`, then
keep the row(s) where `length` (or `individualweight`) equals the column max, and `collect()`
only those. **Don't** collect all cod and take the max in R: that pulls millions of rows and
can freeze the machine (see [`../knowledge/performance.md`](../knowledge/performance.md)).
`length` is in **metres** → ×100 for cm.

## Code

```r
library(tidyverse); library(DBI); library(duckdb)

con <- dbConnect(duckdb::duckdb(),
                 dbdir = path.expand("~/IMR_biotic_BES_database/bioticexplorer.duckdb"),
                 read_only = TRUE)
indall <- tbl(con, "indall")

# Longest cod — max computed in DuckDB; only the matching row(s) come back
longest <- indall |>
  filter(commonname == "torsk", !is.na(length)) |>
  filter(length == max(length, na.rm = TRUE)) |>
  select(commonname, startyear, serialnumber, length, individualweight, age, sex) |>
  collect() |>
  mutate(length_cm = length * 100)

# Heaviest cod
heaviest <- indall |>
  filter(commonname == "torsk", !is.na(individualweight)) |>
  filter(individualweight == max(individualweight, na.rm = TRUE)) |>
  select(commonname, startyear, serialnumber, length, individualweight, age, sex) |>
  collect()

longest
heaviest

dbDisconnect(con, shutdown = TRUE)
```

## Expected output

Two one-row (or few-row, on ties) tibbles. The **longest** cod is ~1.7–1.8 m
(`length_cm` ≈ 170–180); the longest specimen may have **no** `individualweight` recorded, so
report the **heaviest** separately. Each row carries year, station (`serialnumber`), length,
weight, and `age`/`sex` if recorded. (Illustrative magnitudes, not real records.)

## Notes & caveats

- **Report both** longest and heaviest — they're usually different fish, and the longest may
  lack a weight.
- **Memory:** the `filter(x == max(x))` form reduces in DuckDB so only the top row(s) are
  collected. Never `indall |> filter(commonname=="torsk") |> collect()` then `slice_max()`.
- Watch for data-entry outliers (an impossible 3 m cod). Sanity-check the top few in DuckDB:
  `... |> arrange(desc(length)) |> head(5) |> collect()`.
- Add `filter(missiontype %in% c(4, 5))` to restrict to research surveys.

## Related

- Skill: `../skills/biotic-query/SKILL.md`
- Performance: `../knowledge/performance.md`
- Glossary: `../knowledge/field-glossary.md`
