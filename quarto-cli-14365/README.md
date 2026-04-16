# quarto-cli-14365

Quarto book project using [project profiles](https://quarto.org/docs/projects/profiles.html) to produce different outputs from the same source.

## Profiles

The `online` and `print` profiles are mutually exclusive.
When no profile is specified, `online` is used as the default.

- **online**: HTML output with all chapters and appendices.
  Includes a "Download PDF" sidebar button linking to the print output.
  Because profiles are rendered independently, Quarto cannot auto-detect
  the PDF; the link is configured explicitly via `book.sidebar.tools` in
  `_quarto-online.yml`.
- **print**: PDF (LaTeX) output with a reduced set of chapters and one appendix.
  Cross-page links are rewritten to absolute URLs via the `offpage-crosslinks.lua` filter.

## Rendering

Render both profiles (print first so the PDF exists for the HTML download link):

```bash
quarto render --profile print
quarto render --profile online --no-clean
```

The `--no-clean` flag is required when rendering one profile at a time, otherwise
the output from the previous profile is deleted before the next render starts.

Alternatively, render a single profile:

```bash
quarto render --profile online
```

```bash
quarto render --profile print
```
