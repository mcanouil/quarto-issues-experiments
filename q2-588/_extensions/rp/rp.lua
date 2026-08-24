local function exists(path)
  local handle = io.open(path, "r")
  if handle then
    handle:close()
    return "exists"
  end
  return "MISSING"
end

local top = quarto.utils.resolve_path("_modules/greet.lua")
local by_require = require("_modules/probe").resolved
local by_dofile = dofile(quarto.utils.resolve_path("_modules/probe.lua")).resolved

local report = {
  string.format("top-level : %s  %s", top, exists(top)),
  string.format("via-require: %s  %s", by_require, exists(by_require)),
  string.format("via-dofile : %s  %s", by_dofile, exists(by_dofile)),
}

return {
  ["rp"] = function()
    return pandoc.Str(table.concat(report, " | "))
  end,
}
