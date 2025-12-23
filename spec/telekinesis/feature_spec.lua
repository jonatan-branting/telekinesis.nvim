local t = require("../test_utils")

vim.keymap.set({"o", "x"}, "ir", function() require("telekinesis").instance():await_select_inner() end, {})
vim.keymap.set({"n", "x"}, "s", function() require("telekinesis").instance():await_goto_remote() end, {})

describe("goto", function()
  it("can use a text object to move the cursor", function()
    t.setup_buffer(
      [[
        local foo = "bar"
        local function hello(arg)
          print('Hello, world!')
        end
      ]],
      "lua"
    )

    t.feed([[sff]])

    local row, col = unpack(vim.api.nvim_win_get_cursor(0))

    assert.are.equal(3, row)
    assert.are.equal(0, col)

  end)

  it("is possible to repeat the goto", function()
    t.setup_buffer(
      [[
        local foo = bar("baz")
        local function hello(arg)
          print("Hello, world!")
        end

        local function goodbye(arg)
          print("Goodbye, world!" )
        end
      ]],
      "lua"
    )

    t.feed([[gg0spn]])

    require("telekinesis").instance():await_goto_next()

    local row, col = unpack(vim.api.nvim_win_get_cursor(0))

    assert.are.equal(3, row)
    assert.are.equal(21, col)
  end)
end)

describe("select", function()
  it("can use a text object with an action", function()
    t.setup_buffer(
      [[
        local function hello(arg)
          print('Hello, world!')
        end
      ]],
      "lua"
    )

    t.feed([[cirff"new function content!"]])

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

  it("it works with visual mode", function()
    t.setup_buffer(
      [[
        local function hello(arg)
          print('Hello, world!')
        end
      ]],
      "lua"
    )

    t.feed([[virfsd]])

    assert.buffer_matches(
      [[
        local function hello(arg)

        end
      ]]
    )
  end)
end)
