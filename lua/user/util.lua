USER_PARAMS = ''
DEFAULT_POPUP = nil

local M = {}

vim.util = {
  env = function(name)
    local val = vim.fn.getenv(name) or ''
    return type(val) == 'string' and val or ''
  end,

  urlencode = function(str)
    str = string.gsub (str, "\n", "\r\n")
    str = string.gsub (str, "([^%w %-%_%.%~])",
          function (c) return string.format("%%%02X", string.byte(c)) end)
    str = string.gsub (str, " ", "+")

    return str
  end,

  urlify = function (obj)
    if type(obj) == 'string' then
      return 'text=' .. vim.util.urlencode(obj)
    end

    local parts = {}
    for k, v in pairs(obj) do
      local str = (type(v) == 'string' and v) or vim.inspect(v)
      table.insert(parts, k .. '=' .. vim.util.urlencode(str))
    end

    return table.concat(parts, '&')
  end,

  alert = function(obj)
    if USE_HSWSS then
      os.execute("zsh -c 'hswss \"hammerspoon://alert?" .. vim.util.urlify({ text = obj }) .. "\"' &")
    else
      vim.notify(vim.inspect(obj), vim.log.levels.INFO)
    end
  end,

  log = function(obj)
    if USE_HSWSS then
      os.execute("zsh -c 'hswss \"hammerspoon://log?" .. vim.util.urlify({
        source = "vim",
        message = obj
      }) .. "\"' &")
    else
      -- log to ~/.config/nvim/log
      os.execute("echo '" .. vim.inspect(obj) .. "' >> ~/.config/nvim/log")
    end
  end,

  shallowCopy = function(obj)
    local copy = {}
    for k, v in pairs(obj) do
      copy[k] = v
    end
    return copy
  end,

  findWorkspace = function(path)
    if path[1] ~= '/' then path = vim.fn.expand('%:p:h') end
    while vim.fn.isdirectory(path .. '/.git') == 0 do
      path = vim.fn.fnamemodify(path, ':h')
      if path == '/' or path == '' or path == '.' then return nil end
    end
    return path
  end,

  findDir = function(path)
    if path[1] ~= '/' then path = vim.fn.expand('%:p:h') end
    while vim.fn.isdirectory(path) == 0 do
      path = vim.fn.fnamemodify(path, ':h')
    end
    return path
  end,

  projects = function ()
    require('telescope').extensions.projects.projects()
  end,

  submodules = function (opts)
    require('telescope').extensions.git_submodules.show(opts)
  end,

  files = function ()
    require('telescope.builtin').find_files()
  end,

  defaultPopup = function()
    M.defaultPopup(true)
  end,

  isTelescope = function()
    local bufnrs = require('telescope.state').get_existing_prompt_bufnrs()
    return #bufnrs > 0
  end,

  closeTelescope = function()
    require("telescope.pickers")._Picker:close_existing_pickers()

    local current = vim.api.nvim_get_current_buf()
    while not vim.bo.modifiable do
      vim.cmd "q!"
      local next = vim.api.nvim_get_current_buf()
      if next == current then break end
    end
  end,

  closePane = function()
    if vim.util.isTelescope() then
      vim.util.closeTelescope()
    else
      local bufs = vim.util.getBuffers()
      if #bufs == 1 then
        M.handleLastBuffer()
      else
        vim.cmd "q"
      end
    end
  end,

  openTermHere = function()
    local file = vim.fn.expand "%:p"
    if file == "" then
    vim.cmd "ToggleTerm"
    else
      local dir = vim.util.findDir(file)
      vim.cmd("ToggleTerm dir=" .. dir)
    end
  end,

  esc = function (withCmd)
    if vim.bo.buftype == 'quickfix' then
      vim.cmd 'cclose'
    elseif vim.api.nvim_get_mode().mode == 'i' then
      local copilot = require('copilot.suggestion')
      local cmp = require('cmp')
      local handled = false

      if withCmd then
        if copilot.is_visible() then
          copilot.dismiss()
          handled = true
        elseif cmp.visible() then
          cmp.close()
          handled = true
        end
      end

      if not handled then
        local move = vim.fn.col('.') > 1
        vim.cmd('stopinsert')
        if move then vim.util.feedkeys('l') end
      end
    else vim.util.feedkeys('<esc>')
    end
  end,

  tab = function ()
    local copilot = require('copilot.suggestion')
    local cmp = require('cmp')
    if copilot.is_visible() then
      copilot.accept_line()
    elseif cmp.visible() then
      cmp.select_next_item()
    else
      vim.util.feedkeys(vim.fn.col('.') % 2 == 0 and '<space>' or '<space><space>')
    end
  end,

  feedkeys = function (keys, flags)
    vim.api.nvim_feedkeys(
      vim.api.nvim_replace_termcodes(keys, true, false, true),
      flags or 'nt',
      false
    )
  end,

  pgUp = function()
    local h = vim.api.nvim_win_get_height(0)
    local pageH = math.floor(h / 3)
    vim.util.feedkeys(pageH..'k')
  end,

  pgDown = function()
    local h = vim.api.nvim_win_get_height(0)
    local pageH = math.floor(h / 3)
    vim.util.feedkeys(pageH..'j')
  end,

  zsh = function(cmd)
    local ioCmd = io.popen('zsh -c "' .. cmd:gsub('"', '\\"'):gsub('\\', '\\\\') .. '"', 'r')
    if ioCmd == nil then return '' end
    local output = ioCmd:read('*a')
    ioCmd:close()
    return output
  end,

  base64 = function(input)
    local escaped_input = input:gsub('"', '\\"')
    return vim.util.zsh('base64 <<< "' .. escaped_input .. '"')
  end,

  osc = function(code, payload)
    io.write(string.format('\x1b]%s;%s\a', code, payload))
  end,

  wezSetVar = function(name, value)
    vim.util.osc('1337', string.format('SetUserVar=%s=%s', name, vim.util.base64(value)))
  end,

  -- implement a spwn function which calls the callback with the output of the command
  spawn = function(cmd, args, callback, cwd)
    local handle
    local stdout = vim.loop.new_pipe(false)

    local results = {}

    handle = vim.loop.spawn(
      cmd,
      {
        args  = args,
        stdio = {nil, stdout, nil},
        cwd   = cwd,
      },
      vim.schedule_wrap(function()
        stdout:read_stop()
        stdout:close()
        if handle then handle:close() end
        if callback then callback(table.concat(results, '')) end
      end)
    )

    vim.loop.read_start(stdout, function(err, data)
      if not err then
        table.insert(results, data)
      end
    end)
  end,

  open = function(path)
    TELESCOPE_READY = false -- avoid handling empty buffer until the file gets opened

    -- exit the standalone git mode
    require('telescope').extensions.git_submodules.end_standalone()
    DEFAULT_POPUP = nil

    if vim.b.term_title then
      vim.cmd 'q'
    elseif vim.util.isTelescope() then
      require("telescope.pickers")._Picker:close_existing_pickers()
    end

    vim.cmd('edit! ' .. path)

    vim.schedule(function()
      TELESCOPE_READY = true
    end)
  end,

  getBuffers = function ()
    return vim.tbl_map(function(win)
      return vim.api.nvim_win_get_buf(win)
    end, vim.api.nvim_list_wins())
  end,

  isModified = function(bufnr)
    return vim.api.nvim_get_option_value('modified', { buf = bufnr })
  end,

  isTerminal = function(bufnr)
    return vim.api.nvim_get_option_value('buftype', { buf = bufnr }) == 'terminal'
  end,

  cleanupBuffers = function()
    local bufs = vim.util.getBuffers()
    vim.tbl_map(function(buf)
      if not vim.tbl_contains(bufs, buf) then
        if not vim.util.isModified(buf) and not vim.util.isTerminal(buf) then
          vim.api.nvim_buf_delete(buf, {})
        end
      end
    end, vim.api.nvim_list_bufs())
  end,

  isSSH = function()
    return vim.util.env('SSH_TTY') ~= ''
  end,
}

function M.handleLastBuffer()
  vim.util.cleanupBuffers()
  vim.cmd "bd"
end

function M.defaultPopup(shouldOpen)
  -- cwd setup
  local file = vim.fn.expand('%:p')
  local path = file == "" and vim.fn.expand('%:p:h') or file
  local project = vim.util.findWorkspace(path)
  vim.api.nvim_set_current_dir(project or vim.util.findDir(path))

  -- global popup choice
  if file == "" then
    if USER_PARAMS:find("--git") then
      DEFAULT_POPUP = 'git'
      USER_PARAMS = ''
      if shouldOpen then vim.util.submodules() end
    elseif project then
      DEFAULT_POPUP = 'files'
      if shouldOpen then vim.util.files() end
    else
      DEFAULT_POPUP = 'projects'
      if shouldOpen then vim.util.projects() end
    end
  elseif vim.fn.isdirectory(file) == 1 then
    vim.bo.modifiable = false
    DEFAULT_POPUP = 'files'
    if shouldOpen then vim.util.files() end
  end
end

USER_PARAMS = vim.util.env('NVIM_USER_PARAMS')
M.defaultPopup()
