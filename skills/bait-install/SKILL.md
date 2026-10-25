---
name: bait-install
description: 'Install or set up BAIT (Biotic AI Toolkit) for working with IMR Biotic data. Use when the user says "install BAIT", "install https://github.com/DeepWaterIMR/BAIT", "set up BAIT", or first asks to work with Biotic data and BAIT is not yet installed. Runs setup review for data classification and provider handling, then clones BAIT, install skills globally, set up the database, verify the connection.'
---

# Install BAIT

Goal: get BAIT working **once per machine** so it's available in **every** project — not
copied into each repo. Run these four steps in order. Stop and resolve any blocker before
moving on.

For a direct machine-wide install, use `fiskwise-install` when the user has chosen managed
lifecycle. If this skill was invoked by that workflow, continue only the BAIT-specific privacy
and optional database steps; leave clone, registry, skill registration, and dependency work to
the parent workflow. The standalone procedure below remains available.

> Trigger: the user prompts *"install https://github.com/DeepWaterIMR/BAIT"* (or similar).

---

## Step 1 — Privacy and classification review

Most Biotic data are open; some subsets are restricted or sensitive. Review the classification
of the data and outputs to be used, and the active provider/account's transmission, retention,
and training behavior. Local R/DuckDB execution does not guarantee that prompts, tools, logs,
or outputs stay on-device. A training opt-out is not a guarantee against transmission or
retention. Consult [`../biotic-privacy/SKILL.md`](../biotic-privacy/SKILL.md) and current
provider documentation.

For open data, proceed with routine work under its license and provider terms. For restricted
or unknown-classification material, keep it local unless external processing is authorized
under IMR rules. An existing `privacy_onboarded_at` records a past review only; do not treat it
as proof of current settings or require repeated confirmation for ordinary open-data queries.
If useful, record the review date and provider/account in `~/.bait/config.json`.

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
   git -C "<chosen-path>" config core.hooksPath .githooks
   ```
   The second line enables the version-stamping `pre-commit` hook, so a user who
   contributes a recipe back gets the version bump for free. It is harmless for users who
   never commit.
6. **Record the install** so every future session/project can find it. In managed mode, pass
   the pack path and any chosen database path/provenance to `fiskwise-install`; let that
   lifecycle merge the registry and `~/.bait/config.json` without overwriting unrelated fields.
   For standalone installation:
   - Write/merge `~/.bait/config.json`. On Windows, store `bes_db_path` as an explicit
     `%USERPROFILE%`-based absolute path rather than `~`, because R can expand `~` to
     Documents. Example macOS/Linux config:
     ```json
     { "bait_path": "<chosen-path>",
       "bes_db_path": "~/IMR_biotic_BES_database/bioticexplorer.duckdb",
       "privacy_onboarded_at": "<YYYY-MM-DD>",
       "privacy_onboarded_for": "<agent-or-tier>",
       "skills_synced_to": ["~/.claude/skills", "~/.agents/skills"],
       "installed": "<YYYY-MM-DD>" }
     ```
   - **Save to your own long-term memory** that BAIT lives at `<chosen-path>` and what it's
     for, so you recall it across projects. (For Claude Code, note it in user-level memory.)
7. **Make BAIT work across projects — install the skills globally.** Sync each BAIT-owned
   skill folder separately. `rsync --delete` must target a named BAIT skill directory, never
   the full user skills directory. On first migration, back up and reconcile matching legacy
   Codex folders so duplicate skills do not remain active:
   - macOS/Linux:
     ```bash
     bait_path="<bait_path>"
     legacy="$HOME/.codex/skills"
     backup_root="$HOME/.agents/skill-backups/$(date +%Y%m%d-%H%M%S)"
     resolve_path() { python3 -c 'import os,sys; print(os.path.realpath(sys.argv[1]))' "$1"; }
     for source in "$bait_path"/skills/*; do
       [ -d "$source" ] || continue
       name=${source##*/}
       source_path=$(resolve_path "$source")
       case "$name" in r-package-setup|quarto-reporting) continue ;; esac
       legacy_backup=0
       if [ -L "$legacy/$name" ] && [ "$(resolve_path "$legacy/$name")" = "$source_path" ]; then
         legacy_backup=1 # Archive the duplicate only after the canonical link is verified.
       elif [ -e "$legacy/$name" ] || [ -L "$legacy/$name" ]; then
         diff -qr "$legacy/$name" "$source" || echo "Legacy $name differs; preserve it in $backup_root."
         legacy_backup=1
       fi
       for destination in "$HOME/.claude/skills" "$HOME/.agents/skills"; do
         target="$destination/$name"
         if [ -L "$target" ] && [ "$(resolve_path "$target")" = "$source_path" ]; then
           continue
         fi
         if [ -e "$target" ] || [ -L "$target" ]; then
           mkdir -p "$backup_root"
           mv "$target" "$backup_root/$(basename "$(dirname "$destination")")-$name"
         fi
         mkdir -p "$destination"
         ln -s "$source_path" "$target"
       done
       if [ "$legacy_backup" = 1 ]; then
         mkdir -p "$backup_root"
         mv "$legacy/$name" "$backup_root/codex-$name"
       fi
     done
     ```
   - Windows (PowerShell):
     ```powershell
     $legacy = "$HOME/.codex/skills"
     $backup = "$HOME/.agents/skill-backups/$(Get-Date -Format yyyyMMdd-HHmmss)"
     foreach ($source in Get-ChildItem "<bait_path>/skills" -Directory) {
       $name = $source.Name
       if ($name -in @("r-package-setup", "quarto-reporting")) { continue }
       $sourcePath = [IO.Path]::GetFullPath($source.FullName)
       $legacyItem = $null
       $legacySameLink = $false
       if (Test-Path "$legacy/$name") {
         $legacyItem = Get-Item -Force "$legacy/$name"
         if ($legacyItem.LinkType -eq "SymbolicLink" -and $legacyItem.Target -eq $sourcePath) {
           $legacySameLink = $true
         }
       }
       if ($null -ne $legacyItem -and -not $legacySameLink) {
         New-Item -ItemType Directory -Force $backup | Out-Null
         Move-Item "$legacy/$name" "$backup/$name"
         Compare-Object (Get-Content "$backup/$name/SKILL.md") (Get-Content "$($source.FullName)/SKILL.md") |
           Out-File "$backup/$name-differences.txt"
       }
       foreach ($destination in @("$HOME/.claude/skills", "$HOME/.agents/skills")) {
         $target = "$destination/$name"
         $targetItem = Get-Item -Force $target -ErrorAction SilentlyContinue
         if ($targetItem -and $targetItem.LinkType -eq "SymbolicLink" -and $targetItem.Target -eq $sourcePath) { continue }
         if ($targetItem) {
           New-Item -ItemType Directory -Force $backup | Out-Null
           $agentName = Split-Path (Split-Path $destination -Parent) -Leaf
           Move-Item $target "$backup/$agentName-$name"
         }
         New-Item -ItemType Directory -Force $destination | Out-Null
         try {
           New-Item -ItemType SymbolicLink -Path $target -Target $sourcePath -ErrorAction Stop | Out-Null
         } catch {
           # Ordinary Windows accounts may not have symbolic-link privileges.
           Copy-Item -LiteralPath $source.FullName -Destination $target -Recurse -Force -ErrorAction Stop
         }
         if (-not (Test-Path "$target/SKILL.md")) { throw "Skill installation failed: $target" }
       }
       if ($legacySameLink) {
         New-Item -ItemType Directory -Force $backup | Out-Null
         Move-Item "$legacy/$name" "$backup/codex-$name"
       }
     }
     ```
   - Claude Code uses `~/.claude/skills/`; Codex uses `~/.agents/skills/`. The legacy migration
     backs up and moves only same-named BAIT skill folders from `~/.codex/skills/`; it leaves
     unrelated folders there untouched. Compare any reported differences with the saved copy
     and reconcile wanted edits into BAIT's source before the next sync. For other agents,
     point project/agent instructions at `<bait_path>` and rely on the saved config.
   - `r-package-setup` and `quarto-reporting` are forwarding compatibility entries for
     wise-writing. Do not register them as BAIT skills. Ensure wise-writing is available on
     demand when a task needs its shared reporting or package-loading skills; do not install
     wise-writing solely because BAIT is installed.
   - If a destination skill is already a valid symlink to the exact source skill folder, leave
     it in place; pulling BAIT updates it automatically. Never copy or sync a source onto its
     own symlink. Back up a differing folder or link before replacing it.
8. **Link the shared `knowledge/` so global skills can read it.** Skills reference
   `../../knowledge/`, resolving to the agent-level `knowledge/` directory.
   **Symlink** that to the repo's `knowledge/` so it stays current with every `git pull` — no
   separate copy to go stale:
   - macOS/Linux:
     ```bash
     ln -sfn "<bait_path>/knowledge" ~/.claude/knowledge
     ln -sfn "<bait_path>/knowledge" ~/.agents/knowledge
     ```
   - Windows (PowerShell, Developer Mode or admin):
     ```powershell
     New-Item -ItemType SymbolicLink -Force -Path "$HOME/.claude/knowledge" -Target "<bait_path>/knowledge"
     New-Item -ItemType SymbolicLink -Force -Path "$HOME/.agents/knowledge" -Target "<bait_path>/knowledge"
     ```
     If symlinks aren't permitted, copy instead — but then it must be **re-copied on every
     update** (it won't track `git pull`): copy it to the applicable agent-level
     `knowledge/` directory.
   - If a legacy `skills/knowledge` directory exists, verify it is BAIT's misplaced copy
     before removing it; shared knowledge belongs beside `skills/`, not inside it.

After this, the keyword **"biotic"** (and tasks like maps/maturity ogives on Biotic data)
should make you reach for the `biotic-*` skills automatically, in any project.

---

## Step 3 — Locate or install the Biotic database (BES DuckDB)

1. **Look for it:** check `bes_db_path` from `~/.bait/config.json`, then the default
   `~/IMR_biotic_BES_database/bioticexplorer.duckdb`. If present, adopt it and skip to Step 4;
   never claim an existing database as BAIT-created.
2. **If missing, ask whether to install it.** It's a large download (>2 GB, can take hours).
3. **If yes, ask for the location** using the **same rules as Step 2** (no root/system dirs;
   suggest a default). **Strongly recommend the default `~/IMR_biotic_BES_database/` on
   macOS/Linux, or `%USERPROFILE%\IMR_biotic_BES_database\` on Windows** so the
   BioticExplorer Shiny app can auto-detect it. Also recommend **not** placing the database in
   a cloud-synced/backup folder (Dropbox, OneDrive, ownCloud, OneDrive Documents) — it's
   large and sensitive. In managed mode, pass the selected path to the parent lifecycle so it
   can merge `bes_db_path`; for standalone installation, record it in `~/.bait/config.json`.
4. **Run the download** via [`../biotic-server-setup/SKILL.md`](../biotic-server-setup/SKILL.md)
   — it handles the intranet check, runs the download as a background/`screen` job with a log,
   monitors it, and swaps in the new database on success. Record database creation provenance
   only when the destination was confirmed absent before this approved compile and the compile
   and verification succeeded. A database is user data: uninstall does not remove it by
   default, and any removal is a separate explicit action that keeps its sidecars and backups.
   For managed installation, pass provenance only through the Fiskwise lifecycle registry at
   `~/.fiskwise/config.json`; standalone installs record the selected `bes_db_path` but must
   not infer ownership from the path or filename.

---

## Step 4 — Verify the connection

Confirm [`../biotic-connect/SKILL.md`](../biotic-connect/SKILL.md) actually works:

```r
library(DBI); library(duckdb)
con <- dbConnect(duckdb::duckdb(),
                 dbdir = path.expand("<bes_db_path>"), read_only = TRUE)
DBI::dbListTables(con)        # expect core tables plus csindex/gearindex/taxaindex
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
(`git pull` + re-sync skills; and incremental database refresh via biotic-server-setup).

On Windows without symbolic-link privileges, keep per-skill copies and refresh them on updates.
Keep an existing `~/.codex/knowledge` link as a compatibility alias when using `~/.agents/knowledge`.
