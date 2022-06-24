---@diagnostic disable: undefined-global

local M = {}
local api = vim.api

local function detect_color(str)
	local hex_pattern = "#%x%x%x%x%x%x"
	local rgb_pattern = "rgb%(%s*%d+%s*,%s*%d+%s*,%s*%d+%s*%)"
	local hsl_pattern = "hsl%(%s*%d+%s*,%s*%d+%s*,%s*%d+%s*%)"

	local results = {}
	for match in string.gmatch(str, hex_pattern) do
		table.insert(results, match)
	end

	P(results)
end

local function get_color_at_cursor()
	local cur_pos = api.nvim_win_get_cursor(0)
	P(cur_pos)
	--> logic:
	-- look at matches, their begin & end locations
	-- if the cursor is in between them, then there's a match
	-- if the cursor is not, if there's only 1 color on the line, pick that color
end

-- color: #121221, #122233
-- color: #f4f4f4
-- color: rgb(0,0,0)
-- color: rgb( 0, 0, 0)
-- color: rgb( 0  , 0 , 0)
-- color: hsl( 0  , 0 , 0)

local function get_current_line()
	local cur_line = api.nvim_get_current_line()

	return cur_line
end

vim.keymap.set("n", "<C-A-J>", function()
	get_color_at_cursor()
end, { noremap = true, silent = true })

vim.keymap.set("n", "<C-A-K>", function()
	vim.cmd("messages clear")
	detect_color(get_current_line())
end, { noremap = true, silent = true })

-- for quickly reload file
vim.keymap.set("n", "<A-r>", ":luafile %<cr>", { noremap = true, silent = false })

return M
