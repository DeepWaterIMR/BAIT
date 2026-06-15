---
name: biotic-maps
description: Make maps of Biotic data — static maps with ggOceanMaps (basemap/qmap, with bathymetry) or interactive maps with leaflet (pan/zoom, bathymetry, catch-composition markers). Use for "map the catches", "where was X caught", station maps, distribution maps.
---

# Make maps of Biotic data

First get a tidy data frame of stations via [`../biotic-query/SKILL.md`](../biotic-query/SKILL.md).
Map columns: `longitudestart`, `latitudestart` (decimal degrees, WGS84). Always drop `NA`
and obviously bad coordinates first.

```r
sp <- stnall |>
  filter(commonname == "brosme", !is.na(longitudestart), !is.na(latitudestart),
         latitudestart > 0) |>
  collect()
```

## Static maps — ggOceanMaps (publication)

```r
library(ggOceanMaps)

# Quick look:
qmap(sp, color = factor(startyear))

# Publication map with bathymetry, auto-cropped to the data:
basemap(data = sp, bathymetry = TRUE) +
  ggspatial::geom_spatial_point(
    data = sp, aes(x = longitudestart, y = latitudestart, size = catchweight),
    color = "red", alpha = 0.6) +
  labs(size = "Catch (kg)")
```

- `qmap()` = fastest; `basemap()` = full control (limits, projection, `bathymetry = TRUE`).
- ggOceanMaps reprojects automatically and handles high-latitude/polar extents well.
- Docs: https://mikkovihtakari.github.io/ggOceanMaps/

## Interactive maps — leaflet

```r
library(leaflet)

leaflet(sp) |>
  addProviderTiles("Esri.OceanBasemap") |>          # includes bathymetry shading
  addCircleMarkers(~longitudestart, ~latitudestart,
                   radius = ~sqrt(pmax(catchweight, 0)) + 1,
                   stroke = FALSE, fillOpacity = 0.6,
                   popup = ~paste0(commonname, "<br>", round(catchweight, 1), " kg"))
```

- **Catch-composition** markers (pie/bar per station): `leaflet.minicharts::addMinicharts()`.
  BioticExplorer (`R/figure_functions.R`) has a reference implementation.
- For static export of a leaflet map: `mapview::mapshot()`.
- Docs: https://rstudio.github.io/leaflet/

## Choosing

| Want | Use |
|---|---|
| Figure for a paper/report | `ggOceanMaps::basemap(bathymetry = TRUE)` |
| Quick sanity check | `ggOceanMaps::qmap()` |
| Pan/zoom, hover, web | `leaflet` |
| Catch composition per station | `leaflet.minicharts::addMinicharts()` |

## Privacy

Maps can reveal exact positions. For sensitive data (Russian-zone, vulnerable species/
habitats) consider aggregating to a grid or jittering before sharing, and **ask the user**
before producing a shareable map. Don't commit rendered maps with real coordinates
(`.gitignore` blocks image files by default).

Worked example: [`../../cookbook/map-cusk-eggan.md`](../../cookbook/map-cusk-eggan.md).
