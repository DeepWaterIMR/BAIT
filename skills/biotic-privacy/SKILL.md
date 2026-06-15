---
name: biotic-privacy
description: Guide safe handling of confidential/sensitive IMR Biotic data with AI agents — turning off model training/data retention, keeping raw data local, handling Russian-zone and other sensitive data, and deciding what outputs are safe to share. Use before working on Biotic data and whenever a privacy or data-handling question comes up.
---

# Handling Biotic data safely

Biotic data is confidential; some of it is sensitive (e.g. Russian-zone data, exact
positions of vulnerable species/habitats). BAIT's promise: **raw data stays on the user's
machine and never trains a model.** This skill is how you keep that promise.

> Key fact: a coding agent does **not** train on your data by reading it. Training only
> happens if (a) data is sent to a model provider **and** (b) that provider is allowed to
> retain/train on it. BAIT closes both doors.

## Pre-flight checklist (run before working on Biotic data)

Confirm with the user, in order:

1. **Training / data-retention is OFF** for the agent in use (see vendor notes below).
2. **The database is in its own location** (`~/IMR_biotic_BES_database/`), *outside* any repo
   that could be pushed.
3. **You're in a working folder that won't be committed with data** — BAIT's
   `.gitignore`/`.claudeignore` block data extensions; don't override them.
4. **For sensitive subsets** (Russian-zone, protected species), the user has agreed on what
   may be produced/shared.

If any is unmet, pause and resolve it before querying data.

## Turning off training / retention (verify the current setting — UIs change)

General principle: use a mode where your inputs are **not** used to improve/train models and
ideally **not retained**. Where to look:

- **Claude / Claude Code (consumer):** Settings → Privacy — disable the "help improve
  Claude" / model-training option. **API / Team / Enterprise / Bedrock / Vertex:** API
  inputs are not used for training by default, and zero-data-retention can be arranged.
- **OpenAI / Codex / ChatGPT:** Settings → Data Controls — turn off "improve the model for
  everyone" (training). API usage is not used for training by default; ZDR available on
  eligible accounts.
- **Other agents (Cursor, Gemini CLI, etc.):** find the equivalent "privacy mode" / "do not
  train on my data" / "zero data retention" setting and enable it.

Because these settings move, **don't assert the exact menu path — point the user to the
provider's current privacy/data-controls page and have them confirm the toggle.** When in
doubt, prefer API/enterprise tiers with ZDR over consumer tiers.

## Working with data over time

- **Keep raw data local.** Never upload/paste raw rows into external tools, issues, chats
  that leave the machine, or commit them.
- **Minimise what enters context.** Query and summarise; don't dump whole tables into the
  conversation. `.claudeignore` keeps data files out of automatic reads — point the agent at
  a specific file only when needed.
- **Outputs:** aggregates, model parameters (L50, L∞…), and figures are generally shareable;
  raw individual records and precise sensitive coordinates are not. **Default to derived
  outputs.**
- **Sensitive data:** for Russian-zone catches, protected species, or vulnerable habitats,
  aggregate/jitter positions and **ask before producing or sharing** anything position-level.
- **Dashboards:** run locally; never deploy Biotic data to a public host
  (see [`../biotic-dashboards/SKILL.md`](../biotic-dashboards/SKILL.md)).
- **Sharing data with a colleague** = a deliberate act: export to a file (it'll be outside
  the repo), transfer it through approved IMR channels, and record what/why. Don't route it
  through the agent or the internet.

## If something leaks

Tell the user immediately, stop, and help them: revoke/rotate any shared access, delete the
exposed copy, and (if a provider with training enabled received it) report per IMR data-
handling policy. Note that data sent to an external service may persist even after deletion.
