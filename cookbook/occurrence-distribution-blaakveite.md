---
title: Estimate a species distribution from survey occurrences
questions:
  - "Estimate the distribution of Greenland halibut based on occurrences in the Biotic data."
  - "Where does blåkveite occur? Map its distribution."
  - "Make an occurrence / presence-absence distribution map for a species."
  - "What depths does this species occur at?"
tables: [stnall]
packages: [tidyverse, duckdb, mgcv, sf, ggOceanMaps, patchwork]
tags: [map, query, survey-analysis]
---

# Estimate a species distribution from survey occurrences

**Answers:** where a species occurs, as an effort-corrected occurrence-probability surface
plus its depth and latitude response, estimated from presence/absence in research
bottom-trawl hauls. Worked here for `blåkveite` (Greenland halibut); swap the species and
the domain for anything else.

## Approach

Occurrence is a *ratio*, so the denominator has to be built first: aggregate `stnall` to
one row per haul (`missionid + serialnumber`) **before** filtering to the species, then
left-join the species on. A haul without a target record is then a genuine zero rather than
a missing row. Keep only design-based stations (`samplequality == 1`) — code 2 is *targeted*
sampling and must not be pooled with it (see
[`../knowledge/quality-codes.md`](../knowledge/quality-codes.md)).

Fit two binomial GAMs: a spatial smooth `s(x, y)` on projected kilometres for the map, and a
separate `s(log(depth)) + s(lat)` habitat model for the response curves. Predict the spatial
model onto a regular grid **masked to cells near a real haul**, so the surface never
extrapolates into unsampled water.

Use occurrence, not catch weight, unless the catch-part structure has been resolved: a
species can have several `catchsampleid` rows per haul that may be nested rather than
additive (see [`../knowledge/sampling-units.md`](../knowledge/sampling-units.md)).

## Code

```r
library(tidyverse); library(DBI); library(duckdb)
library(mgcv); library(sf); library(ggOceanMaps)

con <- dbConnect(duckdb::duckdb(),
                 dbdir = path.expand("~/IMR_biotic_BES_database/bioticexplorer.duckdb"),
                 read_only = TRUE)
stnall <- tbl(con, "stnall")

species <- "blåkveite"

# 1. Effort frame FIRST: one row per haul, built before any species filter -------
bt <- stnall |>
  filter(missiontype %in% c("4", "5"),          # research + chartered vessel
         gearcategory == "Bottom trawls")       # note: missiontype is CHARACTER here

hauls <- bt |>
  group_by(missionid, serialnumber) |>
  summarise(startyear = min(startyear, na.rm = TRUE),
            lat   = min(latitudestart,    na.rm = TRUE),
            lon   = min(longitudestart,   na.rm = TRUE),
            depth = min(bottomdepthstart, na.rm = TRUE),
            squal = min(samplequality,    na.rm = TRUE),
            gcond = min(gearcondition,    na.rm = TRUE),
            n_meta_lat = n_distinct(latitudestart),   # must be 1 -> haul key is valid
            .groups = "drop")

target <- bt |>                                  # occurrence only, weights NOT summed
  filter(commonname == species) |>
  group_by(missionid, serialnumber) |>
  summarise(n_cs = n(), .groups = "drop")

dat <- hauls |> left_join(target, by = c("missionid", "serialnumber")) |> collect()
dbDisconnect(con, shutdown = TRUE)

stopifnot(all(dat$n_meta_lat == 1))              # station metadata constant within the key

# 2. Qualify the frame ----------------------------------------------------------
d <- dat |>
  mutate(present = as.integer(!is.na(n_cs))) |>
  filter(!is.na(lat), !is.na(lon),
         lat > 55, lon > -40, lon < 80,          # NE Atlantic / Arctic domain
         startyear >= 1980,                      # earlier hauls too few to be representative
         squal == 1,                             # design-based stations only
         gcond %in% c(1, 2))                     # gear OK / minor damage

# Project to metric coordinates so the spatial smooth is isotropic at high latitude
xy <- st_as_sf(d, coords = c("lon", "lat"), crs = 4326) |>
  st_transform(3995) |> st_coordinates()         # Arctic polar stereographic
d$x <- xy[, 1] / 1000; d$y <- xy[, 2] / 1000     # km

# 3. Models ---------------------------------------------------------------------
m_sp  <- bam(present ~ s(x, y, k = 300), data = d, family = binomial, discrete = TRUE)

dd    <- d |> filter(!is.na(depth), depth > 0, depth < 2000)
m_hab <- bam(present ~ s(log(depth), k = 20) + s(lat, k = 20),
             data = dd, family = binomial, discrete = TRUE)

# 4. Prediction grid, masked to sampled water -----------------------------------
res <- 25                                        # km
grd <- expand_grid(x = seq(min(d$x) - res, max(d$x) + res, by = res),
                   y = seq(min(d$y) - res, max(d$y) + res, by = res)) |>
  mutate(x = round(x / res) * res, y = round(y / res) * res)

mask <- d |>                                     # cells holding a haul, dilated one cell
  transmute(x = round(x / res) * res, y = round(y / res) * res) |> distinct() |>
  crossing(expand_grid(dx = c(-1, 0, 1) * res, dy = c(-1, 0, 1) * res)) |>
  transmute(x = x + dx, y = y + dy) |> distinct()

grd <- grd |> semi_join(mask, by = c("x", "y"))
grd$p <- as.vector(predict(m_sp, newdata = grd, type = "response"))

# 5. Map ------------------------------------------------------------------------
cells <- function(df, res) {                     # cell centres (km) -> sf squares
  h <- res / 2 * 1000
  g <- lapply(seq_len(nrow(df)), function(i) {
    cx <- df$x[i] * 1000; cy <- df$y[i] * 1000
    st_polygon(list(cbind(c(cx - h, cx + h, cx + h, cx - h, cx - h),
                          c(cy - h, cy - h, cy + h, cy + h, cy - h))))
  })
  st_sf(df, geometry = st_sfc(g, crs = 3995))
}

lims <- c(-20, 62, 60, 82.5)
basemap(limits = lims, land.col = "grey88", land.border.col = "grey45") +
  geom_sf(data = cells(grd, res), aes(fill = p), colour = NA) +
  scale_fill_viridis_c(option = "magma", limits = c(0, 1), labels = scales::percent) +
  labs(fill = "P(occurrence)")
```

Marginal habitat curves, averaged over the observed distribution of the other covariates so
they are directly comparable to binned observations:

```r
samp <- as.data.frame(slice_sample(dd, n = 4000))
marg <- function(var, seqv) {
  map_dfr(seqv, function(v) {
    nd <- samp; nd[[var]] <- v
    pr <- predict(m_hab, nd, type = "link", se.fit = TRUE, discrete = FALSE)
    tibble(v = v, p  = mean(plogis(pr$fit)),
           lo = mean(plogis(pr$fit - 1.96 * pr$se.fit)),
           hi = mean(plogis(pr$fit + 1.96 * pr$se.fit)))
  })
}
curve_depth <- marg("depth", exp(seq(log(50), log(1500), length.out = 60)))
```

## Expected output

- `d` — roughly 5–6 × 10⁴ hauls for a well-sampled species over 1980–present, with a
  `present` column; overall occurrence a few tens of percent.
- `m_sp` — deviance explained around 0.5 for a strongly habitat-associated species.
- `grd` — a few thousand 25 km cells with a fitted `p` between 0 and 1.
- A `ggOceanMaps` raster-style map: for a slope species, a continuous high-probability band
  following the shelf break and the deep troughs, near-zero on shallow banks.
- `curve_depth` — a unimodal response; for Greenland halibut it peaks near 800 m at close to
  100 %, with the 50 % band spanning roughly 450–1400 m.

## Notes & caveats

- **`missiontype` is a character column**, so filter with `c("4", "5")`, not `c(4, 5)`.
  Numeric values raise a DuckDB `DECIMAL(2,1)` cast error.
- **Build the denominator before the species filter.** Filtering `stnall` to the species
  first and mapping the result gives presence-only points with no effort correction.
- **Do not pool `samplequality` 1 and 2.** Targeted stations show markedly different
  occurrence (for blåkveite, roughly 21 % vs 32 %), which biases the surface.
- **Occurrence, not abundance.** Summing `catchweight` across catchsample rows is only valid
  once the catch-part logic is verified; several species (blåkveite on Egga among them) have
  multiple, possibly nested, rows per haul.
- **Mask the prediction grid.** Without the mask the GAM happily extrapolates into water no
  survey has ever trawled.
- **Read the deep edge of the range as a sampling limit.** Bottom-trawl effort thins out
  below ~1400 m, so a falling fitted probability there is partly an effort artefact.
- Set the R locale to UTF-8 (`LANG=en_US.UTF-8`) before running from a shell — under the
  `C` locale `commonname == "blåkveite"` silently matches nothing.
- **Privacy:** gridded occurrence and fitted surfaces are derived outputs and normally fine
  to share internally; the underlying haul positions are not. Don't commit rendered figures.

## Related

- Skill: `../skills/biotic-survey-analysis/SKILL.md`, `../skills/biotic-maps/SKILL.md`
- Knowledge: `../knowledge/sampling-units.md`, `../knowledge/quality-codes.md`
- Example script: `../examples/occurrence-distribution-blaakveite.R`
- Recipes: `map-cusk-eggan.md`, `pigghaa-ices-1-2.md`
