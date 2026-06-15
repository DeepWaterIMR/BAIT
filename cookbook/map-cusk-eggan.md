---
title: Map cusk caught on the EggaN surveys
questions:
  - "Make a map of cusk caught on the EggaN surveys."
  - "Where was brosme caught on the continental slope survey?"
tables: [mission, stnall]
packages: [tidyverse, duckdb, BioticExplorerServer, ggOceanMaps]
tags: [map, query]
---

# Map cusk caught on the EggaN surveys

**Answers:** a station map of cusk (`brosme`) catches from the EggaN cruise series (the
northern continental-slope survey).

## Approach

"EggaN" is a **cruise series**, identified via `BioticExplorerServer::cruiseSeries`
(code ↔ name). The `cruiseseriescode` column is a comma-separated list, so match the code
anywhere in it. Filter `stnall` to that series and to `commonname == "brosme"`, drop bad
coordinates, then map with `ggOceanMaps`.

## Code

```r
library(tidyverse); library(DBI); library(duckdb)
library(BioticExplorerServer); library(ggOceanMaps)

con <- dbConnect(duckdb::duckdb(),
                 dbdir = path.expand("~/IMR_biotic_BES_database/bioticexplorer.duckdb"),
                 read_only = TRUE)
stnall <- tbl(con, "stnall")

# 1. EggaN cruise-series code(s): northern continental-slope survey
csList <- BioticExplorerServer::cruiseSeries |>
  select(cruiseseriescode, name) |> unique()
selCS  <- csList[grepl("continental", csList$name, ignore.case = TRUE), ]
# If north & south both match, narrow by name, e.g. grepl("nord|north", name, TRUE)
csFilt <- selCS$cruiseseriescode

# 2. comma-separated -> match the code anywhere in the list
filtExp <- paste(sapply(csFilt, function(k) paste0(
  "cruiseseriescode %like% '", k, ",%' | cruiseseriescode %like% '%,", k,
  "' | cruiseseriescode %like% '%,", k, ",%' | cruiseseriescode %in% c('", k, "')")),
  collapse = " | ")

# 3. filter to series + species + valid positions
sp <- stnall |>
  filter(!!!rlang::parse_exprs(filtExp)) |>
  filter(commonname == "brosme",
         !is.na(longitudestart), !is.na(latitudestart), latitudestart > 0) |>
  collect()

# 4. map
basemap(data = sp, bathymetry = TRUE) +
  ggspatial::geom_spatial_point(
    data = sp, aes(longitudestart, latitudestart, size = catchweight),
    color = "firebrick", alpha = 0.6) +
  labs(title = "Cusk (brosme) on EggaN", size = "Catch (kg)")

dbDisconnect(con, shutdown = TRUE)
```

## Expected output

A `ggOceanMaps` map of the Norwegian Sea / Barents Sea slope with points along the shelf
break, sized by catch weight. Row count ~ tens–hundreds of stations depending on years.

## Notes & caveats

- Confirm the exact series name with `csList` — "continental" may match both north (EggaN)
  and south (EggaS). Narrow on the name string.
- For an interactive version use `leaflet` (see `../skills/biotic-maps/SKILL.md`).
- **Privacy:** slope-survey positions are usually fine to map internally, but check before
  sharing externally; don't commit the rendered figure.

## Related

- Skill: `../skills/biotic-maps/SKILL.md`, `../skills/biotic-query/SKILL.md`
- Knowledge: `../knowledge/species-and-surveys.md`
