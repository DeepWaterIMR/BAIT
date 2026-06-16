---
name: bait-update
description: Update BAIT to the latest version — git pull the BAIT repo, re-sync the skills into the global skills folder, and optionally refresh the Biotic database. Use when the user says "update BAIT", "pull the latest BAIT", or asks to get new recipes/skills or fresher Biotic data.
---

# Update BAIT

Two things can be updated: **the BAIT toolkit** (skills/knowledge/recipes via `git pull`) and
**the Biotic database** (a fresh download). Ask the user which they want; default to the
toolkit.

## 1. Update the toolkit (git pull + re-sync skills)

1. Find the repo: `bait_path` in `~/.bait/config.json` (fall back to a search). If BAIT
   isn't installed at all, switch to [`../bait-install/SKILL.md`](../bait-install/SKILL.md).
2. Pull:
   ```bash
   git -C "<bait_path>" pull --ff-only
   ```
   - If the user has **local changes** (e.g. their own draft recipes), don't clobber them —
     `git -C "<bait_path>" status` first; stash or commit, or pull on a clean tree.
3. **Re-sync skills to the global folder** (overwrite with the updated versions):
   - macOS/Linux:
     ```bash
     cp -R "<bait_path>/skills/." ~/.claude/skills/
     ```
   - Windows (PowerShell):
     ```powershell
     Copy-Item -Recurse -Force "<bait_path>/skills/*" "$HOME/.claude/skills/"
     ```
   - This overwrites the BAIT-managed skills under `~/.claude/skills/` with the latest. It
     does not touch unrelated skills the user has there.
   - **Knowledge needs no re-copy if it's a symlink.** `~/.claude/knowledge` should be a
     symlink to `<bait_path>/knowledge` (set up by `bait-install`), so the `git pull` above
     already refreshed it. Just make sure the link exists and points at the repo:
     ```bash
     [ -L ~/.claude/knowledge ] || ln -sfn "<bait_path>/knowledge" ~/.claude/knowledge
     rm -rf ~/.claude/skills/knowledge   # remove stale misplaced copy from older installs
     ```
     On Windows, if knowledge was **copied** rather than symlinked, re-copy it now:
     `Copy-Item -Recurse -Force "<bait_path>/knowledge" "$HOME/.claude/knowledge"`.
4. If the field glossary source (the XSD) or `scripts/distill_xsd.R` changed, offer to
   regenerate `knowledge/field-glossary.md`:
   ```bash
   Rscript "<bait_path>/scripts/distill_xsd.R" \
     "https://www.imr.no/formats/nmdbiotic/v3/nmdbioticv3.xsd" \
     "<bait_path>/knowledge/field-glossary.md"
   ```
5. Tell the user what changed (`git -C "<bait_path>" log --oneline -5`).

## 2. Update the Biotic database (fresh data)

The IMR source has no change timestamps, so a database update = a **full re-download**.
Requires the **IMR intranet** (VPN / HI-Adm). Hand off to
[`../biotic-server-setup/SKILL.md`](../biotic-server-setup/SKILL.md) → "Update the database":
it **first checks that BioticExplorerServer itself is up to date on GitHub** (Step 1), then
builds alongside the current database, monitors the background job with a log, and swaps the
new file in on success (so a failed download never destroys the working database).

## Notes

- Updating skills here keeps BAIT working **across all projects** without re-cloning anywhere.
- Keep `~/.bait/config.json` accurate if paths changed.
