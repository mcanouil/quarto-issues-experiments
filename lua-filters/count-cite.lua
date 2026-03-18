--- count-cite - Filter
--- @module count-cite.lua
--- @license MIT
--- @copyright 2026 Mickaël Canouil
--- @author Mickaël Canouil
--- @version 0.1.0

local citation_count = {}

function Cite(cite)
  for _, citation in ipairs(cite.citations) do
    local id = citation.id
    citation_count[id] = (citation_count[id] or 0) + 1
  end
end

function Pandoc(doc)
  quarto.log.output(citation_count)
end
