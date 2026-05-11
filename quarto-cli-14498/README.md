# `include` shortcode ignores the project-absolute path (`/`) from a file inside an underscore directory

## Bug description

The `{{< include "/path" >}}` shortcode resolves a leading `/` against the project root for files in normal directories, but against the file's own directory when the including file lives inside an underscore-prefixed directory (such as `_lessons/`).

Files inside `**/_*/**` are excluded from the project input list, so rendering one of them directly returns no project context (`project-context.ts`), and the render falls back to single-file mode.
In single-file mode, the `include` directive's `resolvePath` (`src/core/handlers/base.ts`) uses the source file's directory as the root, so `/_exercises/exercise1.qmd` is resolved as `_lessons/_exercises/exercise1.qmd` instead of `_exercises/exercise1.qmd`.

## Project layout

- `_quarto.yml` (establishes the project root).
- `_exercises/exercise1.qmd` (the file being included).
- `articles/article1.qmd` includes `/_exercises/exercise1.qmd` and renders fine.
- `_lessons/lesson2.qmd` includes `/_exercises/exercise1.qmd` and fails.

## Reproduce

```bash
quarto render articles/article1.qmd --to markdown
# Output created: article1.md

quarto render _lessons/lesson2.qmd --to markdown
```

Expected output for the second command:

```text
ERROR: Include directive failed.
  in file .../quarto-cli-14498/_lessons/lesson2.qmd,
  could not find file .../quarto-cli-14498/_lessons/_exercises/exercise1.qmd.
```

## Expected behaviour

A leading `/` in an `include` path should always resolve against the project root, regardless of whether the including file sits inside an underscore-prefixed directory.

## Workaround

Use a relative path from the including file (`../_exercises/exercise1.qmd`) instead of a project-absolute path.

## Environment

- Reported on Quarto 1.9.37, Pandoc 3.8.3, Ubuntu 24.04.
- Reproduced against a local `quarto-cli` `src/` checkout (version `99.9.9`).
