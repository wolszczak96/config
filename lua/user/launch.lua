vim.g.loaded_netrwPlugin = 1
vim.g.loaded_netrw = 1
vim.g.loaded_netrwSettings = 1
vim.g.loaded_netrwFileHandlers = 1
vim.g.loaded_netrw_gitignore = 1

vim.opt.shortmess:append("I")

-- websocket communication with hammerspoon (hswss). Should be disabled if it's not in PATH
USE_HSWSS = not vim.util.isSSH()

-- global colorscheme default
CATPPUCCIN_FLAVOUR = 'frappe'
if vim.loop.os_uname().sysname == 'Darwin' then
  local defaultsCmd = io.popen('defaults read -g AppleInterfaceStyle 2>/dev/null')
  if defaultsCmd then
    CATPPUCCIN_FLAVOUR = defaultsCmd:read('*a'):match('Dark') and 'frappe' or 'latte'
    defaultsCmd:close()
  end
end

-- lazy helper
LAZY_PLUGIN_SPEC = {}
function spec(item)
  if item.enabled ~= false then
    table.insert(LAZY_PLUGIN_SPEC, { import = item })
  end
end
