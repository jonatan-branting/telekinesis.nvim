local Enumerable = require("telekinesis.lib.enumerable")
local Query = require("telekinesis.treesitter.query")

local Treesitter = {
  Query = Query,
}


-- function Treesitter.Node:new(opts)
--   local instance = {
--     node = opts.node,
--     bufnr = opts.bufnr or 0,
--   }
--
--   setmetatable(instance, self)
--   self.__index = self
--
--   return instance
-- end

return Treesitter
