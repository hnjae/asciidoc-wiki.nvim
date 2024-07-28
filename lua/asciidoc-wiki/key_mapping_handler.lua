local M = {}

local link = require("asciidoc-wiki.link")
local func = require("asciidoc-wiki.functions")
local list = require("asciidoc-wiki.list")
local var = require("asciidoc-wiki.var")

M.buf_setup = function()
  local keymap_config = var.config.key_mappings
  if not keymap_config.buffer then
    return
  end

  local mappings_with_prefix = {
    ["b"] = { rhs = link.go_backlink, desc = "go-backlink" },
    -- TODO: Supports [count] feature <2022-06-18, Hyunjae Kim>
    ["i"] = { rhs = "<cmd>WikiIndex<CR>", desc = "wiki-index" },
    ["/"] = { rhs = func.wiki_search, desc = "wiki-search" },
    ["<Space>"] = { rhs = list.toggle_list_item, desc = "toggle-list-item" },
  }
  for lhs, val in pairs(mappings_with_prefix) do
    vim.keymap.set("n", keymap_config.prefix .. lhs, val.rhs, {
      silent = true,
      noremap = false,
      buffer = 0,
      desc = val.desc,
    })
  end

  if keymap_config.mappings_without_prefix then
    local mappings = {
      ["<CR>"] = { rhs = link.follow_link, desc = "follow-link" },
      -- ["<TAB>"] = { rhs = link.next_xref, desc = "next-xref" },
      -- ["<S-TAB>"] = { rhs = link.prev_xref, desc = "prev-xref" },
    }
    for lhs, val in pairs(mappings) do
      vim.keymap.set("n", lhs, val.rhs, {
        silent = true,
        noremap = false,
        buffer = 0,
        desc = val.desc,
      })
    end
  end
end

M.glob_setup = function()
  local keymap_config = var.config.key_mappings
  if not keymap_config.global then
    return
  end
end

return M
