local Logger = require("telekinesis.lib.logger")
local Enumerable = require("telekinesis.lib.enumerable")
local utils = require("telekinesis.lib.utils")

local Telekinesis = {}

_G.Telekinesis_occurrence_operator = function(type)
  local instance = Telekinesis.instance()

  local Node = require("telekinesis.node")
  local Cursor = require("telekinesis.cursor")

  local captures = { instance.occurrence_operator_opts.node_name, }
  instance.occurrence_operator_opts.node:to_cursor():goto()

  require("telekinesis.polykinesis").instance():clear_buffer()

  Node
    .find_all_in_selection(captures, { winid = 0 })
    :filter(function(node)
      return node:content() == instance.occurrence_operator_opts.node_content
    end)
    :reject(function(node)
      return node:equals(instance.occurrence_operator_opts.node)
    end)
    :map(function(node)
      return Cursor:new({ row = node.start_row, col = node.start_col, bufnr = node.bufnr})
    end)
    :each(function(cursor)
      require("telekinesis.polykinesis").instance():add_cursor(cursor)
    end)

  utils.abort_operation()
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(instance.current_operator .. "iw", true, false, true), "mt", false)
end

vim.keymap.set("o", "<Plug>(telekinesis-select-node)", function()

end)

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

  local Polykinesis = require("telekinesis.polykinesis")

  _G.telekinesis_instance = Telekinesis:new(opts)
  _G.polykinesis_instance = Polykinesis:new(opts)

  vim.cmd([[hi! link TelekinesisLabel Cursor]])

  return _G.telekinesis_instance
end

function Telekinesis:new(opts)
  local instance = {
    config = opts,
    logger = Telekinesis.logger(),
    last_capture_group = {},
    last_node = nil,
    current_operatorfunc = nil,
    current_operator = nil,
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
    ["a"] = "parameter.inner",
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
    ["a"] = "parameter.outer",
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
      return node.start_row * 10000 + node.start_col
    end)
    :reverse()
    :find_maybe(function(node)
      local cursor_row, cursor_col = unpack(vim.api.nvim_win_get_cursor(0))
      return node.range:is_before(cursor_row - 1, cursor_col)
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
      return node.start_row * 10000 + node.start_col
    end)
    :find_maybe(function(node)
      local cursor_row, cursor_col = unpack(vim.api.nvim_win_get_cursor(0))
      return node.range:is_after(cursor_row - 1, cursor_col)
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
      return node.start_row * 10000 + node.start_col
    end)
    :select(function(node)
      local cursor_row, cursor_col = unpack(vim.api.nvim_win_get_cursor(0))
      return node.range:is_after(cursor_row - 1, cursor_col)
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
      return node.start_row * 10000 + node.start_col
    end)
    :reverse()
    :select(function(node)
      local cursor_row, cursor_col = unpack(vim.api.nvim_win_get_cursor(0))
      return node.range:is_before(cursor_row - 1, cursor_col)
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

-- operator - await_select_occurrences -> occurrence_operator (add cursors) -> replay operator

-- This chains _with other motions_ effectively allowing you to reinterpret the incoming motion.
function Telekinesis:await_select_occurrences()
  local Node = require("telekinesis.node")

  local node = Node.find_all_under_cursor({ "variable", "function.inner", "block", "constant", "parameter" }, { winid = 0 })
    :sort(function(node)
      return node:size()
    end)
    :to_table()[1]

  assert(node, "No node found under cursor")

  self.current_operator = vim.v.operator
  self.current_operatorfunc = vim.go.operatorfunc
  self.occurrence_operator_opts = {
    node = node,
    node_name = node.name,
    node_content = node:content(),
  }

  vim.go.operatorfunc = "v:lua.Telekinesis_occurrence_operator"

  utils.abort_operation()
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("g@", true, false, true), "n", false)
end

-- c(hange)r(egex)i(n)f(unction)
-- 
-- The `r` operator here should reinterpret the selection from `if`, and return
-- a cursor (along with a node), for each match!
--
--
-- Question: Should the input regex be requested before or after the `if` selection?
-- Answer: After!
--
-- And here, 
function Telekinesis:await_select_matches()
  self.current_operator = vim.v.operator
  self.current_operatorfunc = vim.go.operatorfunc
  self.match_operator_opts = {
    view = vim.fn.winsaveview(),
  }

  vim.go.operatorfunc = "v:lua.Telekinesis_match_operator"

  utils.abort_operation()
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("g@", true, false, true), "n", false)
end

_G.Telekinesis_match_operator = function(type)
  local keys = vim.api.nvim_replace_termcodes("<Esc>", true, false, true)
  vim.api.nvim_feedkeys(keys, "nx", false)

  vim.fn.winrestview(Telekinesis.instance().match_operator_opts.view)

  local instance = Telekinesis.instance()

  -- Prompt for regex
  local pattern = vim.fn.input("/")
  if pattern == "" then
    utils.abort_operation()
    return
  end

  local regex = vim.regex(pattern)

  local matches = {}

  local Selection = require("telekinesis.selection")
  Selection
    .from_visual_selection(0)
    :foreach_line(function(_, row, start_col, end_col)
      local match_start, match_end = regex:match_line(0, row, start_col, end_col)

      if not match_start then return end

      table.insert(matches, {
        row = row,
        start_col = match_start,
        end_col = match_end,
      })
    end)

  local selections = Enumerable
    :new(matches)
    :map(function(match)
      return Selection:new({
        range = {
          match.row,
          match.start_col,
          match.row,
          match.end_col,
        },
        bufnr = 0,
      })
    end)
    :to_table()

  local first_selection = selections[1]
  first_selection:select()

  for i = 2, #selections do
    local cursor = selections[i]:to_cursor()

    require("telekinesis.polykinesis").instance():add_cursor(cursor)
  end

  utils.abort_operation()
  vim.schedule(function()
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(instance.current_operator .. "iw", true, false, true), "mt", false)
  end)
end

return Telekinesis
