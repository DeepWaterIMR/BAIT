## Largest cod in the database — mirrors cookbook/largest-cod.md
## Reports BOTH the longest and the heaviest cod, computing the max in DuckDB so only the
## matching row(s) are pulled into R (never collect all cod — see knowledge/performance.md).
## Requires a local DuckDB at ~/IMR_biotic_BES_database/bioticexplorer.duckdb

library(tidyverse)
library(DBI)
library(duckdb)

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
  mutate(length_cm = length * 100)   # length is in metres

# Heaviest cod
heaviest <- indall |>
  filter(commonname == "torsk", !is.na(individualweight)) |>
  filter(individualweight == max(individualweight, na.rm = TRUE)) |>
  select(commonname, startyear, serialnumber, length, individualweight, age, sex) |>
  collect()

print(longest)
print(heaviest)

dbDisconnect(con, shutdown = TRUE)
