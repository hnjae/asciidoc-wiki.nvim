-- Copyright (c) 2022 Hyunjae Kim
-- GPLv2 License

-- local link_handler   = require('asciidoc-wiki.link_handler')
local key_mapping_handler = require('asciidoc-wiki.key_mapping_handler')
local user_command_handler = require('asciidoc-wiki.user_command_handler')
local var = require('asciidoc-wiki.var')
local link = require('asciidoc-wiki.link')

local M = {}
-- local ts_utils = require'nvim-treesitter.ts_utils'
-- local highlighter = vim.treesitter.highlighter
-- local parsers = require'nvim-treesitter.parsers'
-- local augroup = api.nvim_create_augroup
-- local command = api.nvim_create_user_command
--
local defaut_opener = function()
  if vim.fn.has('mac') == 1 then
    return "open"
  else
    return "xdg-open"
  end
end

local default_wiki = {
  path = "~/wiki",
  index_filename = "index",
  diary_rel_path = ".",
  diary_filename = "diary",
}
local default_config = {
  wiki_list = { default_wiki },
  key_mappings = {
    prefix = "<Leader>w",
    global = true,
    buffer = true,
    mappings_without_prefix = true,
  },
  checkbox_mark = "x", -- should be x or *
  opener = defaut_opener()
}


function M.buf_setup()
  user_command_handler.buf_setup()
  key_mapping_handler.buf_setup()
end

function M.glob_setup()
  user_command_handler.glob_setup()
  key_mapping_handler.glob_setup()
end


local is_setuped = false

function M.setup(user_config)
  if is_setuped then
    return
  end
  is_setuped = true

  user_config = user_config or {}
  user_config = vim.tbl_deep_extend('force', {}, default_config, user_config)
  local temp_wikis = {}
  for _, wiki in ipairs(user_config.wiki_list) do
    -- table.insert(
    --   temp_wikis, vim.tbl_deep_extend('force', {}, default_wiki, wiki)
    -- )
    local temp_wiki = vim.tbl_deep_extend('force', {}, default_wiki, wiki)
    -- use :absolute() to resolve relative path if any.
    -- local wiki_str = Path:new(Path:new(wiki.path):expand()):absolute()
    temp_wiki.path = vim.fn.expand(temp_wiki.path)
    table.insert(temp_wikis, temp_wiki)
  end
  if #temp_wikis == 0 then
    table.insert(user_config.wiki_list, default_wiki)
  else
    user_config.wiki_list = temp_wikis
  end

  var.update_config(user_config)
  M.glob_setup()
  vim.api.nvim_create_autocmd(
      "FileType", {
      pattern  = { "asciidoc", "asciidoctor" },
      callback = M.buf_setup
    }
  )

end

return M
