# Resolving coded fields (NMD Reference API)

Many Biotic columns are **codes**, not literal values — `sex`, `maturationstage`,
`specialstage`, `missiontype`, `readability`, `gear`, `nation`, … In the field glossary these
are the rows flagged **code? = yes** (type `KeyType` / `CompositeTaxa*KeyType`). A code like
`sex = 1` is meaningless until you resolve it against the **NMDreference** tables.

> **Rule:** don't guess what a code means, and don't read it off some package's
> `recode()` call — those can be incomplete or stale. Resolve it against the **authoritative
> source**: the database's own index tables when present, otherwise the IMR Reference API
> below.

## Order of preference

1. **In-database index tables first** (no network, works offline): `taxaindex` (species),
   `csindex` (cruise series), `gearindex` (gear). See `species-and-surveys.md`.
2. **The IMR Reference API** for everything else (`sex`, `maturationstage`, …). It is the
   canonical registry the database codes point into.

## The IMR Reference API (read-only)

An **IMR-internal** REST service (reachable on the HI network / VPN — behind the institute
firewall). Base:

```
https://reference-api.hi.no/apis/nmdapi/reference/v2
```

**Reads are unauthenticated; writes are not.** `GET` works without a token. `POST`/`PUT`/
`DELETE` require a bearer token *and would modify IMR's shared reference registry*.

> **🔒 Agents must only ever GET.** Never call a write method against this API — you would be
> editing institutional reference data for everyone. There is no BAIT task that writes here.
> Also: this endpoint is for resolving *codes*. **Never send Biotic data, positions, or any
> query results to it** — the privacy rules in `AGENTS.md` apply unchanged.

### List the available tables

```bash
curl -s -H "Accept: application/json" \
  "https://reference-api.hi.no/apis/nmdapi/reference/v2/tables?version=2.1"
```

Returns ~177 reference tables (`sex`, `maturationstage`, `nation`, `missiontype`,
`specialstage-<taxa>-<sex>`, …) under a `row[]` array, each with a `name.value`.

### Resolve a single code

```bash
# /model/{table}/{code}?lang=en  →  shortname + description
curl -s -H "Accept: application/json" \
  "https://reference-api.hi.no/apis/nmdapi/reference/v2/model/sex/1?version=2.1&lang=en"
# → shortname "Female"
```

Use `lang=no` for Norwegian, `lang=en` for English. `version=2.1` returns JSON cleanly;
omit the `Accept` header and you get XML.

### From R

```r
resolve_code <- function(table, code, lang = "en") {
  url <- sprintf(
    "https://reference-api.hi.no/apis/nmdapi/reference/v2/model/%s/%s?version=2.1&lang=%s",
    table, code, lang)
  x <- jsonlite::fromJSON(url)
  x$shortname$value
}
resolve_code("sex", 1)   # "Female"
```

This works for **any** coded column — pass the glossary's column name as `table` (most match
directly: `sex`, `maturationstage`, `nation`, `missiontype`, …).

## Cached common codes

Small, stable lookups worth keeping inline so a query can decode without a network call.
**Verify against the API if a value looks off** — the registry is the source of truth and can
change.

### `sex` (in `indall`)

| code | meaning |
|---|---|
| 1 | Female |
| 2 | Male |
| 3 | Intersex |
| 4 | Hermaphroditic |

> Codes 1/2 dominate; 3/4 are rare and post-2017. Some packages collapse everything except
> 1/2 to "Unidentified" — that loses the Intersex/Hermaphroditic distinction the registry
> makes. `NA` sex means *not recorded*, which is not the same as a code.
>
> **Greenland halibut (`blåkveite`) on the Egga surveys:** when `sex` is missing it has
> historically been encoded in `catchpartnumber` ("delnummer") instead — `1 = female`,
> `2 = male`. Only apply this back-fill for Greenland halibut on EggaN/EggaS; elsewhere a
> missing `sex` is just missing. See `species-and-surveys.md`.

Add other tables here as you confirm them against the API (keep them small — the API is the
full reference).

## Security notes for this file

- The API base URL is an **internal IMR endpoint** (firewalled), included here only so agents
  on the HI network can resolve codes. It exposes *reference metadata*, not Biotic data.
- **Read-only.** Never authenticate or write against it from a BAIT task.
- Do not paste API responses verbatim into committed files if they carry editor identities
  (`updatedBy`/`insertedBy` hold staff usernames) — keep only the `code → meaning` mapping.

## Discovery (how this endpoint was found)

The Swagger UI's initializer points at `…/v2/v3/api-docs/swagger-config`, whose `url` field
gives the OpenAPI spec at `…/v2/v3/api-docs`. The spec lists `GET /tables`,
`GET /{tablename}`, and `GET /model/{table}/{code}` as the read endpoints (the matching
`POST`/`PUT` carry `bearerAuth`).

## Related

- `field-glossary.md` — which columns are codes (`code? = yes`).
- `species-and-surveys.md` — `taxaindex`/`csindex`/`gearindex` in-database lookups.
- `../skills/biotic-query/SKILL.md` — decode codes when reporting results to the user.
