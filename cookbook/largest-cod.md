---
title: Largest cod in the database
questions:
  - "What is the largest cod recorded in the database?"
  - "Biggest torsk ever measured?"
tables: [indall]
packages: [tidyverse, duckdb]
tags: [query]
---

# Largest cod in the database

**Answers:** the largest Atlantic cod (`commonname == "torsk"`) — reported **both ways**:
the **longest** (`length`) and the **heaviest** (`individualweight`), since "largest" is
ambiguous.

## Approach

Use `indall` (one row per measured fish). **This is a trap question:** the single largest
`length` and `individualweight` in Biotic are usually **data-entry errors**, so the naive
`filter(x == max(x))` reports a typo as the answer. Instead pull the **top ~10** (still reduced
in DuckDB — cheap), **sanity-check** them, tell the user about likely typos, and report the
largest **plausible** fish. **Don't** collect all cod and take the max in R: that pulls millions
of rows (see [`../knowledge/performance.md`](../knowledge/performance.md)). `length` is in
**metres** → ×100 for cm; `individualweight` is in **kg**. Full method:
[`../knowledge/data-quality.md`](../knowledge/data-quality.md).

## Code

```r
library(tidyverse); library(DBI); library(duckdb)

con <- dbConnect(duckdb::duckdb(),
                 dbdir = path.expand("~/IMR_biotic_BES_database/bioticexplorer.duckdb"),
                 read_only = TRUE)
indall <- tbl(con, "indall")

# --- HEAVIEST ---

# Step 1: top 10 candidates reduced in DuckDB
heaviest_cand <- indall |>
  filter(commonname == "torsk", !is.na(individualweight)) |>
  slice_max(individualweight, n = 10) |>
  select(startyear, serialnumber, length, individualweight, age, sex) |>
  collect() |>
  mutate(
    length_cm = length * 100,
    K = ifelse(!is.na(length) & length > 0,
               100 * (individualweight * 1000) / (length_cm)^3, NA_real_)
  )

# Step 2: station-clustering check — one haul with grams-for-kg entries will fill all top slots
station_counts <- count(heaviest_cand, serialnumber, sort = TRUE)
bad_stations   <- station_counts |> filter(n >= 3) |> pull(serialnumber)

# Step 3: if bad station(s) detected, re-query excluding them
if (length(bad_stations) > 0) {
  message("Excluding station(s) with systematic entry errors: ", paste(bad_stations, collapse = ", "))
  heaviest_cand <- indall |>
    filter(commonname == "torsk", !is.na(individualweight),
           !serialnumber %in% bad_stations) |>
    slice_max(individualweight, n = 10) |>
    select(startyear, serialnumber, length, individualweight, age, sex) |>
    collect() |>
    mutate(
      length_cm = length * 100,
      K = ifelse(!is.na(length) & length > 0,
                 100 * (individualweight * 1000) / (length_cm)^3, NA_real_)
    )
}

# Step 4: flag remaining individual records with implausible Fulton's K
heaviest_cand <- heaviest_cand |>
  mutate(flag = !is.na(K) & (K < 0.4 | K > 3))

heaviest_cand                                              # inspect flagged rows
heaviest <- heaviest_cand |> filter(!flag) |> slice_max(individualweight, n = 1)

# --- LONGEST ---

# Length outliers without weight cannot be cross-checked with K — do not auto-flag them
longest_cand <- indall |>
  filter(commonname == "torsk", !is.na(length)) |>
  slice_max(length, n = 10) |>
  select(startyear, serialnumber, length, individualweight, age, sex) |>
  collect() |>
  mutate(
    length_cm = length * 100,
    K = ifelse(!is.na(individualweight) & length > 0,
               100 * (individualweight * 1000) / (length_cm)^3, NA_real_),
    flag = !is.na(K) & (K < 0.4 | K > 3),   # only flag when K can be computed
    note = ifelse(is.na(K), "no weight — unverifiable", ifelse(flag, "implausible K", "OK"))
  )

longest_cand                                               # inspect; NA weight = can't cross-check
longest <- longest_cand |> filter(!flag) |> slice_max(length, n = 1)

# --- DECODE before reporting: sex is a code, not a label (1 = Female, 2 = Male) ---
sex_lab <- c("1" = "Female", "2" = "Male", "3" = "Intersex", "4" = "Hermaphroditic")
heaviest <- heaviest |> mutate(sex = dplyr::recode(as.character(sex), !!!sex_lab))
longest  <- longest  |> mutate(sex = dplyr::recode(as.character(sex), !!!sex_lab))

dbDisconnect(con, shutdown = TRUE)
```

> **Decode codes before you report them.** `sex` is a NMDreference code — reporting `sex = 1`
> as "male" is a real mistake to avoid (`1 = Female`). See
> [`../knowledge/reference-codes.md`](../knowledge/reference-codes.md).

## Expected output

Two candidate tables of 10 rows each, with a `flag` / `note` column, plus the filtered one-row
answers. As of the 2026 build:

- **Heaviest (plausible):** ~41 kg, ~146–151 cm, age 15–18.
  The first query returns all 10 slots from a single station (`serialnumber = 50256`, 2026) with
  weights in grams-for-kg (raw "max" = 18 100 kg at 114 cm). The station-clustering check
  detects this and re-queries excluding that station. The second pass still has two individual
  typos: 133 kg at 107 cm (K ≈ 11, likely 13.3 kg) and 100 kg at 20 cm age 2 (K ≈ 1250,
  probably 100 g). After flagging those by K, the **plausible heaviest is ~41 kg**.
- **Longest:** top entries are 170–179 cm (all without weight). These cannot be cross-checked
  with K and are reported as "unverifiable" — not auto-flagged as typos.

Report the plausible answers **and** disclose the flagged records as suspected data-entry errors
so the user can verify the raw data.

## Notes & caveats

- **Report both** longest and heaviest — they're usually different fish, and the longest may
  lack a weight.
- **Never report the raw `max()`** — the extreme tail is where typos live. Top N →
  station-clustering check → K sanity-check → largest plausible. See
  [`../knowledge/data-quality.md`](../knowledge/data-quality.md).
- **Station clustering is the first check.** A whole haul recorded in grams instead of kg will
  fill all top slots — Fulton's K alone won't catch it because K is computed per fish. Look for
  `serialnumber` appearing ≥3 times in the top 10 and exclude the station before going further.
- **Fulton's K** `= 100·W(g)/L(cm)³` is a species-agnostic cross-check: real fish ≈ 0.8–1.5;
  typos blow it into the tens or hundreds. Use it whenever both length and weight are present.
- **Length-only records** cannot be cross-checked with K. Report them as "unverifiable" rather
  than auto-flagging as typos — large individuals exist.
- **Memory:** `slice_max(x, n = 10)` reduces in DuckDB so only 10 rows are collected. Never
  `indall |> filter(commonname=="torsk") |> collect()` then `slice_max()`.
- Add `filter(missiontype %in% c(4, 5))` to restrict to research surveys.

## Related

- Skill: `../skills/biotic-query/SKILL.md`
- Performance: `../knowledge/performance.md`
- Glossary: `../knowledge/field-glossary.md`
