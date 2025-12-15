local Enumerable = require("telekinesis.lib.enumerable")
local logger = require("telekinesis"):logger()

local Node = {}

function Node.find_all(captures, opts)
  if type(captures) == "string" then
    captures = { captures }
  end

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

function Node.find_all_visible(captures, opts)
  local winid = opts.winid or 0
  local bufnr = vim.api.nvim_win_get_buf(winid)
  local nodes = Node.find_all(captures, { bufnr = bufnr })

  local topline, botline
  vim.api.nvim_win_call(winid, function()
    topline = vim.fn.line("w0")
    botline = vim.fn.line("w$")
  end)

  return nodes
    :filter(function(node)
      local start_row, _, end_row, _ = unpack(node.range)

      return start_row >= topline and end_row <= botline
    end)
end

function Node:new(opts)
  local instance = {
    name = opts.name,
    ts_node = opts.ts_node,
    bufnr = opts.bufnr or 0,
    range = opts.range,
    ns_id = vim.api.nvim_create_namespace("TelekinesisNode"),
    label_prefix = opts.label_prefix or "",
    label = opts.label or "",
    __type = "Node",
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
function Node:render_label()
  assert(self.label ~= nil, "Node:render_label() requires a label to render")
  -- TODO: Should also render the entire node!
  local opts = {
    virt_text = { { self.label, "TelekinesisLabel" } },
    virt_text_pos = "inline",
  }

  if self.id then
    opts.id = self.id
  end

  self.id = vim.api.nvim_buf_set_extmark(self.bufnr, self.ns_id, self.start_row, self.start_col, opts)

  return self.id
end

function Node:clear()
  logger:debug("Node:clear()")

  if self.id then
    vim.api.nvim_buf_del_extmark(self.bufnr, self.ns_id, self.id)

    self.id = nil
  end
end

function Node:content()
  local start_row, start_col, end_row, end_col = unpack(self.range)

  logger:debug("Node:content() range:", start_row, start_col, end_row, end_col)

  return vim.api.nvim_buf_get_text(self.bufnr, start_row, start_col, end_row, end_col, {})
end

function Node:select()
  logger:debug("Node:select()")

  vim.fn.setpos("'<", { self.bufnr, self.start_row + 1, self.start_col + 1, 0 })
  vim.fn.setpos("'>", { self.bufnr, self.end_row + 1, self.end_col, 0 })

  -- `o` to set the cursor to the start of the selection, as this likely keeps
  -- the viewport more stable in most cases
  vim.cmd("normal! gvo")
end

function Node:jump_to()
  logger:debug("Node:jump_to()")

  vim.api.nvim_win_set_cursor(0, { self.start_row + 1, self.start_col + 1 })
end

return Node
