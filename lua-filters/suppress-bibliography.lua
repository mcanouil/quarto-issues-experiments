--- @module "suppress-bibliography"
--- @license MIT
--- @copyright 2026 Mickaël Canouil
--- @author Mickaël Canouil
--- @description Suppress the bibliography output in Typst documents while
---   keeping citation references functional. When `suppress-bibliography` is
---   set to `true` in the document metadata, a Typst show rule is injected
---   before the body to hide the bibliography block.

--- Inject a Typst show rule to hide the bibliography when requested.
--- Skips injection when `citeproc` is `true` or the format is not Typst.
--- @param meta pandoc.Meta
--- @return pandoc.Meta|nil
function Meta(meta)
  if not quarto.doc.is_format("typst") then
    return nil
  end
  if meta["suppress-bibliography"] ~= true then
    return nil
  end
  if meta["citeproc"] == true then
    return nil
  end
  quarto.doc.include_text("before-body", "#show bibliography: none")
  return nil
end
