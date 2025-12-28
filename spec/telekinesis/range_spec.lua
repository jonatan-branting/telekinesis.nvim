local Range = require("telekinesis.range")
local t = require("../test_utils")

describe("Range", function()
  describe(":new", function()
    it("creates a new Range with coords and bufnr", function()
      local coords = {5, 10, 8, 20}
      local range = Range:new(coords, 1)

      assert.same(coords, range.coords)
      assert.same(1, range.bufnr)
      assert.same("Range", range.__type)
    end)

    it("defaults bufnr to 0 when not provided", function()
      local coords = {5, 10, 8, 20}
      local range = Range:new(coords)

      assert.same(0, range.bufnr)
    end)
  end)

  describe("property access via __index", function()
    it("exposes start_row from coords[1]", function()
      local range = Range:new({5, 10, 8, 20}, 0)
      assert.same(5, range.start_row)
    end)

    it("exposes start_col from coords[2]", function()
      local range = Range:new({5, 10, 8, 20}, 0)
      assert.same(10, range.start_col)
    end)

    it("exposes end_row from coords[3]", function()
      local range = Range:new({5, 10, 8, 20}, 0)
      assert.same(8, range.end_row)
    end)

    it("exposes end_col from coords[4]", function()
      local range = Range:new({5, 10, 8, 20}, 0)
      assert.same(20, range.end_col)
    end)
  end)

  describe(":unpack", function()
    it("returns all 4 coordinates", function()
      local range = Range:new({5, 10, 8, 20}, 0)
      local start_row, start_col, end_row, end_col = range:unpack()

      assert.same(5, start_row)
      assert.same(10, start_col)
      assert.same(8, end_row)
      assert.same(20, end_col)
    end)
  end)

  describe(":to_table", function()
    it("returns the coords table", function()
      local coords = {5, 10, 8, 20}
      local range = Range:new(coords, 0)

      assert.same(coords, range:to_table())
    end)
  end)

  describe(":is_before", function()
    it("returns true when range starts before the given position (earlier row)", function()
      local range = Range:new({5, 10, 8, 20}, 0)
      assert.is_true(range:is_before(10, 5))
    end)

    it("returns true when range starts before the given position (same row, earlier col)", function()
      local range = Range:new({5, 10, 8, 20}, 0)
      assert.is_true(range:is_before(5, 15))
    end)

    it("returns false when range starts after the given position (later row)", function()
      local range = Range:new({5, 10, 8, 20}, 0)
      assert.is_false(range:is_before(3, 5))
    end)

    it("returns false when range starts after the given position (same row, later col)", function()
      local range = Range:new({5, 10, 8, 20}, 0)
      assert.is_false(range:is_before(5, 5))
    end)

    it("returns false when range starts at the exact position", function()
      local range = Range:new({5, 10, 8, 20}, 0)
      assert.is_false(range:is_before(5, 10))
    end)
  end)

  describe(":is_after", function()
    it("returns true when range starts after the given position (later row)", function()
      local range = Range:new({5, 10, 8, 20}, 0)
      assert.is_true(range:is_after(3, 5))
    end)

    it("returns true when range starts after the given position (same row, later col)", function()
      local range = Range:new({5, 10, 8, 20}, 0)
      assert.is_true(range:is_after(5, 5))
    end)

    it("returns false when range starts before the given position (earlier row)", function()
      local range = Range:new({5, 10, 8, 20}, 0)
      assert.is_false(range:is_after(10, 5))
    end)

    it("returns false when range starts before the given position (same row, earlier col)", function()
      local range = Range:new({5, 10, 8, 20}, 0)
      assert.is_false(range:is_after(5, 15))
    end)

    it("returns false when range starts at the exact position", function()
      local range = Range:new({5, 10, 8, 20}, 0)
      assert.is_false(range:is_after(5, 10))
    end)
  end)

  describe(":distance", function()
    it("calculates distance from a position on the same row", function()
      local range = Range:new({5, 10, 8, 20}, 0)
      local distance = range:distance(5, 20)

      -- Column distance is divided by 4: |20 - 10| / 4 = 2.5
      -- Row distance is 0
      -- Distance = sqrt(0^2 + 2.5^2) = 2.5
      assert.same(2.5, distance)
    end)

    it("calculates distance from a position on a different row", function()
      local range = Range:new({5, 10, 8, 20}, 0)
      local distance = range:distance(8, 10)

      -- Row distance: |8 - 5| = 3
      -- Column distance: |10 - 10| / 4 = 0
      -- Distance = sqrt(3^2 + 0^2) = 3
      assert.same(3.0, distance)
    end)

    it("calculates distance from a position with both row and column difference", function()
      local range = Range:new({5, 10, 8, 20}, 0)
      local distance = range:distance(9, 14)

      -- Row distance: |9 - 5| = 4
      -- Column distance: |14 - 10| / 4 = 1
      -- Distance = sqrt(4^2 + 1^2) = sqrt(17) ≈ 4.123
      assert.is_true(math.abs(distance - 4.123105625617661) < 0.0001)
    end)

    it("returns 0 when position is at range start", function()
      local range = Range:new({5, 10, 8, 20}, 0)
      local distance = range:distance(5, 10)

      assert.same(0.0, distance)
    end)
  end)

  describe(":is_visible", function()
    it("returns true when range start is within visible lines", function()
      local range = Range:new({5, 10, 8, 20}, 0)
      -- Range start_row is 5 (0-indexed), which becomes 6 (1-indexed)
      assert.is_true(range:is_visible(3, 10))
    end)

    it("returns true when range start is exactly at topline", function()
      local range = Range:new({5, 10, 8, 20}, 0)
      -- Range start_row is 5 (0-indexed), which becomes 6 (1-indexed)
      assert.is_true(range:is_visible(6, 10))
    end)

    it("returns true when range start is exactly at botline", function()
      local range = Range:new({5, 10, 8, 20}, 0)
      -- Range start_row is 5 (0-indexed), which becomes 6 (1-indexed)
      assert.is_true(range:is_visible(1, 6))
    end)

    it("returns false when range start is before topline", function()
      local range = Range:new({5, 10, 8, 20}, 0)
      -- Range start_row is 5 (0-indexed), which becomes 6 (1-indexed)
      assert.is_false(range:is_visible(7, 10))
    end)

    it("returns false when range start is after botline", function()
      local range = Range:new({5, 10, 8, 20}, 0)
      -- Range start_row is 5 (0-indexed), which becomes 6 (1-indexed)
      assert.is_false(range:is_visible(1, 5))
    end)
  end)

  describe("buffer operations", function()
    local t = require("../test_utils")

    describe(":content", function()
      it("extracts text content from the buffer", function()
        local bufnr = t.setup_buffer(
          [[
            local function hello()
              print('Hello, world!')
            end
          ]],
          "lua"
        )

        -- The text "print('Hello, world!')" is on line 3 (0-indexed: 2)
        -- Start col: 2, End col: 24
        local range = Range:new({2, 2, 2, 24}, bufnr)
        local content = range:content()

        assert.same(1, #content)
        assert.same("print('Hello, world!')", content[1])
      end)

      it("extracts multi-line content", function()
        local bufnr = t.setup_buffer("line1\nline2\nline3", "lua")

        -- Note: setup_buffer adds an empty line at the start, so:
        -- Row 0: "", Row 1: "line1", Row 2: "line2", Row 3: "line3"
        -- Extract rows 2-3 (should get "line2" and "line3")
        local range = Range:new({2, 0, 3, 5}, bufnr)
        local content = range:content()

        assert.same(2, #content)
        assert.same("line2", content[1])
        assert.same("line3", content[2])
      end)
    end)

    describe(":select", function()
      it("sets visual selection marks", function()
        local bufnr = t.setup_buffer(
          [[
            local function hello()
              print('Hello, world!')
            end
          ]],
          "lua"
        )

        -- Select "print('Hello, world!')" on line 3 (0-indexed: 2)
        local range = Range:new({2, 2, 2, 24}, bufnr)
        range:select()

        -- Visual marks use 1-indexed positions
        assert.same({ 0, 3, 3, 0 }, vim.fn.getpos("'<"))
        assert.same({ 0, 3, 24, 0 }, vim.fn.getpos("'>"))
      end)
    end)

    describe(":goto_start", function()
      it("moves cursor to range start", function()
        local bufnr = t.setup_buffer(
          [[
            local function hello()
              print('Hello, world!')
            end
          ]],
          "lua"
        )

        -- Position at "print" on line 3 (0-indexed: 2), col 2
        local range = Range:new({2, 2, 2, 24}, bufnr)
        range:goto_start()

        -- Cursor uses 1-indexed row, 0-indexed col
        assert.same({ 3, 2 }, vim.api.nvim_win_get_cursor(0))
      end)
    end)
  end)

  describe(":foreach_line", function()
    it("iterates over each line in the range", function()
      local bufnr = t.setup_buffer(
        [[
          line1
          line2
          line3
          line4
        ]],
        "lua"
      )

      local range = Range:new({2, 2, 4, 5}, bufnr)  -- lines 2 to 4 (0-indexed)

      local result = {}
      range:foreach_line(function(line, i, start_col, end_col)
        table.insert(result, {
          line = line,
          line_number = i,
          start_col = start_col,
          end_col = end_col,
        })
      end)

      assert.same(3, #result)
      assert.same({ line = "ne2", line_number = 2, start_col = 2, end_col = 5 }, result[1])
      assert.same({ line = "line3", line_number = 3, start_col = 0, end_col = 5 }, result[2])
      assert.same({ line = "line4", line_number = 4, start_col = 0, end_col = 5 }, result[3])
    end)
  end)
end)
