local assert = require("luassert")
local utils = require("test_utils")

local buffer_matches = function(_, arguments)
  local expected = arguments[1]

  local expected_lines = { "" }
  for line in string.gmatch(expected, "[^\r\n]+") do
    table.insert(expected_lines, line)
  end
  expected_lines = utils.normalize_whitespace(expected_lines)

  local actual_lines = utils.get_buf_lines()

  assert.are.same(expected_lines, actual_lines)

  return true
end

assert:register("assertion",  "buffer_matches", buffer_matches)

