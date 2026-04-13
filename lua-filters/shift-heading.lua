--- Shift Heading - Filter
--- @module shift-heading
--- @license MIT
--- @copyright 2026 Mickaël Canouil
--- @author Mickaël Canouil
--- @version 0.0.0
--- @brief Shift an individual heading level and optionally its child headings.
--- @description
---   Reads two attributes on Header elements:
---
---   - `revealjs-heading-offset` (integer, required): amount to add to the
---     heading level.
---     Positive values push the heading deeper; negative values pull it up.
---     The result is clamped to [1, 6].
---
---   - `revealjs-heading-depth` (non-negative integer, optional, default 0):
---     how many levels of immediately following child headings also receive
---     the same offset.
---     `0` means only the heading carrying the attribute is shifted.
---     `1` shifts the heading and every directly nested child (one level
---     deeper).
---     Cascading stops as soon as a heading at or above the base level is
---     encountered.
---
---   Both attributes are stripped from the output.
---
---   Intended for reveal.js presentations where the global
---   `shift-heading-level-by` format option shifts all headings but
---   individual headings occasionally need an independent adjustment.
---
---   Usage:
---     ## Section {revealjs-heading-offset="1"}
---       Produces a level-3 heading; child headings are unaffected.
---
---     ## Section {revealjs-heading-offset="1" revealjs-heading-depth="1"}
---       Produces a level-3 heading; directly nested headings (### ...) also
---       shift by 1; deeper headings (#### ...) are not shifted.

--- Process all blocks in sequence to support depth-based cascading.
--- @param doc pandoc.Pandoc The full document.
--- @return pandoc.Pandoc The document with heading levels adjusted.
local function process_pandoc(doc)
  local active_shift      = nil
  local active_base_level = nil
  local active_max_depth  = nil

  local new_blocks = pandoc.Blocks({})

  for _, block in ipairs(doc.blocks) do
    if block.t == 'Header' then
      local raw_offset = block.attributes['revealjs-heading-offset']

      if raw_offset then
        local shift = tonumber(raw_offset)
        if shift then
          shift = math.floor(shift)
          local raw_depth = block.attributes['revealjs-heading-depth']
          local depth     = math.floor(math.max(0, tonumber(raw_depth) or 0))
          local orig_level = block.level

          block.level = math.max(1, math.min(6, orig_level + shift))
          block.attributes['revealjs-heading-offset'] = nil
          block.attributes['revealjs-heading-depth']  = nil

          if depth > 0 then
            active_shift      = shift
            active_base_level = orig_level
            active_max_depth  = depth
          else
            active_shift      = nil
            active_base_level = nil
            active_max_depth  = nil
          end
        end
      elseif active_shift then
        if block.level <= active_base_level then
          -- Sibling or ancestor: stop cascading.
          active_shift      = nil
          active_base_level = nil
          active_max_depth  = nil
        elseif block.level - active_base_level <= active_max_depth then
          -- Child within depth: apply offset.
          block.level = math.max(1, math.min(6, block.level + active_shift))
        end
        -- Child beyond max_depth: leave unchanged, keep cascade active.
      end
    end

    new_blocks:insert(block)
  end

  doc.blocks = new_blocks
  return doc
end

return {
  { Pandoc = process_pandoc }
}
