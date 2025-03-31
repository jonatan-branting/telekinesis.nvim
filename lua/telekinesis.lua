local Node = require("telekinesis.node")
local Logger = require("telekinesis.lib.logger")

local Telekinesis = {}

function Telekinesis.logger()
  return Logger:new(
    {
      level = vim.env.telekinesis_LOG_LEVEL or "debug"
    }
  )
end

-- Remote operator pendings
-- cia => change in argument
-- <c>ira => change in remote argument
-- Usage: vim.keymap.set { "o", "ra", "<Plug>(telekinesis-argument)" }
function Telekinesis:operator_pending(query)
  Node.find_all(query):each({
    type = node_type,
    action = vim.go.operatorfunc,
  })
end

-- Occurence operator pendings
-- coif => change occurrences in function

-- Current node operator pendings
-- cne => chance node end
-- cnw => chance node until next
-- cnb => change node back

vim.keymap.set("o", "n", "<Plug>(telekinesis-node)")

function Telekinesis.setup()
  Telekinesis.logger():debug("Telekinesis.setup()")

  require("telekinesis.treesitter.query").add_directives()
end

return Telekinesis
