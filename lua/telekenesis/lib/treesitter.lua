local Enumerable = require('telekenesis.lib.enumerable')

local Treesitter = {
  Query = {},
  Node = {}
}

function Treesitter.Query:new(opts)
  local instance = {
    query_string = opts.query_string,
    bufnr = opts.bufnr or 0,
  }

  setmetatable(instance, self)
  self.__index = self

  return instance
end

function Treesitter.Query:foreach_node(func)
  local parser = vim.treesitter.get_parser(self.bufnr)
  local query = vim.treesitter.query.parse(parser:lang(), self.query_string)
  local root = parser:parse()[1]:root()

  -- print(self.bufnr, self.query_string, vim.inspect(query))

  local mapped = {}
  for _, match, metadata in query:iter_matches(root, 0, 0, -1, { all = true }) do
    for id, nodes in pairs(match) do
      -- local name = query.captures[id]
      for _, node in ipairs(nodes) do
        node = Treesitter.Node:new({ node = node, bufnr = self.bufnr })
        local result, _ = func(node, node:text())

        table.insert(mapped, result)
      end
    end
  end

  return Enumerable:new(mapped)
end

function Treesitter.Node:new(opts)
  local instance = {
    node = opts.node,
    bufnr = opts.bufnr or 0,
  }

  setmetatable(instance, self)
  self.__index = self

  return instance
end

function Treesitter.Node:text()
  local bufnr = self.bufnr
  local node = self.node

  if not self.node then
    return {}
  end

  -- We have to remember that end_col is end-exclusive
  local start_row, start_col, end_row, end_col = vim.treesitter.get_node_range(node)

  if start_row ~= end_row then
    local lines = vim.api.nvim_buf_get_lines(bufnr, start_row, end_row + 1, false)
    if next(lines) == nil then
      return {}
    end
    lines[1] = string.sub(lines[1], start_col + 1)
    -- end_row might be just after the last line. In this case the last line is not truncated.
    if #lines == end_row - start_row + 1 then
      lines[#lines] = string.sub(lines[#lines], 1, end_col)
    end
    return lines
  else
    local line = vim.api.nvim_buf_get_lines(bufnr, start_row, start_row + 1, false)[1]
    -- If line is nil then the line is empty
    return line and { string.sub(line, start_col + 1, end_col) } or {}
  end
end


return Treesitter
