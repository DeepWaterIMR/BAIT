---
name: bait-install
description: Install or set up BAIT (Biotic AI Toolkit) for working with IMR Biotic data. Use when the user says "install BAIT", "install https://github.com/DeepWaterIMR/BAIT", "set up BAIT", or first asks to work with Biotic data and BAIT is not yet installed. Runs the full onboarding: privacy gate, clone BAIT, install skills globally, set up the database, verify the connection.
---

# Install BAIT

Goal: get BAIT working **once per machine** so it's available in **every** project — not
copied into each repo. Run these four steps in order. Stop and resolve any blocker before
moving on.

> Trigger: the user prompts *"install https://github.com/DeepWaterIMR/BAIT"* (or similar).

---

## Step 1 — Privacy gate (model training MUST be off)

Biotic data is confidential. Before anything else:

1. **Try to detect** whether model-training / data-retention is off for the agent you are.
   - If you can determine it (e.g. you're running on an API/enterprise/ZDR tier where inputs
     are not used for training), confirm that to the user and continue.
   - If you **cannot** verify it programmatically, do **not** assume it's off.
2. **If unverified or on a consumer tier**, tell the user clearly:
   > "Model training has to be turned off before using BAIT."
   Then give **agent-specific** instructions for turning it off (write them for the agent you
   actually are — Claude Code, Codex, Cursor, …; point to the provider's current privacy /
   data-controls page since menus change). See
   [`../biotic-privacy/SKILL.md`](../biotic-privacy/SKILL.md).
3. **Gate on explicit confirmation.** Present a single choice the user must select:
   **"I have turned off model training."** Do not proceed until they pick it. (In Claude Code
   use a selection prompt; otherwise ask and wait for an unambiguous yes.)

Never skip this step, even if BAIT is already partly installed.

---

## Step 2 — Locate or clone the BAIT repo

1. **Look for an existing install** before cloning:
   - Read `~/.bait/config.json` if it exists → use its `bait_path`.
   - If `bait_path` exists and contains `AGENTS.md`, `CLAUDE.md`, and `skills/bait-install/SKILL.md`,
     treat BAIT as already installed. Do **not** clone another copy.
   - If you already cloned BAIT during this install attempt before finding the existing
     `bait_path`, remove that accidental duplicate (or ask for confirmation if your tool
     requires approval for destructive actions) after verifying it has no uncommitted user
     changes. Keep the configured `bait_path` as the one source of truth.
   - Otherwise search likely locations (home, Documents, projects/code folders, any path the
     user has mentioned). If found, reuse it.
2. **If an existing install is found, reuse it.**
   - Check `git status --short --branch` in the existing install and report whether it is clean.
   - Continue with skill syncing, database lookup, and connection verification using that path.
3. **If not found, ask where to clone it.** Suggest a sensible default based on what you know
   about the user (e.g. their usual code/projects folder); otherwise propose `~/Documents/BAIT`
   or `~/BAIT`.
4. **🔒 Security — never install at a filesystem root or system directory.**
   - Reject paths like `/`, `C:\` (drive root), `/usr`, `/opt`, `C:\Windows`, `C:\Program Files`.
     (Some users — especially on Windows — drop repos straight into `C:\`. Don't allow it.)
   - If the user *insists* on root, **deny the request** and propose a safe user-space
     location instead (under their home directory). Explain it's a security/permissions risk.
   - If you discover an existing BAIT **or** BES database already sitting in a root/system
     dir, warn the user it shouldn't live there and offer to move it.
5. **Clone only when no existing install was found:**
   ```bash
   git clone https://github.com/DeepWaterIMR/BAIT "<chosen-path>"
   ```
6. **Record the install** so every future session/project can find it:
   - Write/merge `~/.bait/config.json`:
     ```json
     { "bait_path": "<chosen-path>",
       "bes_db_path": "~/IMR_biotic_BES_database/bioticexplorer.duckdb",
       "skills_synced_to": "~/.claude/skills",
       "installed": "<YYYY-MM-DD>" }
     ```
   - **Save to your own long-term memory** that BAIT lives at `<chosen-path>` and what it's
     for, so you recall it across projects. (For Claude Code, note it in user-level memory.)
7. **Make BAIT work across projects — install the skills globally.** Copy the skill folders
   into the user-level skills directory so they auto-load in every project:
   - macOS/Linux:
     ```bash
     mkdir -p ~/.claude/skills && cp -R "<bait_path>/skills/." ~/.claude/skills/
     ```
   - Windows (PowerShell):
     ```powershell
     New-Item -ItemType Directory -Force "$HOME/.claude/skills" | Out-Null
     Copy-Item -Recurse -Force "<bait_path>/skills/*" "$HOME/.claude/skills/"
     ```
   - For agents without a global-skills mechanism (e.g. Codex), instead point the agent's
     project/agent instructions at `<bait_path>` and rely on the saved config + memory.
8. **Link the shared `knowledge/` so the global skills can read it.** The skills reference
   `../../knowledge/`, which from `~/.claude/skills/<skill>/` resolves to `~/.claude/knowledge`.
   **Symlink** that to the repo's `knowledge/` so it stays current with every `git pull` — no
   separate copy to go stale:
   - macOS/Linux:
     ```bash
     ln -sfn "<bait_path>/knowledge" ~/.claude/knowledge
     ```
   - Windows (PowerShell, Developer Mode or admin):
     ```powershell
     New-Item -ItemType SymbolicLink -Force -Path "$HOME/.claude/knowledge" -Target "<bait_path>/knowledge"
     ```
     If symlinks aren't permitted, copy instead — but then it must be **re-copied on every
     update** (it won't track `git pull`):
     `Copy-Item -Recurse -Force "<bait_path>/knowledge" "$HOME/.claude/knowledge"`.
   - Remove any stale `~/.claude/skills/knowledge` left by older installs (wrong level — the
     links resolve to `~/.claude/knowledge`, not inside `skills/`).

After this, the keyword **"biotic"** (and tasks like maps/maturity ogives on Biotic data)
should make you reach for the `biotic-*` skills automatically, in any project.

---

## Step 3 — Locate or install the Biotic database (BES DuckDB)

1. **Look for it:** check `bes_db_path` from `~/.bait/config.json`, then the default
   `~/IMR_biotic_BES_database/bioticexplorer.duckdb`. If present, skip to Step 4.
2. **If missing, ask whether to install it.** It's a large download (>2 GB, can take hours).
3. **If yes, ask for the location** using the **same rules as Step 2** (no root/system dirs;
   suggest a default). **Strongly recommend the default `~/IMR_biotic_BES_database/`** so the
   BioticExplorer Shiny app can auto-detect it. Also recommend **not** placing the database in
   a cloud-synced/backup folder (Dropbox, OneDrive, ownCloud) — it's large and sensitive.
   Record the chosen path in `~/.bait/config.json`.
4. **Run the download** via [`../biotic-server-setup/SKILL.md`](../biotic-server-setup/SKILL.md)
   — it handles the intranet check, runs the download as a background/`screen` job with a log,
   monitors it, and swaps in the new database on success.

---

## Step 4 — Verify the connection

Confirm [`../biotic-connect/SKILL.md`](../biotic-connect/SKILL.md) actually works:

```r
library(DBI); library(duckdb)
con <- dbConnect(duckdb::duckdb(),
                 dbdir = path.expand("<bes_db_path>"), read_only = TRUE)
DBI::dbListTables(con)        # expect: mission, stnall, indall, ageall, metadata, csindex, gearindex
DBI::dbDisconnect(con, shutdown = TRUE)
```

- If it fails, **debug until it works**: common causes are a `duckdb` package/file-format
  mismatch (update `duckdb`, or rebuild via biotic-server-setup), the database still
  downloading, a wrong path in the config, or another process holding the file.
- When it works, tell the user BAIT is ready and show one example query (e.g. from
  [`../../cookbook/largest-cod.md`](../../cookbook/largest-cod.md)).

---

## Done

Summarise for the user: where BAIT is, that skills are installed globally, where the database
is, and that **updates** are handled by [`../bait-update/SKILL.md`](../bait-update/SKILL.md)
(`git pull` + re-sync skills; and database refresh via biotic-server-setup).
