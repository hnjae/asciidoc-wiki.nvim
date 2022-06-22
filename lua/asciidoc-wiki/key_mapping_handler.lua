local M = {}
local link = require('asciidoc-wiki.link')
local func = require('asciidoc-wiki.functions')
local list = require('asciidoc-wiki.list')
local status_wk, wk = pcall(require, "which-key")
local var = require('asciidoc-wiki.var')


local buf_noprefix_mappings = {
  ["<CR>"] = { link.follow_link, "follow-link" },
  ["<TAB>"] = { link.next_xref, "next-xref" },
  ["<S-TAB>"] = { link.prev_xref, "prev-xref" },
}
local buf_prefix_mappings = {
  ["b"] = { link.go_backlink, "go-backlink" },
  -- TODO: Supports [count] feature <2022-06-18, Hyunjae Kim>
  ["i"] = { "<cmd>WikiIndex<CR>", "wiki-index" },
  ["/"] = { func.wiki_search, "wiki-search" },
  ["<Space>"] = { list.toggle_list_item, "toggle-list-item" },
}


local function_to_lua_string = {
  [link.follow_link] = "<cmd>lua require('asciidoc-wiki.link').follow_link()<CR>",
  [link.go_backlink] = "<cmd>lua require('asciidoc-wiki.link').go_backlink()<CR>",
  [func.wiki_search] = "<cmd>lua require('asciidoc-wiki.functions').wiki_search()<CR>",
}

local buf_set_keymap = function(keymap, map_mode, map_prefix)
  if status_wk then
    wk.register(
      keymap,
      {
        buffer = 0,
        mode = map_mode,
        prefix = map_prefix,
        silent = true,
        noremap = false,
      }
    )
    return
  end

  for lhs, rhs_capsuled in pairs(keymap) do
    local rhs = nil
    if type(rhs_capsuled[1]) == "string" then
      rhs = rhs_capsuled[1]
    else
      rhs = function_to_lua_string[rhs_capsuled[1]]
    end

    vim.api.nvim_buf_set_keymap(
      0,
      map_mode,
      map_prefix .. lhs,
      rhs,
      {silent = true, noremap = false}
    )
  end
end


M.buf_setup = function()
  local keymap_config = var.config.key_mappings
  if not keymap_config.buffer then
    return
  end
  buf_set_keymap(buf_prefix_mappings, "n", keymap_config.prefix)

  if keymap_config.mappings_without_prefix then
    buf_set_keymap(buf_noprefix_mappings, "n", "")
  end
end

M.glob_setup = function()
  local keymap_config = var.config.key_mappings
  if not keymap_config.global then
    return
  end
end

return M
