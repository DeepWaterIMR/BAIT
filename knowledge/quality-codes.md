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
```

If `gearcondition_codes` or `samplequality_codes` is empty, the database predates the relevant `codeindex` refresh or that refresh failed. Update the database references with BioticExplorerServer before interpreting unfamiliar codes. The NMD Biotic schema identifies both fields as extensible reference keys: <https://www.imr.no/formats/nmdbiotic/v3/nmdbioticv3_en.html>.
