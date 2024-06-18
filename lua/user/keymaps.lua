local noremap = { noremap = true, silent = true }
local loud = { noremap = true, silent = false }

local function bind(mode, lhs, rhs, opts)
  if rhs == nil then
    vim.notify("Invalid mapping: " .. lhs, vim.log.levels.ERROR)
  else
    vim.keymap.set(mode, lhs, rhs, opts or noremap)
  end
end

vim.g.mapleader = " "
vim.g.maplocalleader = " "

local function unbind(...)
  local keys = {...}
  local modes = (type(keys[1]) == "table" and table.remove(keys, 1)) or {"n","v"}
  for _, key in ipairs(keys) do
    bind(modes, key, "<Nop>")
  end
end

local function chord(base)
  return function(key, keys) return '<' .. base .. '-' .. key .. '>' .. (keys or '') end
end

local function seq(base, simple)
  if simple then
    return function(keys) return '<' .. base .. '>' .. (keys or '') end
  else
    return function(key, keys)
      if #key > 1 and not key:find("^<.*>$") then key = '<' .. key .. '>' end
      return '<' .. base .. '>' .. key .. (keys or '')
    end
  end
end

local function charset(chars)
  local set = {}
  for index = 1, #chars do
    set[chars:sub(index, index)] = true
  end
  return set
end

local NO_UNBIND = charset('hjkl:iavq@%f1234567890')
local CTL_NO_UNBIND = charset('t')

local esc = seq('esc', true)

local function run(...)
  return vim.iter({...}):map(function (command)
    return '<cmd>' .. command .. '<cr>'
  end):join('')
end

local function quickmap(modes) return function(...) return bind(modes, ...) end end

local n = quickmap("n")
local v = quickmap("v")
local i = quickmap("i")
local t = quickmap("t")

local all = quickmap({ "n", "v", "i", "t", "c" })

local i_helper = function (lhs, preserve, opts)
  i(lhs, function()
    vim.util.esc()
    vim.api.nvim_input(lhs)
    if preserve then vim.defer_fn(function() vim.api.nvim_input('i') end, 0) end
  end, opts)
end

local ni_helper = function(lhs, rhs, preserveMode, opts)
  n(lhs, rhs, opts)
  i_helper(lhs, preserveMode:match('i'), opts)
end
local ni = function (lhs, rhs, opts) ni_helper(lhs, rhs, '', opts) end
local nI = function (lhs, rhs, opts) ni_helper(lhs, rhs, 'i', opts) end

local nV = quickmap({ "n", "v" })
local nv = function (lhs, rhs, opts)
  n(lhs, rhs, opts)
  v(lhs, esc(rhs), opts)
end

local nvi_helper = function(lhs, rhs, preserveMode, opts)
  local nv_ = preserveMode:match('v') and nV or nv
  nv_(lhs, rhs, opts)
  i_helper(lhs, preserveMode:match('i'), opts)
end
local nvi = function (lhs, rhs, opts) nvi_helper(lhs, rhs, '', opts) end
local nVi = function (lhs, rhs, opts) nvi_helper(lhs, rhs, 'v', opts) end
local nvI = function (lhs, rhs, opts) nvi_helper(lhs, rhs, 'i', opts) end
local nVI = function (lhs, rhs, opts) nvi_helper(lhs, rhs, 'vi', opts) end

local opt = chord("M")
local ctl = chord("C")
local shf = chord("S")
local ctlShf = chord("C-S")

local cmd = seq("f13")
local cmdShf = seq("f14")
local cmdOpt = seq(opt("f15"))
local cmdCtl = seq(ctl("f16"))

vim.util.kbd = {
  opt = opt,
  ctl = ctl,
  shf = shf,
  ctlShf = ctlShf,
  cmd = cmd,
  cmdShf = cmdShf,
  cmdCtl = cmdCtl,
  cmdOpt = cmdOpt,
  esc = esc,
  run = run,
}

for charcode = 32, 126 do
  local key = string.char(charcode)
  if not NO_UNBIND[key] then
    unbind(key)
  end
end

for charcode = 32, 126 do
  local key = string.char(charcode)
  if not CTL_NO_UNBIND[key] then
    unbind(ctl(key))
  end
end

-- unbind replacements with R key
for charcode = 32, 126 do
  local key = 'r' .. string.char(charcode)
  unbind(key)
end

unbind('gg', '<bs>')

-- better escape
n(esc(), run('lua vim.util.esc()'))
v(esc(), esc())
i(esc(), run('lua vim.util.esc()'))
i(cmd(esc()), run('lua vim.util.esc(true)'))

-- custom escape sequences
-- all('<f15><esc>[nvim_sequence', vim.util.nvim_sequence)

-- insert mode
i('<tab>', run('lua vim.util.tab()'))

-- visual mode
v('i', 'I')
n('b', ctl('v'))
n('n', 'V')
nvi(cmd('a'), 'ggVG')
v('<bs>', '"_d')

-- normal mode
unbind('cw')
n('pwf', run('echo expand("%:p")'))
n('pwd', run('echo getcwd()'))
-- TODO: 'pwr' - display root dir of current file's project
--       'pww' - display workspace directory
--       'cd.' - change to the directory of the current file
--       'cdr' - change to the root dir of current file's project
--       'cdw' - change to the workspace directory

-- indentation
n('<tab>', '>>')
n(shf('tab'), '<<')
v('<tab>', '>gv')
v(shf('tab'), '<gv')

-- go to the end of file in all modes
nVi(cmd('j'), 'G')

-- go to the beginning of file in all modes
nVi(cmd('k'), "gg")

-- page up and page down in all modes
nVi(opt('j'), run('lua vim.util.pgDown()'))
nVi(opt('k'), run('lua vim.util.pgUp()'))

-- jumps navigation
nv(cmd('['), ctl('o'))
nv(cmd(']'), ctl('i'))
n(cmd('.'), 'nzz')
n(cmd(','), 'Nzz')

-- end of line in all modes
ni(cmd('l'), "$l")
v(cmd('l'), "$")

-- beginning of line in all modes
nVi(cmd('h'), '^')

-- prev word in all modes
nVi(opt('h'), "bge")

-- next word in all modes
nVi(opt('l'), "we")

-- backspace in normal mode
n(ctl('u'), '"_d0')
n(ctl('w'), '"_db')
n(ctl('bs'), '"_dh')
n('dd', '"_dd')

-- comment line
ni(cmd('/'), "<Plug>(comment_toggle_linewise_current)$l")
v(cmd('/'), "<Plug>(comment_toggle_linewise_visual)")

-- move lines
n(shf('j'), ":m .+1<cr>==")
n(shf('k'), ":m .-2<cr>==")
v(shf('j'), ":m'>+<cr>gv=gv")
v(shf('k'), ":m-2<cr>gv=gv")

-- return behavior
ni(cmd('cr'), 'o')
ni(cmdShf('cr'), 'O')

-- copy, cut
v(cmd('c'), "y<esc>")
v(cmd('x'), "d<esc>")
n(cmd('x'), 'dd')
n(cmd('c'), 'yy')

-- undo, redo
nvi(cmd('z'), 'u')
nvi(cmdShf('z'), '<c-r>')

-- format, save and quit
nvi(cmd('s'), run("lua require('conform').format()", 'w'))
nvi(cmdShf('s'), run('w!'))
nvi(cmd('w'), run('lua vim.util.closePane()'))
nvi(cmdShf('w'), run('q!'))
nvi(cmd('e')..'f', run("lua require('conform').format()"))
nvi(cmd('e')..'s', run('w')) -- save without formatting
nvi(cmd('e'), '<Nop>')
n('ef', run('EslintFixAll'))

function vim.util.kbd.setup()
  -- terminal
  n('tt', run('lua vim.util.openTermHere()'))
  n('tr', run('ToggleTerm'))
  t(cmd('w'), ctl('c')..ctl('d'))
  t(opt('j'), '<PageDown>')
  t(opt('k'), '<PageUp>')

  -- Search
  nvi(cmd('f'), '/', loud)
  nvi(cmd('o'), run('Telescope find_files'))
  nvi(cmdShf('f'), run('Telescope live_grep'))
  nvi(cmdShf('o'), run('Telescope oldfiles')) -- recent files
  nvi(cmd('p'), run("lua vim.util.projects()"))
  nvi(cmdShf('g'), run("lua vim.util.submodules()"))

  -- Replace
  nvi(cmd('r'), ':%s/', loud)
  nvi(cmdShf('r'), run('Spectre'))
  n('ra', run("lua require('spectre.actions').run_replace()"))
  n('rl', run("lua require('spectre.actions').run_current_replace()"))

  -----------------

  -- splits and tabs
  nvi(cmd('\\'), run('vs')) -- vertical split
  nvi(cmdShf('\\'), '<c-w>s') -- horizontal split
  nvi(cmd('t'), run('tabnew', 'Telescope find_files')) -- new tab
  nvi(cmdShf('t'), run('tabnew #')) -- reopen last closed tab -- TODO: FIX THAT

  nvi(ctl('h'), 'gT') -- prev tab
  nvi(ctl('l'), 'gt') -- next tab

  -- splits navigation
  nvi(cmdShf('h'), '<c-w>h')
  nvi(cmdShf('j'), '<c-w>j')
  nvi(cmdShf('k'), '<c-w>k')
  nvi(cmdShf('l'), '<c-w>l')

  -- rebind ':' to default (command mode)
  nV(':', ':')
end

-- if default popup is git, we're in a standalone git state - disable command mode
if DEFAULT_POPUP == 'git' then
  unbind(':')
else
  vim.util.kbd.setup()
  function vim.util.kbd.setup() end
end
