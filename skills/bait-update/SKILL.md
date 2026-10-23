---
name: bait-update
description: Update BAIT to the latest version — git pull the BAIT repo, re-sync the skills into the global skills folder, and optionally refresh the Biotic database. Use when the user says "update BAIT", "pull the latest BAIT", or asks to get new recipes/skills or fresher Biotic data.
---

# Update BAIT

Two things can be updated: **the BAIT toolkit** (skills/knowledge/recipes via `git pull`) and
**the Biotic database** (an incremental changed-year refresh). Ask the user which they want;
default to the toolkit.

## 1. Update the toolkit (git pull + re-sync skills)

1. Find the repo: `bait_path` in `~/.bait/config.json` (fall back to a search). If BAIT
   isn't installed at all, switch to [`../bait-install/SKILL.md`](../bait-install/SKILL.md).
2. Pull:
   ```bash
   git -C "<bait_path>" pull --ff-only
   ```
   - If the user has **local changes** (e.g. their own draft recipes), don't clobber them —
     `git -C "<bait_path>" status` first; stash or commit, or pull on a clean tree.
3. **Re-sync BAIT-managed skill folders** to supported global folders. Scope deletion to each
   named skill directory. Back up and move matching legacy Codex folders so old duplicates do
   not stay active:
   - macOS/Linux:
     ```bash
     bait_path="<bait_path>"
     legacy="$HOME/.codex/skills"
     backup=""
     for source in "$bait_path"/skills/*; do
       [ -d "$source" ] || continue
       name=${source##*/}
       if [ -d "$legacy/$name" ]; then
         [ -n "$backup" ] || backup=$(mktemp -d "$HOME/.codex/skills-backup.XXXXXX")
         diff -qr "$legacy/$name" "$source" || \
           echo "Legacy $name differed; its full copy will be preserved in $backup."
       fi
       for destination in "$HOME/.claude/skills" "$HOME/.agents/skills"; do
         mkdir -p "$destination/$name"
         rsync -a --delete "$source/" "$destination/$name/"
       done
       if [ -d "$legacy/$name" ]; then mv "$legacy/$name" "$backup/"; fi
     done
     ```
   - Windows (PowerShell):
     ```powershell
     $legacy = "$HOME/.codex/skills"
     $backup = "$HOME/.codex/skills-backup-$(Get-Date -Format yyyyMMdd-HHmmss)"
     foreach ($source in Get-ChildItem "<bait_path>/skills" -Directory) {
       $name = $source.Name
       if (Test-Path "$legacy/$name") {
         New-Item -ItemType Directory -Force $backup | Out-Null
         Move-Item "$legacy/$name" "$backup/$name"
         if ((Get-ChildItem "$backup/$name" -Recurse | Measure-Object).Count -gt 0) {
           Compare-Object (Get-Content "$backup/$name/SKILL.md") (Get-Content "$($source.FullName)/SKILL.md") |
             Out-File "$backup/$name-differences.txt"
         }
       }
       foreach ($destination in @("$HOME/.claude/skills", "$HOME/.agents/skills")) {
         New-Item -ItemType Directory -Force "$destination/$name" | Out-Null
         robocopy $source.FullName "$destination/$name" /E /PURGE | Out-Null
       }
     }
     ```
   - Sync only folders supported by the installed agent(s). Claude Code uses
     `~/.claude/skills/`; Codex uses `~/.agents/skills/`. Other agents can read BAIT through
     `AGENTS.md` and the configured `bait_path`.
   - This replaces BAIT-managed skill folders only; it does not touch unrelated skills.
     The legacy migration backs up and moves only matching BAIT skill folders; compare any
     reported differences with the saved copy and reconcile wanted edits into BAIT's source.
   - **Knowledge needs no re-copy if it's a symlink.** The applicable agent-level
     `knowledge/` directory should point to `<bait_path>/knowledge`, so `git pull` refreshes
     it automatically. Verify the links:
     ```bash
     [ -L ~/.claude/knowledge ] || ln -sfn "<bait_path>/knowledge" ~/.claude/knowledge
     [ -L ~/.agents/knowledge ] || ln -sfn "<bait_path>/knowledge" ~/.agents/knowledge
     ```
     On Windows, if knowledge was **copied** rather than symlinked, re-copy it to each
     applicable location:
     ```powershell
     Copy-Item -Recurse -Force "<bait_path>/knowledge" "$HOME/.claude/knowledge"
     Copy-Item -Recurse -Force "<bait_path>/knowledge" "$HOME/.agents/knowledge"
     ```
     If a legacy `skills/knowledge` directory exists, verify it is BAIT's misplaced copy
     before removing it.
4. If the field glossary source (the XSD) or `scripts/distill_xsd.R` changed, offer to
   regenerate `knowledge/field-glossary.md`:
   ```bash
   Rscript "<bait_path>/scripts/distill_xsd.R" \
     "https://www.imr.no/formats/nmdbiotic/v3/nmdbioticv3.xsd" \
     "<bait_path>/knowledge/field-glossary.md"
   ```
5. **Make sure the version hook is enabled** (older clones predate it):
   ```bash
   git -C "<bait_path>" config core.hooksPath .githooks
   ```
6. Tell the user what changed — the new version and the last few commits:
   ```bash
   cat "<bait_path>/VERSION"
   git -C "<bait_path>" log --oneline -5
   ```

## 2. Update the Biotic database (incremental)

Requires the **IMR intranet** (VPN / HI-Adm). Hand off to
[`../biotic-server-setup/SKILL.md`](../biotic-server-setup/SKILL.md) → "Update the database":
it **first checks that BioticExplorerServer itself is up to date on GitHub** (Step 1), then
runs `updateDatabase()`. That function downloads only changed years in normal operation and
automatically performs a safe full rebuild if the package schema changed.
The update job snapshots the database first and writes `bait_update_report.md` afterwards;
summarise it for the user (new entries and suspicious entries), as described under "After the
update" in that skill.

## Notes

- Updating skills here keeps BAIT working **across all projects** without re-cloning anywhere.
- Keep `~/.bait/config.json` accurate if paths changed, and preserve any
  `privacy_onboarded_at` / `privacy_onboarded_for` fields already recorded there. If an older
  install has no privacy onboarding marker yet, add it when the user confirms their setup
  while you are already updating the config for another reason.
