local t = require("../test_utils")

local Selection = require("telekinesis.selection")

describe("Selection.from_visual_selection", function()
  it("creates a Selection from the current visual selection", function()
    local bufnr = t.setup_buffer(
      [[
        local function hello()
          print('Hello, world!')
        end
      ]],
      "lua"
    )

    t.set_cursor(2, 2)
    t.feed("v$<esc>")  -- Visual select "print('Hello, world!')"

    local selection = Selection.from_visual_selection(bufnr)

    assert.same("print('Hello, world!')", selection.range:content())
  end)
end)
