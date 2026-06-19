---
name: biotic-privacy
description: Guide safe handling of confidential/sensitive IMR Biotic data with AI agents — turning off model training/data retention, keeping raw data local, handling Russian-zone and other sensitive data, and deciding what outputs are safe to share. Use during install/onboarding, for privacy questions, and for occasional reminders during Biotic work; do not block routine local queries just because the user has not re-confirmed the training toggle in the current chat.
---

# Handling Biotic data safely

Biotic data is confidential; some of it is sensitive (e.g. Russian-zone data, exact
positions of vulnerable species/habitats). BAIT's promise: **raw data stays on the user's
machine and never trains a model.** This skill is how you keep that promise.

> Key fact: a coding agent does **not** train on your data by reading it. Training only
> happens if (a) data is sent to a model provider **and** (b) that provider is allowed to
> retain/train on it. BAIT closes both doors.

## Install/onboarding check (blocking, once per machine/agent setup)

Confirm these during `bait-install` or first-time setup:

1. **Training / data-retention is OFF** for the agent in use (see vendor notes below).
2. **The database is in its own location** (`~/IMR_biotic_BES_database/`), *outside* any repo
   that could be pushed.
3. **You're in a working folder that won't be committed with data** — BAIT's
   `.gitignore`/`.claudeignore` block data extensions; don't override them.
4. **For sensitive subsets** (Russian-zone, protected species), the user has agreed on what
   may be produced/shared.

When this is done, record it in `~/.bait/config.json` as `privacy_onboarded_at` (and, if
useful, `privacy_onboarded_for`). That marker tells future agents the one-time onboarding
check already happened.

## Routine use (non-blocking)

For ordinary local database queries:

1. **If `~/.bait/config.json` contains `privacy_onboarded_at`, assume the training toggle was
   already covered during setup.** Do **not** stop and ask again just because a new chat or
   session started.
2. **Give a brief reminder only when it adds value**:
   - the user asks about privacy or data handling;
   - the task involves unusually sensitive subsets or precise positions;
   - there is a concrete reason to think the setting changed;
   - the agent is helping with first-time setup and no onboarding marker exists yet.
3. **If the marker is missing on an older install, remind rather than block.** Continue with
   the local query unless another privacy rule would be breached, and write the marker next
   time `bait-install`/`bait-update` or another config-writing workflow runs.

The thing that must remain hard-blocked is **sending raw data out of the machine**. A missing
fresh confirmation in the current chat is not, by itself, a reason to block a routine local
query.

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
