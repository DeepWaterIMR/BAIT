# HTML analysis

Use HTML when the deliverable is an inspectable analysis rather than a fixed-layout
publication. Decide whether readers should see code, whether the file must work offline,
and whether the output may contain confidential derived results before choosing options.

## Recommended shape

For a portable analysis, start from settings like these and adjust them to the project:

```yaml
format:
  html:
    self-contained: true
    toc: true
    toc-depth: 3
    number-sections: true
    code-fold: true
    code-summary: "Show code"
execute-dir: project
execute:
  warning: false
  message: false
  cache: false
  freeze: false
```

- Use `self-contained: true` when one offline file is more important than file size. For
  very large or widget-heavy analyses, keep an asset directory and deliver it with the
  HTML instead.
- Use code folding when reproducibility matters but code should not interrupt reading.
  Hide code only when the intended audience does not need it.
- Set `execute-dir` deliberately and render from the documented root. Avoid path-discovery
  workarounds when a stable project-root convention is available.
- Enable caching or freezing only as an explicit performance decision. Document how to
  invalidate stale results and do not let cached output conceal changed source data.
- Keep confidential HTML ignored and local. Self-contained does not mean safe to share.

## Validation

Before rendering, run focused tests or source changed helpers in a clean session. After
rendering:

1. Confirm that the HTML exists, is non-empty, and was produced by the current render.
2. Check for unresolved cross-references, missing figures, execution errors, and unexpected
   external assets when a self-contained file was requested.
3. Inspect headings and navigation, code-fold controls, captions, tables, legends, units,
   citations, and representative small- and large-screen layouts.
4. Reconcile every displayed result and substantive narrative claim with the executed code
   or a cited source.

If browser policy prevents opening a local file, perform structural checks and inspect the
generated figures separately, but disclose that interactive visual QA was incomplete.
