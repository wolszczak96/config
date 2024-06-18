local M = {
  'wakatime/vim-wakatime',
  lazy = false,
}

function M.enabled()
  return not vim.util.isSSH()
end

return M
