--- @module code-language
--- @license MIT
--- @copyright 2026 Mickaël Canouil
--- @author Mickaël Canouil
--- @brief Normalise code blocks with no language class.

--- Assign "default" class to code blocks with no language.
--- Sets a marker attribute to suppress auto-filename downstream.
--- @param block pandoc.CodeBlock
--- @return pandoc.CodeBlock
function CodeBlock(block)
  if not block.classes or #block.classes == 0 then
    block.classes:insert('default')
    block.attributes['code-window-no-auto-filename'] = 'true'
  end
  return block
end
