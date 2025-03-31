require("spec")
local t = require("../helper")

local Query = require("telekinesis.treesitter.query")

describe("query", function()
  it("returns all nodes matching a given query", function()
    local bufnr = t.setup_buffer(
      {
        "local function hello(arg, arg2)",
          '  print("Hello, world!")',
          "end"
      },
      "lua"
    )
    local query = Query:new({ bufnr = bufnr })

    local result = query:nodes()

    assert.same(17, result:length())
  end)
end)
