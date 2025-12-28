local t = require("../test_utils")

local Node = require("telekinesis.node")

describe(".find_all_in_selection", function()
  it("returns the nodes within the visual selection matching a given query", function()
    local bufnr = t.setup_buffer(
      [[
        local function hello(arg)
          print('Hello, world!', arg)
        end
      ]],
      "lua"
    )
    local captures = { "variable" }

    -- Create a visual selection around the function
    t.feed("gg0jwwvjj$<esc>")

    local result = Node.find_all_in_selection(captures, { bufnr = bufnr }):to_table()[1]

    assert.same("variable", result.name)
    assert.same(
      {
        "arg"
      },
      result:content()
    )
  end)
end)

describe(".find_all_under_cursor", function()
  it("returns the nodes under the cursor matching a given query", function()
    local bufnr = t.setup_buffer(
      [[
        local function hello(arg)
          print('Hello, world!', arg)
        end
      ]],
      "lua"
    )
    local captures = { "variable" }

    -- Place the cursor inside the function
    vim.api.nvim_win_set_cursor(0, { 2, 23 })

    local result = Node.find_all_under_cursor(captures, { bufnr = bufnr }):to_table()[1]

    assert.same("variable", result.name)
    assert.same(
      {
        "arg"
      },
      result:content()
    )
  end)
end)

describe(".find_all", function()
  it("returns all nodes matching a given query", function()
    local bufnr = t.setup_buffer(
      [[
        local function hello(arg)
          print('Hello, world!')
        end
      ]],
      "lua"
    )
    local captures = { "function.inner" }
    local result = Node.find_all(captures, { bufnr = bufnr })

    assert.same(1, result:length())
    assert.same("function.inner", result:first().name)
    assert.same(
      {
        [[print('Hello, world!')]]
      },
      result:first():content()
    )
  end)
end)

describe(".find_all_visible", function()
  it("returns all visible nodes matching a given query", function()
    local bufnr = t.setup_buffer(
      [[
        local function hello(arg)
          print('Hello, world!')
        end
      ]],
      "lua"
    )
    local captures = { "function.inner" }

    -- Scroll down so that the function is not visible
    vim.api.nvim_win_set_cursor(0, { 1, 0 })

    local result = Node.find_all_visible(captures, { winid = 0 })

    assert.same(0, result:length())
  end)
end)

describe("#render_label", function()
  it("renders a label next to the node and returns the id of the extmark", function()
    local bufnr = t.setup_buffer(
      [[
        local function hello(arg)
          print('Hello, world!')
        end
      ]],
      "lua"
    )
    local captures = { "function.inner" }
    local node = Node.find_all(captures, { bufnr = bufnr }):first()
    node.label = "test"

    local extmark_id = node:render_label()
    local extmark = vim.api.nvim_buf_get_extmark_by_id(bufnr, node.ns_id, extmark_id, { details = true })

    assert.same(node.start_row, extmark[1])
    assert.same(node.start_col, extmark[2])

    local extmark_opts = extmark[3]
    assert.same("test", extmark_opts.virt_text[1][1])
    assert.same("TelekinesisLabel", extmark_opts.virt_text[1][2])
    assert.same(node.ns_id, extmark_opts.ns_id)
  end)
end)

describe("#select", function()
  it("sets the visual registers", function()
    local bufnr = t.setup_buffer(
      [[
        local function hello(arg)
          print('Hello, world!')
        end
      ]],
      "lua"
    )
    local captures = { "function.inner" }
    local node = Node.find_all(captures, { bufnr = bufnr }):first()

    node:select()

    assert.same({ 0, 3, 3, 0 }, vim.fn.getpos("'<"))
    assert.same({ 0, 3, 24, 0 }, vim.fn.getpos("'>"))
  end)
end)

describe("#goto", function()
  it("sets the cursor to the start of the node", function()
    local bufnr = t.setup_buffer(
      [[
        local function hello(arg)
          print('Hello, world!')
        end
      ]],
      "lua"
    )
    local captures = { "function.inner" }
    local node = Node.find_all(captures, { bufnr = bufnr }):first()

    node:goto()

    assert.same({ 3, 2 }, vim.api.nvim_win_get_cursor(0))
  end)
end)
