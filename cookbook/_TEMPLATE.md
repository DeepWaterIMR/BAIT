---
title: <short imperative title, e.g. "Largest cod in the database">
questions:
  - "<a natural-language question this recipe answers>"
  - "<a paraphrase the agent might also see>"
tables: [stnall]          # which flattened tables it uses
packages: [tidyverse, duckdb]
tags: [query]             # query | map | lifehistory | dashboard | maintenance
---

# <Title>

**Answers:** <one-line restatement of the question(s).>

## Approach

<2–4 sentences: which table, key columns, key filters, any unit conversion.>

## Code

```r
library(tidyverse); library(DBI); library(duckdb)

con <- dbConnect(duckdb::duckdb(),
                 dbdir = path.expand("~/IMR_biotic_BES_database/bioticexplorer.duckdb"),
                 read_only = TRUE)
stnall <- tbl(con, "stnall"); indall <- tbl(con, "indall")

# ... the query / plot ...

dbDisconnect(con, shutdown = TRUE)
```

## Expected output

<Describe the SHAPE of the result — columns, row count order of magnitude, plot type.
Use rounded or synthetic numbers ONLY. Never paste real records or coordinates.>

## Notes & caveats

- <units, NA handling, code lookups, survey/cruise-series choices, etc.>

## Related

- Skill: `../skills/<skill>/SKILL.md`
- Recipes: `<other-recipe>.md`
