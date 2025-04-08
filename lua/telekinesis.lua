local Logger = require("telekinesis.lib.logger")
local utils = require("telekinesis.lib.utils")

local Telekinesis = {}

function Telekinesis.instance()
  assert(_G.telekinesis_instance, "Telekinesis has not been setup")

  return _G.telekinesis_instance
end

function Telekinesis.logger()
  return Logger:new(
    {
      level = vim.env.telekinesis_LOG_LEVEL or "error",
    }
  )
end

function Telekinesis.setup(opts)
  Telekinesis.logger():debug("Telekinesis.setup")

  opts = vim.tbl_extend(
    "force",
    require("telekinesis.config").default_opts,
    opts or {}
  )

  _G.telekinesis_instance = Telekinesis:new(opts)

  vim.cmd([[hi! link TelekinesisLabel Cursor]])

  return _G.telekinesis_instance
end

function Telekinesis:new(opts)
  local instance = {
    config = opts,
    logger = Telekinesis.logger(),
  }

  setmetatable(instance, self)
  self.__index = self

  require("telekinesis.treesitter.query").add_directives()

  return instance
end

function Telekinesis:select(captures)
  local Node = require("telekinesis.node")
  local Picker = require("telekinesis.picker")

  local nodes = Node.find_all_visible(captures, { winid = 0 })

  Picker
    :new(nodes)
    :render_labels(
      {
        callback = function(node)
          node:select()
        end,
        on_nothing_selected = function()
          utils.abort_operation()
        end
      }
    )
end

function Telekinesis:await_select_inner()
  -- Should come from config in the future
  local mapping = {
    ["f"] = "function.inner",
    ["c"] = "class.inner",
    ["b"] = "block.inner",
  }

  local picked_char = vim.fn.getcharstr()
  local picked_node = mapping[picked_char]

  if picked_node == nil then
    self.logger:warn("No mapping for " .. picked_char)

    -- doesn't seem to work!
    utils.abort_operation()

    return
  end

  self:select({ picked_node })
end

return Telekinesis
