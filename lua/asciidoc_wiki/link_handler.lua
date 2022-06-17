local M = {}

local regex_pattern = {
  -- patten match per line
  -- this var should be list not dict.

  {"fail_xref_pattern", "xref:pattern:[^ \n\t]*"},
  -- asciidoctor does not parse xref starts with +, -, !, ※, as link

  -- type = "magic" Regex Pattern
  -- NOTE: Asciidoctor does not consider url starts with _ + * as a link. (2022-06-16)
  {"angled_link", "\\zs<[a-z]\\+://[^ \n\t\\[\\]]\\+>\\ze"},
  {"autolink_w_text", "\\([\\_+*]\\)\\@<!\\<[a-z]\\+://[^ \n\t\\[\\]]\\+\\[.\\{-}\\]"},
  {"autolink",  "\\([\\_+*]\\)\\@<!\\<[a-z]\\+://[^ \n\t\\[\\]]\\+"},

  -- NOTE: xref with no *.adoc extension converts to an anchor. (2022-06-18)
  {"xref", "xref:[^`~![\\]@$%^&*()-=+}\\|;',?※][^ \n\t]\\+\\[.\\{-}\\]"},

  -- NOTE: Even Asciidoctor does handle well when ] or [ is included in the link_pass syntax. (2022-06-16)
  {"link_pass", "link:pass:\\[.\\{-}\\]\\[.\\{-}\\]"},
  {"link_pp", "link:++.\\+++\\[.\\{-}\\]"},
  {"link", "link:[^ \n\t\\[\\]]\\+\\[.\\{-}\\]"},

  {"mailto", "mailto:[^`~![\\]@$%^&*()-=+}\\|;',?※][^ \n\t]*\\[.*\\]"},
  {"email", "[^ \n\t@|/]\\+@[^ \\.\n\t@|+!~=/]\\+\\.[^ \\.\n\t@|+!~=/]\\+"},

  {"fail_link",  "link:[^ \n\t]*"},
  {"fail_xref",  "xref:[^ \n\t]*"},
  {"fail_autolink",  "[^ \n\t]*://[^ \n\t]*"},
  {"fail_mailto",  "mailto:[^ \n\t]*"},
  {"fail_email",  "[^ \n\t]\\+@[^ \n\t]\\+"},
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

local parse_link = function(link_type, link_raw)
  -- NOTE: What if two # in link? <2022-06-15, Hyunjae Kim>
  -- A: It will treat as filename in asciidoctor. (2022-06-16)
  -- TODO: Handle https://docs.asciidoctor.org/asciidoc/latest/macros/link-macro-attribute-parsing/ <2022-06-15, Hyunjae Kim>

  local pstart, pend = nil, nil
  local l_ref, anchor, l_string = nil, nil, nil

  if link_type == "xref" then
    -- xref:blabla.adoc#optional[blabla]

    pstart, pend = vim.regex("\\[\\zs.\\{-}\\ze\\]$"):match_str(link_raw)
    l_string = link_raw:sub(pstart+1, pend)

    -- l_ref_raw: blabla.adoc#optional
    local l_ref_raw = link_raw:sub(6, pstart-1)

    if l_ref_raw:find("^#") then
      -- xref:#anchor[string] is same as xref:anchor[string]
      anchor = l_ref_raw:sub(2, l_ref_raw:len())
      -- TODO: this is an anchor, implement it <2022-06-17, Hyunjae Kim>
      print("Not supported yet: Anchor : " .. anchor)
      return nil, anchor, l_string
    end

    anchor = vim.fn.matchstr(l_ref_raw, "\\#\\zs[^#]*\\ze$")
    if anchor:len() == 0 then
      l_ref = l_ref_raw

      if not l_ref:find("%.adoc$") then
        anchor = l_ref
        -- TODO: this is an anchor, implement it <2022-06-17, Hyunjae Kim>
        print("Not supported yet: Anchor : " .. anchor)
        return nil, anchor, l_string
      end

      -- local anchor = vim.fn.matchstr(link_raw, "\\#\\zs.*\\ze\\[")
      -- NOTE: `:help non-greedy` \\{-}
      return l_ref, anchor, l_string
    end

    -- xref:babla#blabla then
    l_ref = l_ref_raw:sub(1, -anchor:len() -2)
    if not l_ref:find("%.adoc$") then
      -- NOTE: xref:aaa#bbb[ccc] is translated as <a href="aaa.html#bbb">ccc</a> (2022-06-18 confirmed)
      return l_ref .. ".html", anchor, l_string
    end

    return l_ref, anchor, l_string
  end

  if link_type == "link" then

    pstart, pend = vim.regex("\\[\\zs.\\{-}\\ze\\]$"):match_str(link_raw)
    l_string = link_raw:sub(pstart+1, pend)
    local l_ref_raw = string.sub(link_raw, 6, pstart-1)

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
      l_ref = link_raw:sub(1, - l_string:len() - 3)
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
      "https", "http", "ftp", "irc",
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
      print("Following URL scheme is not supported: " .. l_ref)
      return
    end

    return l_ref, nil, l_string
  end


  -- TODO: implement link_pass <2022-06-16, Hyunjae Kim>
  -- TODO: implement link_pp <2022-06-16, Hyunjae Kim>
  -- TODO: implement email <2022-06-16, Hyunjae Kim>

  print("Syntax error: " .. link_raw .. " " .. link_type )
  -- print("Syntax error: " .. link_raw .. " " .. link_type )
  return nil, nil, nil
end

local get_link_from_cursor = function()
  -- return raw_link and link_type
  local cursor_loc = vim.fn.col('.')
  local linestr = vim.fn.getline('.')

  local link_start, link_end, link_type = nil, nil, nil

  for _, val in ipairs(regex_pattern) do
    local pattern_type = val[1]
    local pattern_reg = val[2]

    -- TODO: this code can not handle multiple link in same line <2022-06-16, Hyunjae Kim>
    link_start, link_end = vim.regex(pattern_reg):match_str(linestr)
    if link_start and cursor_loc <= link_end and cursor_loc > link_start then
      link_type = pattern_type
      break
    end
  end

  if link_type == nil then
    return nil
  end

  -- print(string.sub(linestr, link_start+1, link_end))
  return string.sub(linestr, link_start+1, link_end), link_type
end

local create_link = function()
  -- TODO: Handle v mode <2022-06-15, Hyunjae Kim>
  -- TODO: Handle non-allowed character <2022-06-15, Hyunjae Kim>
  -- TODO: if link includes .adoc, skip it <2022-06-16, Hyunjae Kim>
  -- TODO: if cursor's link start with xref: link: url:// but does not follow asciidoc's syntax, skip creating link. <2022-06-16, Hyunjae Kim>
  local word = vim.fn.expand("<cWORD>")

  if word == "" then
    return
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

    local output = vim.fn.system("xdg-open -- " .. vim.fn.shellescape(target) .. " &")
  end

  -- if link_type ~= "xref" then
  if not (link_type == "xref" and arg:match("%.adoc$")) then
    open_external(arg)
    return
  end


  -- TODO: Consider using full path <2022-06-15, Hyunjae Kim>
  local history = {
    (vim.fn.expand("%:h") .. "/" .. vim.fn.expand("%:t")),
    vim.fn.getpos('.'),
  }
  local win_id = vim.fn.win_getid()
  if not history_stack[win_id] then
    history_stack[win_id] = {}
  end
  table.insert(history_stack[win_id], history)

  -- TODO: What if arg is absolute? <2022-06-15, Hyunjae Kim>
  local new_file = vim.fn.expand("%:h") .. "/" .. arg

  local is_readonly = vim.opt_local.readonly:get()
  if not is_readonly then
    vim.fn.execute("w")
  end

  local old_buf = vim.fn.bufnr("%")
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

--------------------------------------------

M.go_backlink = function()
  local msg = "No history in stack."
  local win_id = vim.fn.win_getid()
  if not history_stack[win_id]then
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

  local old_buf = vim.fn.bufnr("%")
  vim.fn.execute("edit " .. latest_his[1])
  vim.fn.setpos(".", latest_his[2])

  -- If no windows contain old_buf than close it.
  if #vim.fn.win_findbuf(old_buf) == 0 then
    vim.fn.execute("bdelete " .. old_buf)
  end
  -- TODO: hisdel?? <2022-06-15, Hyunjae Kim>
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

return M
