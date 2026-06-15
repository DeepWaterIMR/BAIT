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
5. **Build lazily; aggregate/filter in DuckDB; `collect()` only the small final result.**
   This is a hard rule — see [`../../knowledge/performance.md`](../../knowledge/performance.md).
   **Never `collect()` a whole table** (millions of rows can freeze the machine), and for any
   query of unknown size, **count first, estimate memory, and ask before a large collect.**
6. **Report units correctly:** `length` is metres (×100 for cm), weights are kg.
7. **Answer the whole question.** "Largest" is ambiguous → give **both** longest and heaviest.
8. **Sanity-check extremes for data-entry errors.** The single `max()` is the record most
   likely to be a typo. Pull the **top ~10**, check against biology / Fulton's K, tell the user
   about likely typos, and report the largest **plausible** record — never the raw max. See
   [`../../knowledge/data-quality.md`](../../knowledge/data-quality.md).
9. If the question is new, **offer to save a cookbook recipe** (see `../../CONTRIBUTING.md`).

## Patterns

**Largest / extreme value — pull the top N, sanity-check, report the largest *plausible* row**
The single max is the record most likely to be a data-entry error. Pull the **top ~10**
(cheap — still reduced in DuckDB), flag implausible rows, and answer with the largest plausible
one. Report both length and weight, since "largest" is ambiguous.
```r
# Top heaviest candidates, descending — only N rows collected
cand <- indall |>
  filter(commonname == "torsk", !is.na(individualweight)) |>
  slice_max(individualweight, n = 10) |>
  select(startyear, serialnumber, length, individualweight, age, sex) |>
  collect() |>
  mutate(
    length_cm = length * 100,
    K = 100 * (individualweight * 1000) / (length_cm)^3,   # Fulton's K (~0.8–1.5 for cod)
    flag = is.na(K) | K < 0.4 | K > 3 | individualweight > 60   # tune per species
  )

cand                                                       # inspect: flagged = suspected typos
heaviest <- cand |> filter(!flag) |> slice_max(individualweight, n = 1)  # the real answer
# Do the same for `length` (longest), flagging against a plausible max length for the species.
```
Don't `collect()` all cod and take the max in R — that pulls millions of rows. Don't report the
raw `max()` either — it may be a typo. See
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

**Catch of a species on a named survey (cruise series)** — see the cruise-series filter
in [`../../knowledge/species-and-surveys.md`](../../knowledge/species-and-surveys.md) and
the worked recipe [`../../cookbook/map-cusk-eggan.md`](../../cookbook/map-cusk-eggan.md).

**Get tidy data, then map / plot** → [`../biotic-maps/SKILL.md`](../biotic-maps/SKILL.md),
[`../biotic-lifehistory/SKILL.md`](../biotic-lifehistory/SKILL.md).

## Cautions

- A column may not exist in every build — check `colnames()` first.
- Coordinates: drop `NA` and bad values (`latitudestart > 0`) before mapping.
- Empty-catch stations can have `commonname = NA`.
- Some operations aren't supported lazily in DuckDB — if a verb errors, reduce/aggregate as
  much as possible first, then `collect()` the **minimal** subset and finish in R.
- **Memory:** never `collect()` a whole table; do max/mean/count in DuckDB; count + estimate
  before a large collect and ask the user. See
  [`../../knowledge/performance.md`](../../knowledge/performance.md).
- **Data-entry errors:** the extreme tail is where typos hide (a 179 cm cod, an 18 100 kg
  fish). Never report the raw `max()` as "the largest"; pull the top ~10, flag the implausible
  ones for the user, and answer with the largest plausible record. See
  [`../../knowledge/data-quality.md`](../../knowledge/data-quality.md).
- **Privacy:** show the user aggregates/derived results; never paste large raw extracts into
  the chat or write them to committed files.
