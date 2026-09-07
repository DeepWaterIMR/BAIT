# Sample and gear quality codes

Quality codes describe sampling circumstances; they are not a universal ordered scale. Decode them from the reference tables available with the data and define a survey-specific acceptance rule before analysis.

## `samplequality`

The current BES `codeindex` defines the principal research-survey codes as follows:

| Code | Meaning | Quantitative interpretation |
|---|---|---|
| 1 | Gear deployed at a preselected position; trawl sensors indicated normal operation | Design-based station with normal gear operation |
| 2 | Gear deployed on an acoustic registration or other information about fish; sensors indicated normal operation when used | Targeted station; technically valid, but not equivalent to a preselected station |
| 3 | Preselected station with bottom-contact, spread, or other gear-performance problems | Gear performance may invalidate quantitative use |
| 4 | Targeted station with gear-performance problems | Targeting and gear-performance concerns |
| 5 | Gear did not fish correctly because of rigging, obstruction, twisting, or another problem | Failed gear operation |
| 6 | Catch was not representative because of a failed set or substantial stones, sponge, clay, or similar material | Non-representative catch |

Codes 7–11 describe commercial-fishery reporting or catch handling, and codes 12–14 are NANSIS use classes. The former experimental-trawl code 100 is deprecated and excluded from current BES reference tables. Reference lists are extensible, so query the database rather than assuming this table is exhaustive.

Code 2 is not simply “lower quality.” It identifies targeted sampling. It may be appropriate for descriptive survey analyses or a specific index if the target-selection mechanism is compatible with the estimand and is documented. It should not be pooled silently with code 1 in a design-based analysis.

## `gearcondition`

The NMD schema defines `gearcondition` as the condition of the gear after the haul. BioticExplorerServer 0.8.5 and later include both `gearcondition` and `samplequality` in the default `codeindex` refresh.

| Code | Meaning | Quantitative interpretation |
|---|---|---|
| 1 | Gear OK | Normal operation |
| 2 | Minor damage with no material effect on selectivity or catch | May be retained with code 1 |
| 3 | Gear damaged; some fish may have escaped | Catch may be biased |
| 4 | Long tears or large pieces of netting missing; codend intact | Substantial damage |
| 5 | Codend torn; little catch | Failed quantitative catch |
| 6 | Gear completely destroyed | Failed operation |
| 7 | Gear lost | No quantitative catch |
| 8 | Rigging or deployment problems (NANSIS) | Survey-specific failure/problem class |
| 9 | Fishing operation aborted (NANSIS) | Incomplete operation |

Deprecated codes 101, 102, 103, and 106 described whether a trawl hit a targeted acoustic registration. BES excludes deprecated reference rows from `codeindex`; do not use these codes in new filtering rules.

Codes 1–2 can normally be retained when minor damage is irrelevant to the response. The analytical rule remains survey-specific: inspect observed codes and document why each retained class yields a quantitative sample.

## `stationtype`

`stationtype` flags *why* a station was taken, and it is the field that identifies stations whose catch is not representative of the survey design. It is easy to miss because the column is named `stationtype` in Biotic, while the NMD Reference API publishes its code list under a different name, **`fishstationtype`**. A lookup keyed on the literal string `stationtype` returns an unrelated registry of hydrography, acoustic and plankton station types (codes 1000–4420) that decodes none of the values found in `stnall`. BioticExplorerServer resolved that wrong dataset before version 0.8.8; run `updateDatabase()` to refresh `codeindex` if your database predates it.

| Code | Norwegian shortname | Meaning |
|---|---|---|
| 1 | Inngår i døgnst. | Part of a 24-hour (døgn) station |
| 2 | Inngår i redsk.f. | Part of a gear trial |
| 3 | Vanlig, inngår i fors. | Part of a gear trial, but also a regular fish station |
| 4 | Flerpose | Part of a multi-codend trawl station whose codends fish at different times or depths |
| 5 | Hovedpose | Main codend |
| 6 | Babord pose | Port codend |
| 7 | Senterpose | Centre codend |
| 8 | Styrbord pose | Starboard codend |
| 9 | Vanlig fiskestasjon | Regular fish station |
| 10 | Døgnstasjon i referanseflåten | Reference-fleet 24-hour station; the day's total catch |
| 11 | Stasjon for identifisering av akustisk registrering (Nansis) | Station taken to identify an acoustic registration |
| 12 | Forhåndsutvalgt stasjon for swept-area analyse (Nansis) | Preselected station for swept-area analysis |
| 13 | Tilleggstasjon | Additional station, preselected for a special purpose |
| A | I stengt område | Station inside a closed area, taken to document closure of a fishing field because of a species |
| C | Bestemt formål | Station taken for a specific purpose where the catch is **not** representative |
| D | Industritråler | Catch from an industrial trawler |
| E | Ringnot/kolmule | Catch from a purse seiner or blue-whiting trawler |
| H | Turstasjon | Trip station: all catch for the whole trip is registered, e.g. to capture bycatch that cannot be allocated to individual hauls |
| I | Inngår i turstn. | Also part of a trip station |

### Excluding non-representative stations

Codes **2, C, A and E** are the ones most often excluded from quantitative survey analyses:

- **C** is explicit — the registry itself states the catch is not representative.
- **A** is targeted at a species to justify closing a fishing field, so it is not design-representative.
- **2** is a gear trial, where catchability is not comparable to the standard gear.
- **E** is commercial purse-seine/blue-whiting catch rather than a survey haul.

Consider **D** (commercial industrial-trawler catch) on the same grounds, and treat **H** and **I** with care: a trip station aggregates a whole trip, so it is not a haul-level sampling unit and will double-count if pooled with the individual hauls it summarises. As with the other quality fields, the rule is survey-specific — inspect the codes actually present and document the choice.

### `NULL` is the normal case — do not drop it

Most stations carry no `stationtype` at all (about 72% of `stnall` rows): an ordinary station with no special flag, which must be **retained**. This creates a trap, because the filter runs in DuckDB, not in R. SQL `NOT IN` evaluates to `NULL` — not `TRUE` — when the column is `NULL`, so those rows are discarded silently:

```r
# WRONG - silently drops every station with a NULL stationtype (~2.2 of 3.1 million rows)
stn |> dplyr::filter(!stationtype %in% c("2", "A", "C", "E"))

# RIGHT - keep unflagged stations explicitly
stn |> dplyr::filter(is.na(stationtype) | !stationtype %in% c("2", "A", "C", "E"))
```

Negated `%in%` is the only common predicate that changes meaning across the `collect()` boundary, so the same line behaves differently before and after `collect()`. Other predicates (`!=`, `>`, bare `%in%`) drop missing values consistently in both engines — which is also usually wrong for these fields. The same care applies to any nullable coded column, including `samplequality` and `gearcondition`. See [`connection.md`](connection.md#missing-values-across-the-collect-boundary) for the full comparison, and always count rows before and after a filter to check the difference against what you expected to remove.

## Read the codes locally

```r
codeindex <- dplyr::tbl(con, "codeindex")

samplequality_codes <- codeindex |>
  dplyr::filter(reftable == "samplequality") |>
  dplyr::select(code, shortname, description) |>
  dplyr::collect()

gearcondition_codes <- codeindex |>
  dplyr::filter(reftable == "gearcondition") |>
  dplyr::select(code, shortname, description) |>
  dplyr::collect()

# Stored under the Biotic column name, even though the API dataset is `fishstationtype`
stationtype_codes <- codeindex |>
  dplyr::filter(reftable == "stationtype") |>
  dplyr::select(code, shortname, description) |>
  dplyr::collect()
```

If `gearcondition_codes` or `samplequality_codes` is empty, the database predates the relevant `codeindex` refresh or that refresh failed. Update the database references with BioticExplorerServer before interpreting unfamiliar codes. If `stationtype_codes` returns four-digit codes (1000–4420) rather than `1`–`13`/`A`–`I`, the database was built before BioticExplorerServer 0.8.8 and carries the wrong reference dataset; refresh it with `updateDatabase()`. The NMD Biotic schema identifies both fields as extensible reference keys: <https://www.imr.no/formats/nmdbiotic/v3/nmdbioticv3_en.html>.
