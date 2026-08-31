# Formal Word and PDF reports

Use this mode for fixed-layout reports intended for submission, circulation, printing, or
an organisation's document system. Word and PDF are separate render targets; validate each
one rather than assuming that a correct source produces identical layouts.

## Word template selection

When Word output is requested:

1. If the user supplied a `.docx` or `.dotx` reference document, inspect it and use it as
   the design authority through Quarto's `reference-doc` option.
2. If the user explicitly requests an IMR web report, `nettrapport`, or the bundled IMR
   design, follow [`imr-nettrapport.md`](imr-nettrapport.md). Do not apply that design to
   unrelated reports merely because BAIT is being used.
3. Otherwise, if no template was supplied, ask once whether the user wants to provide an
   MS Word template. Continue without delay if they decline or do not have one.
4. With no user template, use Microsoft Word's generic **Manuscript** design when it is
   installed. Locate `Manuscript.dotx` within the local Microsoft Word or Office
   installation. On macOS its usual path is
   `/Applications/Microsoft Word.app/Contents/Resources/QuickStyles/Manuscript.dotx`.
   Search rather than assuming a path on other platforms.
5. Build a complete local reference document with:

   ```sh
   python scripts/build_manuscript_reference.py \
     --manuscript path/to/Manuscript.dotx \
     --out path/to/manuscript-reference.docx
   ```

   Use the generated `.docx` as `reference-doc`. Do not pass the style-set `.dotx`
   directly: it lacks some Pandoc-specific styles used for tables, captions, and code.
   Treat the generated reference document as local unless its licence permits
   redistribution.
6. If neither a user template nor the installed Manuscript design is available, use
   Pandoc's default Word reference document and tell the user that the Manuscript design
   could not be applied. Do not claim template fidelity that was not verified.

Do not copy proprietary or organisation-specific templates into a skill or repository
unless the owner explicitly authorises inclusion. A reference document controls
styles, theme, page properties, and some document parts; its body is not a reusable report
body. Exact covers, closing pages, headers, automatic numbering, or other organisation
features may require a small project-specific postprocessor after Quarto renders. Keep such
logic outside this generic skill and verify it against the supplied template.

## Quarto configuration

Specify only the formats requested. A typical multi-format declaration is:

```yaml
format:
  docx:
    reference-doc: path/to/reference.docx
    fig-dpi: 300
  pdf:
    pdf-engine: xelatex
    documentclass: article
    papersize: a4
    number-sections: true
```

Keep bibliography, CSL, PDF header/footer files, images, and reference documents in
documented project locations. Use Pandoc markup rather than fragile Unicode typography
when the same text must render in both Word and PDF.

Keep slow or network-dependent data refreshes in a separate script with an explicit
toggle. The normal compiler should render from validated local snapshots, allow the user
to select formats, and fail clearly rather than silently producing a partly refreshed
report.

## Validation

For every requested format:

1. Confirm that the output exists, is non-empty, and is newer than the render start time.
2. Inspect all pages, not only the first page. Check typography, headings and numbering,
   cross-references, citations, figures, table widths, page breaks, margins, headers,
   footers, and missing glyphs.
3. Render Word output to page images or PDF for visual QA. If a supplied template controls
   the design, compare the output with it and check any expected cover or closing pages.
4. Inspect the PDF independently, including the table of contents, links, fonts, equations,
   and final page.
5. Re-render after any template or OOXML post-processing. Treat visual inspection as the
   final shipping gate.

Network filesystems can report a cleanup error after writing a valid output. Classify the
error by checking the expected output's existence, size, and modification time; do not
ignore a failed render merely because an older output file exists.
