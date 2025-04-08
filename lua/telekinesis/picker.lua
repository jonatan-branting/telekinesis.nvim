local Picker = {}

function Picker:new(nodes)
  local instance = {
    nodes = nodes,
    config = _G.telekinesis_instance.config,
  }

  setmetatable(instance, self)
  self.__index = self

  return instance
end

function Picker:render_labels(opts)
  local callback = opts.callback or function() end
  local on_nothing_selected = opts.on_nothing_selected or function() end

  local labels = self.config.labels

  local node_label_pairs = {}

  self.nodes
    :each(function(node, i)
      node_label_pairs[labels[i]] = node

      node:render_label(labels[i])
    end)

  vim.cmd("redraw")

  local label = vim.fn.getcharstr()

  if node_label_pairs[label] ~= nil then
    callback(node_label_pairs[label])
  else
    on_nothing_selected()
  end

  self.nodes:each(function(node)
    node:clear()
  end)
end

return Picker
