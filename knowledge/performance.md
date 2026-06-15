# Memory & performance — don't crash the user's machine

The database is large (millions of individual records). The #1 risk is pulling too much into
R memory with `collect()`. **Do the work in DuckDB; collect only the small final result.**

## Golden rules

1. **Filter and aggregate *before* `collect()`.** DuckDB works on-disk and streams; `collect()`
   copies rows into RAM. A lazy `tbl()` costs nothing until collected.
2. **Never `collect()` a whole table.** `indall`/`stnall` can be millions of rows × dozens of
   columns. `indall |> collect()` can exhaust RAM and freeze the machine.
3. **Compute extremes and summaries in the database, not in R.** Don't collect all rows and
   then take a max/mean — let DuckDB reduce first.
4. **`select()` only the columns you need** before `collect()` (narrower = lighter).
5. **Estimate before a big/unknown collect, and ask if it's large** (see below).

## Extremes the memory-safe way (the "largest cod" lesson)

❌ **Don't** pull every cod into R and then find the max:
```r
indall |> filter(commonname == "torsk") |> collect() |> slice_max(length)   # collects millions of rows
```

✅ **Do** the reduction in DuckDB so only the matching row(s) come back:
```r
indall |>
  filter(commonname == "torsk", !is.na(length)) |>
  filter(length == max(length, na.rm = TRUE)) |>          # computed in DuckDB
  select(commonname, startyear, serialnumber, length, individualweight, age, sex) |>
  collect()
```

(`slice_max(length, n = 1)` *can* be pushed down by dbplyr, but the explicit
`filter(x == max(x))` is reliably evaluated in the database.)

## Estimate before collecting an unknown-sized result

When a query might return many rows, **count first (cheap), estimate the memory, and warn the
user if it's a large fraction of their RAM** — don't just collect and hope.

```r
# 1. How many rows would come back? (runs in DuckDB; returns one number)
n <- query |> summarise(n = n()) |> pull(n)

# 2. Total RAM on this machine (bytes), best-effort and cross-platform:
total_ram <- switch(Sys.info()[["sysname"]],
  Darwin  = as.numeric(system("sysctl -n hw.memsize", intern = TRUE)),
  Linux   = as.numeric(system("awk '/MemTotal/{print $2}' /proc/meminfo", intern = TRUE)) * 1024,
  Windows = as.numeric(system2("powershell",
              c("-NoProfile","-Command","(Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory"),
              stdout = TRUE)),
  NA_real_)

# 3. Rough size of the result: rows × selected columns × ~bytes/cell (≈64 is a safe guess;
#    wide/character data is heavier). Keeping only needed columns shrinks this a lot.
est_bytes <- n * n_selected_columns * 64
```

**Decision rule:** if `est_bytes` is more than ~**25% of `total_ram`** (or the row count is in
the millions), **stop and tell the user** the estimated size and row count, and **ask whether
to proceed**, offering lighter alternatives:
- aggregate/summarise in the database instead of collecting raw rows;
- narrow with more filters (species, years, area, `missiontype %in% c(4, 5)`);
- `select()` fewer columns;
- collect a sample or a per-year/per-area summary first.

If `total_ram` can't be determined, be conservative: treat anything above ~1–2 million rows
as "large — ask first."

## Other tips

- **Avoid needless copies.** Each `as.data.table()`/`as.data.frame()` of a big object can
  double memory. Work on the collected tibble in place.
- **Disconnect when done:** `DBI::dbDisconnect(con, shutdown = TRUE)` frees DuckDB resources.
- **Re-use the lazy refs** loaded by `biotic-connect` (`mission`/`stnall`/`indall`/…); don't
  re-`collect()` reference tables repeatedly.
- **Joins:** join lazily in DuckDB and filter first; `stnall`/`indall` already contain the
  upstream columns, so manual joins are rarely needed.
