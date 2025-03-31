local Node = {}

function Node.find_all(captures, opts)
  local Query = require("telekinesis.treesitter.query")
  local bufnr = opts.bufnr or 0

  return Query
    :new({ captures = captures, bufnr = bufnr })
    :foreach_node(function(ts_node)
      return Node:new({ts_node = ts_node, bufnr = bufnr})
    end)
end

-- might just remove this
function Node.from_ts_node(ts_node, opts)
  return Node:new({
    name = opts.name,
    ts_node = ts_node,
    range = {
      ts_node:start(),
      ts_node:_end()
    },
    bufnr = opts.bufnr
  })
end

function Node:new(opts)
  local instance = {
    name = opts.name,
    ts_node = opts.ts_node, -- this is optional, but a reference is nice?
    bufnr = opts.bufnr or 0,
    range = opts.range,
    label = nil,
  }

  setmetatable(instance, self)
  self.__index = self

  return instance
end

-- Renders the node based on its label using extmarks
function Node:render()
  vim.api.nvim_buf_set_extmark(0, 0, self.line, self.column, {
    virt_text = { { self.label, "TelekinesisLabel" } },
    virt_text_pos = "overlay",
    hl_mode = "combine",
    id = self.id,
  })
end

function Node:content()
  local start_row, start_col, end_row, end_col = unpack(self.range)

  return vim.api.nvim_buf_get_text(self.bufnr, start_row, start_col, end_row, end_col, {})
end

return Node
