local M = {
  'williamboman/mason-lspconfig.nvim',
  dependencies = {
    'williamboman/mason.nvim',
  },
}


function M.config()
  require('mason').setup {
    ui = {
      border = 'rounded',
    },
  }

  require('mason-lspconfig').setup {
    ensure_installed = {
      'lua_ls',
      'cssls',
      'html',
      'tsserver',
      'pyright',
      'bashls',
      'jsonls',
      'jdtls',
    },
  }
end

return M
