local M = {
  "neovim/nvim-lspconfig",
  dependencies = {
    { "folke/neodev.nvim" },
  },
}

local function float_list(itemsList, _title)
  if not itemsList or #itemsList == 0 then
    return
  end

  -- deduplicate based on path+line
  local seen = {}
  local items = {}
  for _, item in ipairs(itemsList) do
    local key = item.filename .. ':' .. item.lnum
    if not seen[key] then
      seen[key] = true
      -- item.filename = ' ' .. item.filename -- dummy padding for better display
      table.insert(items, item)
    end
  end

  if #items == 1 then
    local item = items[1]
    vim.api.nvim_set_current_buf(vim.uri_to_bufnr(item.user_data.targetUri))
    vim.api.nvim_win_set_cursor(0, { item.lnum, item.col - 1 })
    return
  end

  vim.fn.setqflist(items)

  local width = vim.api.nvim_win_get_width(0) - 3
  local height = math.min(10, #items)

  local winpos = vim.fn.win_screenpos(0)
  local col = winpos[2]
  local row = winpos[1] + vim.fn.line('.') - vim.fn.line("w0")

  if vim.o.lines / 2 < row then
    row = row - height - 2
  else
    row = row + 1
  end


  local opts = {
    relative = 'editor',
    width = width,
    height = height,
    row = row,
    col = col,
    style = 'minimal',
    border = 'rounded'
  }

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_option_value('buftype', 'quickfix', { buf = buf })
  vim.api.nvim_open_win(buf, true, opts)
  vim.cmd('copen')
end


function vim.lsp.buf.definition_float()
  vim.lsp.buf.definition({
    on_list = function(args) float_list(args.items, "Go to definition") end,
  })
end

function vim.lsp.buf.declaration_float()
  vim.lsp.buf.declaration({
    on_list = function(args) float_list(args.items, "Go to declaration") end,
  })
end

function vim.lsp.buf.implementation_float()
  vim.lsp.buf.implementation({
    on_list = function(args) float_list(args.items, "Go to implementation") end,
  })
end

function vim.lsp.buf.references_float()
  vim.lsp.buf.references(nil, {
    on_list = function(args) float_list(args.items, "References") end,
  })
end

local function lsp_keymaps(bufnr)
  local opts = { noremap = true, silent = true }
  local keymap = vim.api.nvim_buf_set_keymap
  keymap(bufnr, "n", "gD", "<cmd>lua vim.lsp.buf.declaration_float()<CR>", opts)
  keymap(bufnr, "n", "gd", "<cmd>lua vim.lsp.buf.definition_float()<CR>", opts)
  keymap(bufnr, "n", "?", "<cmd>lua vim.lsp.buf.hover()<CR>", opts)
  keymap(bufnr, "n", "gi", "<cmd>lua vim.lsp.buf.implementation_float()<CR>", opts)
  keymap(bufnr, "n", "gr", "<cmd>lua vim.lsp.buf.references_float()<CR>", opts)
  keymap(bufnr, "n", "!", "<cmd>lua vim.diagnostic.open_float()<CR>", opts)
end

local function on_attach(client, bufnr)
  lsp_keymaps(bufnr)

  -- TODO: reenable this after upgrade to nvim 0.10
  -- if client.supports_method "textDocument/inlayHint" then
  --   vim.lsp.inlay_hint.enable(bufnr, true)
  -- end
end

local function common_capabilities()
  local capabilities = vim.lsp.protocol.make_client_capabilities()
  capabilities.textDocument.completion.completionItem.snippetSupport = true
  return capabilities
end

function vim.util.toggle_inlay_hints()
  local bufnr = vim.api.nvim_get_current_buf()
  vim.lsp.inlay_hint.enable(bufnr, not vim.lsp.inlay_hint.is_enabled(bufnr))
end

function M.config()
  local wk = require "which-key"
  wk.register {
    ["ca"] = { "<cmd>lua vim.lsp.buf.code_action()<cr>", "Code Action" },
    ["<leader>lf"] = {
      "<cmd>lua vim.lsp.buf.format({async = true, filter = function(client) return client.name ~= 'typescript-tools' end})<cr>",
      "Format",
    },
    ["<leader>li"] = { "<cmd>LspInfo<cr>", "Info" },
    ["<leader>lj"] = { "<cmd>lua vim.diagnostic.goto_next()<cr>", "Next Diagnostic" },
    ["<leader>lh"] = { "<cmd>lua vim.util.toggle_inlay_hints()<cr>", "Hints" },
    ["<leader>lk"] = { "<cmd>lua vim.diagnostic.goto_prev()<cr>", "Prev Diagnostic" },
    ["<leader>ll"] = { "<cmd>lua vim.lsp.codelens.run()<cr>", "CodeLens Action" },
    ["<leader>lq"] = { "<cmd>lua vim.diagnostic.setloclist()<cr>", "Quickfix" },
    ["<f2>"] = { "<cmd>lua vim.lsp.buf.rename()<cr>", "Rename" },
  }

  local lspconfig = require "lspconfig"
  local icons = require "user.icons"

  local servers = {
    "lua_ls",
    "cssls",
    "html",
    "tsserver",
    "eslint",
    "pyright",
    "bashls",
    "jsonls",
    "yamlls",
    'jdtls',
  }

  local default_diagnostic_config = {
    signs = {
      active = true,
      values = {
        { name = "DiagnosticSignError", text = icons.diagnostics.Error },
        { name = "DiagnosticSignWarn", text = icons.diagnostics.Warning },
        { name = "DiagnosticSignHint", text = icons.diagnostics.Hint },
        { name = "DiagnosticSignInfo", text = icons.diagnostics.Information },
      },
    },
    virtual_text = false,
    update_in_insert = false,
    underline = true,
    severity_sort = true,
    float = {
      focusable = true,
      style = "minimal",
      border = "rounded",
      source = "always",
      header = "",
      prefix = "",
    },
  }

  vim.diagnostic.config(default_diagnostic_config)

  for _, sign in ipairs(vim.tbl_get(vim.diagnostic.config(), "signs", "values") or {}) do
    vim.fn.sign_define(sign.name, { texthl = sign.name, text = sign.text, numhl = sign.name })
  end

  vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, { border = "rounded" })
  vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(vim.lsp.handlers.signature_help, { border = "rounded" })
  require("lspconfig.ui.windows").default_options.border = "rounded"

  for _, server in pairs(servers) do
    local opts = {
      on_attach = on_attach,
      capabilities = common_capabilities(),
    }

    local require_ok, settings = pcall(require, "user.lspsettings." .. server)
    if require_ok then
      opts = vim.tbl_deep_extend("force", settings, opts)
    end

    if server == "lua_ls" then
      require("neodev").setup {}
    end

    lspconfig[server].setup(opts)
  end
end

return M
