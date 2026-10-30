---
name: catch-data
description: Extract and prepare Norwegian commercial catch data with RstoxUtils — sales notes (landings, sluttseddel) from the IMR API since 2005 and the historical Excel files, ERS electronic logbooks from the Directorate of Fisheries open data, and FDIR species, gear and area codes. Use for "landings of <species>", "catch series for the assessment", "catches by gear or nation", logbook positions or effort, or when spict-wise or gadget-wise needs a catch input. Needs the IMR intranet for sales notes.
---

<!-- pack-resources:start -->
**Pack resources:** the `BAIT` root is `~/.bait/config.json` → `bait_path`, else `~/.fiskwise/config.json` →
`components.BAIT.path`, else the checkout containing this skill. Paths such as `knowledge/`
and `project-template/` are relative to that root, never `../../` from a skills folder; resolve
links that leave this skill's folder against the source skill there. Use absolute paths.
<!-- pack-resources:end -->


# Norwegian catch data

[RstoxUtils](https://deepwaterimr.github.io/RstoxUtils/) reads the two Norwegian commercial
catch sources. Check function arguments in the installed package (`args()`, `?downloadLandings`)
and its articles on [sales notes](https://deepwaterimr.github.io/RstoxUtils/articles/LandingsData.html),
[ERS](https://deepwaterimr.github.io/RstoxUtils/articles/ERSdata.html) and
[codes](https://deepwaterimr.github.io/RstoxUtils/articles/CodeDefinitions.html). It needs
RstoxData (StoX, from GitHub) and BioticExplorerServer; follow `r-package-setup` and saved
install consent.

## Choose the source

| Need | Source | Function |
|---|---|---|
| Landings 2005 onward | IMR landings API (intranet) | `downloadLandings(species, years)` → `$summary` plus the sales-note tables (e.g. `$Produkt`) |
| Landings before 2005 | Annual Excel files on the IMR server | `readSluttseddelXLS(species, dataDir, years)` |
| Haul-level catch, position, depth, gear, effort (vessels ≥ 15 m) | FDIR ERS open data | `downloadERS(dest, years)` then `extractERS(path, species)` |
| Species, gear and area codes | Bundled FDIR code list | `FDIRcodes`; refresh with `readFdirCodes()` |

Species names are FDIR Norwegian names (`"Snabeluer"`, `"Blåkveite"`); look them up in
`FDIRcodes$speciesCodes` rather than from memory. Download only the years needed: all years
is slow and large. Run long downloads detached with a log.

## Settle before using the numbers

- **Units.** Sales-note `weight` is round weight (rundvekt) in kg; ERS `weight` is kg. Convert
  once, where the assessment requires (spict-wise works in tonnes).
- **Coverage.** Sales notes are landings at Norwegian facilities, by vessel nation. Other
  nations' catches come from ICES or working-group statistics. ERS covers vessels ≥ 15 m only.
- **Splice.** Where the Excel series meets the API series (2005), compare overlapping totals
  and record the rule.
- **Area.** Select the stock area with FDIR main area (`main_area`) and location (`sub_area`),
  or `ices_area` where present. Write the mapping into the data report.
- **Checks.** No missing years (`setdiff(min(year):max(year), year)`); annual totals against the
  last working-group report; gear and nation splits plausible.

## Confidentiality

Sales notes and ERS records identify vessels, buyers and fishing positions. Keep raw extracts
in the project's ignored `data/source/`, never in a repository or a prompt to an external
service. Share annual totals and aggregates by gear, area or nation; follow
[`biotic-privacy`](../biotic-privacy/SKILL.md) for provider settings and sharing decisions.

## Outputs the assessment packs read

| Consumer | File | Shape |
|---|---|---|
| spict-wise | `data/output/<stock>_catches.rds` | `year` (integer), `total` (tonnes), no missing years |
| spict-wise | `data/output/<stock>_landings.rds` | One row per year, one column per country or fleet, plus `Other` |
| spict-wise | `data/output/<stock>_gear.rds` (optional) | `year`, `gear`, `tonnes` |
| gadget-wise (IMR format) | `data/source/landings.csv` | `year`, `fleet`, `tonnes`; `prepare_catches()` writes `catches_<Fleet>.csv` |

See spict-wise `knowledge/catch-data.md` and gadget-wise `knowledge/layouts.md` for how each
consumer uses them. Record sources, years, filters, the splice rule and the extraction date in
the project's memory or data report.
