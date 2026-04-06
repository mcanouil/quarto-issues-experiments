--- @module "mitex"
--- @license MIT
--- @copyright 2026 Mickaël Canouil
--- @author Mickaël Canouil
--- @description Convert LaTeX maths to Typst using the MiTeX package.
---   DisplayMath blocks become `#mimath(...)` and InlineMath becomes `#mi(...)`.
---   The `#import "@preview/mitex:0.2.6": *` statement is included once in the
---   document header when any maths are found.

--- Track whether any maths elements have been processed.
--- @type boolean
local has_math = false

--- Check whether a Para block contains a single DisplayMath element.
--- @param el pandoc.Para
--- @return boolean
local function is_display_math(el)
  return #el.content == 1 and el.content[1].t == "Math"
    and el.content[1].mathtype == "DisplayMath"
end

--- Replace a Para containing a single DisplayMath with a raw Typst MiTeX block.
--- @param el pandoc.Para
--- @return pandoc.RawBlock|nil
function Para(el)
  if not quarto.doc.is_format("typst") then
    return nil
  end
  if is_display_math(el) then
    has_math = true
    return pandoc.RawBlock("typst", "#mimath(`\n" .. el.content[1].text .. "\n`)")
  end
end

--- Replace inline maths with raw Typst MiTeX calls.
--- @param el pandoc.Math
--- @return pandoc.RawInline|nil
function Math(el)
  if not quarto.doc.is_format("typst") then
    return nil
  end
  if el.mathtype == "InlineMath" then
    has_math = true
    return pandoc.RawInline("typst", "#mi(`" .. el.text .. "`)")
  end
end

--- Include the MiTeX import once in the document header.
--- @param doc pandoc.Pandoc
function Pandoc(doc)
  if has_math then
    quarto.doc.include_text("in-header", '#import "@preview/mitex:0.2.6": *')
  end
end
