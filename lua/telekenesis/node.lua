local Enumerable = require("telekenesis.lib.enumerable")
local Treesitter = require("telekenesis.lib.treesitter")

local Node = {}

function Node.find_all(opts)
  local query = opts.query
  local bufnr = opts.bufnr or 0

  Treesitter.Query
    :new({ query_string = query, bufnr = bufnr })
    :map(function(pattern, match, metadata)
      print(pattern, vim.inspect(match), vim.inspect(metadata))
    end)

  return Enumerable:new(nodes):filter(func)
end

function Node:new()
  local instance = {
    label = nil,
  }

  setmetatable(instance, self)
  self.__index = self

  return instance
end

-- Renders the node based on its label using extmarks
function Node:render()
  vim.api.nvim_buf_set_extmark(0, 0, self.line, self.column, {
    virt_text = { { self.label, "TelekenesisLabel" } },
    virt_text_pos = "overlay",
    hl_mode = "combine",
    id = self.id,
  })
end

return Node
