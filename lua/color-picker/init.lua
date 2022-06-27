---@diagnostic disable: undefined-global
local M = {}
local api = vim.api
local utils_window = require("color-picker.utils.window")

-- local function detect_colors(str) --{{{
--
-- 	local hex_pattern = "#%x%x%x%x%x%x"
-- 	local rgb_pattern = "rgb%(%s*%d+%s*,%s*%d+%s*,%s*%d+%s*%)"
-- 	local hsl_pattern = "hsl%(%s*%d+%s*,%s*%d+%s*,%s*%d+%s*%)"
--
-- 	local results = {}
-- 	local patterns = { hex_pattern, rgb_pattern, hsl_pattern }
--
-- 	for _, pattern in ipairs(patterns) do
-- 		local start_index = 1
-- 		while true do
-- 			local _start, _end = string.find(str, pattern, start_index)
-- 			local _match = string.match(str, pattern, start_index)
--
-- 			if _start == nil then
-- 				break
-- 			end
--
-- 			table.insert(results, { _start, _end, _match })
-- 			start_index = _end + 1
-- 		end
-- 	end
--
-- 	return results
-- end --}}}

-- color: hsl(240,100%,37%), #122233
-- color: #f4f4f4
-- color: rgb(0,0,0)
-- color: rgb( 0, 0, 0)
-- color: rgb( 0  , 0 , 0)
-- color: hsl( 0  , 0 , 0)

-- local function sandwich() --{{{
-- 	-- get cur_line, cur_pos
-- 	local cur_line = api.nvim_get_current_line()
-- 	local cur_pos = api.nvim_win_get_cursor(0)
-- 	local cur_pos_row = cur_pos[1]
-- 	local cur_pos_col = cur_pos[2]
--
-- 	-- get colorRanges
-- 	local colorRanges = detect_colors(cur_line)
--
-- 	-- loop through colorRanges, find if any sandwiches the cursor
-- 	for _, color in ipairs(colorRanges) do
-- 		local start_pos = color[1] - 1
-- 		local end_pos = color[2]
--
-- 		if start_pos <= cur_pos_col and end_pos >= cur_pos_col then
-- 			-- api.nvim_buf_set_text(0, cur_pos_row - 1, start_pos, cur_pos_row - 1, end_pos, { color[3] })
-- 			api.nvim_buf_set_text(0, cur_pos_row - 1, start_pos, cur_pos_row - 1, end_pos, { " Rasputin" })
-- 		end
-- 	end
-- end --}}}

vim.keymap.set("n", "<C-c>", function()
	utils_window.pop("normal")
end, { noremap = true, silent = true })
vim.keymap.set("i", "<C-c>", function()
	utils_window.pop("insert")
end, { noremap = true, silent = true })
vim.keymap.set("n", "<C-A-K>", function()
	vim.cmd("messages clear")
	sandwich()
end, { noremap = true, silent = true })

-- for quickly reload file
vim.keymap.set("n", "<A-r>", function()
	R("color-picker")
	P("color-picker reloaded")
end, { noremap = true, silent = false })

return M
