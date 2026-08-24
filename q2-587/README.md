# `require` works in q2 shortcodes but not in q2 filters

Reported as <https://github.com/quarto-dev/q2/issues/587>.

One extension contributes a filter and a shortcode.
Both run the same line:

```lua
local mod = require("_modules/greet")
```

`quarto render` loads the module on both paths.
`q2 render` loads it in the shortcode and fails in the filter.

## Contents

| Path                                          | Purpose                                                                         |
| --------------------------------------------- | ------------------------------------------------------------------------------- |
| `_extensions/parity/_modules/greet.lua`       | The module. It returns one function.                                            |
| `_extensions/parity/parity-filter.lua`        | Filter. The `require` is wrapped in `pcall` so the render survives and reports. |
| `_extensions/parity/parity-shortcode.lua`     | Shortcode. Same code, same wrapper.                                             |
| `_extensions/parity/parity-filter-strict.lua` | Filter with an unguarded `require`, to show the raw error.                      |
| `index.qmd`                                   | Runs both paths in one render.                                                  |
| `index-strict.qmd`                            | Runs the unguarded filter.                                                      |

## How to run

```bash
quarto render index.qmd --to html
q2 render index.qmd --to html
```

Both verdicts are written into the output document.

## Results

Tested with `quarto` 99.9.9 (local build) and `q2` 0.26.0.

```text
### quarto
    filter-require: OK greet-module-loaded
    shortcode-require: OK greet-module-loaded
### q2
    filter-require: FAIL
    shortcode-require: OK greet-module-loaded
```

The unguarded filter, `q2 render index-strict.qmd --to html`:

<!-- markdownlint-disable MD010 -- verbatim q2 output, tabs kept as emitted -->

```text
Error: Lua filter error: runtime error: [string "/work/_extensions/parity/parity-filter-strict..."]:6: module '_modules/greet' not found:
	no field package.preload['_modules/greet']
	no file '/usr/local/share/lua/5.4/_modules/greet.lua'
	no file '/usr/local/share/lua/5.4/_modules/greet/init.lua'
	no file '/usr/local/lib/lua/5.4/_modules/greet.lua'
	no file '/usr/local/lib/lua/5.4/_modules/greet/init.lua'
	no file './_modules/greet.lua'
	no file './_modules/greet/init.lua'

	can't load C modules in safe mode
```

<!-- markdownlint-enable MD010 -->

The searcher list in that error is the stock Lua one.
No Quarto entry appears in it.

## Cause

`q2` has a script-directory aware `require`, `register_scoped_require` in
`crates/pampa/src/lua/quarto_api.rs:206-306`.
It is registered in the shortcode environment only:

```rust
// crates/pampa/src/lua/shortcode.rs:115-118
// Script-dir-aware `require` so extension scripts can load sibling
// modules (Q1 parity).
super::quarto_api::register_scoped_require(&lua, runtime.clone())
    .map_err(LuaShortcodeError::LuaError)?;
```

`create_filter_environment` in `crates/pampa/src/lua/filter.rs:160-181` calls
`register_quarto_api`, `register_quarto_attribution`, `register_quarto_doc`,
and `push_script_dir`, but it never calls `register_scoped_require`.
A filter therefore runs with the stock Lua `require` and an untouched
`package.path`, and no module resolves.

The file layout is not the problem.
`q2` runs extension filters in place from `_extensions/<name>/`, so the module
sits next to the filter.
`quarto.utils.resolve_path` is not the problem either.
It returns the same correct absolute path under both engines.

## Fix

Call `register_scoped_require` from `create_filter_environment`, as
`shortcode.rs` does.
`runtime` must be cloned before it is moved into `register_pandoc_namespace`
on the preceding line.

## Notes on the environment

`q2` here is the Docker wrapper.
The current directory is bind-mounted at `/work`, so the paths that Lua sees
under `q2` start with `/work`.
The image is `quarto-dev/q2:0.26.0`.
The `q2` clone used for the code references is at `v0.26.0-23-g328e176f`.
`crates/pampa/src/lua/filter.rs`, `quarto_api.rs`, and `shortcode.rs` are
identical between the `v0.26.0` tag and that commit, so the defect is live on
`main`.
