<!-- badges / logo go here once available -->

# 🎣 BAIT — Biotic AI Toolkit

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

> **It is not a trained model.** Your data is never sent anywhere and never enters any
> model's weights. The agent simply *reads this repo* while it helps you. See
> [Privacy](#-privacy-first).

## 🔒 Privacy first

Some Biotic data are confidential, and some are sensitive. BAIT is built so the **raw data stays on your computer**:

- BAIT contains **instructions only — never data**. The `.gitignore`/`.claudeignore` files
  block every common data extension as a safety net.
- The database lives **outside** this repo (`~/IMR_biotic_BES_database/` by default).
- Before you start, **turn off model training / data retention** for your agent — BAIT
  reminds you and walks you through it
  ([`skills/biotic-privacy`](skills/biotic-privacy/SKILL.md)).

## 🚀 Quickstart

1. **Get an agent**: [Claude Code](https://claude.com/claude-code) or
   [Codex](https://openai.com/codex), etc.
2. **Tell your agent:**
   ```
   install https://github.com/DeepWaterIMR/BAIT
   ```
   The agent runs [`bait-install`](skills/bait-install/SKILL.md) and walks you through:
   confirming **model training is off** → cloning BAIT to a sensible place → installing the
   skills **globally** (so BAIT works in every project) → setting up the database →
   verifying the connection.
3. **Ask away**: *"What's the largest cod in the database?"*, *"Map cusk on EggaN."*

Installed **once per machine**, then available in all your projects. Keep it current with
*"update BAIT"* ([`bait-update`](skills/bait-update/SKILL.md)).

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
