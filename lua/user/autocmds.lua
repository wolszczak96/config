TELESCOPE_READY = false

local function loneWord(word)
  return "%f[%a]" .. word .. "%f[%A]"
end

local function shebang()
  if vim.fn.expand('%:e') == '' then
    local bang = vim.fn.getline(1)
    if bang:find "^#!" then
      if bang:find(loneWord "bun") then
        vim.bo.filetype = "typescript"
      elseif bang:find(loneWord "node") then
        vim.bo.filetype = "javascript"
      end
    end
  end
end

local function setScrolloff()
  local h = vim.api.nvim_win_get_height(0)
  vim.wo.scrolloff = math.min(10, math.floor(0.1 * h))
end

local function setSocket()
  vim.util.spawn('ln', { '-sf', vim.api.nvim_get_vvar('servername'), '/tmp/nvimsocket'})
end

local function wezSetBuf()
  local path = vim.fn.expand('%:p')
  if path:find '^/' then
    local ts = vim.util.zsh('date +%s%3N')
    vim.util.wezSetVar('nvim_buf', ts .. ": " .. path)
  end
end

NESTED_LG = false
AWAIT_TELESCOPE = false
local function handleEmpty()
  vim.schedule(function()
    local file = vim.fn.expand('%:p')
    if file == "" or vim.fn.isdirectory(file) == 1 then
      if not vim.util.isTelescope() and #vim.util.getBuffers() == 1 then
        vim.bo.modifiable = false
        vim.wo.relativenumber = false
        if vim.bo.buftype ~= 'quickfix' then
          vim.wo.cursorline = false
          vim.wo.number = false
          if TELESCOPE_READY then
            if DEFAULT_POPUP == 'git' then
              if AWAIT_TELESCOPE then return end
              vim.cmd "qa"
            else vim.util.defaultPopup() end
          else
            AWAIT_TELESCOPE = false
          end
        end
      elseif DEFAULT_POPUP == 'git' and TELESCOPE_READY then
        if vim.util.isTelescope() then
          NESTED_LG = true
          AWAIT_TELESCOPE = false
        end
      end
    elseif not vim.b.term_title then
      vim.wo.cursorline = true
      vim.wo.number = true
      vim.wo.relativenumber = true
      vim.util.kbd.setup()
    elseif NESTED_LG then
      AWAIT_TELESCOPE = true
    end
  end)
end

local function handleBufExit(bufnr)
  if vim.api.nvim_get_option_value('buftype', { buf = bufnr }) == 'quickfix' then
    vim.api.nvim_buf_delete(bufnr, { force = true })
  end
end

local prevBuf = nil
vim.api.nvim_create_autocmd({ "BufEnter" }, {
  pattern = { "*" },
  callback = function()
    shebang()
    wezSetBuf()
    handleEmpty()

    vim.schedule(function()
      if prevBuf and vim.api.nvim_buf_is_valid(prevBuf) then
        handleBufExit(prevBuf)
      end
      prevBuf = vim.api.nvim_get_current_buf()
    end)
  end,
})

vim.api.nvim_create_autocmd({ "BufWinEnter" }, {
  pattern = { "*" },
  callback = function()
    setScrolloff()
    setSocket()
  end,
})

vim.api.nvim_create_autocmd({ "VimResized" }, {
  callback = function()
    setScrolloff()
  end,
})

vim.api.nvim_create_autocmd({ "BufReadPost" }, {
  pattern = 'quickfix',
  callback = function()
    vim.api.nvim_buf_set_keymap(0, 'n', '<CR>', '<CR>', { noremap = true, silent = true })
  end,
})

-- -------- --
-- lunarvim --
-- -------- --
vim.api.nvim_create_autocmd({ "BufWinEnter" }, {
  callback = function()
    vim.cmd "set formatoptions-=cro"
  end,
})

vim.api.nvim_create_autocmd({ "FileType" }, {
  pattern = {
    "netrw",
    "Jaq",
    "qf",
    "git",
    "help",
    "man",
    "lspinfo",
    "oil",
    "spectre_panel",
    "lir",
    "DressingSelect",
    "tsplayground",
    "",
  },
  callback = function()
    vim.cmd [[
      nnoremap <silent> <buffer> q :close<CR>
      set nobuflisted
    ]]
  end,
})

vim.api.nvim_create_autocmd({ "CmdWinEnter" }, {
  callback = function()
    vim.cmd "quit"
  end,
})

vim.api.nvim_create_autocmd({ "VimResized" }, {
  callback = function()
    vim.cmd "tabdo wincmd ="
  end,
})

vim.api.nvim_create_autocmd({ "BufWinEnter" }, {
  pattern = { "*" },
  callback = function()
    vim.cmd "checktime"
  end,
})

vim.api.nvim_create_autocmd({ "TextYankPost" }, {
  callback = function()
    vim.highlight.on_yank { higroup = "Visual", timeout = 40 }
  end,
})

vim.api.nvim_create_autocmd({ "FileType" }, {
  pattern = { "gitcommit", "markdown", "NeogitCommitMessage" },
  callback = function()
    vim.opt_local.wrap = true
    vim.opt_local.spell = true
  end,
})

vim.api.nvim_create_autocmd({ "CursorHold" }, {
  callback = function()
    local status_ok, luasnip = pcall(require, "luasnip")
    if not status_ok then
      return
    end
    if luasnip.expand_or_jumpable() then
      -- ask maintainer for option to make this silent
      -- luasnip.unlink_current()
      vim.cmd [[silent! lua require("luasnip").unlink_current()]]
    end
  end,
})
