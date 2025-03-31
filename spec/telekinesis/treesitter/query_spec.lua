local t = require("../helper")

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

    assert.same(17, result:length())

    -- Ensure we're extracting the correct range
    local function_inner = result:find(function(node)
      return node.name == "function.inner"
    end)

    assert.same({1, 12, 1, 34}, function_inner.range)
  end)
end)
