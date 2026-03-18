--- image-display-size - Filter
--- @module image-display-size.lua
--- @license MIT
--- @copyright 2026 Mickaël Canouil
--- @author Mickaël Canouil
--- @version 0.1.0
--- @description Move width/height attributes to the image inside a nested div of class "cell-output-display", if present.
---   The attributes are removed from the parent div after being transferred to the image.
---   The filter handles images that are either directly in the cell-output-display div
---   or wrapped in a Para element.

--- Move width/height attributes from cell div to image in cell-output-display.
---@param div table
---@return table|nil
function Div(div)
  if not div.classes:includes("cell") then
    return nil
  end

  local width = div.attributes["width"]
  local height = div.attributes["height"]

  if not (width or height) then
    return nil
  end

  local modified = false

  for i, el in ipairs(div.content) do
    if el.t == "Div" and el.classes:includes("cell-output-display") then
      div.content[i] = pandoc.walk_block(el, {
        Image = function(img)
          img.attributes["width"] = width
          img.attributes["height"] = height
          modified = true
          return img
        end
      })
    end
  end

  if modified then
    div.attributes["width"] = nil
    div.attributes["height"] = nil
  end

  return div
end
