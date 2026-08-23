---
name: biotic-survey-analysis
description: Design and audit quantitative survey analyses from IMR Biotic data, including sampling-unit keys, catchsample aggregation, true zeros, sample and gear qualification, effort standardization, and raising length or individual observations. Use for survey catches, stations, CPUE or density, survey time series, multisamplers, or abundance and biomass summaries.
---

# Analyse Biotic survey data

Use this skill when the requested result depends on what constitutes a haul, which samples are quantitative, or how catch and observations are aggregated.

## Required reading

1. [`../biotic-connect/SKILL.md`](../biotic-connect/SKILL.md)
2. [`../../knowledge/data-model.md`](../../knowledge/data-model.md)
3. [`../../knowledge/sampling-units.md`](../../knowledge/sampling-units.md)
4. [`../../knowledge/quality-codes.md`](../../knowledge/quality-codes.md)
5. [`../../knowledge/data-quality.md`](../../knowledge/data-quality.md)

Use [`../biotic-query/SKILL.md`](../biotic-query/SKILL.md) for bounded extraction and [`../biotic-maps/SKILL.md`](../biotic-maps/SKILL.md) for maps.

## Workflow

1. State the estimand and sampling unit: catchsample, fishstation (`serialnumber`), or a documented multi-bag haul (`station`).
2. Build a stable key. In BES use `missionid + serialnumber`; for native Biotic use `missiontype + startyear + platform + missionnumber + serialnumber`.
3. Inspect catchsample/catch-part structure and comments before summing species records.
4. Decode `samplequality`, `gearcondition`, and `stationtype`; apply a documented survey-specific qualification rule. Do not interpret code 2 in either quality field as generically “acceptable.”
5. Build the qualified station roster independently of target catch, then complete verified non-catches as true zeros.
6. Aggregate additive catch and effort to the same unit. Sum numerators and denominators before calculating rates or densities.
7. Raise length or individual observations within catchsample using a numeric representation factor. Keep observed sample size and raised abundance separate.
8. Retain identifiers, gear, vessel/platform, year, and qualification fields in model-ready summaries.
9. Run uniqueness, missingness, metadata-consistency, and before/after total checks. Return unresolved catch-part logic for scientific review rather than guessing.

## Output contract

Report the sampling-unit definition, key, qualification rule, zero-completion rule, aggregation rule, units, and unresolved assumptions with the result. Never expose raw confidential records or precise sensitive positions.
