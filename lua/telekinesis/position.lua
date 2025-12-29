local logger = require("telekinesis").logger()

local Position = {}

function Position.from_visual_selection() end

function Position:new(bufnr, row, col)
  local instance = {
    extmark_id = nil,
    ns_id = vim.api.nvim_create_namespace("TelekinesisPositionNamespace"),
    __type = "Position",
  }

  setmetatable(instance, {
    __index = function(t, key)
      if key == "row" then
        return Position.get_coords(t)[1]
      elseif key == "col" then
        return Position.get_coords(t)[2]
      else
        return Position[key]
      end
    end,
  })

  instance:attach(bufnr or 0, row, col)

  return instance
end

function Position:get_coords()
  local extmark = vim.api.nvim_buf_get_extmark_by_id(self.bufnr, self.ns_id, self.extmark_id, {
    details = true,
  })

  return {
    extmark[1],
    extmark[2],
  }
end

function Position:is_before(row, col)
  return (self.row < row) or (self.row == row and self.col < col)
end

function Position:is_after(row, col)
  return (self.row > row) or (self.row == row and self.col > col)
end

function Position:distance(row, col)
  local row_distance = math.abs(row - self.row)

  -- Take perceived distance into account. A character on the same line _feels_ closer.
  local col_distance = math.abs(col - self.col) / 4

  return math.sqrt(row_distance ^ 2 + col_distance ^ 2)
end

function Position:is_visible(topline, botline)
  return self.row >= topline and self.row <= botline
end

function Position:_goto()
  logger:debug("Position:_goto()")

  vim.api.nvim_win_set_cursor(0, { self.row + 1, self.col })
end

function Position:clear()
  if self.extmark_id then
    vim.api.nvim_buf_del_extmark(self.bufnr, self.ns_id, self.extmark_id)

    self.bufnr = nil
    self.extmark_id = nil
  end
end

function Position:attach(bufnr, row, col)
  self:clear()

  self.bufnr = bufnr
  self.extmark_id = vim.api.nvim_buf_set_extmark(self.bufnr, self.ns_id, row, col, {})
end

return Position
