local has_comment, comment = pcall(require, "Comment.api")
local has_telescope, telescope = pcall(require, "telescope.builtin")

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

function M.addToHistoryNoAnchor()
  local file = vim.api.nvim_buf_get_name(0)
  local r, c = unpack(vim.api.nvim_win_get_cursor(0))
  M.updateAnchorHistory(file, r, c)
end

function M.dropAnchor()
  -- Get the current cursor position
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))

  -- Get the current line's text
  local line = vim.api.nvim_buf_get_lines(0, row - 1, row, false)[1]

  -- Concatenate the anchor with the line's content
  local newLine = "<++> " .. line

  -- Replace the current line with the new content
  vim.api.nvim_buf_set_lines(0, row - 1, row, false, { newLine })

  -- Move the cursor to after the anchor
  local newCol = col + 5 -- Adjusting for the length of "<++> "
  vim.api.nvim_win_set_cursor(0, { row, newCol })

  -- Register in history
  M.updateAnchorHistory(vim.api.nvim_buf_get_name(0), row, newCol)

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
  if #anchorHistory < 1 then
    print("Not enough anchors in history.")
    return
  elseif #anchorHistory == 1 then
    anchorHistory[2] = anchorHistory[1]
  end

  -- Swap the two most recent anchors
  anchorHistory[1], anchorHistory[2] = anchorHistory[2], anchorHistory[1]

  -- Jump to the new top anchor in the history
  local anchor = anchorHistory[1]
  vim.cmd('e ' .. anchor.file)
  vim.api.nvim_win_set_cursor(0, { anchor.line, anchor.col })
end

function M.jumpToNextAnchor()
  -- Define the anchor pattern
  local anchorPattern = "<++>"

  -- Save the current search register, search direction, and cursor position
  local originalSearch = vim.fn.getreg('/')
  local originalSearchDirection = vim.fn.getreg('g/')
  local originalCursor = vim.api.nvim_win_get_cursor(0)

  -- Set the search direction to forward
  vim.fn.setreg('g/', '/')

  -- Search for the next occurrence of the anchor
  if vim.fn.search(anchorPattern, 'W') == 0 then
    -- If not found, wrap around to the beginning of the file and search again
    vim.api.nvim_win_set_cursor(0, { 1, 0 })
    vim.fn.search(anchorPattern, 'W')
  end

  -- Restore the original search register, direction, and cursor position if not found
  if vim.fn.line('.') == originalCursor[1] and vim.fn.col('.') == originalCursor[2] then
    vim.api.nvim_win_set_cursor(0, originalCursor)
    vim.fn.setreg('/', originalSearch)
    vim.fn.setreg('g/', originalSearchDirection)
  end
end

function M.jumpToPrevAnchor()
  -- Define the anchor pattern
  local anchorPattern = "<++>"

  -- Save the current search register, search direction, and cursor position
  local originalSearch = vim.fn.getreg('/')
  local originalSearchDirection = vim.fn.getreg('g/')
  local originalCursor = vim.api.nvim_win_get_cursor(0)

  -- Set the search direction to backward
  vim.fn.setreg('g/', '?')

  -- Search for the previous occurrence of the anchor
  if vim.fn.search(anchorPattern, 'bW') == 0 then
    -- If not found, wrap around to the end of the file and search again
    vim.api.nvim_win_set_cursor(0, { vim.fn.line('$'), 0 })
    vim.fn.search(anchorPattern, 'bW')
  end

  -- Restore the original search register, direction, and cursor position if not found
  if vim.fn.line('.') == originalCursor[1] and vim.fn.col('.') == originalCursor[2] then
    vim.api.nvim_win_set_cursor(0, originalCursor)
    vim.fn.setreg('/', originalSearch)
    vim.fn.setreg('g/', originalSearchDirection)
  end
end

function M.telescopeAnchorsInProject()
  telescope.grep_string({
    search = "<++>",
    -- Customizing the keymap for this specific call
    attach_mappings = function(prompt_bufnr, map)
      local action_state = require('telescope.actions.state')

      -- Define what happens when Enter is pressed
      map('i', '<CR>', function()
        local selection = action_state.get_selected_entry()
        require("telescope.actions").close(prompt_bufnr)
        if selection then
          -- Add entry to Anchor History
          M.updateAnchorHistory(selection.filename, selection.lnum, 0)
          -- Switch to the file and go to the line
          vim.cmd('e ' .. selection.filename)
          vim.api.nvim_win_set_cursor(0, { selection.lnum, 0 })
        end
      end)

      -- Define what happens when Enter is pressed
      map('n', '<CR>', function()
        local selection = action_state.get_selected_entry()
        require("telescope.actions").close(prompt_bufnr)
        if selection then
          -- Add entry to Anchor History
          M.updateAnchorHistory(selection.filename, selection.lnum, 0)
          -- Switch to the file and go to the line
          vim.cmd('e ' .. selection.filename)
          vim.api.nvim_win_set_cursor(0, { selection.lnum, 0 })
        end
      end)

      -- Return true to keep the rest of the mappings
      return true
    end,
  })
end

return M
