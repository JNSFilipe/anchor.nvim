local has_telescope, telescope = pcall(require, "telescope")

if not has_telescope then
        error("This plugins requires nvim-telescope/telescope.nvim")
end

local pickers = require("telescope.builtin")
local Config = require("todo-comments.config")
local Highlight = require("todo-comments.highlight")
local make_entry = require("telescope.make_entry")


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

        -- opts.entry_maker = entry_maker
        pickers.grep_string(opts)
end

return telescope.register_extension({ exports = { anchor = anchor } })
