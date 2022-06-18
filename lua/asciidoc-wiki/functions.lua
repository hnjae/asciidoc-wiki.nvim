-- The module that provides various useful functions.

local M = {}
local var = require('asciidoc-wiki.var')
local Path = require('plenary.path')

local get_cur_wiki = function()
  -- TODO: test this code <2022-06-18, Hyunjae Kim>
  local cur_file = vim.fn.expand("%:p")
  for _, wiki in ipairs(var.config["wiki_list"]) do
    -- NOTE: vim.fn.expand() does not resolve relative path or symbolic link.

    -- use :absolute() to resolve relative path if any.
    local wiki_str = Path:new(Path:new(wiki.path):expand()):absolute()
    if cur_file:match("^" .. wiki_str) then
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


return M
