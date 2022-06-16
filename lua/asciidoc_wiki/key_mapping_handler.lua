local M = {}
local link_handler = require('asciidoc_wiki.link_handler')
local status_wk, wk = pcall(require, "which-key")


-- https://love2d.org/forums/viewtopic.php?t=75392
-- local function getAllLocals(level)
--   local locals = {}
--   local index = 1
--   while true do
--     local varname, value = debug.getlocal(level, index)
--     if varname then
--       locals[varname] = value
--     else
--      break
--     end
--     index = index + 1
--   end
--   return locals
-- end

-- local function inspect(level)
--   print('locals visible at level '..level..':')
--   for k,v in pairs(getAllLocals(level)) do
--     print(k,v)
--   end
-- end


local buffer_keymap = {
  ["<CR>"] = { link_handler.follow_link, "follow-link" },
  ["sb"] = { link_handler.go_backlink, "follow-link" },
}
local function_to_lua_string = {
  [link_handler.follow_link] = "<cmd>lua require('asciidoc_wiki.link_handler').follow_link()<CR>",
  [link_handler.go_backlink] = "<cmd>lua require('asciidoc_wiki.link_handler').go_backlink()<CR>",
}

local buf_set_keymap = function(keymap, map_mode)
  if false and status_wk then
    wk.register(
      keymap, {mode = map_mode, silent = true, noremap = false, buffer = 0 }
    )
    return
  end

  for lhs, rhs_capsuled in pairs(keymap) do
    local rhs = function_to_lua_string[rhs_capsuled[1]]
    vim.api.nvim_buf_set_keymap(0, map_mode, lhs, rhs, {silent = true, noremap = false})
  end
end

M.setup = function()
  buf_set_keymap(buffer_keymap, "n")
end

return M
