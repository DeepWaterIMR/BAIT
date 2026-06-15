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
5. **Build lazily, `collect()` once at the end.** Let DuckDB do the work.
6. **Report units correctly:** `length` is metres (×100 for cm), weights are kg.
7. If the question is new, **offer to save a cookbook recipe** (see `../../CONTRIBUTING.md`).

## Patterns

**Largest / extreme value**
```r
indall |>
  filter(commonname == "torsk", !is.na(length)) |>
  slice_max(length, n = 1) |>
  collect() |>
  mutate(length_cm = length * 100)        # length is in metres
```

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
- Some operations aren't supported lazily in DuckDB — if a verb errors, `collect()` the
  minimal subset first, then finish in R.
- **Privacy:** show the user aggregates/derived results; never paste large raw extracts into
  the chat or write them to committed files.
