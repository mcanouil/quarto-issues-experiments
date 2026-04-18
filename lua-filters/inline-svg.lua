--- Inline SVG - Lua Filter
--- @module "inline-svg"
--- @license MIT
--- @copyright 2026 Mickaël Canouil
--- @author Mickaël Canouil
--- @version 0.1.0
--- @brief Inline SVG images into HTML output as raw markup.
--- @description For HTML output, replaces `Image` elements pointing to
--- `.svg` files with the raw SVG content inlined into the document.
--- Inlining allows the SVG to inherit CSS from the host document and
--- be styled, selected, or scripted like any other DOM content, which
--- is not possible when the SVG is referenced via an `<img>` tag.

-- ============================================================================
-- HELPER FUNCTIONS (PRIVATE)
-- ============================================================================

--- Read the full contents of a file from disk.
--- @param path string Filesystem path to the file
--- @return string|nil The file contents, or nil if the file cannot be opened
local function read_file(path)
  local f = io.open(path, "r")
  if not f then
    return nil
  end
  local content = f:read("*all")
  f:close()
  return content
end

--- Strip the XML declaration from an SVG string.
--- An inlined `<?xml ... ?>` prolog is invalid inside HTML and must be
--- removed before embedding the SVG in the document body.
--- @param svg string The raw SVG markup
--- @return string The SVG markup without any XML declaration
local function strip_xml_declaration(svg)
  return (svg:gsub("<%?xml[^?]*%?>%s*", ""))
end

-- ============================================================================
-- FILTER EXPORT
-- ============================================================================

--- Inline SVG images into HTML output.
--- Only runs for HTML formats and for `Image` elements whose source ends
--- in `.svg`. Non-HTML formats and non-SVG images are left untouched so
--- Quarto's default image handling still applies.
--- @param el pandoc.Image The image element being processed
--- @return pandoc.RawInline|nil Raw HTML with the inlined SVG, or nil to keep the original image
function Image(el)
  if not el.src:match("%.svg$") then
    return nil
  end

  if not quarto.doc.is_format("html") then
    return nil
  end

  local svg = read_file(el.src)
  if not svg then
    return nil
  end

  return pandoc.RawInline("html", strip_xml_declaration(svg))
end
