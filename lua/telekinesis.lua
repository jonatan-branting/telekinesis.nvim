local Logger = require("telekinesis.lib.logger")
local Enumerable = require("telekinesis.lib.enumerable")
local utils = require("telekinesis.lib.utils")

local Telekinesis = {}

function Telekinesis.instance()
  assert(_G.telekinesis_instance, "Telekinesis has not been setup")

  return _G.telekinesis_instance
end

function Telekinesis.logger()
  return Logger:new(
    {
      level = vim.env.TELEKINESIS_LOG_LEVEL or "error",
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
    last_capture_group = {},
    last_node = nil,
  }

  setmetatable(instance, self)
  self.__index = self

  require("telekinesis.treesitter.query").add_directives()

  return instance
end

function Telekinesis:select(capture_groups)
  local Node = require("telekinesis.node")
  local Picker = require("telekinesis.picker")

  local pending_input = ""
  local macro_is_recording = vim.fn.reg_recording() ~= ""
  local macro_is_executing = vim.fn.reg_executing() ~= ""

  if not macro_is_recording and not macro_is_executing then
    while vim.fn.getchar(1) ~= 0 do
      pending_input = pending_input .. vim.fn.getcharstr()
    end
  end

  local nodes = {}
  for key, capture_group in pairs(capture_groups) do
    Node
      .find_all_visible(capture_group, { winid = 0 })
      :each(function(node)
        node.label_prefix = key
        node.capture_group = capture_group

        table.insert(nodes, node)
      end)
  end

  Picker
    :new(Enumerable:new(nodes))
    :render_labels(
      {
        callback = function(node)
          node:select()

          if not macro_is_executing then
            vim.schedule(function()
              vim.api.nvim_feedkeys(pending_input, "m", false)
            end)
          end

          self.last_capture_group = node.capture_group
          self.last_node = node
        end,
        on_nothing_selected = function()
          utils.abort_operation()
        end
      }
    )
end

function Telekinesis:goto(capture_groups)
  local Node = require("telekinesis.node")
  local Picker = require("telekinesis.picker")

  local nodes = {}
  for key, captures in pairs(capture_groups) do
    Node
      .find_all_visible(captures, { winid = 0 })
      :each(function(node)
        node.label_prefix = key

        table.insert(nodes, node)
      end)
  end

  Picker
    :new(Enumerable:new(nodes))
    :render_labels(
      {
        callback = function(node)
          node:goto()

          self.last_capture_group = node.capture_group
          self.last_node = node
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
    ["p"] = "parameter.inner",
    ["o"] = "constant",
  }

  self:select(mapping)
end

function Telekinesis:await_select_outer()
  -- Should come from config in the future
  local mapping = {
    ["f"] = "function.outer",
    ["c"] = "class.outer",
    ["b"] = "block.outer",
    ["p"] = "parameter.outer",
    ["o"] = "constant",
  }

  self:select(mapping)
end

function Telekinesis:await_goto_remote()
  local mapping = {
    ["f"] = "function.outer",
    ["c"] = "class.outer",
    ["b"] = "block.outer",
    ["p"] = "parameter.inner",
    ["o"] = "constant",
  }
  self:goto(mapping)
end

function Telekinesis:await_select_prev()
 assert(self.last_node, "No `last_node` recorded yet")

  local Node = require("telekinesis.node")

  Node
    .find_all_visible({ self.last_node.name }, { winid = 0 })
    :sort(function(node)
      local start_row, start_col, _, _ = unpack(node.range)

      return start_row * 10000 + start_col
    end)
    :reverse()
    :find_maybe(function(node)
      local cursor_row, cursor_col = unpack(vim.api.nvim_win_get_cursor(0))
      local start_row, start_col, _, _ = unpack(node.range)

      start_row = start_row + 1

      return (start_row < cursor_row) or (start_row == cursor_row and start_col < cursor_col)
    end)
    :_then(function(node)
      node:select()
    end)
    :_else(function()
      vim.notify("No next node found", vim.log.levels.WARN)
    end)
end

function Telekinesis:await_select_next()
 assert(self.last_node, "No `last_node` recorded yet")

  local Node = require("telekinesis.node")

  Node
    .find_all_visible({ self.last_node.name }, { winid = 0 })
    :sort(function(node)
      local start_row, start_col, _, _ = unpack(node.range)

      return start_row * 10000 + start_col
    end)
    :find_maybe(function(node)
      local cursor_row, cursor_col = unpack(vim.api.nvim_win_get_cursor(0))
      local start_row, start_col, _, _ = unpack(node.range)

      start_row = start_row + 1

      return (start_row > cursor_row) or (start_row == cursor_row and start_col > cursor_col)
    end)
    :_then(function(node)
      node:select()
    end)
    :_else(function()
      vim.notify("No next node found", vim.log.levels.WARN)
    end)
end

function Telekinesis:await_goto_next()
  assert(self.last_node, "No `last_node` recorded yet")

  local Node = require("telekinesis.node")

  Node
    .find_all_visible({ self.last_node.name }, { winid = 0 })
    :sort(function(node)
      local start_row, start_col, _, _ = unpack(node.range)

      return start_row * 10000 + start_col
    end)
    :select(function(node)
      local cursor_row, cursor_col = unpack(vim.api.nvim_win_get_cursor(0))
      local start_row, start_col, _, _ = unpack(node.range)

      start_row = start_row + 1

      return (start_row > cursor_row) or (start_row == cursor_row and start_col > cursor_col)
    end)
    :_then(function(nodes)
      local node = nodes[math.min(vim.v.count1, #nodes)]

      if node then
        node:goto()
      else
        vim.notify("No next node found", vim.log.levels.WARN)
      end
    end)
end

function Telekinesis:await_goto_prev()
  assert(self.last_node, "No `last_node` recorded yet")

  local Node = require("telekinesis.node")
  Node
    .find_all_visible({ self.last_node.name }, { winid = 0 })
    :sort(function(node)
      local start_row, start_col, _, _ = unpack(node.range)

      return start_row * 10000 + start_col
    end)
    :reverse()
    :select(function(node)
      local cursor_row, cursor_col = unpack(vim.api.nvim_win_get_cursor(0))
      local start_row, start_col, _, _ = unpack(node.range)

      start_row = start_row + 1

      return (start_row < cursor_row) or (start_row == cursor_row and start_col < cursor_col)
    end)
    :_then(function(nodes)
      local node = nodes[math.min(vim.v.count1, #nodes)]

      if node then
        node:goto()
      else
        vim.notify("No prev node found", vim.log.levels.WARN)
      end
    end)
end

return Telekinesis
