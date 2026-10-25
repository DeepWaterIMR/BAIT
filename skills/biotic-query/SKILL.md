---
name: biotic-query
description: Turn a natural-language question about IMR Biotic data into a tidyverse/dplyr query against the DuckDB database (e.g. "largest cod?", "all cusk on EggaN", "how many haddock per year"). Use for any data-retrieval or summary question.
---

# Answer data questions (NL → dplyr)

## Workflow

1. **Connect** (read-only, lazy) — [`../biotic-connect/SKILL.md`](../biotic-connect/SKILL.md).
2. **Pick the table** — [`../../knowledge/data-model.md`](../../knowledge/data-model.md):
   `mission` (cruises), `stnall` (catches/positions), `indall` (measured fish).
3. **Map words → columns** — [`../../knowledge/field-glossary.md`](../../knowledge/field-glossary.md).
   Don't guess column names; confirm with `colnames(stnall)`.
4. **Resolve species/surveys** — [`../../knowledge/species-and-surveys.md`](../../knowledge/species-and-surveys.md).
   `commonname` is **Norwegian**; surveys are **cruise series**.
5. For survey catches or station summaries, define the key, catchsample aggregation, quality
   rule, and true-zero roster using [`../../knowledge/sampling-units.md`](../../knowledge/sampling-units.md)
   and [`../biotic-survey-analysis/SKILL.md`](../biotic-survey-analysis/SKILL.md).
6. **Build lazily; aggregate/filter in DuckDB; `collect()` only the small final result.**
   This is a hard rule — see [`../../knowledge/performance.md`](../../knowledge/performance.md).
   **Never `collect()` a whole table** (millions of rows can freeze the machine), and for any
   query of unknown size, **count first, estimate memory, and ask before a large collect.**
7. **Report units correctly:** `length` is metres (×100 for cm), weights are kg.
   **Decode coded columns** before showing them to the user — `sex`, `maturationstage`, etc.
   are codes, not labels (`sex 1 = Female`, `2 = Male`). See
   [`../../knowledge/reference-codes.md`](../../knowledge/reference-codes.md).
8. **Answer the whole question.** "Largest" is ambiguous → give **both** longest and heaviest.
9. **Review extreme-value candidates.** Pull a small top set, check units, biology, and mission
   and station context, then present candidates with evidence and uncertainty. Do not
   auto-exclude a station or record based on repeated serial numbers or a generic threshold.
   Confirm suspected errors with source/context review. See
   [`../../knowledge/data-quality.md`](../../knowledge/data-quality.md).
10. If the question is new, **offer to save a cookbook recipe** (see `../../CONTRIBUTING.md`).

## Patterns

**Largest / extreme value — review candidates, then explain uncertainty**
Pull a small top set in DuckDB and keep ties. Check units, biology, age, and mission/station
context. Repeated serial numbers or unusual K values are clues to investigate, not automatic
exclusions or proof of error. Confirm suspected errors against source/context before deciding
which candidate to report.

```r
# Top heaviest candidates, descending — only a small set is collected
cand <- indall |>
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

cand  # inspect candidates; K is a screening metric, not an automatic filter
```

Don't `collect()` all cod and take the max in R — that pulls millions of rows. Don't report an
unchecked `max()` as a confirmed result. See
[`../../knowledge/data-quality.md`](../../knowledge/data-quality.md) and the recipe
[`../../cookbook/largest-cod.md`](../../cookbook/largest-cod.md).

**Filter to research surveys**
```r
stnall |> filter(missiontype %in% c(4, 5))   # surveys only
```

**Count / summarise by group**
```r
indall |>
  filter(commonname == "hyse", missiontype %in% c(4, 5)) |>
  count(startyear) |>
  arrange(startyear) |>
  collect()
```

**Catch of a species on a named survey (cruise series)** — survey nicknames and
abbreviations (EggaN, EggaNord, EN, Kysttokt, BESS, …) exist nowhere in the database, so
resolve the name to a `cruiseseriescode` with the nickname registry in
[`../../knowledge/species-and-surveys.md`](../../knowledge/species-and-surveys.md), then use
the cruise-series filter there. A few short forms are ambiguous on purpose (`IBTS` covers
codes 9, 10 and 11 — Q1, Q2_Q3 and Q4); the registry flags them, so ask which one is meant
rather than guessing. Some surveys — the Spurdog Survey (Pigghåtokt) among them — have **no**
cruise-series code and must be selected by cruise number; a cruise-series filter returns
nothing for those without erroring, so check the ad-hoc table in the same file. Worked recipe:
[`../../cookbook/map-cusk-eggan.md`](../../cookbook/map-cusk-eggan.md).

**Get tidy data, then map / plot** → [`../biotic-maps/SKILL.md`](../biotic-maps/SKILL.md),
[`../biotic-lifehistory/SKILL.md`](../biotic-lifehistory/SKILL.md).

## Cautions

- A column may not exist in every build — check `colnames()` first.
- Coordinates: drop `NA` and bad values (`latitudestart > 0`) before mapping.
- Empty-catch stations can have `commonname = NA`.
- **Write species filters with `commonname`, verify them with `aphia`.** Human-readable code
  should filter on the Norwegian `commonname` (`filter(commonname == "blåkveite")`). But
  `commonname` is free text copied from each delivery, so before trusting the result check
  that the name catches every record of the species: count rows per year for the species'
  `aphia` (e.g. blåkveite = `"127144"`) and compare with the `commonname` filter. Years present
  under `aphia` but missing under `commonname` mean a spelling change or corrupted text. List
  the spellings with `filter(aphia == "127144") |> count(commonname)`. Text such as
  `bl<c3><a5>kveite` is encoding corruption, not a spelling variant: follow
  [`../../knowledge/data-quality.md`](../../knowledge/data-quality.md#text-encoding-corruption)
  rather than working around it in the query.
- `stnall` can contain several catchsample rows per fishstation. Do not count rows as hauls or
  sum catch parts until their relationship is known.
- Some operations aren't supported lazily in DuckDB — if a verb errors, reduce/aggregate as
  much as possible first, then `collect()` the **minimal** subset and finish in R.
- **Memory:** never `collect()` a whole table; do max/mean/count in DuckDB; count + estimate
  before a large collect and ask the user. See
  [`../../knowledge/performance.md`](../../knowledge/performance.md).
- **Extreme values:** retrieve a small candidate set and inspect units, biology, and composite
  mission/station context. An unusual value or repeated identifier prompts review; it is not
  proof of error. Do not auto-exclude records. See
  [`../../knowledge/data-quality.md`](../../knowledge/data-quality.md).
- **Privacy:** show the user aggregates/derived results; never paste large raw extracts into
  the chat or write them to committed files.
