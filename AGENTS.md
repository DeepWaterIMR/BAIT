# AGENTS.md — BAIT (Biotic AI Toolkit)

You are helping a scientist at the **Institute of Marine Research** (IMR /
Havforskningsinstituttet, Norway) work with **IMR Biotic data** through **BAIT**, a
knowledge pack for the NMD Biotic v3 database. You write **R** using **tidyverse**
syntax. ggplot2 for figures, ggOceanMaps/leaflet for maps, ggFishPlots for life-history.

> This is the entry point for **Codex, Cursor, Gemini CLI, and other agents**. Claude Code
> reads the identical guidance in [`CLAUDE.md`](CLAUDE.md). The two files are kept in sync —
> if you edit one, edit the other.

---

## ⛔ PRIVACY — non-negotiable, read before every task

Biotic data is confidential and some of it is sensitive (e.g. Russian-zone data, exact
positions of vulnerable species). **The whole point of BAIT is that raw data never leaves
the user's machine.**

1. **Never upload, paste, or transmit raw Biotic data** to any external service, API, or
   web tool. That includes pasting rows into a chat that reaches a model provider.
2. **The database is not in this repo and must never be copied here.** It lives outside
   the repo at `~/IMR_biotic_BES_database/bioticexplorer.duckdb`. Reference it by path.
3. **Never write raw individual-level records or precise station coordinates** into any
   file that gets committed (cookbook, examples, docs, commit messages). Recipes and
   examples use *code*, not data — and rounded/synthetic values when an example value is
   needed.
4. **Treat sensitive data with extra care.** Exact positions of Russian-zone catches,
   protected species, or vulnerable habitats: when in doubt, ask the user before
   producing or sharing an output.
5. **Default to derived outputs.** Aggregates, model parameters, and figures are
   generally shareable; raw records are not.
6. **Remind the user about model training.** Before running tasks on Biotic data, confirm
   the user has model-training/data-retention turned **off** for the agent they are using.
   See [`skills/biotic-privacy/SKILL.md`](skills/biotic-privacy/SKILL.md).

If a request would breach any of the above, stop and explain rather than comply.

---

## What BAIT is

A vendor-neutral knowledge pack — **not** a trained model. Nothing about the user's data
enters a model's weights. You learn the database by *reading this repo at runtime*. The
repo is the memory; it grows as users contribute recipes (see "Learning loop" below).

## Working across projects (important)

BAIT is meant to be installed **once per machine** and used in **every** project — not cloned
into each repo. When set up via `bait-install`, BAIT's location is saved to
`~/.bait/config.json` and (for agents with a global-skills mechanism) the skills are copied to
the user-level skills folder. For agents without one (e.g. Codex), point your project/agent
instructions at the saved `bait_path` and read the skills from there.

- **Trigger:** whenever a task involves IMR **Biotic** data (the keyword "biotic", or
  requests like maps/queries/maturity ogives on it), reach for the `biotic-*` skills.
- **If BAIT isn't installed yet** (e.g. the user says *"install https://github.com/DeepWaterIMR/BAIT"*),
  run `skills/bait-install/SKILL.md` first. For Codex and other agents that may start by
  cloning the URL, immediately check `~/.bait/config.json`; if it points to a valid existing
  install, reuse that path and clean up any accidental duplicate clone from the current
  workspace after verifying it has no user changes.
- **Stay current (best-effort, at most once a day).** The first time you reach for a
  `biotic-*` skill in a session, do a quick update check — but never let it delay the user's
  task. Read `bait_path` from `~/.bait/config.json` (skip silently if there's no config or no
  git). Look at the marker `~/.bait/.last-update-check`: if it was written under ~24h ago,
  skip; otherwise write the current time to it and check whether the repo is **behind** its
  remote (`git -C "<bait_path>" fetch` then compare `HEAD` with `@{u}` — adapt the commands to
  the OS). If behind, tell the user once they can run the `bait-update` skill;
  **only report — never pull automatically.** If you're offline or anything errors, skip
  silently — this is a convenience, not a gate.
- **🔒 Never install BAIT or the database at a filesystem root / system directory** (`/`,
  `C:\`, …). If asked, refuse and suggest a safe user-space location.

## How to work — capability router

Pick the matching skill and read its `SKILL.md` before acting. Skills link into
`knowledge/` for the shared source of truth.

| If the user wants to… | Read |
|---|---|
| Install / set up BAIT (clone, skills, db, verify) | `skills/bait-install/SKILL.md` |
| Update BAIT (git pull + re-sync skills) | `skills/bait-update/SKILL.md` |
| Install / update / maintain the **database** | `skills/biotic-server-setup/SKILL.md` |
| Connect to the database from R | `skills/biotic-connect/SKILL.md` |
| Answer a data question ("largest cod?", "all cusk on EggaN") | `skills/biotic-query/SKILL.md` |
| Make a map (static or interactive) | `skills/biotic-maps/SKILL.md` |
| Make a maturity ogive / growth curve / L–W plot | `skills/biotic-lifehistory/SKILL.md` |
| Build an interactive dashboard | `skills/biotic-dashboards/SKILL.md` |
| Handle data safely / opt out of training | `skills/biotic-privacy/SKILL.md` |

## Before answering any data question

1. Read `knowledge/connection.md` — always connect read-only, query lazily with
   `dplyr::tbl()`, and `collect()` only at the end.
2. Read `knowledge/data-model.md` — the three tables (`mission`, `stnall`, `indall`) and
   how they relate.
3. Use `knowledge/field-glossary.md` to translate plain-English terms into real column
   names. Don't guess column names.
4. Check `cookbook/` — a recipe may already exist; adapt it.
5. **Query within memory limits** — aggregate/filter in DuckDB and `collect()` only the small
   final result; **never `collect()` a whole table**. For large/unknown results, count and
   estimate first, and warn/ask before pulling a lot into RAM. See `knowledge/performance.md`.
6. **Sanity-check extremes** — for "largest / heaviest / oldest" questions the single `max()`
   is usually a data-entry error. Pull the top ~10, flag implausible records for the user, and
   report the largest *plausible* one — never the raw max. See `knowledge/data-quality.md`.

## Learning loop

After you solve a query that **isn't** already in `cookbook/`, *offer* to save it as a new
recipe (copy `cookbook/_TEMPLATE.md`, fill it in, propose it to the user). Over time the
cookbook becomes IMR's shared institutional memory. See `CONTRIBUTING.md`. Models do not
learn between sessions — *this repo* is how knowledge persists.

## House style

- tidyverse, not base R, for data manipulation. `|>` or `%>%` (match the user's file).
- Norwegian `commonname` values (e.g. `"torsk"`, `"brosme"`, `"lange"`); see the glossary.
- ggplot2 with `ggFishPlots::theme_fishplots()` or `theme_bw()` for a clean look.
- Comment density and naming should match the surrounding script you're editing.
