# `resolve_path` returns a different directory inside a loaded file

Reported as <https://github.com/quarto-dev/q2/issues/588>.

An extension calls `quarto.utils.resolve_path("_modules/greet.lua")` from three
places: the top-level script, a file loaded with `require`, and the same file
loaded with `dofile`.

Quarto 1 returns the same path from all three.
q2 returns a doubled path from the `require` case.

## Contents

| Path | Purpose |
| --- | --- |
| `_extensions/rp/_modules/greet.lua` | The target file. It only has to exist. |
| `_extensions/rp/_modules/probe.lua` | Calls `resolve_path` at load time and returns the result. |
| `_extensions/rp/rp.lua` | Top-level shortcode. Calls `resolve_path`, then loads `probe.lua` with `require` and with `dofile`. |
| `index.qmd` | Runs all three cases in one render. |

The extension contributes a shortcode, not a filter, because a q2 filter cannot
`require` at all.
See <https://github.com/quarto-dev/q2/issues/587>.

## How to run

```bash
quarto render index.qmd --to html
q2 render index.qmd --to html
```

The three results are written into the output document.

## Results

Tested with `quarto` 99.9.9 (local build) and `q2` 0.26.0.

```text
### quarto
    top-level  : .../_extensions/rp/_modules/greet.lua  exists
    via-require: .../_extensions/rp/_modules/greet.lua  exists
    via-dofile : .../_extensions/rp/_modules/greet.lua  exists
### q2
    top-level  : /work/_extensions/rp/_modules/greet.lua            exists
    via-require: /work/_extensions/rp/_modules/_modules/greet.lua   MISSING
    via-dofile : /work/_extensions/rp/_modules/greet.lua            exists
```

The `dofile` row is the control.
It shows that the difference comes from `require`, not from `resolve_path`.

## Cause

`resolve_path` joins its argument onto the top of the script-dir stack.

`register_scoped_require` pushes the loaded file's own directory onto that
stack while the file executes, so `resolve_path` inside the file resolves
against the file's directory instead of the extension root.

Quarto 1 never changes the script directory when it loads a file, so the
extension root stays in effect.

## Prior decision

q2 already settled this contract for `dofile` in
<https://github.com/quarto-dev/q2/issues/112>, and removed the push and pop.
The comment at the top of `crates/pampa/src/lua/dofile_wasm.rs` still records
it: the overrides handle file input and output only, and do not modify the
script-dir stack.

`register_scoped_require` was added later, in commit `6ff4221e` (#450), and
pushes the stack again.

## Notes on the environment

`q2` here is the Docker wrapper.
The current directory is bind-mounted at `/work`, so the paths that Lua sees
under `q2` start with `/work`.
The image is `quarto-dev/q2:0.26.0`.
The `q2` clone used for the code references is at `v0.26.0-23-g328e176f`.
