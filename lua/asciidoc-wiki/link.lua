-- TODO:  <2023-02-01, Hyunjae Kim>
local var = require("asciidoc-wiki.var")
local Path = require("plenary.path")

local M = {}

local xref_regex = vim.regex("xref:[^`~![\\]@$%^&*()+}\\|;',?※][^ \n\t]\\+\\[.\\{-}\\]")

local regex_pattern = {
  -- patten match per line
  -- this var should be list not dict.

  { "fail_xref_pattern", vim.regex("xref:pattern:[^ \n\t]*") },
  -- asciidoctor does not parse xref starts with +, -, !, ※, as link

  -- type = "magic" Regex Pattern
  -- NOTE: Asciidoctor does not consider url starts with _ + * as a link. (2022-06-16)
  { "angled_link", vim.regex("\\zs<[a-z]\\+://[^ \n\t\\[\\]]\\+>\\ze") },
  { "autolink_w_text", vim.regex("\\([\\_+*]\\)\\@<!\\<[a-z]\\+://[^ \n\t\\[\\]]\\+\\[.\\{-}\\]") },
  { "autolink", vim.regex("\\([\\_+*]\\)\\@<!\\<[a-z]\\+://[^ \n\t\\[\\]]\\+") },

  -- NOTE: xref with no *.adoc extension converts to an anchor. (2022-06-18)
  -- {"xref", "xref:[^`~![\\]@$%^&*()-=+}\\|;',?※][^ \n\t]\\+\\[.\\{-}\\]"},
  { "xref", xref_regex },

  -- NOTE: Even Asciidoctor does handle well when ] or [ is included in the link_pass syntax. (2022-06-16)
  { "link_pass", vim.regex("link:pass:\\[.\\{-}\\]\\[.\\{-}\\]") },
  { "link_pp", vim.regex("link:++.\\+++\\[.\\{-}\\]") },
  { "link", vim.regex("link:[^ \n\t\\[\\]]\\+\\[.\\{-}\\]") },

  { "mailto", vim.regex("mailto:[^`~![\\]@$%^&*()-=+}\\|;',?※][^ \n\t]*\\[.*\\]") },
  { "email", vim.regex("[^ \n\t@|/]\\+@[^ \\.\n\t@|+!~=/]\\+\\.[^ \\.\n\t@|+!~=/]\\+") },

  { "fail_link", vim.regex("link:[^ \n\t]*") },
  { "fail_xref", vim.regex("xref:[^ \n\t]*") },
  { "fail_autolink", vim.regex("[^ \n\t]*://[^ \n\t]*") },
  { "fail_mailto", vim.regex("mailto:[^ \n\t]*") },
  { "fail_email", vim.regex("[^ \n\t]\\+@[^ \n\t]\\+") },
}

-- TODO: clear history_stack if window closes <2022-06-15, Hyunjae Kim>
-- key of history_stack: windows' id
-- LIMITATION: if we move windows to new tab (C-W S-T) it changes its id.
local history_stack = {}

-- Copied from: http://lua-users.org/wiki/CopyTable (2022-06-15)
-- function string.random(length)
--   local charset = "qwertyuiopasdfghjklzxcvbnmQWERTYUIOPASDFGHJKLZXCVBNM1234567890"
--   math.randomseed(os.time())
--   if length <= 0 then
--     return ""
--   end

--   local ret = {}
--   local r
--   for _=1,length do
--     r = math.random(1, #charset)
--     table.insert(ret, charset:sub(r, r))
--   end
--   return table.concat(ret)
-- end

---@return string|nil, string|nil, string|nil # ref, anchor, link_text
local parse_link = function(link_type, link_raw)
  -- NOTE:
  -- Q: What if two # in link?
  -- A: It will treat as filename in asciidoctor. (2022-06-16)

  -- TODO: Handle https://docs.asciidoctor.org/asciidoc/latest/macros/link-macro-attribute-parsing/ <2022-06-15, Hyunjae Kim>

  local pstart, pend = nil, nil
  local l_ref, anchor, l_string = nil, nil, nil

  if link_type == "xref" then
    -- e.g: xref:blabla.adoc#optional[blabla]

    pstart, pend = vim.regex("\\[\\zs.\\{-}\\ze\\]$"):match_str(link_raw)

    if pstart == nil then
      vim.notify("ERROR: " .. link_raw)
      return nil, nil, nil
    end

    l_string = link_raw:sub(pstart + 1, pend)

    -- e.g.: l_ref_raw: blabla.adoc#optional
    local l_ref_raw = link_raw:sub(6, pstart - 1)

    if l_ref_raw:find("^#") then
      -- xref:#anchor[string] is same as xref:anchor[string]
      anchor = l_ref_raw:sub(2, l_ref_raw:len())
      -- TODO: this is an anchor, implement it <2022-06-17, Hyunjae Kim>
      vim.notify("Not supported yet: Anchor : " .. anchor)
      return nil, anchor, l_string
    end

    anchor = vim.fn.matchstr(l_ref_raw, "\\#\\zs[^#]*\\ze$")
    if anchor:len() == 0 then
      l_ref = l_ref_raw

      if not l_ref:find("%.adoc$") then
        anchor = l_ref
        -- TODO: this is an anchor, implement it <2022-06-17, Hyunjae Kim>
        vim.notify("Not supported yet: Anchor : " .. anchor)
        return nil, anchor, l_string
      end

      -- local anchor = vim.fn.matchstr(link_raw, "\\#\\zs.*\\ze\\[")
      -- NOTE: `:help non-greedy` \\{-}
      return l_ref, anchor, l_string
    end

    -- xref:babla#blabla then
    l_ref = l_ref_raw:sub(1, -anchor:len() - 2)
    if not l_ref:find("%.adoc$") then
      -- NOTE: xref:aaa#bbb[ccc] is translated as <a href="aaa.html#bbb">ccc</a> (2022-06-18 confirmed)
      return l_ref .. ".html", anchor, l_string
    end

    return l_ref, anchor, l_string
  end

  if link_type == "link" then
    pstart, pend = vim.regex("\\[\\zs.\\{-}\\ze\\]$"):match_str(link_raw)
    l_string = link_raw:sub(pstart + 1, pend)
    local l_ref_raw = string.sub(link_raw, 6, pstart - 1)

    anchor = vim.fn.matchstr(l_ref_raw, "\\#\\zs[^#]*\\ze$")
    if anchor:len() == 0 then
      l_ref = l_ref_raw
      return l_ref, anchor, l_string
    end

    l_ref = string.sub(l_ref_raw, 1, string.len(l_ref_raw) - string.len(anchor) - 1)

    -- TODO: correspond to following circumstance <2022-06-18, Hyunjae Kim>
    -- if l_ref:len() == 0 then
    -- l_ref:len() == 0 but anchor exists
    -- link:#aaa[bbb] -- this work as in-file anchor

    return l_ref, anchor, l_string
  end

  if link_type == "angled_link" or link_type == "autolink" or link_type == "autolink_w_text" then
    if link_type == "autolink_w_text" then
      l_string = vim.fn.matchstr(link_raw, "\\[\\zs.\\{-}\\ze\\]$")
      -- l_ref = vim.fn.matchstr(link_raw, ".*\\ze\\[")
      l_ref = link_raw:sub(1, -l_string:len() - 3)
    elseif link_type == "angled_link" then
      -- remove angle brackets
      l_ref = link_raw:sub(2, -2)
      l_string = l_ref
    else
      -- link_type == autolink
      l_ref = link_raw
      l_string = l_ref
    end

    local asciidoctor_allowed_autolink_url_schemes = {
      -- https://docs.asciidoctor.org/asciidoc/latest/macros/autolinks/
      "https",
      "http",
      "ftp",
      "irc",
      -- Although "file" is not listed in documents. it is interpreted as well. (2022-06-17)
      "file",
    }

    local is_matched = false
    for _, url_type in ipairs(asciidoctor_allowed_autolink_url_schemes) do
      if l_ref:match("^" .. url_type .. "://") then
        is_matched = true
        break
      end
    end

    if not is_matched then
      vim.notify("Following URL scheme is not supported: " .. l_ref)
      return
    end

    return l_ref, nil, l_string
  end

  -- TODO: implement link_pass <2022-06-16, Hyunjae Kim>
  -- TODO: implement link_pp <2022-06-16, Hyunjae Kim>
  -- TODO: implement email <2022-06-16, Hyunjae Kim>

  vim.notify("Syntax error: " .. link_raw .. " ")
  -- print("Syntax error: " .. link_raw .. " " .. link_type )
  return nil, nil, nil
end

---@param linestr string
---@return table # lists of link(in [link_start, link_end] format) in line
local get_link_from_line = function(re_obj, linestr)
  if linestr == nil then
    return {}
  end

  local ret = {}

  local line_len = linestr:len()
  local checked_idx = 0

  -- Find match
  while checked_idx + 1 < line_len do
    local l_start, l_end = re_obj:match_str(linestr:sub(checked_idx + 1, -1))

    if l_start == nil then
      break
    end

    -- NOTE: vim.regex() uses 0-based index
    table.insert(ret, { checked_idx + l_start + 1, checked_idx + l_end })
    checked_idx = checked_idx + l_end
  end

  return ret
end

-- return raw_link and link_type
local get_link_from_cursor = function()
  -- NOTE: vim.fn.col uses 1-based index
  local cursor_loc = vim.fn.col(".")

  -- local linestr = vim.fn.getline('.')
  local linestr = vim.api.nvim_get_current_line()

  local link_start, link_end, link_type = nil, nil, nil

  for _, val in ipairs(regex_pattern) do
    local pattern_type, pattern_re_obj = val[1], val[2]

    for _, matched in ipairs(get_link_from_line(pattern_re_obj, linestr)) do
      link_start, link_end = matched[1], matched[2]

      if cursor_loc <= link_end and cursor_loc >= link_start then
        link_type = pattern_type
        goto break_loop
        break
      end
    end
  end

  ::break_loop::
  if link_type ~= nil then
    return linestr:sub(link_start, link_end), link_type
  end

  return nil
end

local create_link = function()
  -- TODO: Handle v mode <2022-06-15, Hyunjae Kim>
  -- TODO: Handle non-allowed character <2022-06-15, Hyunjae Kim>
  local word = vim.fn.expand("<cWORD>")

  if word == "" or word == nil then
    return
  end

  if word:match("%.adoc$") then
    word = word:sub(1, -6)
  end

  local link_str = "xref:" .. word .. ".adoc[" .. word .. "]"
  vim.fn.execute("normal! ciW" .. link_str)
end

-- local goto_anchor = function(anchor)
--   print("Goto Anchor it not supported yet: " .. anchor)
-- end

local open_target = function(arg, anchor, link_type)
  local open_external = function(target)
    if not target then
      return
    end

    -- print("Opening :" .. target)
    -- TODO: handle relative path <2022-06-18, Hyunjae Kim>
    local output = vim.fn.system(var.config.opener .. " -- " .. vim.fn.shellescape(target) .. " &")
  end

  -- if link_type ~= "xref" then
  if not (link_type == "xref" and arg:match("%.adoc$")) then
    open_external(arg)
    return
  end

  -- TODO: Consider using full path <2022-06-15, Hyunjae Kim>
  local history = {
    (vim.fn.expand("%:h") .. "/" .. vim.fn.expand("%:t")),
    vim.fn.getpos("."),
  }
  local win_id = vim.fn.win_getid()
  if not history_stack[win_id] then
    history_stack[win_id] = {}
  end
  table.insert(history_stack[win_id], history)

  local new_file = nil
  if Path:new(arg):is_absolute() then
    new_file = arg
  else
    -- TODO: resolve relative path <2022-06-18, Hyunjae Kim>
    new_file = Path:new(vim.fn.expand("%:h")):joinpath(arg).filename
    -- new_file = vim.fn.expand("%:h") .. "/" .. arg
  end

  local is_readonly = vim.opt_local.readonly:get()
  if not is_readonly then
    vim.fn.execute("w")
  end

  ---@type number
  -- local old_buf = vim.fn.bufnr("%")
  local old_buf = vim.fn.bufnr()

  -- TODO: can not handle character # in new_file <2022-06-17, Hyunjae Kim>
  -- TODO: escape string for use as a vim command arguments <2022-06-18, Hyunjae Kim>
  -- if new_file:find("#") then
  --   print("")
  -- end
  vim.fn.execute("edit " .. new_file)

  -- If no windows contain old_buf than close it.
  if #vim.fn.win_findbuf(old_buf) == 0 then
    vim.fn.execute("bdelete " .. old_buf)
  end
end

M.go_backlink = function()
  local msg = "No history in stack."

  local win_id = vim.fn.win_getid()
  if not history_stack[win_id] then
    print(msg)
    return
  end

  local latest_his = table.remove(history_stack[win_id], #history_stack[win_id])
  if not latest_his then
    print(msg)
    return
  end

  if not vim.opt_local.readonly:get() then
    vim.fn.execute("w")
  end

  -- local old_buf = vim.fn.bufnr("%")
  local old_buf = vim.fn.bufnr()
  vim.fn.execute("edit " .. latest_his[1])
  vim.fn.setpos(".", latest_his[2])

  -- If no windows contain old_buf than close it.
  if #vim.fn.win_findbuf(old_buf) == 0 then
    vim.fn.execute("bdelete " .. old_buf)
  end
end

M.follow_link = function()
  local link_raw, link_type = get_link_from_cursor()
  if not link_raw then
    create_link()
    return
  end
  local link_target, anchor, link_str = parse_link(link_type, link_raw)
  if link_target or anchor then
    open_target(link_target, anchor, link_type)
  end
end

-- M.conceal_link = function()
--   -- copied from https://github.com/ratfactor/vviki
--   -- MIT License; 2022-06-22 checked.
--   vim.cmd([[
--     -- syntax region vvikiLink start=/xref:/ end=/\]/ keepend
--     -- syntax match vvikiLinkGuts /xref:[^[]\+\[/ containedin=vvikiLink contained conceal
--     -- syntax match vvikiLinkGuts /\]/ containedin=vvikiLink contained conceal

--     highlight link vvikiLink Macro
--     highlight link vvikiLinkGuts Comment
--   ]])
-- end

M.next_xref = function()
  -- regex copied from https://github.com/ratfactor/vviki
  -- MIT License; 2022-06-22 checked.
  -- TODO: Write credit about this. <2022-06-22, Hyunjae Kim>
  vim.fn.search("xref:.\\{-1,}]")
end

M.prev_xref = function()
  -- regex copied from https://github.com/ratfactor/vviki
  -- MIT License; 2022-06-22 checked.
  vim.fn.search("xref:.\\{-1,}]", "b")
end

---@param filepath string # filepath to update link
---@param oldname string
---@param newname string
local update_xref = function(filepath, oldname, newname)
  -- TODO: use :match_line method of vim.regex <2022-06-23, Hyunjae Kim>

  if oldname == newname then
    return
  end

  vim.notify("Updating links in " .. filepath)
  local updated_contents = {}
  --@type bool
  local is_any_update = false

  for line_idx, linestr in ipairs(vim.fn.readfile(filepath)) do
    -- linestr 에 oldname 링크가 있으면 갱신하기
    local newline_str = ""
    local num_col_added = 0
    for _, matched in ipairs(get_link_from_line(xref_regex, linestr)) do
      local x_start, x_end = matched[1], matched[2]

      if x_start == nil then
        break
      end

      ---@type string
      local oldlink_str = linestr:sub(x_start, x_end)
      local ref, anchor, link_text = parse_link("xref", oldlink_str)

      if ref == nil or ref:sub(1, -6) ~= oldname then
        -- do nothing if link is not oldname's link
        newline_str = newline_str .. linestr:sub(num_col_added + 1, x_end)
        num_col_added = x_end
      else
        -- TODO: keep anchor in link <2022-12-28, Hyunjae Kim>
        -- TODO: link-macro-attribute-parsing <2022-12-29, Hyunjae Kim>

        local newlink_str = ""
        if link_text == oldname then
          newlink_str = "xref:" .. newname .. ".adoc[" .. newname .. "]"
        else
          newlink_str = "xref:" .. newname .. ".adoc[" .. link_text .. "]"
        end
        newline_str = newline_str .. linestr:sub(num_col_added + 1, x_start - 1) .. newlink_str
        is_any_update = true

        num_col_added = x_end
      end
    end

    if num_col_added ~= 0 then
      -- if there were link in line
      if num_col_added < #linestr then
        newline_str = newline_str .. linestr:sub(num_col_added + 1, #linestr)
      end
      table.insert(updated_contents, newline_str)
    else
      table.insert(updated_contents, linestr)
    end
  end

  if is_any_update then
    os.rename(filepath, filepath .. ".temp")
    vim.fn.writefile(updated_contents, filepath)
    os.remove(filepath .. ".temp")
  end
end

M.wiki_rename_file = function()
  -- rename current buffer's file
  -- TODO: complete this <2022-10-03, Hyunjae Kim>
  -- TODO: ask user to ensure the renaming <2022-12-28, Hyunjae Kim>
  -- TODO: ask user for new name <2022-12-28, Hyunjae Kim>
  -- TODO: find which wiki's file <2022-12-28, Hyunjae Kim>
  -- TODO: check if new name is in wiki_dir <2022-12-29, Hyunjae Kim>
  -- TODO: rename wiki link <2022-12-29, Hyunjae Kim>
  -- TODO: Iterate all file in wiki and rename in file <2022-12-28, Hyunjae Kim>

  --@type string
  local new_name = vim.fn.input({ prompt = "New name: " })
  --@type string
  -- local new_name = vim.fn.input({prompt='Rename ' .. })
  -- vim.notify("!" .. new_name .. "!", 0, {})
  vim.api.nvim_exec("edit", false)
end

return M
