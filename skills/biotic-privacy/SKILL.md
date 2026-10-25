---
name: biotic-privacy
description: Classify Biotic data and outputs, handle restricted or sensitive subsets safely, and explain provider transmission, retention, and training settings. Use for privacy questions, setup, sensitive subsets, or sharing decisions; do not block ordinary work with open data.
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


# Handling Biotic data safely

Most Biotic data are open. Some subsets are restricted or sensitive, especially Russian-zone
and reference-fleet data, and exact positions of vulnerable species or habitats. Classify the
requested data and output under applicable IMR rules. If classification is unknown, keep the
material local until clarified.

BAIT is a knowledge pack, not a model trained on Biotic records. Local R/DuckDB execution
keeps database operations local; it does **not** guarantee that prompts, tool inputs, logs, or
outputs remain on-device or are excluded from provider processing, retention, or training.
Those behaviors depend on the provider, product, account, settings, and connected tools. A
training opt-out does not itself prevent transmission or retention. Do not put restricted
material into external services unless approved under IMR rules.

## Setup and provider controls

During setup, review the current privacy/data controls for the agent and account in use.
Disable model improvement/training where required, and separately check retention and tool
transmission behavior. Menus and terms change; consult current provider documentation. A
recorded `privacy_onboarded_at` indicates that setup review was completed at that time; it is
not proof of the current settings or a guarantee of local-only handling. Do not block normal
queries of open data for a repeated confirmation.

## Routine handling

- Keep the database outside repositories; never commit real individual records or precise
  coordinates. Examples use synthetic values.
- Open data can support routine useful analysis and sharing, subject to source/license rules.
- For restricted, sensitive, or unknown-classification material, minimize extracts and keep
  prompts, files, logs, and outputs local unless sharing is authorized. Derived outputs may
  still disclose sensitive information.
- For sensitive positions, aggregate or generalize only when that meets the intended purpose
  and applicable rules; ask before sharing when authorization is unclear.
- Run dashboards locally when they contain restricted data. Host only on approved IMR
  infrastructure with access controls.
- Deliberate colleague sharing should use approved IMR channels, not an agent or public
  internet service.

## If restricted material may have been exposed

Tell the user promptly, stop further sharing, and help follow applicable IMR incident
procedures. Deletion may not remove copies already transmitted to an external service.
