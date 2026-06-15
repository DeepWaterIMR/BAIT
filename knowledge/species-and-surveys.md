# Species, surveys, and codes

How to turn English/scientific names and survey names into the values the database actually
stores.

## Species — `commonname` is in Norwegian

Filter `stnall`/`indall` on `commonname` using the **Norwegian** name.

**Primary source — the `taxaindex` table.** The database (built by BioticExplorerServer)
carries a `taxaindex` table mapping taxa (`tsn`) → name + synonyms. Use it to translate an
English/scientific name into the Norwegian `commonname` the data uses — everything from the
database, no network calls:

```r
taxa <- dplyr::tbl(con, "taxaindex") |> dplyr::collect()
# search every name/synonym column for a term:
taxa |> dplyr::filter(dplyr::if_any(dplyr::everything(),
                                    ~ grepl("brosme", ., ignore.case = TRUE)))
```

Then confirm the exact value used in the data:

```r
stnall |> dplyr::distinct(commonname) |> dplyr::filter(commonname %like% "brosme") |> dplyr::collect()
```

**Fallback** — only if `taxaindex` is absent (an older database): common species —

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

> Don't hard-code species names from memory beyond the obvious — prefer the `taxaindex`
> lookup above, and always confirm with `distinct(commonname)`. Species/genus also appear via
> `catchcategory`.

## Surveys — use the cruise-series lookup, not guesswork

A "survey" (e.g. EggaN, Coastal survey) is a **cruise series**. The database stores a
comma-separated `cruiseseriescode` column on `mission`/`stnall`, and the **`csindex`** table
maps **code → name**. `csindex` is loaded for you by `biotic-connect` — use it directly
(don't re-load it or call a package).

**Pattern:**

```r
# 1. Find the cruise-series code(s) by name — csindex is loaded by biotic-connect
csList <- csindex |>
  dplyr::distinct(cruiseseriescode, name) |>
  dplyr::collect()

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

### Cruise-series nicknames (living list — users expand it)

Surveys go by **nicknames** (EggaN, Kysttokt, …). Map a nickname to a search term for
`csindex$name`, then use the pattern above. This list grows as the team confirms the exact
`name` strings and codes — **add a row whenever you learn or are taught a new one**, and
verify the search term against `csindex` before relying on it.

| Survey (nickname) | `csindex$name` contains | Notes |
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
- **`gear`** — numeric code; the `gearindex` table (built into the database) resolves
  code → gear name/category.
- Other coded fields (maturity stage, sex, readability…) are NMDreference foreign keys;
  see [`field-glossary.md`](field-glossary.md) for which fields are codes.
