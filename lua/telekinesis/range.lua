local logger = require("telekinesis").logger()
local Enumerable = require("telekinesis.lib.enumerable")

local Range = {}

function Range:new(coords, bufnr)
  if coords.__type == "Range" then
    return coords
  end

  local instance = {
    extmark_id = nil,
    ns_id = vim.api.nvim_create_namespace("TelekinesisRangeNamespace"),
    __type = "Range",
  }


  setmetatable(instance, {
    __index = function(t, key)
      if key == "start_row" then
        return Range.get_coords(t)[1]
      elseif key == "start_col" then
        return Range.get_coords(t)[2]
      elseif key == "end_row" then
        return Range.get_coords(t)[3]
      elseif key == "end_col" then
        return Range.get_coords(t)[4]
      else
        return Range[key]
      end
    end
  })

  instance:attach(bufnr or 0, coords)

  return instance
end

function Range:get_coords()
  local extmark = vim.api.nvim_buf_get_extmark_by_id(
    self.bufnr,
    self.ns_id,
    self.extmark_id,
    {
      details = true,
    }
  )

  return {
    math.min(extmark[1], extmark[3].end_row),
    math.min(extmark[2], extmark[3].end_col),
    math.max(extmark[1], extmark[3].end_row),
    math.max(extmark[2], extmark[3].end_col),
  }
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
  local row_distance = math.abs(row - self.start_row)

  -- Take perceived distance into account. A character on the same line _feels_ closer.
  local col_distance = math.abs(col - self.start_col) / 4

  return math.sqrt(row_distance ^ 2 + col_distance ^ 2)
end

function Range:is_visible(topline, botline)
  return self.start_row >= topline and self.start_row <= botline
end

function Range:contains(row, col)
  if row < self.start_row or row > self.end_row then
    return false
  end

  if row == self.start_row and col < self.start_col then
    return false
  end

  if row == self.end_row and col > self.end_col then
    return false
  end

  return true
end

function Range:size()
  local lines = self:lines()

  if #lines == 0 then
    return 0
  end

  if #lines == 1 then
    return #lines[1]
  end

  local size = 0

  -- First line
  size = size + (#lines[1] - self.start_col)

  -- Middle lines
  for i = 2, #lines - 1 do
    size = size + #lines[i]
  end

  -- Last line
  size = size + self.end_col

  return size
end

function Range:content()
  local lines = self:lines()

  return table.concat(lines, "\n")
end

function Range:lines()
  local lines = vim.api.nvim_buf_get_text(
    self.bufnr,
    self.start_row,
    self.start_col,
    self.end_row,
    self.end_col,
    {}
  )

  return lines
end

function Range:foreach_line(func)
  local lines = self:lines()
  local result = {}

  for i = self.start_row, self.end_row do
    local line_idx = i - self.start_row + 1

    local start_col = 0
    if i == self.start_row then
      start_col = self.start_col
    end
    local end_col = #lines[line_idx] + start_col

    table.insert(result, { func(lines[line_idx], i, start_col, end_col) })
  end

  return Enumerable:new(result)
end

function Range:select()
  vim.fn.setpos("'<", { self.bufnr, self.start_row + 1, self.start_col + 1, 0 })
  vim.fn.setpos("'>", { self.bufnr, self.end_row + 1, self.end_col, 0 })

  -- `o` to set the cursor to the start of the selection, as this likely keeps
  -- the viewport more stable in most cases
  vim.cmd("normal! gvo")
end

function Range:goto_start()
  logger:debug("Range:goto_start()")

  vim.api.nvim_win_set_cursor(0, { self.start_row + 1, self.start_col })
end

function Range:clear()
  if self.extmark_id then
    vim.api.nvim_buf_del_extmark(self.bufnr, self.ns_id, self.extmark_id)

    self.bufnr = nil
    self.id = nil
  end
end

function Range:attach(bufnr, range)
  local start_row, start_col, end_row, end_col = unpack(range)

  self.bufnr = bufnr
  self.extmark_id = vim.api.nvim_buf_set_extmark(
    self.bufnr,
    self.ns_id,
    start_row,
    start_col,
    {
      end_row = end_row,
      end_col = end_col,
    }
  )
end

return Range
