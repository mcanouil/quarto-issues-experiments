--- @module repeat-heading
--- @license MIT
--- @copyright 2026 Mickaël Canouil
--- @author Mickaël Canouil
--- @description Repeat the last slide-level heading on slides created with
---   horizontal rules (`---`). In reveal.js presentations, a `---` separator
---   creates a new slide without a heading. This filter replaces each
---   `HorizontalRule` with a clone of the most recent level-2 header, so
---   every slide carries the parent heading.

--- Track the most recent slide-level (level 2) header.
--- @type pandoc.Header|nil
local last_slide_header = nil

--- Replace `HorizontalRule` blocks with a clone of the last slide header.
--- @param blocks pandoc.Blocks
--- @return pandoc.Blocks
function Blocks(blocks)
  local new_blocks = pandoc.Blocks({})
  for _, block in ipairs(blocks) do
    if block.t == "Header" and block.level == 2 then
      last_slide_header = block
      new_blocks:insert(block)
    elseif block.t == "HorizontalRule" and last_slide_header then
      new_blocks:insert(last_slide_header:clone())
    else
      new_blocks:insert(block)
    end
  end
  return new_blocks
end
