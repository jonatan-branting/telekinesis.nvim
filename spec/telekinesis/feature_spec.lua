local t = require("../test_utils")

local Telekinesis = require("telekinesis")

vim.keymap.set("o", "irf", function() require("telekinesis").instance():select("function.inner") end, {})

describe("feature", function()
  it("can use a text object with an action", function()
    t.setup_buffer(
      [[
        local function hello(arg)
          print('Hello, world!')
        end
      ]],
      "lua"
    )

    t.feed([[cirfs"new function content!"]])

    assert.buffer_matches(
      [[
        local function hello(arg)
          "new function content!"
        end
      ]]
    )
  end)
end)
