---
name: biotic-connect
description: Connect to the IMR Biotic DuckDB database from R using tidyverse, or read NMD Biotic v3 XML files. Use whenever a task needs database access set up before querying, mapping, or analysing Biotic data.
---

# Connect to the Biotic data (R + tidyverse)

Full reference: [`../../knowledge/connection.md`](../../knowledge/connection.md). The
essentials:

## Database mode (the usual case)

```r
library(tidyverse); library(DBI); library(duckdb)

db_path <- if (.Platform$OS.type == "windows") {
  file.path(Sys.getenv("USERPROFILE"), "IMR_biotic_BES_database", "bioticexplorer.duckdb")
} else {
  path.expand("~/IMR_biotic_BES_database/bioticexplorer.duckdb")
}

con <- DBI::dbConnect(duckdb::duckdb(),
                      dbdir = db_path,
                      read_only = TRUE)

mission <- dplyr::tbl(con, "mission") # survey information
stnall  <- dplyr::tbl(con, "stnall") # station data
indall  <- dplyr::tbl(con, "indall") # individual fish data
ageall <- dplyr::tbl(con, "ageall") # age data
meta <- dplyr::tbl(con, "metadata") %>% # update/schema information
  collect() %>%
  mutate(across(any_of(c("timestart", "timeend")), as.POSIXct))
csindex <- dplyr::tbl(con, "csindex") # cruise series index
gearlist <- dplyr::tbl(con, "gearindex") %>% collect() # gear index
```

**Rules:** always `read_only = TRUE`; build queries **lazily**; `collect()` only the final
result; `DBI::dbDisconnect(con, shutdown = TRUE)` when done. Never `collect()` a whole table.

> **Database location:** if BAIT was installed with `bait-install`, the database path is
> recorded in `~/.bait/config.json` (`bes_db_path`) — prefer it over the default above, since
> the user may have chosen a different location. On Windows, avoid R's `~` expansion for the
> default path because it can point to Documents rather than the user profile directory.

## File mode (no database; a few XML files)

```r
d <- RstoxUtils::processBioticFile("path/to/file.xml")   # or processBioticFiles(dir)
d$stnall; d$indall; d$mission   # same shape as the database tables
```

## If the database is missing

`file.exists()` is FALSE → it isn't installed. Send the user to
[`../biotic-server-setup/SKILL.md`](../biotic-server-setup/SKILL.md).

## Next

- Translate a question into a query → [`../biotic-query/SKILL.md`](../biotic-query/SKILL.md)
- Tables & columns → [`../../knowledge/data-model.md`](../../knowledge/data-model.md),
  [`../../knowledge/field-glossary.md`](../../knowledge/field-glossary.md)
- **Before touching data, confirm the privacy pre-flight** →
  [`../biotic-privacy/SKILL.md`](../biotic-privacy/SKILL.md)
