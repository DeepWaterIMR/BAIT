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

### Cruise-series nicknames

Surveys go by **nicknames**, unofficial names and abbreviations (EggaN, EggaNord, EN,
Kysttokt, …) that appear nowhere in the database — `csindex` stores only the long official
`name`, so grepping it for a nickname returns nothing.

The table below is the registry: it maps every name the team uses to the authoritative
`cruiseseriescode`. When a user names a survey, look it up here across **all** name columns,
take the code, and filter on `cruiseseriescode` with the pattern above. It is generated from
a spreadsheet — see [Updating the nickname registry](#updating-the-nickname-registry).

<!-- BEGIN cruise-series-nicknames -->
| Code | Nickname | Abbreviations | Other names in use | Norwegian | Notes |
|---|---|---|---|---|---|
| 5 | Winter Survey; Barents Sea Winter Survey | WinterS; WS; BWS |  | Vintertokt | User-confirmed. |
| 6 | Ecosystem Survey; Barents Sea Ecosystem Survey | BESS; BES; EcoS |  | Økosystemtokt | User-confirmed. 'ES' is reserved for EggaS (code 25). 'ecosystem' alone is ambiguous - codes 8, 17, 26 and 32 also contain it. |
| 7 | Lofoton Survey; Cod Survey; Skrei Survey; Lofoten Cod Survey | CodS |  | Skreitokt |  |
| 9 |  | IBTS |  |  | IBTS is shared with codes 10 and 11 on purpose. This is Q1; ask which quarter is meant. |
| 10 |  | IBTS |  |  | IBTS is shared with codes 9 and 11 on purpose. This is Q2_Q3; ask which quarter is meant. |
| 11 |  | IBTS |  |  | IBTS is shared with codes 9 and 10 on purpose. This is Q4; ask which quarter is meant. |
| 15 | Shrimp Survey | ShrimpS; SS |  | Reketokt | User-confirmed. Only series whose official name contains 'shrimp'. |
| 16 | EggaNord; EggaN | EggaN; EN |  | Eggakanttokt nord; Egga-nord | Confirmed. Stored by season, not compass direction: name says 'autumn', not 'north'. |
| 17 | Norwegian Sea Ecosystem Survey | NES; NS |  | Økosystemtokt i Norskehavet |  |
| 18 | Mackerel Survey | MS |  | Makrelltokt |  |
| 20 | Deep Pelagic; Deep Pelagic Survey | DeepP; DP; DeepPelagic; DPS |  | Dyppelagisk |  |
| 23 | Coastal Survey | CoastalS; CS |  | Kysttokt | User-confirmed: this is Kysttokt; codes 28, 29 and 30 are not. Filter on the code - grepl('coastal\|kyst') matches all four. |
| 25 | EggaSouth; EggaSør; EggaS | EggaS; ES |  | Eggakanttokt sør; Egga-sør | User-confirmed. 'ES' means this survey, not the Ecosystem survey. Name says 'spring', not 'south'. |
| 33 | King Crab Survey | KingCS |  | Kongekrabbetokt |  |

> ⚠️ **Ambiguous short forms** — these map to more than one cruise series. Ask the user
> which one they mean; never pick the first match.
>
> - **IBTS** → codes 9, 10, 11

> Generated from [`cruise-series-nicknames.xlsx`](cruise-series-nicknames.xlsx) on 2026-09-09 by
> `Rscript scripts/cruise-series-nicknames.R import`. **Edit the spreadsheet, not this table.**
> `Code` is `cruiseseriescode` and is authoritative — filter on it rather than grepping
> `csindex$name`. The spreadsheet also lists every series that has no nickname yet.
<!-- END cruise-series-nicknames -->

> ⚠️ The Egga slope surveys are **stored by season, not compass direction**: the `name`
> strings are *"…continental slope NOR deep-sea fish cruise in autumn"* (EggaN, code 16) and
> *"…in spring"* (EggaS, code 25). Grepping `csindex$name` for "north"/"south" returns
> **nothing** — match on "continental" (both) then split by "autumn"/"spring", or filter on
> the code directly. Always confirm against `csindex` before relying on a code.

> ⚠️ **"Ecosystem" alone is ambiguous** — `csindex$name` has *five* cruise series containing
> "ecosystem"/"ecosystem mapping": Barents Sea autumn (code 6, **this is "the Ecosystem
> survey"/BESS/Økosystemtokt** in normal IMR usage), North Sea Q2_Q3 (8), Norwegian Sea May
> (17), Porsangerfjorden/Tanafjorden/Kvænangen spring_autumn (26), and Global OneOcean (32).
> Don't grep "ecosystem" alone and take the first/only hit — filter on "Barents Sea" +
> "autumn" too, or just use code 6 directly once confirmed against `csindex`.

### Surveys that are not a cruise series

Not every survey is registered as a cruise series. These have **no `cruiseseriescode`** at
all, so `csindex` cannot find them and any cruise-series filter returns an empty result
without erroring. Address them by cruise number.

<!-- BEGIN adhoc-surveys -->
| Survey | Other names | Norwegian | Cruise numbers | Notes |
|---|---|---|---|---|
| Spurdog Survey |  | Pigghåtokt | `c("2021011", "2022849", "2023200019", "2024215001", "2025215001")` | User-supplied. Not registered as a cruise series - cruiseseriescode is NA on all five. All are missiontype 5 (chartered vessel, Skulebas/Skulebas Senior), 2021-2025. Add the new cruise number each year. |

> These have **no `cruiseseriescode`** — `csindex` does not know them, and filtering by
> cruise series will silently return nothing. Address them by cruise number instead:
> `filter(cruise %in% c(...))` on `mission` / `stnall` / `indall`.
>
> The lists are **not self-updating** — a new survey year adds a cruise number that
> nobody has recorded here. Check the latest year before reporting a time series as
> complete, and ask the user to add missing cruises via the export/import routine.
<!-- END adhoc-surveys -->

### Updating the nickname registry

Nicknames drift and new surveys appear, so the registry is a round trip through Excel.

```bash
# 1. Refresh the spreadsheet from the database (keeps every hand-edited column)
Rscript scripts/cruise-series-nicknames.R export

# 2. The user edits knowledge/cruise-series-nicknames.xlsx and hands it back

# 3. Regenerate the table above
Rscript scripts/cruise-series-nicknames.R import
```

Run both from the repo root. The workbook has two sheets: `cruise_series` (surveys with a
`cruiseseriescode`) and `ad_hoc_surveys` (surveys without one, addressed by cruise number).
`export` rewrites only the database-derived columns — code, official name, year span, cruise
count, and an `in_database` check on every ad-hoc cruise number — and lists **every** cruise
series, including the ones nobody has named yet. `import` replaces everything between the
marker comments in both sections above and skips unnamed rows.

The spreadsheet is **not committed** — `.gitignore` blocks `*.xlsx` as a data safety net,
and that rule stays. The markdown table above is therefore the shared, version-controlled
copy, and `export` rebuilds the spreadsheet from it when the file is missing. Bump `VERSION`
and commit this file after an import.

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
- Other coded fields (maturity stage, sex, readability…) are NMDreference foreign keys.
  [`field-glossary.md`](field-glossary.md) flags which fields are codes (**code? = yes**);
  resolve them with [`reference-codes.md`](reference-codes.md) — e.g. `sex` `1 = Female`,
  `2 = Male`, `3 = Intersex`, `4 = Hermaphroditic`.

### Greenland halibut sex on the Egga surveys

For **`blåkveite` (Greenland halibut)** on EggaN/EggaS, sex has historically been recorded in
`catchpartnumber` ("delnummer") rather than `sex`: `catchpartnumber == 1` → female,
`== 2` → male. So when `sex` is `NA` for Greenland halibut on these surveys, back-fill it from
`catchpartnumber`; for other species/surveys a missing `sex` is simply not recorded. See
[`reference-codes.md`](reference-codes.md).
