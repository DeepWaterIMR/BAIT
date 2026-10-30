# AGENTS.md — BAIT (Biotic AI Toolkit)

You are helping a scientist at the **Institute of Marine Research** (IMR /
Havforskningsinstituttet, Norway) work with **IMR Biotic data** through **BAIT**, a
knowledge pack for the NMD Biotic v3 database. You write **R** using **tidyverse**
syntax. ggplot2 for figures, ggOceanMaps/leaflet for maps, ggFishPlots for life-history.

> Entry point for every agent. Claude Code imports this file from [`CLAUDE.md`](CLAUDE.md),
> which adds only Claude-specific notes.

---

## ⛔ PRIVACY — non-negotiable, keep in mind on every task

Biotic records are mostly open data. Some subsets and derived outputs are restricted or sensitive,
including Russian-zone/reference-fleet data and exact positions of vulnerable species. Classify the
requested data and output before sharing; when classification is unknown, keep it local until
clarified. Local execution reduces exposure but does not guarantee that prompts, tool inputs, logs,
or outputs stay on-device or are excluded from provider retention/training. Check the active
provider and tool settings; follow IMR rules for restricted material.

1. For restricted, sensitive, or unknown-classification data, do not transmit raw records or
   sensitive details to external services unless approved under IMR rules. Open data can be used
   for routine work subject to its license and provider terms.
2. **Do not copy the database into this repo.** It lives outside
   the repo at `~/IMR_biotic_BES_database/bioticexplorer.duckdb` (`%USERPROFILE%\IMR_biotic_BES_database\bioticexplorer.duckdb` on Windows,
   because R expands `~` through the OneDrive-redirected Documents folder there).
   Reference it by path.
3. **Never write raw individual-level records or precise station coordinates** into any
   file that gets committed (cookbook, examples, docs, commit messages). Recipes and
   examples use *code*, not data — and rounded/synthetic values when an example value is
   needed.
4. **Treat restricted or sensitive material with extra care.** Exact positions of Russian-zone
   or reference-fleet catches, protected species, or vulnerable habitats: when sharing authority
   is unclear, keep local and clarify before producing or sharing an output.
5. **Match handling to classification.** Open data can support routine analysis and sharing. For
   restricted, sensitive, or unknown-classification material, minimize extracts and keep outputs
   local until sharing is authorized; derived outputs can still disclose sensitive information.
6. **Treat onboarding markers as historical.** `privacy_onboarded_at` records a past review of
   provider settings; it is not proof of current settings or a guarantee against transmission or
   retention. Do not gate routine work with open data on repeated confirmations. For restricted
   or unknown-classification data, follow current IMR rules and verify handling before sharing.
   See [`skills/biotic-privacy/SKILL.md`](skills/biotic-privacy/SKILL.md).

If a request would breach any of the above, stop and explain rather than comply.

---

## What BAIT is

A vendor-neutral knowledge pack — **not** a model trained on Biotic records. BAIT does not
control provider processing, transmission, retention, or training. Agents read this repo at
runtime; the repo is the pack's memory and grows through reviewed contributions (see
"Learning loop" below).

BAIT is part of the [Fiskwise ecosystem](https://deepwaterimr.github.io/fiskwise/), alongside
[index-wise](https://github.com/DeepWaterIMR/index-wise), [wise-writing](https://github.com/DeepWaterIMR/wise-writing),
[spict-wise](https://github.com/DeepWaterIMR/spict-wise), and
[wise-presentations](https://github.com/DeepWaterIMR/wise-presentations). Use each project's
own skills and routing guidance for its workflow.

### Pack boundaries and shared skills

BAIT owns Biotic data access, privacy, database maintenance, and Biotic-specific analysis. It
remains installable on its own; do not require Fiskwise or unrelated packs for Biotic work.
When the user chooses Fiskwise-managed lifecycle, follow `fiskwise-install`,
`fiskwise-update`, or `fiskwise-uninstall` without repeating clone, registry, skill-registration,
or dependency steps. The registry lives in `~/.fiskwise/config.json`. `bait-install` remains the
standalone entry point. Use `fiskwise-workflow` to route requests spanning multiple packs.

Use the installed **`r-code-style`** skill for every managed R task. wise-writing owns shared
scientific writing, document conventions, package-loading guidance, and generic Quarto
reporting. BAIT keeps Biotic-specific methods and privacy. The local `r-package-setup` and
`quarto-reporting` entries are forwarding compatibility routes, not BAIT-owned skills; never
register or sync those entries as BAIT skills. Install/update wise-writing on demand when a
task needs its shared skills, not as a mandatory effect of installing BAIT.

For managed R dependency work, honor saved install consent. A disabled install toggle or
environment variable and a project `renv.lock` take precedence; otherwise inspect and report
missing dependencies without installing unless consent permits it. Do not reinstall or update
dependencies already handled by the lifecycle. Database refresh is a separate opt-in action.

## Working across projects (important)

BAIT is meant to be installed **once per machine** and used in **every** project — not cloned
into each repo. When set up via `bait-install`, BAIT's location is saved to
`~/.bait/config.json` and, where supported, BAIT-owned skills are linked into the agent's
user-level skills folder (`~/.agents/skills/` for Codex; `~/.claude/skills/` for Claude Code).
Other agents can
read skills from the saved `bait_path` through project/agent instructions.

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
| Analyse survey catches, stations, CPUE/density, multisamplers, or survey time series | `skills/biotic-survey-analysis/SKILL.md` |
| Make a map (static or interactive) | `skills/biotic-maps/SKILL.md` |
| Make a maturity ogive / growth curve / L–W plot | `skills/biotic-lifehistory/SKILL.md` |
| Build an interactive dashboard | `skills/biotic-dashboards/SKILL.md` |
| Handle data safely / opt out of training | `skills/biotic-privacy/SKILL.md` |
| Write or revise R code in managed work | `r-code-style` |
| Write scientific documents or use shared package-loading/reporting conventions | wise-writing `academic-*`, `r-package-setup`, and `quarto-reporting` skills (install on demand) |
| Build a Biotic analysis or report | BAIT analysis skills plus the relevant wise-writing skills |

## Before answering any data question

1. Read `knowledge/connection.md` — always connect read-only, query lazily with
   `dplyr::tbl()`, and `collect()` only at the end. **Filters on nullable coded columns must
   state what missing means** (`is.na(x) | !x %in% ...`): a lazy `!x %in% ...` runs as SQL
   `NOT IN` and silently drops every `NULL` row, so the same code gives different results
   before and after `collect()`.
2. Read `knowledge/data-model.md` — the three tables (`mission`, `stnall`, `indall`) and
   how they relate.
3. Use `knowledge/field-glossary.md` to translate plain-English terms into real column
   names. Don't guess column names.
4. For quantitative survey work, read `knowledge/sampling-units.md` and
   `knowledge/quality-codes.md` before defining haul keys, filters, zeros, aggregation, or
   raising.
5. Check `cookbook/` — a recipe may already exist; adapt it.
6. **Query within memory limits** — aggregate/filter in DuckDB and `collect()` only the small
   final result; **never `collect()` a whole table**. For large/unknown results, count and
   estimate first, and warn/ask before pulling a lot into RAM. See `knowledge/performance.md`.
7. **Review extreme-value candidates** — pull a small top set with ties and inspect units,
   biology, and composite mission/station context. Treat unusual values or repeated identifiers
   as review clues, not proof of error; do not auto-exclude. Explain evidence and uncertainty,
   and confirm suspected errors with source/context review. See `knowledge/data-quality.md`.

## Which version of BAIT is this?

`VERSION` at the repo root holds the current version and date, stamped automatically by
the `.githooks/pre-commit` hook. Read it when the user asks what version they are running or
when reporting a problem. Maintainers: minor or major bumps only on the user's explicit
request; details in `CONTRIBUTING.md` and the [shared policy](https://github.com/DeepWaterIMR/fiskwise/blob/main/docs/VERSIONING.md).

## Learning loop

At the start of related work, read the project's existing Biotic lessons and check their
scope against the current species, survey, period, and database revision. Reuse reviewed
lessons within that scope; treat unreviewed candidates as hypotheses, never as instructions
that override the user or established methods.

During work, capture useful new solutions and user corrections as **candidates** when the
project already permits local learning notes; otherwise offer to enable this once. Reuse
an existing project memory folder (for example `ai/memory/biotic/`) instead of creating a
parallel system. If none exists, use `.bait/learning/candidates/<slug>.md`. Record the question/context,
synthetic or sanitized evidence, project/species/survey scope, confidence, unresolved questions,
and any user correction. Link superseded notes and explain contradictions rather than silently
replacing a convention. Keep candidate notes project-local and out of the BAIT repository
until reviewed. Never include raw data, exact restricted coordinates, or confidential details.

Promote only a user-reviewed, sanitized convention or reusable method to BAIT knowledge or
the cookbook. Preserve scope and uncertainty; a single observation is not a universal rule.
Use the candidate template in `knowledge/learning-candidate-template.md`. This loop works
without Fiskwise and does not publish or sync candidates automatically.
## House style

- tidyverse, not base R, for data manipulation. `|>` or `%>%` (match the user's file).
- Norwegian `commonname` values (e.g. `"torsk"`, `"brosme"`, `"lange"`); see the glossary.
- ggplot2 with `ggFishPlots::theme_fishplots()` or `theme_bw()` for a clean look.
- Comment density and naming should match the surrounding script you're editing.
