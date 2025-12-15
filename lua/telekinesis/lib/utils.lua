local Utils = {}

function Utils.abort_operation()
  local keys = vim.api.nvim_replace_termcodes("<Esc>", true, false, true)

  vim.api.nvim_feedkeys(keys, "n", false)
end

return Utils
