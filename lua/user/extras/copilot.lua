local M = {
  "zbirenbaum/copilot.lua",
  cmd = "Copilot",
  event = "InsertEnter",
}

function M.config()
  local kbd = vim.util.kbd
  require("copilot").setup {
    panel = {
      keymap = {
        jump_next = "<c-j>",
        jump_prev = "<c-k>",
        accept = "<c-l>",
        refresh = "r",
        open = "<M-CR>",
      },
    },
    suggestion = {
      enabled = true,
      auto_trigger = true,
      keymap = {
        accept = kbd.cmd('tab'),
        accept_word = kbd.opt('tab'),
        accept_line = kbd.cmdShf('tab'),
        next = kbd.opt(']'),
        prev = kbd.opt('['),
        dismiss = kbd.cmdShf('esc'),
      }
    },
    filetypes = {
      markdown = true,
      help = false,
      gitcommit = false,
      gitrebase = false,
      hgcommit = false,
      svn = false,
      cvs = false,
      yaml = true,
      json = true,
      ['.'] = false,
    },
    copilot_node_command = "node",
  }

  -- require("copilot_cmp").setup()
end

return M
