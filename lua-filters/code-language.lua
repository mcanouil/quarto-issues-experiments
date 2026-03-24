--- @module code-language
--- @license MIT
--- @copyright 2026 Mickaël Canouil
--- @author Mickaël Canouil
--- @brief Normalise code blocks with no language class or an unknown language class to "default".

local known_language_cache = {}

--- Check if a language is recognised by Pandoc's syntax highlighter.
--- Renders a test CodeBlock to HTML and checks for the sourceCode class.
--- @param lang string Language identifier
--- @return boolean
local function is_known_language(lang)
  if not lang or lang == '' then
    return false
  end

  if known_language_cache[lang] ~= nil then
    return known_language_cache[lang]
  end

  local test_block = pandoc.CodeBlock('x', pandoc.Attr('', { lang }))
  local html = pandoc.write(pandoc.Pandoc({ test_block }), 'html')
  local is_known = html:find('sourceCode') ~= nil
  known_language_cache[lang] = is_known
  return is_known
end

--- Assign "default" class to code blocks with no language.
--- Sets a marker attribute to suppress auto-filename downstream.
--- Normalise unknown languages to "default", preserving the original
--- name as an explicit filename when one is not already set.
--- @param block pandoc.CodeBlock
--- @return pandoc.CodeBlock
function CodeBlock(block)
  if not block.classes or #block.classes == 0 then
    block.classes:insert('default')
    return block
  end

  local lang = block.classes[1]
  if not is_known_language(lang) then
    block.classes[1] = 'default'
  end

  return block
end
