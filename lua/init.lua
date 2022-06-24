---@diagnostic disable: undefined-global

local M = {}
local api = vim.api

local function detect_color(str)
	local hex_pattern = "#%x%x%x%x%x%x"
	local rgb_pattern = "rgb%(%s*%d+%s*,%s*%d+%s*,%s*%d+%s*%)"

	local hex_match = string.match(str, hex_pattern)
	local rgb_match = string.match(str, rgb_pattern)

	if hex_match then
		print(hex_match)
	end
	if rgb_match then
		print(rgb_match)
	end
end

-- color: #121221
-- color: #f4f4f4
-- color: rgb(0,0,0)
-- color: rgb( 0, 0, 0)
-- color: rgb( 0  , 0 , 0)

local function get_current_line()
	local cur_line = api.nvim_get_current_line()

	return cur_line
end

vim.keymap.set("n", "  k", function()
	vim.cmd("messages clear")
	detect_color(get_current_line())
end, { noremap = true, silent = true })

return M
