---
name: quarto-reporting
description: Compatibility pointer for the shared Quarto reporting skill, now maintained in wise-writing.
metadata:
  version: "0.1.0"
  forwarding: true
license: MIT
---

<!-- pack-resources:start -->
**Pack resources:** the `BAIT` root is `~/.bait/config.json` → `bait_path`, else `~/.fiskwise/config.json` →
`components.BAIT.path`, else the checkout containing this skill. Paths such as `knowledge/`
and `project-template/` are relative to that root, never `../../` from a skills folder; resolve
links that leave this skill's folder against the source skill there. Use absolute paths.
<!-- pack-resources:end -->


# Forwarded skill

The maintained `quarto-reporting` implementation, including its references, script, and
reporting asset, is part of
[wise-writing](https://github.com/DeepWaterIMR/wise-writing/tree/main/skills/quarto-reporting).
Use that skill for reproducible Quarto reports. If it is not already installed, read
`academic_writing_path` from `~/.wise-writing/config.json` (falling back to
`~/.academic-writing/config.json`) and open `<academic_writing_path>/skills/quarto-reporting/SKILL.md`.

This file remains at its former BAIT path for compatibility; it is not a second implementation.
