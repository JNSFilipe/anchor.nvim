local has_telescope, telescope = pcall(require, "telescope")

if not has_telescope then
        error("This plugins requires nvim-telescope/telescope.nvim")
end

local pickers = require("telescope.builtin")
local make_entry = require("telescope.make_entry")

local utils = require("anchor.source")

-- Function to find the nearest non-empty line below a given line number
local function get_next_line_text(filename, line_number)
        local file = io.open(filename, "r") -- Open the file for reading
        if not file then
                print("Cannot open file: " .. filename)
                return nil
        end

        local lnumber = 0
        local nearest_non_empty_line = nil

        -- Iterate through each line in the file
        for line in file:lines() do
                lnumber = lnumber + 1
                if lnumber > line_number and line:match("%S") then -- Check if line is non-empty and below the start line
                        nearest_non_empty_line = line
                        break
                end
        end

        file:close() -- Close the file
        return nearest_non_empty_line
end

local function anchor(opts)
        opts = opts or {}
        opts.vimgrep_arguments = {
                "rg",
                "--color=never",
                "--no-heading",
                "--with-filename",
                "--line-number",
                "--column",
                "--smart-case"
        }
        opts.search = "<\\+\\+>" -- Lua pattern for <++>

        opts.prompt_title = "Find Anchors"
        opts.use_regex = true
        local entry_maker = make_entry.gen_from_vimgrep(opts)

        opts.entry_maker = function(line)
                local ret = entry_maker(line)
                ret.display = function(entry)
                        local display = string.format("%s:%s:%s ", entry.filename, entry.lnum, entry.col)

                        local text = get_next_line_text(entry.filename, entry.lnum)

                        display = display .. " " .. (text or "")

                        return display
                end
                return ret
        end

        -- Define custom action for selection
        opts.attach_mappings = function(prompt_bufnr, map)
                local action_state = require('telescope.actions.state')
                local actions = require('telescope.actions')

                map('i', '<CR>', function()
                        local selection = action_state.get_selected_entry()
                        actions.close(prompt_bufnr)
                        if selection then
                                -- Add entry to Anchor History
                                utils.updateAnchorHistory(selection.filename, selection.lnum, 0)
                                -- Switch to the file and go to the line
                                vim.cmd('e ' .. selection.filename)
                                vim.api.nvim_win_set_cursor(0, { selection.lnum, 0 })
                        end
                end)

                return true
        end

        pickers.grep_string(opts)
end

return telescope.register_extension({ exports = { anchor = anchor } })
