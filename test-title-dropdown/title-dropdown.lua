local function is_empty(s)
  return s == nil or s == ''
end

local function serialise_menu_items(items)
  local js = "window.titleDropdownMenuItems = [\n"
  for _, item in ipairs(items) do
    js = js .. string.format("    { text: '%s', href: '%s' },\n", pandoc.utils.stringify(item.text), pandoc.utils.stringify(item.href))
  end
  js = js .. "];\n"
  return js
end

local function get_memu_items(meta)
  if quarto.doc.is_format("html") then
    if not is_empty(meta['title-dropdown']) then
      local title_dropdown_menu = serialise_menu_items(meta['title-dropdown'])
      quarto.doc.include_text("in-header", "<script>" .. title_dropdown_menu .. "</script>")
      quarto.doc.add_html_dependency({
        name = 'title-dropdown',
        version = '1.0.0',
        scripts = {
          {
            path = "dropdown.js",
            afterBody = true
          }
        }
      })
    end
  end
  return meta
end

return {
  {Meta = get_memu_items}
}
