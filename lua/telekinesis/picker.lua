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

  self.nodes
    :group_by(function(node)
      return node.label_prefix
    end)
    :each(function(group)
      group
        :sort(function(node)
          return node:distance_to_cursor()
        end)
        :each(function(node, i)
          node.label = node.label_prefix .. labels[i]
        end)
    end)

  local candidates = self.nodes:dup()
  local label = ""

  while true do
    candidates:each(function(node)
      node:render_label()
    end)

    vim.cmd("redraw")

    label = vim.fn.getcharstr()

    local picked = candidates:find(function(node)
      return node.label == label
    end)

    candidates:each(function(node)
      node:clear()
    end)

    if picked then
      callback(picked)

      break
    end

    candidates = candidates:filter(function(node)
      return node.label:sub(1, #label) == label
    end)

    if candidates:empty() then
      on_nothing_selected()

      break
    end

    candidates:each(function(node)
      node.label = node.label:sub(#label + 1)
    end)
  end
end

return Picker
