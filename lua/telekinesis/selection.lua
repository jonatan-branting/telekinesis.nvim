local Enumerable = require("telekinesis.lib.enumerable")
local logger = require("telekinesis"):logger()

local Selection = {}

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
  local opts = {
    hl_group = "Visual", -- TODO add TelekinesisSelection highlight group, and abind that to Visual by default!
    hl_mode = "combine",
    end_row = self.end_row,
    end_col = self.end_col,
  }

  if self.id then
    opts.id = self.id
  end

  self.id = vim.api.nvim_buf_set_extmark(self.bufnr, self.ns_id, self.start_row, self.start_col, opts)

  return self.id
end

function Selection:clear()
  logger:debug("Selection:clear()")

  if self.id then
    vim.api.nvim_buf_del_extmark(self.bufnr, self.ns_id, self.id)

    self.id = nil
  end
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

return Selection
