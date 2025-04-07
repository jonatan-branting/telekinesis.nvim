local Enumerable = require("telekinesis.lib.enumerable")
local Node = require("telekinesis.node")
local Query = {}
local logger = require("telekinesis"):logger()

function Query.add_directives()
  -- TODO: We need to allow this to override the directive if it's already there!
  -- Might be a flag?
  logger:debug("Query.add_directives")

  vim.treesitter.query.add_directive(
    "make-range!",
    function (match, pattern, source, predicate, metadata)
      assert(#predicate == 4)

      local capture_name = predicate[2] -- e.g., "@parameter.outer"
      local from_node = match[predicate[3]]
      local to_node = match[predicate[4]]

      from_node = from_node or to_node
      to_node = to_node or from_node

      metadata.directive = "make-range!"
      metadata.capture_name = capture_name

      -- How can you shut up this lint warning?
      metadata.from = from_node
      metadata.to = to_node
      metadata.range = { from_node:start(), to_node:end_() }

      logger:debug("Query.make-range! metadata:", vim.inspect(metadata))
    end,
    {
      force = true
    }
  )
end

function Query:new(opts)
  local bufnr = opts.bufnr or 0
  local parser = vim.treesitter.get_parser(bufnr)
  local query = vim.treesitter.query.get(parser:lang(), "textobjects")
  local root = parser:parse()[1]:root()

  local instance = {}
  instance.bufnr = bufnr
  instance.parser = parser
  instance.query = query
  instance.root = root

  setmetatable(instance, self)
  self.__index = self

  -- This shouldn't be added if it's already there!

  return instance
end

function Query:nodes()
  local nodes = {}

  for _, match, metadata in self.query:iter_matches(self.root, self.bufnr, 0, -1) do
    if metadata.directive == "make-range!" then
      local node = Node:new({ range = metadata.range, bufnr = self.bufnr, name = metadata.capture_name })

      table.insert(nodes, node)
    end

    for id, ts_nodes in pairs(match) do
      local name = self.query.captures[id]

      for _, ts_node in ipairs(ts_nodes) do
        local start_row, start_col, _ = ts_node:start()
        local end_row, end_col, _ = ts_node:end_()

        local node = Node:new({
          bufnr = self.bufnr,
          ts_node = ts_node,
          name = name,
          range = { start_row, start_col, end_row, end_col },
        })

        logger:debug("Query:nodes node:", vim.inspect(node))

        table.insert(nodes, node)
      end
    end
  end

  return Enumerable:new(nodes)
end

return Query
