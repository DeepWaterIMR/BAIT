---
name: biotic-lifehistory
description: Produce fish life-history figures and parameters from Biotic individual data using ggFishPlots — maturity ogives (L50), growth curves (von Bertalanffy/Gompertz/logistic), length-weight relationships, catch curves. Use for "maturity ogive", "L50", "growth curve", "Linf/K", "length-weight".
---

<!-- pack-resources:start -->
**Pack resources:** the `BAIT` root is `~/.bait/config.json` → `bait_path`, else `~/.fiskwise/config.json` →
`components.BAIT.path`, else the checkout containing this skill. Paths such as `knowledge/`
and `project-template/` are relative to that root, never `../../` from a skills folder; resolve
links that leave this skill's folder against the source skill there. Use absolute paths.
<!-- pack-resources:end -->


# Life-history figures & parameters (ggFishPlots)

[ggFishPlots](https://deepwaterimr.github.io/ggFishPlots/) takes **`indall`-shaped** data
(one row per measured fish) and returns **both a ggplot and the fitted parameters**. Always
surface the parameters, not just the figure.

## Get the data

```r
d <- indall |>
  filter(commonname == "lange") |>     # ling
  # add a survey/cruise-series filter as needed (see species-and-surveys.md)
  collect()
```

`ggFishPlots` expects columns like `length`, `individualweight`, `age`, `sex`,
`maturationstage`. Biotic `length` is in **metres**. Convert to cm before calling ggFishPlots, whose length scale and default label use cm (`length_cm = length * 100`).

## Functions

```r
library(ggFishPlots)

# Maturity ogive + L50 (give the maturity column; check its name/coding in the glossary)
# Confirm species-specific mature stages from an authoritative reference first.
# Do not treat maturationstage codes as a universal binary mapping.
# Set these only after checking an authoritative species-specific source.
mature_codes <- NULL
immature_codes <- NULL
stopifnot(length(mature_codes) > 0, length(immature_codes) > 0,
          !anyNA(c(mature_codes, immature_codes)),
          length(intersect(mature_codes, immature_codes)) == 0)

d_l50 <- d |>
  mutate(
    length_cm = length * 100,
    mature = case_when(
      maturationstage %in% mature_codes ~ 1L,
      maturationstage %in% immature_codes ~ 0L,
      TRUE ~ NA_integer_
    )
  ) |>
  filter(!is.na(mature))
fit <- plot_maturity(
  d_l50,
  length = "length_cm",
  maturity = "mature",
  sex = "sex",
  female.sex = "1", male.sex = "2", # NMD codes; verify codeindex for your source
  length.unit = "cm",
  split.by.sex = TRUE
)
fit$plot
fit$params

# Growth model: von Bertalanffy (default), Gompertz, or logistic -> Linf, K, t0
plot_growth(d, length = "length", age = "age", length.unit = "m")$plot

# Length-weight relationship -> a, b
plot_lw(d, length = "length", weight = "individualweight",
        length.unit = "m", weight.unit = "kg")$plot

# Catch curve -> total mortality Z
plot_catchcurve(d, age = "age")$plot
```

- Each function returns a list; grab `$params` (e.g. L50, L∞, K, a, b, Z) and report them.
- Use a consistent look with `fit$plot + ggFishPlots::theme_fishplots()`.
- Maturity coding: `maturationstage` is an NMDreference **code** — confirm a species-specific binary mature/immature
  mapping from an authoritative source before fitting; do not guess a general threshold (see [`../../knowledge/field-glossary.md`](../../knowledge/field-glossary.md)).
- Check the function signatures (`?ggFishPlots::plot_maturity`) — argument names can evolve. Current API uses `split.by.sex` (not `split.by`) and returns `$plot` and `$params`.

## Worked example

Maturity ogive for ling from the Coastal survey:
[`../../cookbook/maturity-ogive-ling-coastal.md`](../../cookbook/maturity-ogive-ling-coastal.md).

## Privacy

Handle results according to source classification. Even fitted parameters or figures may
reveal restricted information; keep sensitive outputs local unless sharing is authorized.
