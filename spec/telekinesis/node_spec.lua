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

describe(".content", function()
end)
