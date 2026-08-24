--[[
# MIT License
# Copyright (c) 2026 Mickaël Canouil
]]

local ok, mod = pcall(require, "_modules/greet")
local verdict = ok and ("OK " .. mod.greeting()) or "FAIL"

return {
  ["parity"] = function()
    return pandoc.Str("shortcode-require: " .. verdict)
  end,
}
