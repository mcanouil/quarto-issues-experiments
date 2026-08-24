--[[
# MIT License
# Copyright (c) 2026 Mickaël Canouil
]]

local ok, mod = pcall(require, "_modules/greet")
local verdict = ok and ("OK " .. mod.greeting()) or "FAIL"

return {
  {
    Pandoc = function(doc)
      doc.blocks:insert(pandoc.Para(pandoc.Str("filter-require: " .. verdict)))
      return doc
    end,
  },
}
