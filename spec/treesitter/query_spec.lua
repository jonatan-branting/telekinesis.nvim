require("spec")

local Treesitter = require("telekenesis.lib.treesitter")

describe("query", function()
  it("returns all nodes matching a given query", function()
    local bufnr = vim.api.nvim_create_buf(false, true)
    local lang = "lua"
    local query_string = "(parameters) @node"

    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { "local function hello(arg)", '  print("Hello, world!")', "end" })
    vim.api.nvim_buf_call(bufnr, function()
      vim.bo.filetype = lang
    end)

    local query = Treesitter.Query:new({ query_string = query_string, bufnr = bufnr })

    local result = query:foreach_node(function(node, content)
      return content
    end)

    assert.same(1, result:length())
    assert.same({"(arg)"}, result:first())
  end)
end)
