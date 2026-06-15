---
title: All spurdog in ICES areas 1 and 2
questions:
  - "Get all spurdog (pigghå) records in ICES areas 1 and 2 and map them."
  - "Where has pigghå been caught in ICES subareas 27.1 and 27.2?"
tables: [stnall]
packages: [tidyverse, duckdb, ggOceanMaps]
tags: [query, map]
---

# All spurdog in ICES areas 1 and 2

**Answers:** every spurdog (`pigghå`) catch record in ICES subareas 1 and 2
(codes starting `27.1` / `27.2`), with a quick map. (Mirrors a real maintainer workflow,
modernised onto the DuckDB driver.)

## Approach

`icesarea` is on `stnall` in the DuckDB build. ICES subareas 1 and 2 have codes like
`27.1.x` and `27.2.x`. Pull the distinct `icesarea` values, keep those matching `27.1.`/
`27.2.`, then filter `stnall` to `pigghå` in those areas.

## Code

```r
library(tidyverse); library(DBI); library(duckdb); library(ggOceanMaps)

con <- dbConnect(duckdb::duckdb(),
                 dbdir = path.expand("~/IMR_biotic_BES_database/bioticexplorer.duckdb"),
                 read_only = TRUE)
stnall <- tbl(con, "stnall")

ices_areas <- stnall |> distinct(icesarea) |> pull() |>
  grep("27\\.1\\.|27\\.2\\.", x = _, value = TRUE)

sp <- stnall |>
  filter(commonname == "pigghå", icesarea %in% ices_areas,
         !is.na(longitudestart), !is.na(latitudestart), latitudestart > 0) |>
  collect()

qmap(sp, color = factor(startyear))   # quick map; use basemap() for a polished figure

dbDisconnect(con, shutdown = TRUE)
```

## Expected output

A tibble of spurdog station records in ICES 1 & 2 and a quick `ggOceanMaps` map coloured by
year. Row count ~ hundreds depending on the time span.

## Notes & caveats

- Confirm `icesarea` exists in your build (`colnames(stnall)`); naming of ICES codes can vary
  (`27.1.a` vs `27.1`). Adjust the regex.
- Add `missiontype %in% c(4, 5)` to restrict to research surveys.
- **Privacy:** spurdog is a sensitive/listed species in places — check before sharing
  position-level outputs externally.

## Related

- Skill: `../skills/biotic-query/SKILL.md`, `../skills/biotic-maps/SKILL.md`
- Knowledge: `../knowledge/species-and-surveys.md`
