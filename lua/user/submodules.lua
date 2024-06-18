local M = {
  "submodules.nvim",
  dir = '~/.config/nvim/local/submodules.nvim',
  event = "VeryLazy",
  after = "telescope.nvim",
  dependencies = "akinsho/toggleterm.nvim",
}

function M.config()
  require('telescope').load_extension('git_submodules')

  TELESCOPE_READY = true

  if DEFAULT_POPUP == 'git' then
    vim.util.submodules({ standalone = true })
  end
end

return M

