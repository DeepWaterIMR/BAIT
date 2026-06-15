# Connecting to the Biotic database (R + tidyverse)

The IMR Biotic database is a **DuckDB** file built by
[BioticExplorerServer](https://github.com/DeepWaterIMR/BioticExplorerServer). Default
location:

```
~/IMR_biotic_BES_database/bioticexplorer.duckdb
```

> ⚠️ The old `MonetDB.R` connection pattern (seen in some legacy scripts) is **obsolete**.
> The database migrated to DuckDB in 2025. Always use the `duckdb` driver below.

## Canonical connection (copy this)

```r
library(tidyverse)
library(DBI)
library(duckdb)

db_path <- path.expand("~/IMR_biotic_BES_database/bioticexplorer.duckdb")

# Read-only: we never modify the database from BAIT.
con <- DBI::dbConnect(duckdb::duckdb(), dbdir = db_path, read_only = TRUE)

# Core tables — lazy, no data pulled yet:
mission <- dplyr::tbl(con, "mission") # survey / cruise information
stnall  <- dplyr::tbl(con, "stnall")  # station + catch data (mission + fishstation + catchsample)
indall  <- dplyr::tbl(con, "indall")  # individual fish (stnall + individual + preferred age)
ageall  <- dplyr::tbl(con, "ageall")  # all age readings (one row per reading)

# Reference / lookup tables — small, safe to collect() up front:
meta     <- dplyr::tbl(con, "metadata") %>%             # when the database was downloaded
  collect() %>% mutate_all(as.POSIXct)
csindex  <- dplyr::tbl(con, "csindex")                  # cruise-series index (code -> name)
gearlist <- dplyr::tbl(con, "gearindex") %>% collect()  # gear index (code -> name/category)
# taxaindex: taxon/commonname lookup — the PRIMARY source for species names. Present in
# databases compiled after the taxa table was added; guard for older databases (fall back to
# the species list in species-and-surveys.md).
if ("taxaindex" %in% DBI::dbListTables(con))
  taxa <- dplyr::tbl(con, "taxaindex") %>% collect()
```

## Tables available

- **Core** (query lazily, `collect()` the result): `mission`, `stnall`, `indall`, `ageall` —
  see [`data-model.md`](data-model.md).
- **Reference / lookup** (small; `collect()` up front): `metadata` (build time), `csindex`
  (cruise-series code → name), `gearindex` (gear code → name/category), and `taxaindex`
  (taxon / `commonname` lookup — see [`species-and-surveys.md`](species-and-surveys.md)).
  Inspect what a given database holds with `DBI::dbListTables(con)`.

## Golden rules

1. **Always `read_only = TRUE`.** BAIT reads; it never writes the database.
2. **Build the query lazily, then `collect()` once at the end.** DuckDB does the filtering;
   only the final (small) result is pulled into R memory. Never `collect()` a whole table.
3. **Disconnect when done:**
   ```r
   DBI::dbDisconnect(con, shutdown = TRUE)
   ```
4. **Check columns before guessing.** Column sets can evolve:
   ```r
   colnames(stnall)   # works on a lazy tbl
   colnames(indall)
   ```
   Use [`field-glossary.md`](field-glossary.md) to map plain English → column names.

## Lazy → collect pattern

```r
result <- stnall |>
  filter(commonname == "torsk", missiontype %in% c(4, 5)) |>   # filter in DuckDB
  select(startyear, serialnumber, longitudestart, latitudestart, catchweight) |>
  collect()                                                     # pull final result only
```

## Two ways to get data, same shape

- **Database mode** (this file): query the compiled DuckDB. Best for cross-cruise questions.
- **File mode**: parse local NMD Biotic v3 XML with
  `RstoxUtils::processBioticFile()` / `processBioticFiles()`, which return the same
  `$mission`/`$stnall`/`$indall` structure. Best when you have a few XML files and no
  database. See [`packages.md`](packages.md).

## Troubleshooting

- **File not found** → the database isn't installed yet. See
  [`../skills/biotic-server-setup/SKILL.md`](../skills/biotic-server-setup/SKILL.md).
- **`duckdb` version mismatch on open** → the DuckDB file format is tied to the `duckdb` R
  package version it was written with. Update the package (`install.packages("duckdb")`) or
  rebuild the database with a matching version.
- **Locked database** → close other R sessions / BioticExplorer instances using the file.
