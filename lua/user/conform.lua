local M = {
  "stevearc/conform.nvim",
  event = "VeryLazy",
}

function M.config()
  require("conform").setup({
    formatters_by_ft = {
      lua = { "stylua" },
      ["javascript"] = { "prettierd" },
      ["javascriptreact"] = { "prettierd" },
      ["typescript"] = { "prettierd" },
      ["typescriptreact"] = { "prettierd" },
      ["vue"] = { "prettierd" },
      ["css"] = { "prettierd" },
      ["scss"] = { "prettierd" },
      ["less"] = { "prettierd" },
      ["html"] = { "prettierd" },
      ["json"] = { "prettierd" },
      -- ["jsonc"] = { "prettierd" },
      ["yaml"] = { "prettierd" },
      ["markdown"] = { "prettierd" },
      ["graphql"] = { "prettierd" },
    },
  })
end

return M
