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
3. **Re-sync skills to supported global folders** (overwrite with the updated versions):
   - macOS/Linux:
     ```bash
     mkdir -p ~/.claude/skills ~/.codex/skills
     cp -R "<bait_path>/skills/." ~/.claude/skills/
     cp -R "<bait_path>/skills/." ~/.codex/skills/
     ```
   - Windows (PowerShell):
     ```powershell
     New-Item -ItemType Directory -Force "$HOME/.claude/skills", "$HOME/.codex/skills" | Out-Null
     Copy-Item -Recurse -Force "<bait_path>/skills/*" "$HOME/.claude/skills/"
     Copy-Item -Recurse -Force "<bait_path>/skills/*" "$HOME/.codex/skills/"
     ```
   - Sync only folders supported by the installed agent(s). Claude Code uses
     `~/.claude/skills/`; Codex uses `~/.codex/skills/`. Other agents can read BAIT through
     `AGENTS.md` and the configured `bait_path`.
   - This overwrites BAIT-managed skill folders only; it does not touch unrelated skills.
   - **Knowledge needs no re-copy if it's a symlink.** The applicable agent-level
     `knowledge/` directory should point to `<bait_path>/knowledge`, so `git pull` refreshes
     it automatically. Verify the links:
     ```bash
     [ -L ~/.claude/knowledge ] || ln -sfn "<bait_path>/knowledge" ~/.claude/knowledge
     [ -L ~/.codex/knowledge ] || ln -sfn "<bait_path>/knowledge" ~/.codex/knowledge
     rm -rf ~/.claude/skills/knowledge   # remove stale misplaced copy from older installs
     rm -rf ~/.codex/skills/knowledge
     ```
     On Windows, if knowledge was **copied** rather than symlinked, re-copy it to each
     applicable location:
     ```powershell
     Copy-Item -Recurse -Force "<bait_path>/knowledge" "$HOME/.claude/knowledge"
     Copy-Item -Recurse -Force "<bait_path>/knowledge" "$HOME/.codex/knowledge"
     ```
4. If the field glossary source (the XSD) or `scripts/distill_xsd.R` changed, offer to
   regenerate `knowledge/field-glossary.md`:
   ```bash
   Rscript "<bait_path>/scripts/distill_xsd.R" \
     "https://www.imr.no/formats/nmdbiotic/v3/nmdbioticv3.xsd" \
     "<bait_path>/knowledge/field-glossary.md"
   ```
5. Tell the user what changed (`git -C "<bait_path>" log --oneline -5`).

## 2. Update the Biotic database (incremental)

Requires the **IMR intranet** (VPN / HI-Adm). Hand off to
[`../biotic-server-setup/SKILL.md`](../biotic-server-setup/SKILL.md) → "Update the database":
it **first checks that BioticExplorerServer itself is up to date on GitHub** (Step 1), then
runs `updateDatabase()`. That function downloads only changed years in normal operation and
automatically performs a safe full rebuild if the package schema changed.

## Notes

- Updating skills here keeps BAIT working **across all projects** without re-cloning anywhere.
- Keep `~/.bait/config.json` accurate if paths changed, and preserve any
  `privacy_onboarded_at` / `privacy_onboarded_for` fields already recorded there. If an older
  install has no privacy onboarding marker yet, add it when the user confirms their setup
  while you are already updating the config for another reason.
