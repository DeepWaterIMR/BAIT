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
8. If the question is new, **offer to save a cookbook recipe** (see `../../CONTRIBUTING.md`).

## Patterns

**Largest / extreme value — reduce in DuckDB, and report both length and weight**
```r
# longest
longest <- indall |>
  filter(commonname == "torsk", !is.na(length)) |>
  filter(length == max(length, na.rm = TRUE)) |>          # max computed in DuckDB
  select(commonname, startyear, serialnumber, length, individualweight, age, sex) |>
  collect() |> mutate(length_cm = length * 100)           # length is in metres

# heaviest
heaviest <- indall |>
  filter(commonname == "torsk", !is.na(individualweight)) |>
  filter(individualweight == max(individualweight, na.rm = TRUE)) |>
  select(commonname, startyear, serialnumber, length, individualweight, age, sex) |>
  collect()
```
Don't `collect()` all cod and take the max in R — that pulls millions of rows. See the recipe
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
- **Privacy:** show the user aggregates/derived results; never paste large raw extracts into
  the chat or write them to committed files.
