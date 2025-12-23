local t = require("../test_utils")

local Query = require("telekinesis.treesitter.query")

describe("query", function()
  it("returns all textobject nodes", function()
    local bufnr = t.setup_buffer(
      [[
        local function hello(arg, arg2)
          print("Hello, world!")
        end
      ]],
      "lua"
    )
    local query = Query:new({ bufnr = bufnr })

    local result = query:nodes()

    assert.same(18, result:length())

    -- Ensure we're extracting the correct range
    local function_inner = result:find(function(node)
      return node.name == "function.inner"
    end)

    assert.same(
      {
        [[print("Hello, world!")]]
      },
      function_inner:content()
    )
  end)
end)
