local Enumerable = require("telekinesis.lib.enumerable")
local logger = require("telekinesis"):logger()

local Node = {}

function Node.find_all(captures, opts)
  captures = captures or {}

  if type(captures) == "string" then
    captures = { captures }
  end

  local Query = require("telekinesis.treesitter.query")
  local bufnr = opts.bufnr or 0

  return Query
    :new({ bufnr = bufnr })
    :nodes()
    :filter(function(node)
      if #captures == 0 then
        return true
      end
      for _, capture in ipairs(captures) do
        if node.name:sub(1, #capture) == capture then return true end
      end

      return false
    end)
end

function Node.find_all_in_selection(captures, opts)
  local winid = opts.winid or 0
  local bufnr = vim.api.nvim_win_get_buf(winid)
  local nodes = Node.find_all(captures, { bufnr = bufnr })

  local _, start_line, start_col = unpack(vim.fn.getpos("'<"))
  local _, end_line, end_col     = unpack(vim.fn.getpos("'>"))

  return nodes:filter(function(node)
    return node:within({ start_line - 1, start_col, end_line - 1, end_col })
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

  return nodes:filter(function(node)
    return node.range:is_visible(topline, botline)
  end)
end

function Node.find_all_under_cursor(captures, opts)
  local winid = opts.winid or 0
  local bufnr = vim.api.nvim_win_get_buf(winid)
  local nodes = Node.find_all(captures, { bufnr = bufnr })

  local topline, botline
  vim.api.nvim_win_call(winid, function()
    topline = vim.fn.line("w0")
    botline = vim.fn.line("w$")
  end)
  local cursor_row, cursor_col = unpack(vim.api.nvim_win_get_cursor(winid))

  return nodes:filter(function(node)
    return node.range:contains(cursor_row - 1, cursor_col) and node.range:is_visible(topline, botline)
  end)
end

function Node:new(opts)
  local Range = require("telekinesis.range")

  local instance = {
    name = opts.name,
    ts_node = opts.ts_node,
    bufnr = opts.bufnr or 0,
    range = Range:new(opts.range, opts.bufnr or 0),
    capture_key = opts.capture_key or "",
    ns_id = vim.api.nvim_create_namespace("TelekinesisNode"),
    label_prefix = opts.label_prefix or "",
    label = opts.label or "",
    __type = "Node",
  }

  setmetatable(instance, self)

  return instance
end

function Node.__index(instance, key)
  if key == "start_row" or key == "start_col" or key == "end_row" or key == "end_col" then
    return instance.range[key]
  else
    return Node[key]
  end
end

-- Renders the node based on its label using extmarks
function Node:render_label()
  assert(self.label ~= nil, "Node:render_label() requires a label to render")
  -- TODO: Should also render the entire node!
  local opts = {
    virt_text = { { self.label, "TelekinesisLabel" } },
    virt_text_pos = "overlay",
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

function Node:distance_to_cursor()
  local cursor_pos = vim.api.nvim_win_get_cursor(0)
  local cursor_row = cursor_pos[1] - 1  -- Convert to 0-indexed
  local cursor_col = cursor_pos[2]

  return self.range:distance(cursor_row, cursor_col)
end

function Node:content()
  return self.range:content()
end

function Node:select()
  self.range:select()
end

function Node:size()
  return self.range:size()
end

function Node:within(range)
  local Range = require("telekinesis.range")
  range = Range:new(range, self.bufnr)

  return range:contains(self.start_row, self.start_col) and range:contains(self.end_row, self.end_col)
end

function Node:goto()
  self.range:goto_start()
end

function Node:equals(other_node)
  if not other_node or other_node.__type ~= "Node" then
    return false
  end

  return self.bufnr == other_node.bufnr
    and self.start_row == other_node.start_row
    and self.start_col == other_node.start_col
    and self.end_row == other_node.end_row
    and self.end_col == other_node.end_col
end

return Node
