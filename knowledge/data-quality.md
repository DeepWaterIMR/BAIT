# Data quality: spotting data-entry errors in extreme-value queries

Biotic is field-collected data and contains **data-entry errors** — a misplaced decimal,
a grams-for-kilograms slip, a transposed digit. These errors cluster exactly where
"largest / heaviest / oldest" queries look: at the extreme tail. The single maximum is the
record **most likely** to be wrong.

> **Rule:** never report the raw `max()` of a measurement as "the largest". Pull the **top N**,
> sanity-check them, **tell the user about likely typos**, and report the largest **plausible**
> record as the answer.

## Why `filter(x == max(x))` is a trap

`filter(x == max(x, na.rm = TRUE))` returns whatever sits at the top — including a 3 m cod or
an 18 100 kg fish. It is memory-safe (good) but it answers with the error (bad). Always look at
the **top ~10**, not the top 1.

## The technique

1. **Pull the top N descending** in DuckDB (`slice_max(x, n = 10)` or
   `arrange(desc(x)) |> head(10)`) — only N rows collected, so still memory-safe.
2. **Sanity-check** each candidate against:
   - **Known biology** — plausible max length/weight/age for the species (see bounds below).
   - **Internal consistency** — for fish with both length and weight, **Fulton's condition
     factor** `K = 100 · W(g) / L(cm)³`. Real fish sit around **K ≈ 0.8–1.5**; a typo
     (e.g. 18 100 kg at 114 cm) gives K in the hundreds or thousands. A length-only or
     weight-only outlier is flagged by the biology bound alone.
3. **Report**: state the largest **plausible** record as the answer, then list the flagged
   records separately as **suspected data-entry errors**, with the likely cause
   (e.g. "100 kg at 20 cm — probably 100 g") and a suggestion to verify the raw record.

## Reference bounds (Northeast Atlantic; rough, for flagging only)

| Species (`commonname`) | Plausible max length | Plausible max weight | Notes |
|---|---|---|---|
| torsk (Atlantic cod)   | ~130 cm (rarely ~150) | ~40–60 kg | 179 cm or 100 kg → almost certainly a typo |
| hyse (haddock)         | ~110 cm | ~14 kg | |
| sei (saithe)           | ~130 cm | ~30 kg | |
| blåkveite (Greenland halibut) | ~130 cm | ~45 kg | |
| kveite (Atlantic halibut) | ~300 cm | ~300 kg | genuinely huge — high bounds |
| uer / snabeluer (redfish) | ~50–100 cm | ~15 kg | depends on species |

These are deliberately generous flagging thresholds, not biological records. When unsure of a
species' limits, lean on the **condition-factor** cross-check, which is species-agnostic.

## Recommended code pattern

```r
# Top candidates, descending — cheap, only N rows collected
cand <- indall |>
  filter(commonname == "torsk", !is.na(individualweight)) |>
  slice_max(individualweight, n = 10) |>
  select(startyear, serialnumber, length, individualweight, age, sex) |>
  collect() |>
  mutate(
    length_cm = length * 100,
    K = 100 * (individualweight * 1000) / (length_cm)^3,   # Fulton's K; NA if length missing
    flag = is.na(K) | K < 0.4 | K > 3 | individualweight > 60
  )

cand                                   # inspect: flagged rows are suspected typos
answer <- cand |> filter(!flag) |> slice_max(individualweight, n = 1)  # largest plausible
```

Adjust the `flag` thresholds per species and question. The point is the **workflow**: top N →
sanity-check → report the largest plausible value and disclose the suspects, never the raw max.

## Related

- Skill: `../skills/biotic-query/SKILL.md`
- Recipe: `../cookbook/largest-cod.md`
- Performance (why we still reduce in DuckDB): `../knowledge/performance.md`
- Glossary (units): `../knowledge/field-glossary.md`
