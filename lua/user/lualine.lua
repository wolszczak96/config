local M = {
  "nvim-lualine/lualine.nvim",
  dependencies = {
    "AndreM222/copilot-lualine",
  },
}

function M.config()
  if DEFAULT_POPUP == 'git' then
    -- disable status line when in standalone git window
    vim.o.laststatus = 0
    return
  end

  local cond = {}
  function cond.in_buffer()
    return vim.fn.empty(vim.fn.expand('%:t')) ~= 1
      and vim.bo.filetype ~= ''
  end
  function cond.bigscreen()
    return vim.fn.winwidth(0) > 80
  end
  function cond.in_buffer_and_bigscreen()
    return cond.in_buffer() and cond.bigscreen()
  end

  -- Config
  local config = {
    options = {
      -- Disable section and component separators
      component_separators = '',
      section_separators = '',
      theme = 'auto'
    },
    sections = {
      -- these are to remove the defaults
      lualine_a = {},
      lualine_b = {},
      lualine_y = {},
      lualine_z = {},
      -- These will be filled later
      lualine_c = {},
      lualine_x = {},
    },
    inactive_sections = {
      -- these are to remove the defaults
      lualine_a = {},
      lualine_b = {},
      lualine_y = {},
      lualine_z = {},
      lualine_c = {},
      lualine_x = {},
    },
  }

  -- Inserts a component in lualine_c at left section
  local function ins_left(component)
    table.insert(config.sections.lualine_c, component)
  end

  -- Inserts a component in lualine_x at right section
  local function ins_right(component)
    table.insert(config.sections.lualine_x, component)
  end

  ins_left {
    function() return ' ' end,
    padding = {},
  }

  ins_left {
    'branch',
    icon = '',
    color = 'Search',
    separator = { left = '', right = '' },
  }

  ins_left {
    'filesize',
    cond = cond.in_buffer,
    color = 'FloatFooter',
  }

  ins_left {
    'filename',
    cond = cond.in_buffer,
    color = 'Title',
  }

  ins_left {
    'location',
    cond = cond.in_buffer,
  }

  ins_left {
    'progress',
    cond = cond.in_buffer,
    color = 'FloatFooter',
  }

  ins_left {
    'diagnostics',
    sources = { 'nvim_diagnostic' },
    symbols = { error = ' ', warn = ' ', info = ' ' },
  }

  -- ------------- --
  -- RIGHT SECTION --
  -- ------------- --
  ins_right {
    'copilot',
    color = 'MoreMsg',
    cond = cond.in_buffer,
  }

  ins_right {
    -- LSP name
    function()
      local msg = '' -- 'No Active Lsp'
      local buf_ft = vim.nvim_get_option_value('filetype', { buf = 0 })
      local clients = vim.lsp.get_clients()
      if next(clients) == nil then
        return msg
      end
      for _, client in ipairs(clients) do
        local filetypes = client.config.filetypes
        if filetypes and vim.fn.index(filetypes, buf_ft) ~= -1 then
          return '  '..client.name
        end
      end
      return msg
    end,
    color = { gui = 'bold' },
  }

  ins_right {
    'o:encoding',
    cond = cond.in_buffer_and_bigscreen,
    color = 'FloatFooter',
  }

  ins_right {
    'fileformat',
    fmt = string.upper,
    icons_enabled = false,
    color = 'FloatFooter',
    cond = cond.in_buffer_and_bigscreen,
  }

  ins_right {
    'diff',
    symbols = { added = ' ', modified = '󰝤 ', removed = ' ' },
    cond = cond.in_buffer_and_bigscreen,
  }

  ins_right {
    function() return ' ' end,
    padding = {},
  }

  require("lualine").setup(config)
end

return M
