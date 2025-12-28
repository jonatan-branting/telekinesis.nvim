local Enumerable = require("telekinesis.lib.enumerable")
local logger = require("telekinesis"):logger()

local Cursor = {}

function Cursor:new(opts)
  opts = opts or {
    bufnr = 0,
    row = assert(opts.row, "Row is required"),
    col = assert(opts.col, "Col is required"),
  }
  local Position = require("telekinesis.position")

  local instance = {
    position = Position:new(opts.bufnr or 0, opts.row, opts.col),
    __type = "Cursor",
  }

  setmetatable(instance, self)

  return instance
end

function Cursor.__index(instance, key)
  if key == "row" or key == "col" then
    return instance.position[key]
  else
    return Cursor[key]
  end
end

function Cursor:distance(row, col)
  return self.position:distance(row, col)
end

function Cursor:goto()
  self.position:goto()
end

return Cursor
