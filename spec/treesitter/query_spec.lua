require("spec")

local Treesitter = require("telekenesis.lib.treesitter")

describe("query", function()
  it("returns all nodes matching a given query", function()
    local bufnr = vim.api.nvim_create_buf(false, true)
    local lang = "lua"
    local query_string = "(_) @node"

    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { "def hello", '  puts "Hello, world!"', "end" })
    vim.api.nvim_buf_call(bufnr, function()
      vim.bo.filetype = lang
    end)

    local query = Treesitter.Query:new({ query_string = query_string, bufnr = bufnr })
    query:map(function(pattern, match, metadata)
      print(pattern, vim.inspect(match), vim.inspect(metadata))
    end)
  end)
end)
