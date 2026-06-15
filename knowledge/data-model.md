# The Biotic data model (what the agent needs to know)

NMD Biotic v3 is a **nested hierarchy**. BioticExplorerServer flattens it into a few wide,
joinable tables in DuckDB. You mostly work with **three**: `mission`, `stnall`, `indall`.

## The raw hierarchy

```
mission            one cruise / survey trip
└─ fishstation     one haul / station (position, time, gear, depths)
   └─ catchsample  one species-portion of a station's catch (commonname, weights, counts)
      └─ individual one measured fish (length, weight, sex, maturity)
         └─ agedetermination  one age reading of that fish (age, readability)
```

(There are more elements — `prey`, `tag`, `copepodedevstage`, etc. — but the above is the
backbone for almost every query.)

## The flattened tables you query

| Table | Made from | One row = | Use for |
|---|---|---|---|
| `mission` | mission | one cruise | cruise/survey overviews |
| `stnall` | mission + fishstation + catchsample | one species-portion of one station | catches, maps, CPUE, distribution |
| `indall` | stnall + individual + preferred agedetermination | one measured fish | length, weight, sex, maturity, age, life-history |
| `ageall` | + all age readings | one age reading | age-reading comparisons (if present) |

`stnall` and `indall` already contain the upstream columns (cruise, position, gear,
species…), so you rarely need manual joins.

> Built by `RstoxUtils::processBioticFile()` (same logic the server uses). Join keys are
> `missiontype, startyear, platform, missionnumber, serialnumber, catchsampleid, specimenid`.

## High-value columns (verified against `coreDataList` + the XSD)

**`mission`** — `missiontype`, `missiontypename`, `startyear`, `platform`, `platformname`,
`missionnumber`, `callsignal`, `cruise`, `missionstartdate`, `missionstopdate`, `purpose`

**`stnall`** (mission + station + catch) — adds:
`serialnumber` (station id), `station`, `stationstartdate`, `stationstarttime`,
`longitudestart`, `latitudestart`, `bottomdepthstart`, `fishingdepthmin`, `gear`,
`distance`, `commonname`, `catchcategory`, `catchpartnumber`, `catchweight`, `catchcount`,
`lengthsampleweight`, `lengthsamplecount`. The DuckDB build also typically carries
geographic lookups such as `icesarea` — confirm with `colnames(stnall)`.

**`indall`** (stnall + individual + age) — adds:
`specimenid`, `sex`, `maturationstage`, `specialstage`, `length`, `individualweight`,
`age`, `readability`, `preferredagereading`, `numberofreads`.

## ⚠️ Units & gotchas (get these right)

- **`length` is in METRES** (per the XSD). A 92 cm cod has `length = 0.92`. Present in cm
  with `length * 100`. Sort "largest" by `length`.
- **`individualweight` is in KILOGRAMS**; `catchweight` is in kg.
- **`commonname` is in Norwegian** (`"torsk"`, `"brosme"`, `"lange"`, …). See
  [`species-and-surveys.md`](species-and-surveys.md) and [`field-glossary.md`](field-glossary.md).
- **`missiontype`** distinguishes survey vs. commercial data — research surveys are
  `missiontype %in% c(4, 5)`. See [`species-and-surveys.md`](species-and-surveys.md).
- **Coordinates** are `longitudestart` / `latitudestart` (decimal degrees). Filter out
  `NA` and obviously bad values (e.g. `latitudestart > 0`) before mapping.
- **Empty-catch stations** can have `commonname = NA` (stations retained without catch).
- **Codes** (gear, area, maturity stage…) are foreign keys into **NMDreference**; the
  glossary flags these. `RstoxUtils` has helpers to resolve some of them.

The full, generated field dictionary is [`field-glossary.md`](field-glossary.md).
