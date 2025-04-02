local t = require("../helper")

local Node = require("telekinesis.node")

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

    local extmark_id = node:render_label("test")
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

    assert.same({ 0, 2, 11, 0 }, vim.fn.getpos("'<"))
    assert.same({ 0, 2, 33, 0 }, vim.fn.getpos("'>"))
  end)
end)

describe("#jump_to", function()
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

    node:jump_to()

    assert.same({ 2, 11 }, vim.api.nvim_win_get_cursor(0))
  end)
end)
