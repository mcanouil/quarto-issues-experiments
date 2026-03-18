if not quarto.doc.is_format("latex") then return {} end

return { {
  CodeBlock = function(el)
    if el.attributes["code-fold"] then return {} end
  end
} }
