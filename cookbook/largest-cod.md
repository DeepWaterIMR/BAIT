---
title: Largest cod candidates in Biotic
questions:
  - "What are the largest cod candidates in the database?"
  - "What are the heaviest or longest torsk records?"
tables: [indall]
packages: [tidyverse, duckdb]
tags: [query]
---

# Review extreme cod candidates

**Answers:** produce a small review table for the longest and heaviest Atlantic cod
(`commonname == "torsk"`). The query identifies candidates; it does not determine the true
largest fish or automatically exclude records.

## Approach

Use `indall` and reduce in DuckDB before collecting. Review length, weight, age, sex, station,
and mission context. A cluster of extreme records at one station is a clue to investigate,
not proof of an error: station and mission identifiers are composite, and repeated station
serials are not an exclusion rule. Keep plausible alternatives and record why any candidate is
flagged. Confirm findings against source records and survey context before presenting an
answer. All example values below are synthetic.

## Code

```r
library(tidyverse)
library(DBI)
library(duckdb)
library(jsonlite)

config_path <- path.expand("~/.bait/config.json")
config <- if (file.exists(config_path)) fromJSON(config_path) else list()
db_path <- config$bes_db_path
if (is.null(db_path) || !nzchar(db_path)) {
  db_path <- if (.Platform$OS.type == "windows") {
    file.path(Sys.getenv("USERPROFILE"), "IMR_biotic_BES_database", "bioticexplorer.duckdb")
  } else {
    path.expand("~/IMR_biotic_BES_database/bioticexplorer.duckdb")
  }
}

con <- dbConnect(duckdb::duckdb(), dbdir = db_path, read_only = TRUE)
indall <- tbl(con, "indall")

candidate_query <- function(measure) {
  indall |>
    filter(commonname == "torsk", !is.na(.data[[measure]])) |>
    slice_max(.data[[measure]], n = 10, with_ties = TRUE) |>
    select(missionid, missiontype, startyear, platform, missionnumber, station, serialnumber, length, individualweight, age, sex) |>
    collect() |>
    mutate(length_cm = length * 100)
}

longest_candidates <- candidate_query("length")
heaviest_candidates <- candidate_query("individualweight")

# Inspect candidates and their mission/station context. Repeated serial numbers may be
# meaningful or erroneous; do not exclude a station without checking the source/context.
longest_candidates
heaviest_candidates

# For weighted fish, calculate a screening metric, not an automatic pass/fail rule.
heaviest_candidates <- heaviest_candidates |>
  mutate(K = if_else(
    !is.na(length_cm) & length_cm > 0 & !is.na(individualweight),
    100 * (individualweight * 1000) / length_cm^3,
    NA_real_
  ))

# Record candidate-specific review decisions and rationale after checking source records.
# Do not infer error solely from K or station clustering.

dbDisconnect(con, shutdown = TRUE)
```

## Expected output

Two small candidate tables. For example, a **synthetic** table might show repeated station
identifiers, a wide spread of weights, and several candidates needing source review. No
candidate is automatically discarded.

## Notes & caveats

- `length` is in metres and `individualweight` in kilograms; `length_cm` is derived for
  readability and screening calculations.
- An extreme K value, unusual length, or repeated serial number is a review signal. Assess
  species, age, unit conventions, mission/station context, and source records; do not classify
  or exclude automatically.
- Use the actual composite identifiers appropriate to the table. Serial numbers can repeat
  across missions and can represent bag-level or haul-level identifiers depending on design.
- Never collect all cod into R merely to find extremes. Candidate selection remains in DuckDB.

## Related

- Skill: `../skills/biotic-query/SKILL.md`
- Sampling-unit keys: `../knowledge/sampling-units.md`
- Data-quality review: `../knowledge/data-quality.md`
- Performance: `../knowledge/performance.md`
