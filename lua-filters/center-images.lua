--- center-images - Filter
--- @module center-images.lua
--- @license MIT
--- @copyright 2026 Mickaël Canouil
--- @author Mickaël Canouil
--- @version 0.1.0
--- @description Align standalone images in Typst output using the `img-align`
--- attribute or metadata field. Must run at `post-quarto`.

local meta = {}

--- Get alignment value from image attributes or document metadata.
local function get_align(img)
  local align = img.attributes["img-align"]
  if align ~= nil then
    return align
  end
  local meta_align = meta["img-align"]
  if meta_align ~= nil then
    return pandoc.utils.stringify(meta_align)
  end
  return "center"
end

--- Check if a Para block contains a single image (with optional soft breaks).
local function get_sole_image(para)
  local img = nil
  for _, inline in ipairs(para.content) do
    if inline.t == "Image" then
      if img ~= nil then
        return nil
      end
      img = inline
    elseif inline.t ~= "SoftBreak" and inline.t ~= "Space" then
      return nil
    end
  end
  return img
end

--- Wrap standalone images in Typst alignment blocks.
local function process_para(para)
  if not quarto.doc.is_format("typst") then
    return nil
  end
  local img = get_sole_image(para)
  if img == nil then
    return nil
  end
  local align = get_align(img)
  local raw_open = pandoc.RawInline("typst", "#align(" .. align .. ")[")
  local raw_close = pandoc.RawInline("typst", "]")
  return pandoc.Para({ raw_open, img, raw_close })
end

return {
  {
    Meta = function(m)
      meta = m
    end,
  },
  {
    Para = process_para,
  },
}
