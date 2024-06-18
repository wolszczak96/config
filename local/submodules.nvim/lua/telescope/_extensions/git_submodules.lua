local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local entry_display = require("telescope.pickers.entry_display")
local conf = require("telescope.config").values
local Terminal = require("toggleterm.terminal").Terminal

local M = {}

local STANDALONE_OPTS = {
  terminal_opts = {
    float_opts = {
      border = 'none',
      width = function() return vim.o.columns end,
      height = function() return vim.o.lines end,
    }
  },
  layout_config = { width = 0.9999, height = 0.9999 }
}

local setup_opts = {
	git_cmd = "lazygit",
	previewer = true,
  initial_mode = "normal",
	terminal_id = 9,
  terminal_opts = {},
}

local last_fetch = {}

local repos = {}

local picker = nil

local currentOpts = {}
local fallbackToList = false
local standalone = false

function M.show_repos(opts)
	opts = vim.tbl_extend("force", setup_opts, opts or {})

  if opts.standalone and not standalone then
    standalone = true
    opts = vim.tbl_extend("force", opts, STANDALONE_OPTS)
  end

  currentOpts = opts

	M.prepare_repos(function ()
    if #repos == 1 then
      fallbackToList = false
      M.open_git_tool(opts, repos[1][2])
    elseif #repos > 1 then
      local previewer_config = nil
      if opts.previewer == true then
        previewer_config = require("telescope.previewers").new_buffer_previewer({
          define_preview = function(self, entry)
            local dir_name = vim.fn.substitute(vim.fn.getcwd(), "^.*/", "", "")
            local t = {}
            if entry.value == dir_name then
              local s = vim.fn.system("git status -s")
              for chunk in string.gmatch(s, "[^\n]+") do
                t[#t + 1] = chunk
              end
            else
              local s = vim.fn.system("git -C " .. entry.value .. " status -s")
              for chunk in string.gmatch(s, "[^\n]+") do
                t[#t + 1] = chunk
              end
            end
            vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, true, t)
          end,
        })
      end

      picker = pickers
        .new(opts, {
          prompt_title = "Git Submodules",
          finder = M.create_finder(),
          sorter = conf.generic_sorter(opts),
          attach_mappings = function(prompt_buf, map)
            actions.select_default:replace(function()
              fallbackToList = true
              -- for whatever reason any attempt to open an external window (such as lazygit)
              -- shall be done after closing the buffer manually
              actions.close(prompt_buf)
              M.open_git_tool(opts, nil)
            end)

            map('n', 'gf', M.fetch_all)
            map('n', 'p', M.pull_current)
            map('n', 'P', M.push_current)
            map('n', 'ss', M.stash_current)
            map('n', 'sp', M.stash_pop_current)

            return true
          end,
          previewer = previewer_config,
        })

      picker:find()

      if opts.stopinsert then
        vim.cmd("stopinsert")
      end

      -- if last fetch was more than 5 minutes ago, fetch all repos
      if os.time() - (last_fetch[vim.fn.getcwd()] or 0) > 300 then
        M.fetch_all()
      end
    end
  end)
end

function M.end_standalone()
  standalone = false
  fallbackToList = false
end

function M.create_finder()
  return finders.new_table({
    results = repos,
    entry_maker = function(entry)
      local columns = vim.o.columns
      local width = conf.width
        or conf.layout_config.width
        or conf.layout_config[conf.layout_strategy].width
        or columns
      local telescope_width
      if width > 1 then
        telescope_width = width
      else
        telescope_width = math.floor(columns * width)
      end
      local repo_branch_width = math.floor(columns * 0.05)
      local repo_path_width = 40
      local repo_status_width = 5
      local displayer = entry_display.create({
        separator = " | ",
        items = {
          { width = repo_status_width },
          { width = repo_path_width },
          { width = telescope_width - repo_branch_width - repo_path_width - repo_status_width },
          { remaining = true },
        },
      })
      local make_display = function()
        return displayer({
          { entry[1] },
          { entry[2] },
          { entry[3] },
        })
      end

      return {
        value = entry[2],
        ordinal = string.format("%s %s", entry[1], entry[2], entry[3]),
        display = make_display,
      }
    end,
  })
end

function M.redraw()
  if picker and not picker.closed and vim.api.nvim_buf_is_valid(picker.prompt_bufnr) then
    local row = picker:get_selection_row()
    picker:refresh(M.create_finder(), { reset_prompt = true })
    if row > 0 then
      vim.defer_fn(function()
        picker:set_selection(row)
      end, 10)
    end
  end
end

function M.open_git_tool(opts, selection)
	if selection == nil then
		selection = action_state.get_selected_entry().value -- picking the repo_path from the item received
	end
	local dir_name = vim.fn.substitute(vim.fn.getcwd(), "^.*/", "", "")

  local term_opts = {
		cmd = opts.git_cmd,
		close_on_exit = true,
		hidden = true,
		direction = "float",
		count = opts.terminal_id,
    on_close = function()
      if fallbackToList then
        M.show_repos(currentOpts)
        fallbackToList = false
      end
    end
	}

  for k, v in pairs(opts.terminal_opts) do
    term_opts[k] = v
  end

	local git_tool = Terminal:new(term_opts)

	if selection == dir_name then
		git_tool.dir = vim.fn.getcwd()
	else
		git_tool.dir = vim.fn.getcwd() .. "/" .. selection
	end
	git_tool:toggle()

	vim.cmd("stopinsert")
	vim.cmd([[execute "normal i"]])
end

function M.resolve_repo(output)
  local i = 1
  local entering
  local repo_path
  local repo_branch
  local repo_git_status = ""
  local diverge = ""

  for s in string.gmatch(output, "[^" .. "\n" .. "]+") do
    for w in string.gmatch(s, "[^" .. " " .. "]+") do
      if entering == i then
        repo_path = w:gsub("%'", ""):gsub("%'", "")
      elseif entering == i - 1 then
        repo_branch = s
      elseif w == "Entering" then
        entering = i
      elseif w == "Exiting" then
        local branchInfo = diverge .. ' ' .. repo_branch
        return { repo_git_status, repo_path, branchInfo }
      elseif w:match('U') and string.find(repo_git_status, "U") == nil then
        repo_git_status = repo_git_status .. 'U'
      elseif (w == "??" or w == "A") and string.find(repo_git_status, "A") == nil then
        repo_git_status = repo_git_status .. 'A'
      elseif w == 'D' and string.find(repo_git_status, "D") == nil then
        repo_git_status = repo_git_status .. 'D'
      elseif w:match('M') and string.find(repo_git_status, "M") == nil then
        repo_git_status = repo_git_status .. 'M'
      elseif w == "##" then
        if not string.find(diverge, "↑") then
          local ahead = string.match(s, "ahead %d+")
          local number = ahead and string.match(ahead, "%d+") or '0'
          diverge = diverge .. number .. "↑ "
        end
        if not string.find(diverge, "↓") then
          local behind = string.match(s, "behind %d+")
          local number = behind and string.match(behind, "%d+") or '0'
          diverge = diverge .. number .. "↓ "
        end
      end
    end
    i = i + 1
  end
end

function M.get_status_async(workspace, callback)
  local output = {}
  local cwd = vim.fn.getcwd() .. '/' .. workspace
  table.insert(output, "Entering '" .. workspace .. "'")

  vim.util.spawn(
    'git', {'rev-parse', '--abbrev-ref', 'HEAD'},
    function (branch)
      table.insert(output, branch)
      vim.util.spawn(
        'git', {'status', '-bs'},
        function (status)
          table.insert(output, status)
          table.insert(output, "Exiting '" .. workspace .. "'")
          callback(M.resolve_repo(table.concat(output, "\n")))
        end,
        cwd
      )
    end,
    cwd
  )
end

function M.update(workspace)
  M.get_status_async(workspace, function (status)
    for i, repo in ipairs(repos) do
      if repo[2] == workspace then
        repos[i] = status
        return M.redraw()
      end
    end
  end)
end

function M.fetch(workspace)
  local cwd = vim.fn.getcwd() .. '/' .. workspace

  vim.util.spawn(
    'git', { 'fetch' },
    function () M.update(workspace) end,
    cwd
  )
end

local function is_loading(workspace)
  for _, repo in ipairs(repos) do
    if repo[2] == workspace then
      return repo[3]:sub(-3) == " ..."
    end
  end
end

local function set_loading(workspace)
  for _, repo in ipairs(repos) do
    if repo[2] == workspace then
      repo[3] = repo[3] .. " ..."
      return
    end
  end
end

local function fetch_all()
  for _, repo in ipairs(repos) do
    set_loading(repo[2])
    M.fetch(repo[2])
  end

  M.redraw()

  last_fetch[vim.fn.getcwd()] = os.time()
end

function M.for_current(args)
  local entry = action_state.get_selected_entry()

  if entry ~= nil then
    local wsp = entry.value
    local cwd = vim.fn.getcwd() .. '/' .. wsp

    if is_loading(wsp) then return end

    set_loading(wsp)
    M.redraw()

    vim.util.spawn(
      'git', args,
      function () M.update(wsp) end,
      cwd
    )
  end
end

function M.pull_current()
  M.for_current({ 'pull' })
end

function M.push_current()
  M.for_current({ 'push' })
end

function M.stash_current()
  M.for_current({ 'stash', '--include-untracked' })
end

function M.stash_pop_current()
  M.for_current({ 'stash', 'pop' })
end

function M.prepare_repos(callback)
  repos = {}
	local current_dir_name = vim.fn.substitute(vim.fn.getcwd(), "^.*/", "", "")
	local isGitRepo = tonumber(vim.fn.system("git rev-parse 2>/dev/null; echo $?")) == 0 -- if 0, then it's a git repo

  local gitmodulesPath = vim.fn.getcwd() .. "/.gitmodules"
  local gitmodules = vim.fn.filereadable(gitmodulesPath) == 1 and vim.fn.readfile(gitmodulesPath) or nil

  if gitmodules then
    local expectAgg = 0
    local resolvedCount = 0

    for _, line in ipairs(gitmodules) do
      local repo_path = string.match(line, "path = (.*)")

      if repo_path and vim.fn.isdirectory(vim.fn.getcwd() .. '/' .. repo_path) == 1 then
        expectAgg = expectAgg + 1
        local i = expectAgg

        M.get_status_async(repo_path, function (status)
          repos[i] = status
          resolvedCount = resolvedCount + 1
          if resolvedCount == expectAgg then
            callback()
          end
        end)
      end
    end
  elseif not isGitRepo then
    vim.notify("Not a git repository", vim.log.levels.WARN)
    callback()
  else
    repos[1] = { "", current_dir_name, "" }
    callback()
  end
end

if vim.fn.executable("git") == 0 then
	print("telescope-git-submodules: git not in path. Cannot register extension.")
	return
else
  M.prepare_repos(fetch_all)

	return require("telescope").register_extension({
		setup = function(ext_config)
			for k, v in pairs(ext_config) do
				setup_opts[k] = v
			end
		end,
		exports = {
			show = M.show_repos,
      end_standalone = M.end_standalone,
		},
	})
end
