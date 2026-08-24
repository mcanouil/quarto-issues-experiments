--[[
# MIT License
# Copyright (c) 2026 Mickaël Canouil
]]

local mod = require("_modules/greet")

return {
  {
    Pandoc = function(doc)
      doc.blocks:insert(pandoc.Para(pandoc.Str("filter-require: OK " .. mod.greeting())))
      return doc
    end,
  },
}
