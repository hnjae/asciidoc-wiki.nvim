-- The module that provides various useful functions.

local M = {}
local var = require('asciidoc-wiki.var')
local Path = require('plenary.path')

local get_cur_wiki = function()
  local cur_file = vim.fn.expand("%:p")
  for _, wiki in ipairs(var.config["wiki_list"]) do
    -- NOTE: vim.fn.expand() does not resolve relative path or symbolic link.

    -- NOTE: wiki.path here should be absolute path. (init.lua resolve it.)
    if cur_file:match("^" .. wiki.path) then
      return wiki
    end
  end

  return nil
end

M.wiki_index = function(wiki_num)
  -- open wiki index
  local wiki = nil

  if not wiki_num then
    wiki = get_cur_wiki()
    if not wiki then
      wiki = var.config.wiki_list[1]
    end
  else
    wiki_num = math.min(wiki_num, #var.config.wiki_list)
    wiki_num = math.max(wiki_num, 1)
    wiki = var.config.wiki_list[wiki_num]
  end

  local index_path = (Path:new(wiki.path)):joinpath(
    wiki.index_filename .. ".adoc"
  )

  vim.fn.execute("edit " .. index_path.filename)
end

M.wiki_search = function()
  local status_telescope, t_builtin = pcall(require, "telescope.builtin")
  if not status_telescope then
    print("telescope.nvim is not installed.")
  end

  local wiki = get_cur_wiki()
  if not wiki then
    return
  end

  t_builtin.live_grep{
    cwd = wiki.path,
    type_filter = "asciidoc"
  }
end


return M
