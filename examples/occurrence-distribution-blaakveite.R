## Estimated distribution of Greenland halibut (blåkveite) from survey occurrences
## Mirrors cookbook/occurrence-distribution-blaakveite.md
##
## Response  : presence/absence of the species in a haul (occurrence, NOT abundance)
## Effort    : design-based research bottom-trawl hauls, 1980-present
## Estimator : binomial GAM — spatial smooth for the map, depth/latitude model for the
##             habitat response curves
##
## Requires a local DuckDB at ~/IMR_biotic_BES_database/bioticexplorer.duckdb, and a UTF-8
## locale (under LC_CTYPE=C the Norwegian commonname silently matches nothing).
## Data stay local: only aggregated grids, fitted surfaces and figures leave this script.

library(tidyverse)
library(DBI)
library(duckdb)
library(mgcv)
library(sf)
library(ggOceanMaps)
library(patchwork)

db_path <- if (.Platform$OS.type == "windows") {
  file.path(Sys.getenv("USERPROFILE"), "IMR_biotic_BES_database", "bioticexplorer.duckdb")
} else {
  path.expand("~/IMR_biotic_BES_database/bioticexplorer.duckdb")
}
con <- dbConnect(duckdb::duckdb(), dbdir = db_path, read_only = TRUE)
stnall <- tbl(con, "stnall")

# ---------------------------------------------------------------- 1. haul frame
# Effort frame is built BEFORE filtering to the species, so absences are real zeros
# within the set of hauls that sort the whole catch (see knowledge/sampling-units.md).
bt <- stnall |>
  filter(missiontype %in% c("4", "5"),        # research vessel + chartered vessel
         gearcategory == "Bottom trawls")

hauls <- bt |>                                 # one row per haul (missionid + serialnumber)
  group_by(missionid, serialnumber) |>
  summarise(startyear = min(startyear, na.rm = TRUE),
            lat   = min(latitudestart,    na.rm = TRUE),
            lon   = min(longitudestart,   na.rm = TRUE),
            depth = min(bottomdepthstart, na.rm = TRUE),
            squal = min(samplequality,    na.rm = TRUE),
            gcond = min(gearcondition,    na.rm = TRUE),
            n_meta_lat = n_distinct(latitudestart),   # must be 1 -> key is valid
            .groups = "drop")

target <- bt |>                                # blåkveite aggregated to the haul
  filter(commonname == "blåkveite") |>
  group_by(missionid, serialnumber) |>
  summarise(n_cs = n(), .groups = "drop")      # occurrence only; weights not summed
                                               # (catch parts may be nested, not additive)

dat <- hauls |> left_join(target, by = c("missionid", "serialnumber")) |> collect()
dbDisconnect(con, shutdown = TRUE)

stopifnot(all(dat$n_meta_lat == 1))            # haul key gives constant station metadata

d <- dat |>
  mutate(present = as.integer(!is.na(n_cs))) |>
  filter(!is.na(lat), !is.na(lon),
         lat > 55, lon > -40, lon < 80,        # NE Atlantic / Arctic domain
         startyear >= 1980,                    # 1970s hauls too few and unrepresentative
         squal == 1,                           # design-based stations only; code 2 is
                                               # targeted sampling and must not be pooled
         gcond %in% c(1, 2)) |>                # gear OK / minor damage
  mutate(period = cut(startyear, c(1979, 1999, 2012, 2030),
                      labels = c("1980-1999", "2000-2012", "2013-2026")))

# work in projected km (Arctic polar stereographic) so the spatial smooth is isotropic
xy <- st_as_sf(d, coords = c("lon", "lat"), crs = 4326) |> st_transform(3995) |>
  st_coordinates()
d$x <- xy[, 1] / 1000; d$y <- xy[, 2] / 1000

# ---------------------------------------------------------------- 2. models
m_sp  <- bam(present ~ s(x, y, k = 300), data = d, family = binomial, discrete = TRUE)

dd    <- d |> filter(!is.na(depth), depth > 0, depth < 2000)
m_hab <- bam(present ~ s(log(depth), k = 20) + s(lat, k = 20) + period,
             data = dd, family = binomial, discrete = TRUE)

summary(m_sp)$dev.expl     # ~0.50
summary(m_hab)

# ---------------------------------------------------------------- 3. prediction grid
res <- 25                                       # km
grd <- expand_grid(x = seq(min(d$x) - res, max(d$x) + res, by = res),
                   y = seq(min(d$y) - res, max(d$y) + res, by = res)) |>
  mutate(x = round(x / res) * res, y = round(y / res) * res)

# mask to cells holding a haul, dilated one cell -> never extrapolate beyond ~35 km
mask <- d |>
  transmute(x = round(x / res) * res, y = round(y / res) * res) |> distinct() |>
  crossing(expand_grid(dx = c(-1, 0, 1) * res, dy = c(-1, 0, 1) * res)) |>
  transmute(x = x + dx, y = y + dy) |> distinct()

grd <- grd |> semi_join(mask, by = c("x", "y"))
grd$p <- as.vector(predict(m_sp, newdata = grd, type = "response"))

# ---------------------------------------------------------------- 4. maps
cells <- function(df, res) {                    # cell centres (km) -> sf squares
  h <- res / 2 * 1000
  g <- lapply(seq_len(nrow(df)), function(i) {
    cx <- df$x[i] * 1000; cy <- df$y[i] * 1000
    st_polygon(list(cbind(c(cx - h, cx + h, cx + h, cx - h, cx - h),
                          c(cy - h, cy - h, cy + h, cy + h, cy - h))))
  })
  st_sf(df, geometry = st_sfc(g, crs = 3995))
}

lims <- c(-20, 62, 60, 82.5)
ring <- rbind(cbind(seq(lims[1], lims[2], length.out = 400), lims[3]),
              cbind(lims[2], seq(lims[3], lims[4], length.out = 400)),
              cbind(seq(lims[2], lims[1], length.out = 400), lims[4]),
              cbind(lims[1], seq(lims[4], lims[3], length.out = 400)))
clipbox <- st_sfc(st_polygon(list(rbind(ring, ring[1, ]))), crs = 4326) |> st_transform(3995)
clipto  <- function(x) suppressWarnings(st_intersection(x, clipbox))

base   <- function() basemap(limits = lims, land.col = "grey88",
                             land.border.col = "grey45", grid.col = "grey80")
sc_occ <- scale_fill_viridis_c(option = "magma", limits = c(0, 1), labels = scales::percent)

p_fit <- base() +
  geom_sf(data = clipto(cells(grd, res)), aes(fill = p), colour = NA) + sc_occ +
  labs(fill = "P(occurrence)",
       title = "Greenland halibut (blåkveite): estimated occurrence probability")

raw <- d |>
  mutate(x = round(x / 50) * 50, y = round(y / 50) * 50) |>
  group_by(x, y) |> summarise(hauls = n(), occ = mean(present), .groups = "drop") |>
  filter(hauls >= 5)

p_raw <- base() +
  geom_sf(data = clipto(cells(raw, 50)), aes(fill = occ), colour = NA) + sc_occ +
  labs(fill = "Hauls with\nblåkveite", title = "Observed occurrence frequency")

p_eff <- base() +
  geom_sf(data = clipto(cells(raw, 50)), aes(fill = hauls), colour = NA) +
  scale_fill_viridis_c(option = "mako", trans = "log10") +
  labs(fill = "Hauls", title = "Survey effort")

# ---------------------------------------------------------------- 5. habitat curves
# marginal effect: average the fitted probability over the observed distribution of
# the other covariates, so the curve is directly comparable to the binned observations
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
curve_lat   <- marg("lat",   seq(56, 83, length.out = 60))

# ---------------------------------------------------------------- 6. summaries
pres <- dd |> filter(present == 1)
quantile(pres$depth, c(.05, .25, .5, .75, .95))   # depth range of occurrences
quantile(dd$depth,   c(.05, .25, .5, .75, .95))   # depth range of effort (for contrast)
sum(grd$p) * res^2                                # expected occupied area, km2
