local M = {
  "catppuccin/nvim",
  as = "catppuccin",
  lazy = false,
  priority = 1000,
}

local flavour_map = {
  dark = "frappe",
  light = "latte",
}

function vim.util.set_theme(flavour)
  flavour = flavour_map[flavour] or flavour
  require('catppuccin').setup({
    transparent_background = true,
    flavour = flavour,
  })
  vim.cmd.colorscheme 'catppuccin'

  vim.api.nvim_set_hl(0, 'VirtualColumn', {
    fg = vim.api.nvim_get_hl(0, { name = 'ColorColumn' }).bg,
  })

  if flavour == 'latte' then
    vim.api.nvim_set_hl(0, 'CursorLine', {
      bg = '#e5e7ec'
    })
  end
end

function M.config()
  vim.util.set_theme(CATPPUCCIN_FLAVOUR)
end

return M
