local logger = require("telekinesis"):logger()

local Range = {}

function Range:new(coords, bufnr)
  local instance = {
    coords = coords,
    bufnr = bufnr or 0,
    __type = "Range",
  }

  setmetatable(instance, {
    __index = function(t, key)
      if key == "start_row" then
        return t.coords[1]
      elseif key == "start_col" then
        return t.coords[2]
      elseif key == "end_row" then
        return t.coords[3]
      elseif key == "end_col" then
        return t.coords[4]
      else
        return Range[key]
      end
    end
  })

  return instance
end

function Range:unpack()
  return unpack(self.coords)
end

function Range:to_table()
  return self.coords
end

function Range:is_before(row, col)
  return (self.start_row < row) or
         (self.start_row == row and self.start_col < col)
end

function Range:is_after(row, col)
  return (self.start_row > row) or
         (self.start_row == row and self.start_col > col)
end

function Range:distance(row, col)
  -- Expects 0-indexed coordinates (matching Range's internal format)
  local row_distance = math.abs(row - self.start_row)

  -- Take perceived distance into account. A character on the same line _feels_ closer.
  local col_distance = math.abs(col - self.start_col) / 4

  return math.sqrt(row_distance ^ 2 + col_distance ^ 2)
end

function Range:is_visible(topline, botline)
  -- topline/botline from vim.fn.line("w0"/"w$") are 1-indexed
  -- start_row is 0-indexed, so convert for comparison
  local start_row = self.start_row + 1

  return start_row >= topline and start_row <= botline
end

function Range:content()
  logger:debug("Range:content() range:", self.start_row, self.start_col, self.end_row, self.end_col)

  return vim.api.nvim_buf_get_text(
    self.bufnr,
    self.start_row,
    self.start_col,
    self.end_row,
    self.end_col,
    {}
  )
end

function Range:select()
  logger:debug("Range:select()")

  -- Convert 0-indexed to 1-indexed for Vim APIs
  vim.fn.setpos("'<", { self.bufnr, self.start_row + 1, self.start_col + 1, 0 })
  vim.fn.setpos("'>", { self.bufnr, self.end_row + 1, self.end_col, 0 })

  -- `o` to set the cursor to the start of the selection, as this likely keeps
  -- the viewport more stable in most cases
  vim.cmd("normal! gvo")
end

function Range:goto_start()
  logger:debug("Range:goto_start()")

  -- Convert 0-indexed to 1-indexed for Vim API
  vim.api.nvim_win_set_cursor(0, { self.start_row + 1, self.start_col })
end

return Range
