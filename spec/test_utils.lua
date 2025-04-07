local M = {}

 function M.normalize_whitespace(lines)
  local min_leading_whitespace = 999
  for _, line in ipairs(lines) do
    local leading_whitespace = line:match("^(%s*)")

    if not line:match("^%s*$") then
      min_leading_whitespace = math.min(min_leading_whitespace, #leading_whitespace + 1)
    end
  end

  local normalized_lines = {}
  for i, line in ipairs(lines) do
    normalized_lines[i] = line:sub(min_leading_whitespace)
  end

  return normalized_lines
end

function M.feed(text, feed_opts)
  feed_opts = feed_opts or "mtx"
  local to_feed = vim.api.nvim_replace_termcodes(text, true, false, true)

  vim.api.nvim_feedkeys(to_feed, feed_opts, false)
end

function M.setup_buffer(str, filetype)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_option(buf, "filetype", filetype)
  vim.api.nvim_command("buffer " .. buf)

  -- Add an empty line to make the diff easier to read, otherwise the indentation will be off
  local input = { "" }
  for line in string.gmatch(str, "[^\r\n]+") do
    table.insert(input, line)
  end

  input = M.normalize_whitespace(input)

  vim.api.nvim_buf_set_lines(0, 0, -1, true, input)

  return buf
end

function M.get_buf_lines()
  local lines = vim.api.nvim_buf_get_lines(0, 0, vim.api.nvim_buf_line_count(0), false)

  lines = M.normalize_whitespace(lines)

  return lines
end

function M.get_buf()
  local lines = M.get_buf_lines()

  return table.concat(lines, "\n")
end

function M.script_path()
  local str = debug.getinfo(2, "S").source:sub(2)
  return str:match(("(.*%s)"):format("/"))
end

return M
