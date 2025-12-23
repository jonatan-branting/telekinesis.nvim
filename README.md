# Telekenesis.nvim

```lua
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

-- vim.keymap.set("o", "n", "<Plug>(telekinesis-node)")


```
TODO
