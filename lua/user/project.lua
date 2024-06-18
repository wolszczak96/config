local M = {
  "ahmedkhalf/project.nvim",
  event = "VeryLazy",
  after = "telescope.nvim",
}

function M.config()
  if DEFAULT_POPUP == "git" then
    return -- standalone git mode
  end

  require("project_nvim").setup {
    active = true,
    on_config_done = nil,
    manual_mode = false,
    detection_methods = { "pattern" },
    patterns = { ".git" },
    ignore_lsp = {},
    exclude_dirs = {},
    show_hidden = false,
    silent_chdir = true,
    scope_chdir = "global",
  }

  local history = require("project_nvim.utils.history")

  ---@diagnostic disable-next-line: duplicate-set-field -- intentionally overwriting.
  require('project_nvim.project').set_pwd = function (dir, method)
    if dir ~= nil then
      M.last_project = dir
      table.insert(history.session_projects, dir)

      if method == 'telescope' then
        vim.api.nvim_set_current_dir(dir)
      elseif method == 'manual' then
        vim.cmd('lcd ' .. dir)
      end
    end
  end

  if DEFAULT_POPUP == "files" then
    vim.util.files()
  elseif DEFAULT_POPUP == 'projects' then
    local function awaitProjects ()
      if not history.recent_projects then
        vim.defer_fn(awaitProjects, 10)
      else
        vim.util.projects()
      end
    end

    awaitProjects()
  end
end

return M
