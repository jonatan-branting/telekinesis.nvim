local Enumerable = require("telekinesis.lib.enumerable")
local logger = require("telekinesis"):logger()

local Node = {}

function Node.find_all(captures, opts)
  local Query = require("telekinesis.treesitter.query")
  local bufnr = opts.bufnr or 0

  return Query
    :new({ bufnr = bufnr })
    :nodes()
    :filter(function(node)
      for _, capture in ipairs(captures) do
        if node.name:sub(1, #capture) == capture then return true end
      end

      return false
    end)
end

function Node:new(opts)
  local instance = {
    name = opts.name,
    ts_node = opts.ts_node,
    bufnr = opts.bufnr or 0,
    range = opts.range,
    ns_id = vim.api.nvim_create_namespace("TelekinesisNode")
  }

  local start_row, start_col, end_row, end_col = unpack(instance.range)

  instance.start_row = start_row
  instance.start_col = start_col
  instance.end_row = end_row
  instance.end_col = end_col

  setmetatable(instance, self)
  self.__index = self

  return instance
end

-- Renders the node based on its label using extmarks
function Node:render_label(label)
  local opts = {
    virt_text = { { label, "TelekinesisLabel" } },
    virt_text_pos = "overlay",
    hl_mode = "combine",
  }

  if self.id then
    opts.id = self.id
  end

  self.id = vim.api.nvim_buf_set_extmark(self.bufnr, self.ns_id, self.start_row, self.start_col, opts)

  return self.id
end

function Node:content()
  local start_row, start_col, end_row, end_col = unpack(self.range)

  logger:debug("Node:content() range:", start_row, start_col, end_row, end_col)

  return vim.api.nvim_buf_get_text(self.bufnr, start_row, start_col, end_row, end_col, {})
end

function Node:select()
  logger:debug("Node:select()")

  vim.fn.setpos("'<", { self.bufnr, self.start_row + 1, self.start_col + 1, 0 })
  vim.fn.setpos("'>", { self.bufnr, self.end_row + 1, self.end_col + 1, 0 })
end

function Node:jump_to()
  logger:debug("Node:jump_to()")

  vim.api.nvim_win_set_cursor(0, { self.start_row + 1, self.start_col + 1 })
end

return Node
