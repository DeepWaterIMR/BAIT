# Data quality: reviewing extreme-value candidates

Extreme measurements can reflect real biology, unusual sampling, or data-entry problems. A
single maximum cannot distinguish these explanations. Keep the review memory-safe by selecting
a small candidate set in DuckDB, then assess each record in context. Do not automatically
exclude records or state a “largest plausible” value without user/source review.

## Review workflow

1. Pull the top candidates in DuckDB, keeping ties. Collect only needed identifiers and
   measurements.
2. Inspect mission and station context using composite keys: `missionid + serialnumber` where
   available, or the native mission key (`missiontype + startyear + platform + missionnumber`)
   plus `serialnumber`. Repeated serial numbers across missions are expected; repeated values
   within a candidate set are a clue to inspect, not proof of a systematic error.
3. Review measurements against species biology, age, units, survey context, source records, and
   internal consistency. Fulton's K can be a screening metric, but its range varies by species,
   life stage, and units. It is not a universal pass/fail threshold.
4. Present candidates and uncertainty. Identify suspected errors as hypotheses and explain
   evidence. Preserve candidates with missing cross-checks as unresolved. Confirm exclusions or
   corrections with the user or source data before using them to select an answer.

## Example screening code

```r
candidates <- indall |>
  filter(commonname == "torsk", !is.na(individualweight)) |>
  slice_max(individualweight, n = 10, with_ties = TRUE) |>
  select(missionid, missiontype, startyear, platform, missionnumber,
         station, serialnumber, length, individualweight, age, sex) |>
  collect() |>
  mutate(
    length_cm = length * 100,
    K = if_else(
      !is.na(length_cm) & length_cm > 0 & !is.na(individualweight),
      100 * individualweight * 1000 / length_cm^3,
      NA_real_
    )
  )

# Inspect rather than exclude based on thresholds or repeated station identifiers.
candidates
```

`K` above is only a screening value. Check the input units and consider species-specific
biology before interpreting it. The method is: small candidate set, contextual review, and a
transparent explanation of confirmed and unresolved concerns.

## Checks after each database update

`scripts/db-update-report.R` (run automatically by the update job in
[`../skills/biotic-server-setup/SKILL.md`](../skills/biotic-server-setup/SKILL.md)) compares the
database with a snapshot taken before the update and checks the new and changed missions for:
text-encoding problems, catch rows without an AphiaID, new spellings of existing species names,
missing or impossible positions, station dates outside the mission year, negative or
species-unusual catch weights, impossible lengths/weights/ages (grouped by species, so unit
slips such as grams entered as kg show up as one line), length-weight outliers relative to the
species' median Fulton's K, duplicated catch samples or individuals, and removed data. Known
source-data issues found when the script was written (2026-10): king crab individual weights
1994–2016 stored in grams; brisling lengths of -99.99 (missing-value code) 1926–2015; a few
2026 Coast Guard cod/saithe/haddock weights in grams.

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

