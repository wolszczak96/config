local M = {}
local utils = {}

utils.ternary = function(cond, T, F)
    if cond then return T else return F end
end

utils.ternily = function(obj, F)
    if obj == nil then return F else return obj end
end

utils.includes = function(table, el)
  for _, val in pairs(table) do
    if val == el then return true end
  end
  return false
end


local setup = function(options)
  if options == nil then
    options = {}
  end

  vim.g.virtual_column_column_number = utils.ternily(options.column_number, 80)
  vim.g.virtual_column_overlay = utils.ternily(options.overlay, false)
  vim.g.virtual_column_enabled = utils.ternily(options.enabled, true)
  vim.g.virtual_column_buftype_exclude = utils.ternily(options.buftype_exclude, {})
  vim.g.virtual_column_filetype_exclude = utils.ternily(options.filetype_exclude, {})

  vim.g.virtual_column_virtual_text = {
    virt_text = {{utils.ternily(options.vert_char, "|"), "VirtualColumn"}},
    virt_text_win_col = vim.g.virtual_column_column_number,
    hl_mode = "combine"
  }

  vim.g.__virtual_column_setup_complete = true
end

M.init = function(options)
  if not vim.g.__virtual_column_setup_complete then
    setup(options)
  end

  if not vim.g.virtual_column_namespace then
    vim.g.virtual_column_namespace = vim.api.nvim_create_namespace("virtual_column")
  end

  M.refresh()
end

M.enable = function()
  vim.g.virtual_column_enabled = true
  M.refresh()
end

M.disable = function()
  vim.g.virtual_column_enabled = false
  if vim.g.virtual_column_namespace == nil then
    return
  end

  local bufnr = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_clear_namespace(bufnr, vim.g.virtual_column_namespace, 0, -1)
end

M.refresh = function()
  if
    vim.g.virtual_column_namespace == nil or
    vim.g.__virtual_column_setup_completed == false
  then
    return
  end

  local bufnr = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_clear_namespace(bufnr, vim.g.virtual_column_namespace, 0, -1)

  if vim.g.virtual_column_enabled then
    local buftype = vim.fn.getbufvar(bufnr, '&buftype')
    local filetype = vim.fn.getbufvar(bufnr, '&filetype')

    if
      vim.api.nvim_buf_is_valid(bufnr) and
      vim.api.nvim_buf_is_loaded(bufnr) and
      not utils.includes(vim.g.virtual_column_buftype_exclude, buftype) and
      not utils.includes(vim.g.virtual_column_filetype_exclude, filetype)
    then
      local num_lines = vim.api.nvim_buf_line_count(bufnr)

      for i = 0,num_lines-1,1 do

        if
          vim.g.virtual_column_overlay or
          #vim.api.nvim_buf_get_lines(bufnr, i, i+1, false)[1] <= vim.g.virtual_column_column_number
        then
          vim.schedule_wrap(vim.api.nvim_buf_set_extmark(
              bufnr,
              vim.g.virtual_column_namespace,
              i,
              -1,
              vim.g.virtual_column_virtual_text
            ))
        end
      end
    end
  end
end

return M
