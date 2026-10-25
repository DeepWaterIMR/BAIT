## Review extreme cod candidates — mirrors cookbook/largest-cod.md
## Candidate flags require contextual/source review; this example never excludes records.

library(tidyverse)
library(DBI)
library(duckdb)
library(jsonlite)

config_path <- path.expand("~/.bait/config.json")
config <- if (file.exists(config_path)) jsonlite::fromJSON(config_path) else list()
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

# Review context and source records. Repeated serialnumber values alone do not justify
# excluding a mission/station or treating records as errors.
longest_candidates
heaviest_candidates

dbDisconnect(con, shutdown = TRUE)
