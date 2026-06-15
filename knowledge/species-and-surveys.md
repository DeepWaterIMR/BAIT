# Species, surveys, and codes

How to turn English/scientific names and survey names into the values the database actually
stores.

## Species — `commonname` is in Norwegian

Filter `stnall`/`indall` on `commonname` using the **Norwegian** name. Common ones:

| English | Scientific | `commonname` |
|---|---|---|
| Atlantic cod | *Gadus morhua* | `torsk` |
| Haddock | *Melanogrammus aeglefinus* | `hyse` |
| Saithe | *Pollachius virens* | `sei` |
| Ling | *Molva molva* | `lange` |
| Blue ling | *Molva dypterygia* | `blålange` |
| Cusk / tusk | *Brosme brosme* | `brosme` |
| Atlantic halibut | *Hippoglossus hippoglossus* | `kveite` |
| Greenland halibut | *Reinhardtius hippoglossoides* | `blåkveite` |
| Golden redfish | *Sebastes norvegicus* | `vanlig uer` |
| Beaked redfish | *Sebastes mentella* | `snabeluer` |
| Spurdog / spiny dogfish | *Squalus acanthias* | `pigghå` |
| Greater silver smelt | *Argentina silus* | `vassild` |

> Don't hard-code from memory beyond the obvious. **Verify** against the database:
> ```r
> stnall |> distinct(commonname) |> filter(commonname %like% "uer") |> collect()
> ```
> **Full name lookup:** the `taxaindex` table maps taxa (`tsn`) → name + synonyms — use it to
> resolve `commonname` ↔ scientific name without a network call:
> ```r
> taxa <- dplyr::tbl(con, "taxaindex") |> collect()
> taxa |> dplyr::filter(grepl("Brosme", name, ignore.case = TRUE))
> ```
> If the database predates the taxa table, fetch the live reference with
> `BioticExplorerServer::prepareTaxaList()`. Species/genus also appear via `catchcategory`.

## Surveys — use the cruise-series lookup, not guesswork

A "survey" (e.g. EggaN, Coastal survey) is a **cruise series**. The database stores a
comma-separated `cruiseseriescode` column on `mission`/`stnall`, and
`BioticExplorerServer::cruiseSeries` (also the `csindex` table) maps **code → name**.

**Pattern (verified against the maintainer's own scripts):**

```r
library(BioticExplorerServer)

# 1. Find the cruise-series code(s) by name
csList <- BioticExplorerServer::cruiseSeries |>
  dplyr::select(cruiseseriescode, name) |>
  unique()

selCS  <- csList[grepl("continental", csList$name, ignore.case = TRUE), ]  # EggaN/EggaS
csFilt <- selCS$cruiseseriescode

# 2. cruiseseriescode is comma-separated → match the code anywhere in the list
filtExp <- paste(sapply(csFilt, function(k) {
  paste0("cruiseseriescode %like% '", k, ",%' | ",
         "cruiseseriescode %like% '%,", k, "' | ",
         "cruiseseriescode %like% '%,", k, ",%' | ",
         "cruiseseriescode %in% c('", k, "')")
}), collapse = " | ")

# 3. Apply to any table
stn <- stnall |> dplyr::filter(!!!rlang::parse_exprs(filtExp)) |> collect()
```

Common survey series (confirm the exact `name` string with the lookup above):

| Survey | Norwegian / series name contains | Notes |
|---|---|---|
| EggaN | "continental" slope, **north** | Slope survey, Norwegian Sea / N |
| EggaS | "continental" slope, **south** | Slope survey, southern part |
| Coastal survey (Kysttokt) | "coastal" / "kyst" | Coastal cod, ling, etc. |
| Winter survey (Vintertokt) | "winter" | Barents Sea winter |
| Ecosystem survey (Økosystemtokt) | "ecosystem" | Barents Sea autumn |
| Shrimp survey (Reketokt) | "shrimp" / "reke" | |
| Spurdog survey (Pigghåtokt) | "spurdog" / "pigghå" | |

## `missiontype` — survey vs. commercial

- **Research surveys**: `missiontype %in% c(4, 5)` (used throughout the maintainer's scripts).
- `missiontypename` gives the human-readable label. Always sanity-check:
  ```r
  mission |> distinct(missiontype, missiontypename) |> collect()
  ```

## Areas and gear (foreign keys → NMDreference)

- **`icesarea`** (on `stnall` in the DuckDB build) — e.g. ICES subareas/divisions like
  `"27.1"`, `"27.2.a"`. Filter with `%like%` / `grepl()` on the prefix.
- **`gear`** — numeric code; the `gearindex` table (and
  `BioticExplorerServer::prepareGearList()`) resolve code → gear name/category.
- Other coded fields (maturity stage, sex, readability…) are NMDreference foreign keys;
  see [`field-glossary.md`](field-glossary.md) for which fields are codes.
