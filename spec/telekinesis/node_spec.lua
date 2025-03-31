local t = require("../helper")

local Node = require("telekinesis.node")

describe("query", function()
  it("returns all nodes matching a given query", function()
    local bufnr = t.setup_buffer(
      {
        "local function hello(arg)",
        },
      "lua"
    )
    local query_string = "function"
    -- print(vim.inspect(require("vim.treesitter.query").get("lua", "textobjects")))

    local result = Node.find_all({"function"}, { bufnr = bufnr })

    -- assert.same(1, result:length())
    -- assert.same({"(arg)"}, result:map("content"):table())
  end)
end)
