--- Strip Mermaid Braces - Filter
--- @module "strip-mermaid-braces"opy 
--- @license MIT
--- @copyright 2026 Mickaël Canouil
--- @author Mickaël Canouil
--- @version 0.1.0
--- @brief Rewrite executable Mermaid cells as plain Mermaid fences for GFM output.
--- @description Quarto Lua filter that converts executable Mermaid code cells
--- (```{mermaid}) into plain Mermaid fenced code blocks (```mermaid) when the
--- output format is a GFM or CommonMark variant, so GitHub renders the
--- diagrams natively.

--- Test whether the current Quarto output format is a GFM/CommonMark variant.
--- @return boolean true when the format is gfm, commonmark, or markdown_strict
local function is_gfm_variant()
  return quarto.doc.is_format('gfm')
      or quarto.doc.is_format('commonmark')
      or quarto.doc.is_format('markdown_strict')
end

--- Rewrite ```{mermaid} cells as plain ```mermaid fences for GFM-like formats.
--- @param el pandoc.CodeBlock the code block to inspect
--- @return pandoc.RawBlock|nil a RawBlock with the rewritten fence, or nil
local function CodeBlock(el)
  if not is_gfm_variant() then return nil end
  if not el.classes:includes('mermaid') then return nil end
  return pandoc.RawBlock('markdown', '```mermaid\n' .. el.text .. '\n```')
end

return {
  { CodeBlock = CodeBlock }
}
