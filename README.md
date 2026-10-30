[![Part of the Fiskwise ecosystem](https://deepwaterimr.github.io/fiskwise/assets/part-of-fiskwise.svg)](https://deepwaterimr.github.io/fiskwise/)

# 🎣 BAIT — Biotic AI Toolkit

<!-- version -->**Version 0.2.16** (2026-10-23)<!-- /version -->

**Teach your AI coding agent to work with IMR Biotic data — safely, on your own machine.**

BAIT is a knowledge pack that turns a general coding agent (Claude Code, Codex, Cursor, Antigravity, Mistral Vibe, …) into a competent assistant for the
[Institute of Marine Research](https://www.hi.no/hi) (IMR) **NMD Biotic** database. Install it and your agent can:

1. **Install, update, and maintain** the Biotic database
   ([BioticExplorerServer](https://github.com/DeepWaterIMR/BioticExplorerServer)).
2. **Connect** to it from R using tidyverse syntax.
3. **Answer data questions** — *"What is the largest cod in the database?"*, *"Map all cusk
   caught on the EggaN surveys."*
4. **Make plots, tables, maps, life-history analyses, and dashboards** with
   [ggplot2](https://ggplot2.tidyverse.org/),
   [ggOceanMaps](https://mikkovihtakari.github.io/ggOceanMaps/),
   [leaflet](https://rstudio.github.io/leaflet/),
   [ggFishPlots](https://deepwaterimr.github.io/ggFishPlots/), and
   [BioticExplorer](https://github.com/DeepWaterIMR/BioticExplorer)/Shiny.
5. **Extract Norwegian catch data** — sales notes (landings) and ERS logbooks with
   [RstoxUtils](https://deepwaterimr.github.io/RstoxUtils/), shaped for spict-wise and
   gadget-wise.
6. **Build reproducible Quarto analyses and reports** in HTML, Word, and PDF, using an
   organisation's Word template when supplied, the bundled IMR web-report template when
   explicitly requested, or a generic Manuscript design otherwise.

> **It is a knowledge pack, not a model trained on Biotic records.** Local R/DuckDB work
> does not guarantee that prompts, tool inputs, logs, or outputs stay on-device or are excluded
> from provider processing, retention, or training. See
> [Privacy](#-privacy-first).

## 🔒 Privacy first

Most Biotic data are open; some subsets are restricted or sensitive. Classify data and outputs under IMR rules. Local execution does not guarantee that agent prompts, tools, logs, or outputs stay on-device:

- BAIT contains **instructions only — never database records**. Examples and cookbook recipes
  use code and synthetic values, not real records. Ignore files block common data extensions
  as a safety net.
- The database lives **outside** this repo (`~/IMR_biotic_BES_database/` by default on
  macOS/Linux; `%USERPROFILE%\IMR_biotic_BES_database\` on Windows). These are defaults; the
  configured `bes_db_path` takes precedence.
- During setup, review provider training, retention, and tool-transmission controls. An
  onboarding record reflects a past review; settings may change, and a training opt-out does
  not guarantee no transmission or retention
  ([`skills/biotic-privacy`](skills/biotic-privacy/SKILL.md)).

## 🚀 Quickstart

1. **Get an agent**: [Claude Code](https://claude.com/claude-code) or
   [Codex](https://openai.com/codex), etc.
2. **Tell your agent:**
   ```
   install https://github.com/DeepWaterIMR/BAIT
   ```
   The agent runs [`bait-install`](skills/bait-install/SKILL.md) and walks you through:
   a privacy and data-classification review → cloning BAIT to a sensible place
   → installing the skills **globally** (so BAIT works in every project) → setting up the
   database → verifying the connection.
3. **Ask away**: *"What's the largest cod in the database?"*, *"Map cusk on EggaN."*

Installed **once per machine**, then available in all your projects. Keep it current with
*"update BAIT"* ([`bait-update`](skills/bait-update/SKILL.md)).

If you use Fiskwise's managed pack lifecycle, follow its `fiskwise-install`, `fiskwise-update`,
and `fiskwise-uninstall` skills instead of repeating clone and skill-registration steps. BAIT
remains usable as a standalone pack. Shared scientific writing and generic Quarto/package
loading guidance comes from wise-writing and is installed on demand. The Biotic database is
separate user data: an existing database is adopted, a new one is recorded as BAIT-created only
after an approved successful compile, and refresh/removal are separate opt-in actions.
Use `fiskwise-workflow` for requests spanning packs. For managed R tasks, always use
**`r-code-style`**.

> **Manual / advanced:** you can still `git clone https://github.com/DeepWaterIMR/BAIT`
> yourself and open your agent in the folder — it reads [`CLAUDE.md`](CLAUDE.md) /
> [`AGENTS.md`](AGENTS.md) automatically. The agent-driven install above just does this for
> you and sets up cross-project use.

## 🗂️ What's inside

| Folder | What it holds |
|---|---|
| [`CLAUDE.md`](CLAUDE.md) / [`AGENTS.md`](AGENTS.md) | Agent entry points (identity + privacy guardrails + router) |
| [`skills/`](skills/) | One skill per capability — the agent reads these on demand |
| [`knowledge/`](knowledge/) | Vendor-neutral reference: data model, field glossary, connection, packages |
| [`cookbook/`](cookbook/) | Standardized query → code recipes (grows over time) |
| [`examples/`](examples/) | Runnable `.R` scripts mirroring the cookbook |
| [`scripts/`](scripts/) | Maintenance scripts (e.g. regenerate the field glossary from the XSD) |
| [`docs/`](docs/) | The BAIT website (Quarto → GitHub Pages) |

## 🧰 Siblings

BAIT is the data layer. The packs that build on it:

- [**wise-writing**](https://github.com/DeepWaterIMR/wise-writing) — scientific writing style, document conventions, and the project skeleton the other packs scaffold from.
- [**index-wise**](https://github.com/DeepWaterIMR/index-wise) — sdmTMB spatiotemporal survey indices, built from Biotic data through BAIT.
- [**spict-wise**](https://github.com/DeepWaterIMR/spict-wise) — SPiCT biomass-dynamic stock assessments, driven by an index from index-wise and a catch series from `catch-data`.
- [**gadget-wise**](https://github.com/DeepWaterIMR/gadget-wise) — gadget3 length- and age-structured models; BAIT is its default data-loop for Biotic length, age and maturity data.
- [**wise-presentations**](https://github.com/DeepWaterIMR/wise-presentations) — Quarto RevealJS slides.

Install whichever you need alongside; the skills stay out of each other's way.

## 🧠 It learns from you

When you ask something new, the agent offers to save the solution as a cookbook recipe.
Review it, commit it, and the next person's agent benefits. The cookbook is IMR's shared,
version-controlled institutional memory. See [`CONTRIBUTING.md`](CONTRIBUTING.md).

## 📚 Website

Example queries and getting-started guidance: **https://deepwaterimr.github.io/BAIT/**
(built from [`docs/`](docs/)).

## 🙋 Contact

Maintainer: Mikko Vihtakari (<mikko.vihtakari@hi.no>),
[DeepWaterIMR](https://github.com/DeepWaterIMR). Contributions welcome — see
[`CONTRIBUTING.md`](CONTRIBUTING.md).
