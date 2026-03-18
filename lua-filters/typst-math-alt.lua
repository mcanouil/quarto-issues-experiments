--- typst-math-alt - Filter
--- @module typst-math-alt.lua
--- @license MIT
--- @copyright 2026 Mickaël Canouil
--- @author Mickaël Canouil
--- @version 0.1.0
--- @brief Emit #math.equation(alt: ...) for Math elements wrapped in a
---   Span or Div that carries an alt attribute.
--- @description Quarto already generates math.equation(alt: ...) for
---   display equations with a cross-reference label, but equations that
---   only have {alt="..."} (no label) lose their alt text in Typst output.
---   This filter intercepts Span and Div elements with an alt attribute
---   that contain a Math element and emits explicit Typst raw content.

local function escape_typst_string(s)
  return s:gsub('\\', '\\\\'):gsub('"', '\\"')
end

local function math_to_typst(math_el)
  local doc = pandoc.Pandoc({ pandoc.Para({ math_el }) })
  local raw = pandoc.write(doc, "typst")
  return raw:match("^%s*(.-)%s*$")
end

function Span(el)
  if not quarto.doc.is_format("typst") then
    return nil
  end
  local alt = el.attributes["alt"]
  if alt == nil then
    return nil
  end

  local math_el = nil
  el:walk({
    Math = function(m)
      math_el = m
    end,
  })
  if math_el == nil then
    return nil
  end

  local typst_math = math_to_typst(math_el)
  local escaped_alt = escape_typst_string(alt)

  if math_el.mathtype == "DisplayMath" then
    return pandoc.RawBlock(
      "typst",
      '#math.equation(block: true, alt: "' .. escaped_alt .. '", [ ' .. typst_math .. " ])"
    )
  end
  return pandoc.RawInline(
    "typst",
    '#math.equation(alt: "' .. escaped_alt .. '", ' .. typst_math .. ")"
  )
end

function Div(el)
  if not quarto.doc.is_format("typst") then
    return nil
  end
  local alt = el.attributes["alt"]
  if alt == nil then
    return nil
  end

  local math_el = nil
  el:walk({
    Math = function(m)
      math_el = m
    end,
  })
  if math_el == nil then
    return nil
  end

  local typst_math = math_to_typst(math_el)
  local escaped_alt = escape_typst_string(alt)

  if math_el.mathtype == "DisplayMath" then
    return pandoc.RawBlock(
      "typst",
      '#math.equation(block: true, alt: "' .. escaped_alt .. '", [ ' .. typst_math .. " ])"
    )
  end
  return pandoc.RawInline(
    "typst",
    '#math.equation(alt: "' .. escaped_alt .. '", ' .. typst_math .. ")"
  )
end
