---
name: quarto-reporting
description: Compatibility pointer for the shared Quarto reporting skill, now maintained in wise-writing.
metadata:
  version: "0.1.0"
  forwarding: true
license: MIT
---

<!-- pack-resources:start -->
**Pack resources:** resolve `BAIT` from `~/.bait/config.json` → `bait_path` (or
`~/.fiskwise/config.json` → `components.BAIT.path`). If neither exists, use the
checkout containing this skill, or locate/obtain the pack through its install instructions.
Paths such as `knowledge/`, `cookbook/`, `config/` and `project-template/` belong to that
repository, not the current research directory. For a copied skill, resolve a link that
leaves this skill's directory against the corresponding source skill under that root;
keep bundled `references/` links relative to the skill. Never assume `../../` from an
agent's global skills folder reaches the repository. Use absolute resolved script paths.
<!-- pack-resources:end -->


# Forwarded skill

The maintained `quarto-reporting` implementation, including its references, script, and
reporting asset, is part of
[wise-writing](https://github.com/DeepWaterIMR/wise-writing/tree/main/skills/quarto-reporting).
Use that skill for reproducible Quarto reports. If it is not already installed, read
`academic_writing_path` from `~/.wise-writing/config.json` (falling back to
`~/.academic-writing/config.json`) and open `<academic_writing_path>/skills/quarto-reporting/SKILL.md`.

This file remains at its former BAIT path for compatibility; it is not a second implementation.
