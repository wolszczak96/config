local BYTE_MAP = {
  ["110"] = "n",
  ["105"] = "i",
  ["118"] = "v",
  ["99"] = "c",
  ["116"] = "t",
  ["115"] = "s",
  ["22"] = "b",
  ["86"] = "l",
  ["82"] = "r",
}

local DEFAULT_CURSOR = vim.opt.guicursor

function vim.util.getMode()
  local byte = tostring(string.byte((vim.api.nvim_get_mode().mode):sub(1, 1)))
  return BYTE_MAP[byte] or byte
end

local function setTitle(title)
  if vim.opt.titlestring ~= title then
    vim.opt.titlestring = title
    vim.opt.title = true
    vim.cmd("redraw")
  end
end

function vim.util.updateTitle()
  local term_title = vim.b.term_title
  if term_title then
    if term_title:match("^term://") then
      local parts = vim.split(term_title, "[:;]")
      local title = parts[#parts - 1]
      return setTitle(title)
    end

    if term_title:match("^[%w-]+@[%w-]+:") then
      local parts = vim.split(term_title, ":")
      table.remove(parts, 1)
      return setTitle(table.concat(parts, ":"))
    end

    return setTitle(term_title)
  end

  local filename = vim.fn.expand('%:t') -- Get the current file name

  if filename ~= "" then filename = filename .. " " end
  local title = "vim - " .. filename .. "{" .. vim.util.getMode() .. "}"

  setTitle(title)
end

vim.api.nvim_create_autocmd({"BufEnter", "BufWinEnter", "ModeChanged"}, {
  pattern = {"*"},
  callback = vim.util.updateTitle,
})

vim.util.nvim_sequence = function()
  local sequence = vim.fn.getcmdline()
  vim.notify(sequence, vim.log.levels.INFO)
end

