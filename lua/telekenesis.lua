local Node = require("telekenesis.node")

local Telekenesis = {}

-- cia => change in argument
-- <c>ira => change in remote argument
-- Usage: vim.keymap.set { "o", "ra", "<Plug>(telekenesis-argument)" }
function Telekenesis:operator_pending(query)
  Node.find_all(query):each({
    type = node_type,
    action = vim.go.operatorfunc,
  })
end

-- coif => change occurrences in function

return Telekenesis
