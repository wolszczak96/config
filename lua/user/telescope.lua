local M = {
  "nvim-telescope/telescope.nvim",
  dependencies = { { "nvim-telescope/telescope-fzf-native.nvim", build = "make", lazy = true } },
}

function M.config()
  local icons = require "user.icons"
  local actions = require "telescope.actions"
  local action_state = require "telescope.actions.state"

  function actions.delete_file(prompt_bufnr)
    local current_picker = action_state.get_current_picker(prompt_bufnr)
    current_picker:delete_selection(function(selection)
      if vim.fn.confirm('Delete file ' .. selection.value .. '?', '&Yes\n&No', 2) == 1 then
        vim.fn.delete(selection.path)
      end
    end)
  end

  local unmap = {
    [vim.util.kbd.cmd('\\')] = actions.nop,
    [vim.util.kbd.cmdShf('\\')] = actions.nop,
    [vim.util.kbd.cmd('t')] = actions.nop,
    [vim.util.kbd.cmdShf('t')] = actions.nop,
    [vim.util.kbd.cmd('[')] = actions.nop,
    [vim.util.kbd.cmd(']')] = actions.nop,
  }

  require("telescope").setup {
    defaults = {
      layout_strategy = "horizontal",
      sorting_strategy = "ascending",
      dynamic_preview_title = true,
      prompt_prefix = icons.ui.Telescope .. " ",
      selection_caret = icons.ui.Forward .. " ",
      entry_prefix = "   ",
      initial_mode = "insert",
      selection_strategy = "reset",
      color_devicons = true,
      vimgrep_arguments = {
        "rg",
        "--color=never",
        "--no-heading",
        "--with-filename",
        "--line-number",
        "--column",
        "--smart-case",
        "--hidden",
        "--glob=!.git/",
      },

      file_ignore_patterns = { ".git/", "node_modules/", '/.env', '/.env.*', '/*.png', '/*.jpg' },

      mappings = {
        i = vim.tbl_extend('force', unmap, {
          [vim.util.kbd.cmd('<esc>')] = vim.util.closeTelescope,
          [vim.util.kbd.cmd('w')] = vim.util.closeTelescope,
        }),
        n = vim.tbl_extend('force', unmap, {
          ["<esc>"] = actions.nop,
          [vim.util.kbd.cmd('<esc>')] = vim.util.closeTelescope,
          [vim.util.kbd.cmd('w')] = vim.util.closeTelescope,
          ["j"] = actions.move_selection_next,
          ["k"] = actions.move_selection_previous,
        }),
      },
    },
    pickers = {
      live_grep = {
        hidden = true,
      },

      find_files = {
        hidden = true,
        mappings = {
          i = {
           [vim.util.kbd.ctl('u')] = actions.delete_file,
          },
          n = {
           [vim.util.kbd.ctl('u')] = actions.delete_file,
          },
        },
      },

      buffers = {
        theme = "dropdown",
        previewer = false,
        initial_mode = "normal",
        mappings = {
          i = {
            [vim.util.kbd.ctl('u')] = actions.delete_buffer,
          },
          n = {
            [vim.util.kbd.ctl('u')] = actions.delete_buffer,
          },
        },
      },

      planets = {
        show_pluto = true,
        show_moon = true,
      },

      colorscheme = {
        enable_preview = true,
      },

      lsp_references = {
        theme = "dropdown",
        initial_mode = "normal",
      },

      lsp_definitions = {
        theme = "dropdown",
        initial_mode = "normal",
      },

      lsp_declarations = {
        theme = "dropdown",
        initial_mode = "normal",
      },

      lsp_implementations = {
        theme = "dropdown",
        initial_mode = "normal",
      },
    },
    extensions = {
      fzf = {
        fuzzy = true, -- false will only do exact matching
        override_generic_sorter = true, -- override the generic sorter
        override_file_sorter = true, -- override the file sorter
        case_mode = "smart_case", -- or "ignore_case" or "respect_case"
      },

      git_submodules = {
        terminal_opts = {
          name="lazygit"
        }
      },
    },
  }
end

return M
