# The R package ecosystem BAIT builds on

Use these packages; don't reinvent what they already do.

## Data access & processing

| Package | Role | Key functions |
|---|---|---|
| [BioticExplorerServer](https://github.com/DeepWaterIMR/BioticExplorerServer) | **Builds/maintains** the DuckDB database via the server-setup skill. Bakes the `csindex`/`gearindex`/`taxaindex` lookup tables into the DB | `compileDatabase()` for setup; `updateDatabase()` for updates |
| [RstoxUtils](https://deepwaterimr.github.io/RstoxUtils/) | Parse NMD Biotic XML; the `stnall`/`indall` flattening logic | `processBioticFile()`, `processBioticFiles()`, `coreDataList()` |
| [RstoxData](https://github.com/StoXProject/RstoxData) | Low-level NMD Biotic XML reader (used under the hood) | `readXmlFile()` |
| DBI + duckdb | Database connection | `dbConnect()`, `dplyr::tbl()` |
| tidyverse (dplyr, tidyr, …) | Querying & wrangling | lazy `filter`/`select`/`summarise` → `collect()` |

## Figures & maps

| Package | Role | Key functions |
|---|---|---|
| [ggplot2](https://ggplot2.tidyverse.org/) | All static figures | `ggplot()`, `geom_*`, `theme_bw()` |
| [ggOceanMaps](https://mikkovihtakari.github.io/ggOceanMaps/) | **Static** maps with land/bathymetry | `basemap()`, `qmap()` |
| [leaflet](https://rstudio.github.io/leaflet/) | **Interactive** maps (+ bathymetry) | `leaflet()`, `addTiles()`, `addCircleMarkers()` |
| [leaflet.minicharts](https://github.com/rte-antares-rpackage/leaflet.minicharts) | Pie/bar markers on leaflet (catch composition) | `addMinicharts()` |
| [ggFishPlots](https://deepwaterimr.github.io/ggFishPlots/) | **Life-history** figures & parameters from `indall` | `plot_maturity()` (L50 ogive), `plot_growth()` (von Bertalanffy/Gompertz/logistic), `plot_lw()` (length–weight), `plot_catchcurve()`, `theme_fishplots()` |

## Dashboards & exploration

| Package | Role |
|---|---|
| [BioticExplorer](https://github.com/DeepWaterIMR/BioticExplorer) | Ready-made Shiny app: file mode (XML) + database mode (DuckDB). Maps, overviews, species life-history plots, exports |
| shiny / shinydashboard | Build custom dashboards (see `../skills/biotic-dashboards/SKILL.md`) |

## Conventions

- **Read reference data from the database, not from BES functions.** Cruise series, gear, and
  taxa/species names come from the `csindex`/`gearindex`/`taxaindex` tables in the DuckDB.
  `BioticExplorerServer` is used **only** to build/update the database (the server-setup
  skill) — don't call `prepareTaxaList()`/`prepareGearList()`/`cruiseSeries` etc. at query time.
- **Maps**: prefer `ggOceanMaps::qmap()` for a quick look; `basemap()` for publication
  figures with bathymetry. Use `leaflet` when the user wants pan/zoom interactivity.
- **Life-history**: `ggFishPlots` functions take `indall`-shaped data and return both the
  plot **and** the fitted parameters (e.g. L50, L∞, K) — surface the parameters too.
- **Install from GitHub** (not all are on CRAN):
  ```r
  remotes::install_github("DeepWaterIMR/RstoxUtils")
  remotes::install_github("DeepWaterIMR/ggFishPlots")
  remotes::install_github("DeepWaterIMR/BioticExplorerServer")
  install.packages(c("ggOceanMaps", "leaflet"))
  ```
