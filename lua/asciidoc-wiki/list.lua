local M = {}

local var =  require('asciidoc-wiki.var')

M.toggle_list_item = function()
  local unordered_list_regex = "[ \t]*\\*\\+[ \t]\\+"

  --- @type string
  local linestr = vim.fn.getline(".")

  -- Check checkbox
  local _, u_end = vim.regex(unordered_list_regex):match_str(linestr)

  if u_end == nil then
    print("Not an unordered list")
    return
  end

  local checkbox = linestr:sub(u_end+1, u_end + 3)
  local checkbox_start, _ = vim.regex("\\[[ *x]\\]"):match_str(checkbox)

  if checkbox_start then
    -- toggle_checkbox

    local new_line = nil
    if linestr:sub(u_end+2, u_end+2) == " " then
      new_line = vim.fn.strpart(linestr, 0, u_end+1) .. var.config.checkbox_mark .. vim.fn.strpart(linestr, u_end+2)
    else
      new_line = vim.fn.strpart(linestr, 0, u_end+1) .. " " .. vim.fn.strpart(linestr, u_end+2)
    end
    vim.fn.setline(
      '.',
      new_line
    )

  else
    -- create checkbox
    vim.fn.setline(
      '.',
      vim.fn.strpart(linestr, 0, u_end) .. "[ ] " .. vim.fn.strpart(linestr, u_end)
    )
  end

end

return M
