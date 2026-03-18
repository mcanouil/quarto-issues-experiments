--- subfig-ref - Filter
--- @module subfig-ref
--- @license MIT
--- @copyright 2026 Mickaël Canouil
--- @author Mickaël Canouil
--- @version 0.1.0
--- @brief Pandoc AST filter for subfig-ref.
--- @description Strip parent prefix from subfigure cross-references inside
---   their parent figure. At post-quarto, Quarto replaces Div IDs/classes with
---   __quarto_custom_* attributes. The Div handler is not called for these
---   custom elements, so the filter walks the AST manually via a Pandoc handler.

local function is_float_ref_target(el)
  return el.t == "Div" and el.attributes["__quarto_custom_type"] == "FloatRefTarget"
end

local function has_nested_float_ref(div)
  local found = false
  div:walk({
    Div = function(inner)
      if is_float_ref_target(inner) then
        found = true
      end
    end
  })
  return found
end

--- HTML: Link content is [Figure, NBSP, 1, Space, (, a, )].
--- Strip everything before the opening "(" Str.
local function strip_html_link_prefix(link)
  if not link.classes:includes("quarto-xref") then
    return nil
  end

  local paren_idx = nil
  for i, inline in ipairs(link.content) do
    if inline.t == "Str" and inline.text:match("^%(") then
      paren_idx = i
      break
    end
  end
  if paren_idx == nil then
    return nil
  end

  local new_content = pandoc.Inlines({})
  for i = paren_idx, #link.content do
    new_content:insert(link.content[i])
  end
  link.content = new_content
  return link
end

--- Typst: Reference is RawInline("#ref(<id>, supplement: [") + content + RawInline("])").
--- Replace the whole construct with RawInline("#subref(<id>)").
local function strip_typst_prefix(inlines)
  local new = pandoc.Inlines({})
  local i = 1
  local changed = false
  while i <= #inlines do
    local el = inlines[i]
    if el.t == "RawInline" and el.format == "typst" then
      local ref_id = el.text:match("^#ref%((<fig%-.->), supplement: %[$")
      if ref_id then
        local j = i + 1
        while j <= #inlines do
          if inlines[j].t == "RawInline" and inlines[j].format == "typst" and inlines[j].text:match("^%]%)$") then
            break
          end
          j = j + 1
        end
        if j <= #inlines then
          new:insert(pandoc.RawInline("typst", "#subref(" .. ref_id .. ")"))
          i = j + 1
          changed = true
        else
          new:insert(el)
          i = i + 1
        end
      else
        new:insert(el)
        i = i + 1
      end
    else
      new:insert(el)
      i = i + 1
    end
  end
  if changed then
    return new
  end
  return nil
end

local function process_parent_figure(div)
  if quarto.doc.is_format("html") then
    return div:walk({
      Link = strip_html_link_prefix
    })
  end

  local strip_prefix
  if quarto.doc.is_format("typst") then
    strip_prefix = strip_typst_prefix
  else
    return div
  end

  return div:walk({
    Plain = function(plain)
      local result = strip_prefix(plain.content)
      if result then
        plain.content = result
        return plain
      end
      return nil
    end,
    Para = function(para)
      local result = strip_prefix(para.content)
      if result then
        para.content = result
        return para
      end
      return nil
    end
  })
end

local function process_blocks(blocks)
  local changed = false
  for i, block in ipairs(blocks) do
    if is_float_ref_target(block) and has_nested_float_ref(block) then
      blocks[i] = process_parent_figure(block)
      changed = true
    elseif block.t == "Div" then
      if process_blocks(block.content) then
        changed = true
      end
    end
  end
  return changed
end

--- Inject format-specific header content for \subref / #subref support.
local function add_header_includes(meta)
  local raw_block = nil

  if quarto.doc.is_format("typst") then
    raw_block = pandoc.RawBlock("typst", [[#let subref(target) = {
  link(target, context {
    let idx = quartosubfloatcounter.at(query(target).first().location()).first() + 1
    [(#numbering("a", idx))]
  })
}]])
  end

  if raw_block == nil then
    return nil
  end

  local includes = meta["header-includes"]
  if includes == nil then
    includes = pandoc.MetaList({})
  end
  includes:insert(pandoc.MetaBlocks({ raw_block }))
  meta["header-includes"] = includes
  return meta
end

function Pandoc(doc)
  local meta_changed = add_header_includes(doc.meta)
  local blocks_changed = process_blocks(doc.blocks)
  if meta_changed or blocks_changed then
    return doc
  end
  return nil
end
