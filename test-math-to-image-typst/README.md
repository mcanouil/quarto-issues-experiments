# Math to Image Lua Filter

A Quarto Lua filter that converts LaTeX mathematics to images using Typst rendering engine.

## Overview

This filter processes mathematical expressions in Quarto documents and renders them as PNG or SVG images using `quarto typst`.
It allows you to convert all math, only display math, or only inline math to images, whilst providing fine-grained control over image format and quality.

## Features

- **Dual image formats**: Render to PNG (raster) or SVG (scalable vector graphics).
- **Flexible conversion modes**: Convert all math, only display math, or only inline math.
- **Quality control**: Adjustable DPI for PNG output (default 300).
- **Smart caching**: Identical math expressions are rendered only once using content-based hashing.
- **Portable output**: Optional mediabag embedding for self-contained documents.
- **Cross-format compatibility**: Works with all Quarto output formats (HTML, PDF, Word, etc.).
- **Error resilience**: Gracefully falls back to original math if rendering fails.
- **Label preservation**: Math expressions with cross-reference labels are preserved as-is.

## Installation

Copy `math-to-image.lua` to your Quarto project directory.

## Usage

### Basic Usage

Add the filter to your Quarto document YAML metadata:

```yaml
---
title: My Document
filters:
  - math-to-image.lua
---
```

By default, this will convert all display math (`$$...$$`) to PNG images at 300 DPI.

### Configuration Options

Control filter behaviour via document metadata:

```yaml
---
title: My Document
filters:
  - math-to-image.lua

# Image format: 'png' or 'svg' (default: 'png')
math-format: png

# Conversion mode: 'display', 'inline', or 'full' (default: 'display')
math-convert: display

# PNG resolution in DPI (default: 300, only used for PNG)
math-dpi: 300

# Embed images in mediabag for portability (default: true)
math-embed: true
---
```

### Examples

**Convert all math (inline and display) to SVG:**

```yaml
math-format: svg
math-convert: full
```

**Convert only inline math to high-quality PNG:**

```yaml
math-format: png
math-convert: inline
math-dpi: 600
```

**Convert display math to PNG without mediabag embedding:**

```yaml
math-format: png
math-convert: display
math-embed: false
```

## How It Works

1. **Metadata parsing**: Reads configuration options from document YAML.
2. **AST traversal**: Walks the Pandoc AST to find Math elements.
3. **Filtering**: Checks each Math element against the conversion mode (display/inline/full).
4. **Content hashing**: Generates a unique filename based on math content for caching.
5. **Typst rendering**: Creates temporary Typst files and uses `quarto typst compile` to render.
6. **Image replacement**: Replaces Math elements with Image elements in the AST.
7. **Mediabag embedding**: Optionally embeds images for portable output.
8. **Cleanup**: Removes temporary Typst files after rendering.

## Output

Generated images are stored in the `_math_images/` directory using deterministic filenames:

```
_math_images/
├── math-a1b2c3d4-display.png    # Display math, PNG format
├── math-e5f6g7h8-inline.svg     # Inline math, SVG format
└── math-i9j0k1l2-display.svg    # Display math, SVG format
```

These images are cached—identical math expressions across multiple documents won't be re-rendered.

## Limitations

- **No macro support**: Custom LaTeX macros defined in the document are not supported. Only standard LaTeX math syntax works.
- **Cross-references**: Math expressions with `\label{}` commands are preserved as-is to maintain reference capability. Convert them manually if needed.
- **Empty math**: Empty math expressions are skipped.

## Performance Considerations

- **First run**: Initial rendering of all math will take time based on the number of unique expressions.
- **Subsequent runs**: Cached images are reused, significantly speeding up re-renders.
- **SVG vs PNG**: SVG rendering may be slightly faster than PNG, but both are generally quick.
- **DPI impact**: Higher DPI values (e.g. 600) produce higher-quality PNG images but increase file size.

## Error Handling

The filter gracefully handles errors:

- **Rendering failures**: If Typst rendering fails, the original Math element is preserved and a warning is logged.
- **File system errors**: Directory creation or file writing failures are caught and logged.
- **Invalid options**: Invalid configuration values trigger warnings and fall back to defaults.

## Requirements

- Quarto CLI with Typst support.
- Pandoc (provided by Quarto).
- Lua 5.3 (provided by Quarto).
- Access to `quarto typst compile` command.

## License

MIT License. See [LICENSE](LICENSE) for details.
