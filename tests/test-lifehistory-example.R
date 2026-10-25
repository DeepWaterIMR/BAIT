# Synthetic checks of the API, units and coding used by the life-history recipe.
if (!requireNamespace("ggFishPlots", quietly = TRUE)) stop("ggFishPlots is required for this check.")
set.seed(430)
d <- data.frame(length = rep(seq(.15, .9, length.out = 120), 2),
                sex = rep(c("1", "2"), each = 120))
d$length_cm <- d$length * 100
d$mature <- stats::rbinom(nrow(d), 1, stats::plogis((d$length_cm - 50) / 10))
fit <- ggFishPlots::plot_maturity(d, length = "length_cm", maturity = "mature",
                                 sex = "sex", female.sex = "1", male.sex = "2",
                                 split.by.sex = TRUE, length.unit = "cm")
stopifnot(inherits(fit$plot, "ggplot"), is.data.frame(fit$params), nrow(fit$params) > 0)
# Explicit units avoid treating Biotic metres as the API's default centimetres.
stopifnot("length.unit" %in% names(formals(ggFishPlots::plot_growth)),
          all(c("length.unit", "weight.unit") %in% names(formals(ggFishPlots::plot_lw))))
message("Life-history example contract passed with synthetic fish; no Biotic data read.")
