---
title: Catch-composition pie charts per station for the Coastal survey
questions:
  - "Catch-composition pie charts per station for the coastal survey."
  - "Show station-level catch composition on the Kysttokt as pie charts."
tables: [stnall, csindex]
packages: [tidyverse, duckdb, leaflet, leaflet.minicharts, htmlwidgets]
tags: [map, query]
---

# Catch-composition pie charts per station for the Coastal survey

**Answers:** an interactive `leaflet` map of Coastal survey stations, with a pie chart at
each station showing catch composition by species.

## Approach

The Coastal survey (Kysttokt) spans multiple cruise-series codes, so first look those up in
`csindex` using `"coastal|kyst"`. Then filter `stnall` to valid station coordinates and
positive catch weights, summarise the catch by station and species, and plot the composition
with `leaflet.minicharts::addMinicharts()`. For readability, a good default is the **latest
available survey year**, with the **top species by total catch** shown explicitly and all
remaining species grouped as `"Other"`.

## Code

```r
library(tidyverse); library(DBI); library(duckdb)
library(leaflet); library(leaflet.minicharts); library(htmlwidgets)

con <- dbConnect(duckdb::duckdb(),
                 dbdir = path.expand("~/IMR_biotic_BES_database/bioticexplorer.duckdb"),
                 read_only = TRUE)
stnall  <- tbl(con, "stnall")
csindex <- tbl(con, "csindex")

# 1. Coastal survey cruise-series code(s)
csList <- csindex |>
  distinct(cruiseseriescode, name) |>
  collect()
selCS  <- csList[grepl("coastal|kyst", csList$name, ignore.case = TRUE), ]
csFilt <- selCS$cruiseseriescode

filtExp <- paste(sapply(csFilt, function(k) paste0(
  "cruiseseriescode %like% '", k, ",%' | cruiseseriescode %like% '%,", k,
  "' | cruiseseriescode %like% '%,", k, ",%' | cruiseseriescode %in% c('", k, "')")),
  collapse = " | ")

# 2. Pull valid station catches and default to the latest survey year
d <- stnall |>
  filter(!!!rlang::parse_exprs(filtExp)) |>
  filter(!is.na(commonname), !is.na(catchweight), catchweight > 0,
         !is.na(longitudestart), !is.na(latitudestart), latitudestart > 0) |>
  select(startyear, cruise, serialnumber, longitudestart, latitudestart,
         commonname, catchweight) |>
  collect()

latest_year <- max(d$startyear, na.rm = TRUE)
d_year <- d |>
  filter(startyear == latest_year)

# 3. Keep the dominant species explicit; group the tail as "Other"
top_species <- d_year |>
  group_by(commonname) |>
  summarise(total_kg = sum(catchweight, na.rm = TRUE), .groups = "drop") |>
  slice_max(total_kg, n = 8, with_ties = FALSE) |>
  pull(commonname)

station_species <- d_year |>
  mutate(species_group = if_else(commonname %in% top_species, commonname, "Other")) |>
  group_by(startyear, cruise, serialnumber, longitudestart, latitudestart, species_group) |>
  summarise(catch_kg = sum(catchweight, na.rm = TRUE), .groups = "drop")

station_pies <- station_species |>
  tidyr::pivot_wider(names_from = species_group, values_from = catch_kg, values_fill = 0)

species_cols <- setdiff(colnames(station_pies),
                        c("startyear", "cruise", "serialnumber",
                          "longitudestart", "latitudestart"))
species_cols <- c(top_species[top_species %in% species_cols],
                  setdiff(species_cols, top_species))

station_totals <- station_species |>
  group_by(startyear, cruise, serialnumber, longitudestart, latitudestart) |>
  summarise(total_kg = sum(catch_kg), .groups = "drop")

station_plot <- station_pies |>
  left_join(station_totals,
            by = c("startyear", "cruise", "serialnumber",
                   "longitudestart", "latitudestart")) |>
  mutate(radius_px = pmin(36, pmax(14, 12 + sqrt(total_kg) / 2)))

# 4. Interactive pie-chart map
palette <- c("#1b9e77", "#d95f02", "#7570b3", "#e7298a",
             "#66a61e", "#e6ab02", "#a6761d", "#1f78b4", "#666666")
palette <- palette[seq_along(species_cols)]

m <- leaflet(station_plot) |>
  addProviderTiles("Esri.OceanBasemap") |>
  fitBounds(lng1 = min(station_plot$longitudestart),
            lat1 = min(station_plot$latitudestart),
            lng2 = max(station_plot$longitudestart),
            lat2 = max(station_plot$latitudestart)) |>
  addLegend("bottomright", colors = palette, labels = species_cols,
            title = "Catch composition")

m <- leaflet.minicharts::addMinicharts(
  map = m,
  lng = station_plot$longitudestart,
  lat = station_plot$latitudestart,
  chartdata = as.matrix(station_plot[, species_cols]),
  type = "pie",
  colorPalette = palette,
  width = station_plot$radius_px,
  height = station_plot$radius_px,
  opacity = 0.85,
  transitionTime = 0
)

htmlwidgets::saveWidget(
  m,
  file = paste0("coastal_catch_composition_", latest_year, ".html"),
  selfcontained = FALSE
)

dbDisconnect(con, shutdown = TRUE)
```

## Expected output

An interactive HTML map with one pie chart per station for the latest Coastal survey year.
Each pie shows relative catch composition by species, with marker size scaled by total catch.
Expect hundreds of stations for a recent year, and a legend with a compact set of dominant
species plus `"Other"`.

## Notes & caveats

- The Coastal survey often resolves to multiple cruise-series codes in `csindex`; do the
  lookup instead of hard-coding a single code.
- If the user wants **all years**, consider faceting by year, filtering to a single region,
  or restricting the species set first; otherwise the map gets very crowded.
- Pie charts can become unreadable if you include too many species. Grouping the tail as
  `"Other"` is usually the best default.
- Station positions are exact. Treat the rendered map as internal unless the user asks for a
  shareable, aggregated version.

## Related

- Skill: `../skills/biotic-maps/SKILL.md`
- Recipes: `map-cusk-eggan.md`
