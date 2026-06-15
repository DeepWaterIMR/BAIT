## Largest cod in the database — mirrors cookbook/largest-cod.md
## Requires a local DuckDB at ~/IMR_biotic_BES_database/bioticexplorer.duckdb

library(tidyverse)
library(DBI)
library(duckdb)

con <- dbConnect(duckdb::duckdb(),
                 dbdir = path.expand("~/IMR_biotic_BES_database/bioticexplorer.duckdb"),
                 read_only = TRUE)
indall <- tbl(con, "indall")

biggest <- indall |>
  filter(commonname == "torsk", !is.na(length)) |>
  slice_max(length, n = 1, with_ties = FALSE) |>
  collect() |>
  mutate(length_cm = length * 100)   # length is in metres

print(biggest |>
  select(startyear, cruise, serialnumber, length_cm, individualweight, age, sex))

dbDisconnect(con, shutdown = TRUE)
