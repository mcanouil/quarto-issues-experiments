--- @module repeat-heading
--- @license MIT
--- @copyright 2026 Mickaël Canouil
--- @author Mickaël Canouil
--- @description Repeat top-level headings on slides created with horizontal
---   rules (`---`). In reveal.js presentations, a `---` separator creates a
---   new slide without a heading. This filter replaces each `HorizontalRule`
---   with clones of the heading chain from the most recent slide.
---
---   When `---` is followed by a heading, only parent headings above that
---   level are repeated. When followed by non-heading content, the entire
---   heading chain is repeated.
---
---   Accounts for `shift-heading-level-by` by detecting the actual slide-level
---   heading in the pre-shift AST.

--- Detect the pre-shift heading level that corresponds to the slide level.
--- With `shift-heading-level-by`, Pandoc shifts heading levels AFTER filters,
--- so the AST still has the original (pre-shift) levels.
--- @param blocks pandoc.Blocks
--- @return integer
local function detect_slide_level(blocks)
  local slide_level = 2
  if PANDOC_WRITER_OPTIONS and PANDOC_WRITER_OPTIONS.slide_level then
    slide_level = PANDOC_WRITER_OPTIONS.slide_level
  end
  local min_level = nil
  for _, block in ipairs(blocks) do
    if block.t == "Header" then
      if not min_level or block.level < min_level then
        min_level = block.level
      end
    end
  end
  if not min_level then
    return slide_level
  end
  if min_level >= slide_level then
    return min_level + 1
  end
  return slide_level
end

--- Process the full document: detect the effective slide level, then
--- replace each `HorizontalRule` with clones of the heading chain
--- from the most recent slide.
--- @param doc pandoc.Pandoc
--- @return pandoc.Pandoc
function Pandoc(doc)
  local slide_level = detect_slide_level(doc.blocks)
  local chain = {}
  local at_slide_start = false
  local new_blocks = pandoc.Blocks({})

  for i, block in ipairs(doc.blocks) do
    if block.t == "Header" and block.level == slide_level then
      chain = { block }
      at_slide_start = true
      new_blocks:insert(block)
    elseif at_slide_start and block.t == "Header" then
      table.insert(chain, block)
      new_blocks:insert(block)
    elseif block.t == "HorizontalRule" and #chain > 0 then
      local next_block = doc.blocks[i + 1]
      local next_is_header = next_block and next_block.t == "Header"
      local new_chain = {}
      for _, h in ipairs(chain) do
        if not next_is_header or h.level < next_block.level then
          local clone = h:clone()
          clone.identifier = ""
          new_blocks:insert(clone)
          table.insert(new_chain, clone)
        end
      end
      chain = new_chain
      at_slide_start = true
    else
      at_slide_start = false
      new_blocks:insert(block)
    end
  end

  doc.blocks = new_blocks
  return doc
end
