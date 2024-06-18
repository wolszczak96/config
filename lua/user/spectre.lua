local M = {
  "nvim-pack/nvim-spectre",
  event = "VeryLazy",
}

function M.config()
  require('spectre').setup({})
end

return M
