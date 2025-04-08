local Utils = {}

function Utils.abort_operation()
  local text = "<Esc><Esc>"
  local feed_opts = "mtx"
  local to_feed = vim.api.nvim_replace_termcodes(text, true, false, true)

  vim.api.nvim_feedkeys(to_feed, feed_opts, false)
end

return Utils
