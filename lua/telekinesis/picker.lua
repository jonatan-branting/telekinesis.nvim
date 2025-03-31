local Picker = {}

function Picker:new(nodes)
  local instance = {
    nodes = nodes,
  }

  setmetatable(instance, self)
  self.__index = self

  return instance
end

function Picker:render()
  self.nodes:each(function(node, i)
    node.label = i -- TODO better labeling
    node.render()
  end)

  local label = vim.fn.getcharstr()

  self.nodes
    :find(function(node)
      return node.label == label
    end)
    :execute_action()
end

return Picker
