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

Use `indall` (one row per measured fish). **This is a trap question:** the single largest
`length` and `individualweight` in Biotic are usually **data-entry errors**, so the naive
`filter(x == max(x))` reports a typo as the answer. Instead pull the **top ~10** (still reduced
in DuckDB — cheap), **sanity-check** them, tell the user about likely typos, and report the
largest **plausible** fish. **Don't** collect all cod and take the max in R: that pulls millions
of rows (see [`../knowledge/performance.md`](../knowledge/performance.md)). `length` is in
**metres** → ×100 for cm; `individualweight` is in **kg**. Full method:
[`../knowledge/data-quality.md`](../knowledge/data-quality.md).

## Code

```r
library(tidyverse); library(DBI); library(duckdb)

con <- dbConnect(duckdb::duckdb(),
                 dbdir = path.expand("~/IMR_biotic_BES_database/bioticexplorer.duckdb"),
                 read_only = TRUE)
indall <- tbl(con, "indall")

# Top heaviest candidates, descending — only 10 rows collected
heaviest_cand <- indall |>
  filter(commonname == "torsk", !is.na(individualweight)) |>
  slice_max(individualweight, n = 10) |>
  select(startyear, serialnumber, length, individualweight, age, sex) |>
  collect() |>
  mutate(
    length_cm = length * 100,
    K = 100 * (individualweight * 1000) / (length_cm)^3,   # Fulton's K (~0.8–1.5 for cod)
    flag = is.na(K) | K < 0.4 | K > 3 | individualweight > 60
  )

# Top longest candidates — flag against a plausible max length (~150 cm for cod)
longest_cand <- indall |>
  filter(commonname == "torsk", !is.na(length)) |>
  slice_max(length, n = 10) |>
  select(startyear, serialnumber, length, individualweight, age, sex) |>
  collect() |>
  mutate(length_cm = length * 100, flag = length_cm > 150)

heaviest_cand                                              # inspect flagged rows
heaviest <- heaviest_cand |> filter(!flag) |> slice_max(individualweight, n = 1)
longest  <- longest_cand  |> filter(!flag) |> slice_max(length, n = 1)

dbDisconnect(con, shutdown = TRUE)
```

## Expected output

Two candidate tables of 10 rows each, with a `flag` column marking suspected typos, plus the
filtered one-row answers. As of the 2026 build:

- **Heaviest (plausible):** ~41 kg, ~146–151 cm, age 15–18. The raw max is **18 100 kg at
  114 cm** — a typo (K ≈ 1200), and a **100 kg at 20 cm** record is another (probably 100 g).
- **Longest (plausible):** ~150 cm. The raw max is **179 cm** with no weight — implausible for
  cod (record ~130 cm), so flagged.

Report the plausible answers **and** disclose the flagged records as suspected data-entry errors
so the user can verify the raw data.

## Notes & caveats

- **Report both** longest and heaviest — they're usually different fish, and the longest may
  lack a weight.
- **Never report the raw `max()`** — the extreme tail is where typos live. Top N → sanity-check
  → largest plausible. See [`../knowledge/data-quality.md`](../knowledge/data-quality.md).
- **Fulton's K** `= 100·W(g)/L(cm)³` is a species-agnostic cross-check: real fish ≈ 0.8–1.5;
  typos blow it into the hundreds. Use it whenever both length and weight are present.
- **Memory:** `slice_max(x, n = 10)` reduces in DuckDB so only 10 rows are collected. Never
  `indall |> filter(commonname=="torsk") |> collect()` then `slice_max()`.
- Add `filter(missiontype %in% c(4, 5))` to restrict to research surveys.

## Related

- Skill: `../skills/biotic-query/SKILL.md`
- Performance: `../knowledge/performance.md`
- Glossary: `../knowledge/field-glossary.md`
