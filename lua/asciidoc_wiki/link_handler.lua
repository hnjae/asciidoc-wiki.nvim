local M = {}

-- local regex_pattern = {
--   -- "magic" Regex Pattern
--   xref = "\\<xref:.\\+\\[.*\\]",
--   link = "\\<link:.\\+\\[.*\\]",
-- }

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
  -- TODO: What if two # in link? <2022-06-15, Hyunjae Kim>
  -- TODO: What if multiple [] in link? <2022-06-15, Hyunjae Kim>
  -- TODO: Handle https://docs.asciidoctor.org/asciidoc/latest/macros/link-macro-attribute-parsing/ <2022-06-15, Hyunjae Kim>

  local l_string = vim.fn.matchstr(link_raw, "\\[\\zs.*\\ze\\]")
  local anchor = vim.fn.matchstr(link_raw, "\\#\\zs.*\\ze\\[")
  -- NOTE: `:help non-greedy` \\{-}
  local l_ref = vim.fn.matchstr(link_raw, link_type .. ":\\zs.\\{-}[\\#\\[]\\@=")

  return l_ref, anchor, l_string
end

local get_link = function()
  local cursor_loc = vim.fn.col('.')
  local linestr = vim.fn.getline('.')

  local link_start, link_end = vim.regex("xref:.\\+\\[.*\\]"):match_str(linestr)
  if not link_start or cursor_loc > link_end or cursor_loc <= link_start then
    return nil
  end
  return string.sub(linestr, link_start+1, link_end), "xref"
end

local create_link = function()
  -- TODO: Handle v mode <2022-06-15, Hyunjae Kim>
  -- TODO: Handle non-allowed character <2022-06-15, Hyunjae Kim>
  local word = vim.fn.expand("<cWORD>")

  if word == "" then
    return
  end

  local link_str = "xref:" .. word .. ".adoc[" .. word .. "]"
  vim.fn.execute("normal! ciW" .. link_str)
end

local openfile = function(file_path)
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

  -- TODO: What if file_path is absolute? <2022-06-15, Hyunjae Kim>
  local new_file = vim.fn.expand("%:h") .. "/" .. file_path

  local is_readonly = vim.opt_local.readonly:get()
  if not is_readonly then
    vim.fn.execute("w")
  end

  local old_buf = vim.fn.bufnr("%")
  vim.fn.execute("edit " .. new_file)

  -- If no windows contain old_buf than close it.
  if #vim.fn.win_findbuf(old_buf) == 0 then
    vim.fn.execute("bdelete " .. old_buf)
  end
end

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
  local link_raw, link_type = get_link()
  if not link_raw then
    -- No link exists under cursor
    create_link()
    return
  end
  local l_ref, anchor, l_string = parse_link(link_type, link_raw)
  if l_ref then
    openfile(l_ref)
  end
end

return M
