local M = {
  "virtual-column.nvim",
  dir = "~/.config/nvim/local/virtual-column.nvim",
}

function M.config()
  require('virtual-column').init({
    column_number = 80,
    overlay = false,
    vert_char = "│",
    enabled = true,
    buftype_exclude = { 'prompt', 'nofile', 'quickfix' },
    filetype_exclude = { '' },
  })
end

return M
