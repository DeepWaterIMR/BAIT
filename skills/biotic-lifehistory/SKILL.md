---
name: biotic-lifehistory
description: Produce fish life-history figures and parameters from Biotic individual data using ggFishPlots — maturity ogives (L50), growth curves (von Bertalanffy/Gompertz/logistic), length-weight relationships, catch curves. Use for "maturity ogive", "L50", "growth curve", "Linf/K", "length-weight".
---

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
`maturationstage`. Remember `length` is in **metres** — convert if a function or the user
expects cm (`length * 100`).

## Functions

```r
library(ggFishPlots)

# Maturity ogive + L50 (give the maturity column; check its name/coding in the glossary)
plot_maturity(d, length = "length", maturity = "maturationstage", split.by = "sex")

# Growth model: von Bertalanffy (default), Gompertz, or logistic -> Linf, K, t0
plot_growth(d, length = "length", age = "age")

# Length-weight relationship -> a, b
plot_lw(d, length = "length", weight = "individualweight")

# Catch curve -> total mortality Z
plot_catchcurve(d, age = "age")
```

- Each function returns a list; grab `$params` (e.g. L50, L∞, K, a, b, Z) and report them.
- Use a consistent look with `+ ggFishPlots::theme_fishplots()`.
- Maturity coding: `maturationstage` is an NMDreference **code** — confirm which stages mean
  "mature" for the species before fitting (see [`../../knowledge/field-glossary.md`](../../knowledge/field-glossary.md)).
- Check the function signatures (`?ggFishPlots::plot_maturity`) — argument names can evolve.

## Worked example

Maturity ogive for ling from the Coastal survey:
[`../../cookbook/maturity-ogive-ling-coastal.md`](../../cookbook/maturity-ogive-ling-coastal.md).

## Privacy

Fitted parameters and figures are derived outputs and generally shareable. The underlying
individual records are not — keep them local.
