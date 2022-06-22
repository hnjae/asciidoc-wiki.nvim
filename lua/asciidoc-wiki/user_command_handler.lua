local M = {}

local func = require('asciidoc-wiki.functions')
local link = require('asciidoc-wiki.link')
local list = require('asciidoc-wiki.list')

local api = vim.api

M.buf_setup = function()
  -- api.nvim_buf_create_user_command(0, 'WikiFollowLink', link_handler.follow_link, {})
  -- api.nvim_buf_create_user_command(0, 'WikiGoBackLink', link_handler.go_backlink, {})
  -- api.nvim_buf_create_user_command(0, 'WikiGoBackLink', link_handler.go_backlink, {})
  api.nvim_buf_create_user_command(
    0,
    'WikiIndex',
    function(opts)
      func.wiki_index(tonumber(opts.args))
    end,
    { nargs = "?" }
  )
  api.nvim_buf_create_user_command(
    0,
    'WikiSearch',
    func.wiki_search,
    { nargs = 0 }
  )

  api.nvim_buf_create_user_command(
    0,
    'WikiToggleListItem',
    list.toggle_list_item,
    { nargs = 0 }
  )
  -- api.nvim_buf_create_user_command(0, 'WikiIndex', "lua require('asciidoc-wiki.functions').wiki_index", {})
  -- api.nvim_buf_create_user_command(0, 'WikiIndex', "echo 'srtrts'", {})
end

M.glob_setup = function()
  -- api.nvim_buf_create_user_command(0, 'WikiGoBackLink', link_handler.go_backlink, {})
  -- api.nvim_create_user_command('WikiIndex', func.wiki_index, {})
end

return M
