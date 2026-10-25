---
name: biotic-connect
description: Connect to the IMR Biotic DuckDB database from R using tidyverse, or read NMD Biotic v3 XML files. Use whenever a task needs database access set up before querying, mapping, or analysing Biotic data.
---

<!-- pack-resources:start -->
**Pack resources:** resolve `BAIT` from `~/.bait/config.json` → `bait_path` (or
`~/.fiskwise/config.json` → `components.BAIT.path`). If neither exists, use the
checkout containing this skill, or locate/obtain the pack through its install instructions.
Paths such as `knowledge/`, `cookbook/`, `config/` and `project-template/` belong to that
repository, not the current research directory. For a copied skill, resolve a link that
leaves this skill's directory against the corresponding source skill under that root;
keep bundled `references/` links relative to the skill. Never assume `../../` from an
agent's global skills folder reaches the repository. Use absolute resolved script paths.
<!-- pack-resources:end -->


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
> default path because it can point to Documents rather than the user profile directory —
> `BioticExplorerServer::findDatabase()` checks both locations if that package is installed.

## Integrity check (once per session, after connecting)

```r
n_escaped <- DBI::dbGetQuery(con, "
  SELECT count(*) AS n FROM stnall
  WHERE regexp_matches(commonname, '<[89a-f][0-9a-f]>')")$n
```

`n_escaped > 0` → the database has text-encoding corruption (`bl<c3><a5>kveite` instead of
`blåkveite`), and species/platform filters will silently miss years. Stop and follow
[`../../knowledge/data-quality.md`](../../knowledge/data-quality.md#text-encoding-corruption):
tell the user, offer the repair, and draft a bug report if the repair is not possible.

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
- Keep the privacy guidance in mind →
  [`../biotic-privacy/SKILL.md`](../biotic-privacy/SKILL.md)
  Routine local queries should not block on a fresh training-toggle confirmation if
  onboarding already covered it.
