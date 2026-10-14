# Data quality: spotting data-entry errors in extreme-value queries

Biotic is field-collected data and contains **data-entry errors** — a misplaced decimal,
a grams-for-kilograms slip, a transposed digit. These errors cluster exactly where
"largest / heaviest / oldest" queries look: at the extreme tail. The single maximum is the
record **most likely** to be wrong.

> **Rule:** never report the raw `max()` of a measurement as "the largest". Pull the **top N**,
> sanity-check them, **tell the user about likely typos**, and report the largest **plausible**
> record as the answer.

## Why `filter(x == max(x))` is a trap

`filter(x == max(x, na.rm = TRUE))` returns whatever sits at the top — including a 3 m cod or
an 18 100 kg fish. It is memory-safe (good) but it answers with the error (bad). Always look at
the **top ~10**, not the top 1.

## The technique

1. **Pull the top N descending** in DuckDB (`slice_max(x, n = 10)` or
   `arrange(desc(x)) |> head(10)`) — only N rows collected, so still memory-safe.
2. **Check for station clustering.** If multiple of the top-N records share the same
   `serialnumber`, that is a station-level systematic error — e.g. one haul where weights were
   recorded in grams instead of kg. A single station appearing **three or more times in the top
   10 is a strong red flag**. Exclude that `serialnumber` and re-query to find the true extreme.
   Do this before any other sanity check.
3. **Sanity-check** each remaining candidate against:
   - **Internal consistency** — for fish with both length and weight, **Fulton's condition
     factor** `K = 100 · W(g) / L(cm)³`. Real fish sit around **K ≈ 0.8–1.5** for most
     demersal species; a typo (e.g. 133 kg at 107 cm, or 100 kg at 20 cm) gives K in the
     tens or hundreds. This check is species-agnostic and should be the primary filter.
   - **Known biology** — plausible max length/weight/age for the species (see bounds below).
     Use these as a secondary check when K cannot be computed (e.g. weight is missing).
   - **Age consistency** — a 2-year-old fish weighing 100 kg is implausible regardless of K.
   - **Length-only outliers** (no weight): K cannot be computed. Do not auto-flag these —
     report them as "unverifiable without weight" and note the missing cross-check.
4. **Report**: state the largest **plausible** record as the answer, then list the flagged
   records separately as **suspected data-entry errors**, with the likely cause
   (e.g. "100 kg at 20 cm — probably 100 g; 133 kg at 107 cm — likely grams-for-kg slip on
   a whole haul") and a suggestion to verify the raw record.

## Reference bounds (Northeast Atlantic; rough, for flagging only)

| Species (`commonname`) | Plausible max length | Plausible max weight | Notes |
|---|---|---|---|
| torsk (Atlantic cod)   | up to ~180 cm | ~40–60 kg (rarely ~95 kg) | Use K as primary check; length outliers without weight are unverifiable |
| hyse (haddock)         | ~110 cm | ~14 kg | |
| sei (saithe)           | ~130 cm | ~30 kg | |
| blåkveite (Greenland halibut) | ~130 cm | ~45 kg | |
| kveite (Atlantic halibut) | ~300 cm | ~300 kg | genuinely huge — high bounds |
| uer / snabeluer (redfish) | ~50–100 cm | ~15 kg | depends on species |

These are deliberately generous flagging thresholds, not biological records. When unsure of a
species' limits, lean on the **condition-factor** cross-check, which is species-agnostic.

## Recommended code pattern

```r
# Step 1 — top 10 candidates, reduced in DuckDB (only 10 rows collected)
cand <- indall |>
  filter(commonname == "torsk", !is.na(individualweight)) |>
  slice_max(individualweight, n = 10) |>
  select(startyear, serialnumber, length, individualweight, age, sex) |>
  collect() |>
  mutate(
    length_cm = length * 100,
    K = ifelse(!is.na(length) & length > 0,
               100 * (individualweight * 1000) / (length_cm)^3, NA_real_)
  )

# Step 2 — station-clustering check: is any serialnumber dominant?
station_counts <- count(cand, serialnumber, sort = TRUE)
print(station_counts)   # if one station has ≥3 entries, treat it as a systematic error

# Step 3 — if bad station(s) detected, exclude and re-query
bad_stations <- station_counts |> filter(n >= 3) |> pull(serialnumber)

if (length(bad_stations) > 0) {
  cand <- indall |>
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

# Step 4 — flag remaining implausible records via Fulton's K
cand <- cand |>
  mutate(flag = (!is.na(K) & (K < 0.4 | K > 3)))

cand                                   # inspect: flagged rows are suspected individual typos
answer <- cand |> filter(!flag) |> slice_max(individualweight, n = 1)
```

The **station-clustering check is the most important step**: a single haul with grams-for-kg
entries will dominate all top-10 slots and make Fulton's K look fine after correction — you'd
never discover the error from K alone. Check clustering first, then apply K to the clean set.

Adjust the `flag` thresholds per species and question. The point is the **workflow**: top N →
cluster check → K sanity-check → report the largest plausible value and disclose the suspects,
never the raw max.

## Related

- Skill: `../skills/biotic-query/SKILL.md`
- Recipe: `../cookbook/largest-cod.md`
- Performance (why we still reduce in DuckDB): `../knowledge/performance.md`
- Glossary (units): `../knowledge/field-glossary.md`

## Text-encoding corruption

Databases compiled or updated with BioticExplorerServer <= 0.8.8 under a non-UTF-8 locale store
Norwegian characters as literal escape text: `blåkveite` → `bl<c3><a5>kveite`, `Sjøfareren` →
`Sj<c3><b8>fareren`. Every free-text column is affected (`commonname`, `platformname`,
`missiontypename`, `purpose` and all comment fields), but only for the years written by the
faulty run, typically the most recent ones after an incremental update. The result is two
spellings of the same name, so `filter(commonname == "blåkveite")` silently loses those years.
The usual cause is a background `Rscript` (screen, cron, an agent's shell) started with `LANG`
unset.

**Detect** (read-only, cheap; `biotic-connect` runs this after connecting):

```r
DBI::dbGetQuery(con, "
  SELECT 'stnall' AS tab, count(*) AS n FROM stnall
   WHERE regexp_matches(commonname, '<[89a-f][0-9a-f]>')
  UNION ALL
  SELECT 'mission', count(*) FROM mission
   WHERE regexp_matches(platformname, '<[89a-f][0-9a-f]>')")
```

Any `n > 0` means the database is affected. Tell the user before answering species or platform
questions from it: name the affected years (`count(startyear)` on the same filter) and the
likely consequence for their query.

**Act** — this is a database problem, never something to patch in the query:

1. **Repair (preferred, minutes).** Close every connection to the database (R sessions,
   BioticExplorer), make sure BioticExplorerServer is >= 0.8.9
   (`remotes::install_github("DeepWaterIMR/BioticExplorerServer")`), then in a **fresh** R
   session:

   ```r
   BioticExplorerServer::repairDatabaseEncoding(dryRun = TRUE)  # what would change
   BioticExplorerServer::repairDatabaseEncoding()               # repair in place + re-index
   ```

   Re-run the detection query; it must return 0. The repair asks no questions, but it writes to
   the user's database, so confirm with the user first.
2. **Rebuild (fallback, hours).** If the repair errors, leaves escaped text behind, or other
   corruption is suspected: `compileDatabase(overwrite = TRUE)` as a monitored background job
   (see [`../skills/biotic-server-setup/SKILL.md`](../skills/biotic-server-setup/SKILL.md)).
3. **Report.** If a database built with BioticExplorerServer >= 0.8.9 shows this corruption, or
   the repair fails, that is a new bug. Draft an issue for
   <https://github.com/DeepWaterIMR/BioticExplorerServer/issues> with the BES version
   (`packageVersion("BioticExplorerServer")`), the `metadata` table, `Sys.getlocale()`, the
   detection-query output, and one example `hex(commonname)`. Show it to the user and let them
   submit it (no data rows beyond the example names: see `biotic-privacy`).

