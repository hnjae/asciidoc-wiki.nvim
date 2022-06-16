-- Copyright (c) 2022 Hyunjae Kim
-- GPLv2 License

local link_handler   = require('asciidoc_wiki.link_handler')
local key_mapping_handler = require('asciidoc_wiki.key_mapping_handler')
local api            = vim.api

local M = {}
-- local ts_utils = require'nvim-treesitter.ts_utils'
-- local highlighter = vim.treesitter.highlighter
-- local parsers = require'nvim-treesitter.parsers'
-- local augroup = api.nvim_create_augroup
-- local command = api.nvim_create_user_command


local default_config = {
  wiki_list = {
    {
      path = "~/wiki",
      diary_rel_path = ".",
      -- name of index file
      index = "index",
    },
  },
  -- conceal_links = true,
  -- hide_ext = false,
  key_mappings = {
    global = false,
    buffer = false,
  },
  key_mapping_suffix = "<Leader>w"
}
local config = {}


function M.buffer_setup(config)
  -- api.nvim_buf_create_user_command(0, 'WikiFollowLink', link_handler.follow_link, {})
  -- api.nvim_buf_create_user_command(0, 'WikiGoBackLink', link_handler.go_backlink, {})

  key_mapping_handler.setup()
end

function M.global_setup(config)
end


local is_setuped = false

function M.setup(raw_config)
  if is_setuped then
    return
  end
  is_setuped = true

  local user_config = raw_config or {}
  local config = vim.tbl_deep_extend('force', {}, default_config, user_config)

  M.global_setup(config)
  vim.api.nvim_create_autocmd(
      "FileType", {
      pattern  = { "python" },
      callback = M.buffer_setup(config)
    }
  )
end

return M
