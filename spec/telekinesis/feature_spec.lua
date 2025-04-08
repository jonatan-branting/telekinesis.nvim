local t = require("../test_utils")

vim.keymap.set("o", "ir", function() require("telekinesis").instance():await_select_inner() end, {})

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

  it("is possible to cancel the selection", function()
    t.setup_buffer(
      [[
        local function hello(arg)
          print('Hello, world!')
        end
      ]],
      "lua"
    )

    t.feed([[cirf<esc>f]])

    -- Should remain unchanged, the `f` should not be added to the buffer
    assert.buffer_matches(
      [[
        local function hello(arg)
          print('Hello, world!')
        end
      ]]
    )
  end)
end)
