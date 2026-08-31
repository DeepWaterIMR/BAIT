# IMR web-report Word design

Use this optional path only when the user explicitly requests an IMR web report,
`nettrapport`, or the bundled IMR Word design. Keep all other Word-report work on the
generic template-selection path in `formal-reports.md`.

## Template

BAIT includes the current IMR web-report reference document at
`assets/nettrapport_template.docx`. Resolve that path from the `quarto-reporting` skill
directory. Prefer copying the asset into a documented project location such as `src/`
and referring to that project-local copy so the `.qmd` remains portable:

```yaml
format:
  docx:
    reference-doc: src/nettrapport_template.docx
    fig-dpi: 300
    number-sections: false
```

Do not replace a newer template supplied by the user. Record which template file was used
and visually compare the rendered report with it.

## What `reference-doc` preserves

Pandoc uses the reference document's styles, theme, page properties, headers, footers,
numbering definitions, and related document parts. It does not reuse the reference
document's body. Consequently, using `nettrapport_template.docx` directly provides the
IMR typography and much of the page design, but does not by itself reproduce body-anchored
cover artwork, closing-page content, or every section transition.

Use the direct `reference-doc` workflow when style fidelity is sufficient. If the user
requires the complete IMR cover and closing-page design, add a small project-local
postprocessor after Quarto rendering. Its responsibilities may include restoring anchored
artwork, reconciling first-page and body sections, and preserving template relationships
and media. Keep report-specific headings, landscape sections, data refreshes, and other
project rules outside this generic skill.

Leave Quarto `number-sections` off unless the template numbering has been deliberately
removed or a postprocessor replaces it. The bundled template applies Word list numbering
to heading styles; enabling both systems produces duplicate section numbers.

## Tables

Create report tables explicitly in the `.qmd` with `flextable`; ordinary Markdown pipe
tables do not lay out reliably with this template. Set header styling, alignment, widths,
and table layout in the source. A postprocessor may repair OOXML wrappers, grids, or
widths only when rendered-page inspection demonstrates that this is necessary; it should
not be the primary definition of a table's meaning or appearance.

## Validation

Render the final DOCX to page images or PDF and inspect every page. In addition to the
general Word checks, verify the cover, logo and artwork placement, first/body page
transitions, heading numbering, table widths, landscape sections, headers, footers, and
closing page. Report clearly whether the output uses only the template as a reference
document or also uses a project-specific postprocessor.
