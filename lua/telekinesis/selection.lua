local Enumerable = require("telekinesis.lib.enumerable")
local Cursor = require("telekinesis.cursor")
local logger = require("telekinesis"):logger()

local Selection = {}

function Selection.from_visual_selection(bufnr)
  local Range = require("telekinesis.range")

  local _, start_line, start_col = unpack(vim.fn.getpos("'<"))
  local _, end_line, end_col     = unpack(vim.fn.getpos("'>"))

  local range = Range:new({ start_line - 1, start_col - 1, end_line - 1, end_col - 1 }, bufnr or 0)

  return Selection:new({ range = range, bufnr = bufnr or 0 })
end

function Selection:new(opts)
  local Range = require("telekinesis.range")

  local instance = {
    range = Range:new(opts.range, opts.bufnr or 0),
    __type = "Selection",
  }

  setmetatable(instance, self)

  return instance
end

function Selection.__index(instance, key)
  if key == "start_row" or key == "start_col" or key == "end_row" or key == "end_col" then
    return instance.range[key]
  else
    return Selection[key]
  end
end

function Selection:render()
end

function Selection:clear()
end

function Selection:content()
  return self.range:content()
end

function Selection:select()
  self.range:select()
end

function Selection:goto()
  self.range:goto_start()
end

function Selection:lines()
  return Enumerable:new(self.range:content())
end

function Selection:foreach_line(func)
  return self.range:foreach_line(func)
end

function Selection:to_cursor()
  return Cursor:new({
    bufnr = self.bufnr,
    row = self.start_row,
    col = self.start_col,
  })
end

return Selection
