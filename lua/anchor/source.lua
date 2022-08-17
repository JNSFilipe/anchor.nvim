local M = {}

M.config = {
  sanchor = "<++",
  eanchor = ">",
}

-- Function to get commenting wrappers bluntly stolen from:
-- https://github.com/terrortylor/nvim-comment/blob/main/lua/nvim_comment.lua
function M._get_comment_wrapper()
  local cs = vim.api.nvim_buf_get_option(0, "commentstring")

  -- make sure comment string is understood
  if cs:find("%%s") then
    local left, right = cs:match("^(.*)%%s(.*)")
    if right == "" then
      right = nil
    end

    -- left comment markers should have padding as linterers preffer
    if M.config.marker_padding then
      if not left:match("%s$") then
        left = left .. " "
      end
      if right and not right:match("^%s") then
        right = " " .. right
      end
    end

    return left, right
  else
    api.nvim_command('echom "Commentstring not understood: ' .. cs .. '"')
  end
end

function M.drop_anchor()

  left, right = M._get_comment_wrapper()

  -- standarise indentation before adding
  -- local line = l:gsub("^" .. indent, "")

  -- find indentation
  local indent
  local cline, _ = unpack(vim.api.nvim_win_get_cursor(0))     -- Get current cursor position
  local lines = vim.api.nvim_buf_get_lines(0, cline - 1, cline + 1, false)
  for _, v in pairs(lines) do
    if not v:match("^%s*$") then
      local line_indent = v:match("^%s+") or ""
      if not indent or string.len(line_indent) < string.len(indent) then
        indent = line_indent
      end
    end
  end

  -- Build anchor text
  local anchr = indent .. left .. " " .. M.config.sanchor .. M.config.eanchor
  if right then
    anchr = anchr .. right
  end

  -- Write anchor in new line
  vim.api.nvim_buf_set_lines(0, cline-1, cline-1, false, {anchr})

  return anchr
end

return M
