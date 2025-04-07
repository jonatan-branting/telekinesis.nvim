local Utils = {}

function Utils.abort_operation()
  vim.api.nvim_feedkeys(
    vim.api.nvim_replace_termcodes("<Esc><Esc>", true, false, true),
    "n", -- non-recursive
    false
  )
end

return Utils
