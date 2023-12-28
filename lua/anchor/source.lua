local has_comment, comment = pcall(require, "Comment.api")

if not has_comment then
  error("This plugins requires numToStr/Comment.nvim")
end

local M = {}

local anchorHistory = {}

function M.updateAnchorHistory(file, line, col)
  -- Add the current anchor to the history
  table.insert(anchorHistory, 1, { file = file, line = line, col = col })

  -- Keep only the two most recent entries in the history
  if #anchorHistory > 2 then
    table.remove(anchorHistory, 3)
  end
end

function M.dropAnchor()
  -- Get the current cursor position
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))

  -- Insert the anchor '<++>' in a new line below the current cursor position
  vim.api.nvim_buf_set_lines(0, row, row, false, { "<++>" })

  -- Move the cursor to the new line with the anchor
  vim.api.nvim_win_set_cursor(0, { row + 1, col })

  -- Register in history
  M.updateAnchorHistory(vim.api.nvim_buf_get_name(0), row + 1, col)

  -- Comment the line with the anchor
  -- Check if a count is provided, otherwise use 1
  comment.toggle.linewise.count(vim.v.count > 0 and vim.v.count or 1)
end

function M.hoistAllAnchors()
  -- Anchor pattern to search for
  local anchorPattern = "<%+%+>"

  -- Retrieve the number of lines in the current buffer
  local lineCount = vim.api.nvim_buf_line_count(0)

  -- Iterate over each line in reverse order
  for i = lineCount, 1, -1 do
    -- Get the line content
    local line = vim.api.nvim_buf_get_lines(0, i - 1, i, false)[1]

    -- If the line contains the anchor pattern, delete it
    if line:find(anchorPattern) then
      vim.api.nvim_buf_set_lines(0, i - 1, i, false, {})
    end
  end

  anchorHistory = {} -- Erase Anchor anchor history TODO: remove only history of the current file
end

function M.jumpToRecentAnchor()
  -- Ensure there are at least two anchors in the history
  if #anchorHistory < 2 then
    print("Not enough anchors in history to jump.")
    return
  end

  -- Swap the two most recent anchors
  anchorHistory[1], anchorHistory[2] = anchorHistory[2], anchorHistory[1]

  -- Jump to the new top anchor in the history
  local anchor = anchorHistory[1]
  vim.cmd('e ' .. anchor.file)
  vim.api.nvim_win_set_cursor(0, { anchor.line, anchor.col })
end

return M
