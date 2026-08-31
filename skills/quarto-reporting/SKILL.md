---
name: quarto-reporting
description: >-
  Build or revise reproducible Quarto analyses and reports in HTML, Word, or PDF,
  including executable narrative, local data snapshots, Word reference documents, and
  rendered-output QA. Use for .qmd analyses, technical reports, or multi-format Quarto
  deliverables; not for a standalone R script with no document output.
---

# Build reproducible Quarto outputs

Treat the `.qmd` source as the authoritative executable document. Keep the workflow
generic: project or organisation templates may be supplied by the user. The bundled IMR
web-report template is an opt-in alternative, not the default for unrelated work.

## Choose the output mode

- For an exploratory or inspectable HTML analysis, read
  [`references/html-analysis.md`](references/html-analysis.md).
- For a formal Word or PDF report, read
  [`references/formal-reports.md`](references/formal-reports.md).
- If the user explicitly requests an IMR web report, `nettrapport`, or the bundled IMR
  Word design, also read
  [`references/imr-nettrapport.md`](references/imr-nettrapport.md).
- Read both references when the same source must produce both kinds of output.
- When adding or changing package-loading code, also use
  [`../r-package-setup/SKILL.md`](../r-package-setup/SKILL.md).
- When the source contains Biotic data, also apply the relevant `biotic-*` skills and
  BAIT privacy rules.

The Word Manuscript fallback uses
[`scripts/build_manuscript_reference.py`](scripts/build_manuscript_reference.py) to retain
Pandoc's required styles while applying the locally installed Word design.

## Shared workflow

1. Establish the document's purpose, audience, requested formats, data inputs, and
   scientific or technical decisions that remain unresolved. Inspect before making
   substantial analytical changes.
2. Preserve project instructions and unrelated working-tree changes. Treat source data
   as read-only unless the user explicitly requests a data update.
3. Separate extraction or refresh from rendering. Prefer validated, local, versioned or
   deliberately ignored snapshots so an ordinary render is deterministic and can run
   offline. Do not make the `.qmd` silently refresh remote data.
4. Calculate reported values once, before the prose that uses them. Use inline code for
   data-derived values and Quarto cross-references for figures, tables, sections, and
   citations so narrative and outputs cannot drift apart.
5. Keep reusable transformations and graphics in helper files. Put survey-, client-, or
   report-specific settings in a small configuration layer rather than hard-coding them
   throughout the document.
6. Validate the analysis contract before polishing prose: identifiers, joins, sampling
   units, aggregation, missing values, units, inclusion rules, and consistency among
   equations, tables, figures, captions, and narrative.
7. Run focused tests, render from the documented project root, classify every warning,
   and inspect the rendered deliverable. A successful command alone is not proof that the
   report is complete or visually correct.

## Delivery contract

Report which formats were rendered, which tests and visual checks passed, whether the
render used refreshed data or existing snapshots, and any unresolved analytical or
template limitations. Do not expose confidential raw data through embedded tables,
coordinates, logs, or committed outputs.
