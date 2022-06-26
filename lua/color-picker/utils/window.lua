local M = {}
local api = vim.api
local utils = require("color-picker.utils")

local win = nil
local buf = nil
local ns = api.nvim_create_namespace("color-picker-popup")

local rgbToHex = utils.rgbToHex
local round = utils.round
local HSLToRGB = utils.HSLToRGB
local RGBToHSL = utils.RGBToHSL
local hslToHex = utils.hslToHex

vim.cmd(":highlight ColorPickerOutput guifg=#white")

local output_type = "rgb"
local color_mode = "rgb"

local color_mode_extmarks = {}
local color_value_extmarks = {}
local color_values = { 0, 0, 0 }
local boxes_extmarks = {}
local output_extmark = {}
local output = nil

local target_buf = nil
local target_line = nil
local target_pos = nil

local function create_empty_lines() ---create empty lines in the popup so we can set extmarks{{{
	api.nvim_buf_set_lines(buf, 0, -1, false, {
		"",
		"",
		"",
		"",
	})
end --}}}

local function delete_ext(id) -- shortcut for delete extmarks given an id{{{
	api.nvim_buf_del_extmark(buf, ns, id)
end --}}}

local function ext(row, col, text, hl_group, virt_text_pos) ---shortcut to create extmarks{{{
	return api.nvim_buf_set_extmark(buf, ns, row, col, {
		virt_text = { { text, hl_group or "Normal" } },
		virt_text_pos = virt_text_pos or "eol",
	})
end --}}}

local function set_color_marks(marks) --{{{
	local t = {}
	marks:gsub(".", function(c)
		table.insert(t, c)
	end)

	for _, value in ipairs(color_mode_extmarks) do
		delete_ext(value)
	end

	for i, value in ipairs(t) do
		color_mode_extmarks[i] = ext(i - 1, 0, string.upper(value), nil, "overlay")
	end
end --}}}

local function string_fix_right(str, width) --{{{
	if type(str) == "number" then
		str = tostring(str)
	end

	local number_of_spaces = width - #str

	return string.rep(" ", number_of_spaces) .. str
end --}}}

local function update_boxes(line) --{{{
	delete_ext(boxes_extmarks[line])

	local floor = nil
	local arithmetic = nil
	if color_mode == "rgb" then
		floor = math.floor(color_values[line] / 25.5)
		arithmetic = color_values[line] / 25.5 - floor
	elseif color_mode == "hsl" then
		if line == 1 then
			floor = math.floor(color_values[line] / 36)
			arithmetic = color_values[line] / 36 - floor
		else
			floor = math.floor(color_values[line] / 10)
			arithmetic = color_values[line] / 10 - floor
		end
	end

	local box_string = ""

	if arithmetic ~= 0 then
		box_string = ""
	else
		box_string = " "
	end

	for _ = 1, floor, 1 do
		box_string = "ﱢ" .. box_string
	end

	for _ = 1, 10 - floor do
		box_string = box_string .. " "
	end

	boxes_extmarks[line] = ext(line - 1, 0, box_string, nil, "right_align")
end --}}}

local function get_fg_color() --{{{
	local fg_color = "white"
	local rgb = color_values

	if color_mode == "hsl" then
		rgb = HSLToRGB(color_values[1], color_values[2], color_values[3])
	end

	if (rgb[1] + rgb[2] + rgb[3]) > 300 then
		fg_color = "black"
	end

	return fg_color
end --}}}

local function update_output() --{{{
	delete_ext(output_extmark)

	local arg1 = tostring(color_values[1])
	local arg2 = tostring(color_values[2])
	local arg3 = tostring(color_values[3])

	if output_type == "rgb" then
		output = "rgb(" .. arg1 .. "," .. arg2 .. "," .. arg3 .. ")"
	elseif output_type == "hex" then
		output = rgbToHex(arg1, arg2, arg3)
	elseif output_type == "hsl" then
		output = "hsl(" .. arg1 .. "," .. arg2 .. "%," .. arg3 .. "%)"
	end

	local fg_color = get_fg_color()

	if color_mode == "rgb" then
		vim.cmd(":highlight ColorPickerOutput guifg=" .. fg_color .. " guibg=" .. rgbToHex(arg1, arg2, arg3))
	elseif color_mode == "hsl" then
		vim.cmd(":highlight ColorPickerOutput guifg=" .. fg_color .. " guibg=" .. hslToHex(arg1, arg2, arg3))
	end

	output_extmark = ext(3, 0, output, "ColorPickerOutput", "right_align")
end --}}}

local function change_output_type() --{{{
	if output_type == "rgb" then
		output_type = "hsl"
	elseif output_type == "hsl" then
		output_type = "hex"
	elseif output_type == "hex" then
		output_type = "rgb"
	end
	update_output()
end --}}}

local function update_number(curline, increment) --{{{
	local colorValue = color_values[curline]
	delete_ext(color_value_extmarks[curline])

	local new_value = colorValue + increment
	color_value_extmarks[curline] = ext(curline - 1, 0, string_fix_right(new_value, 4))
	color_values[curline] = new_value

	update_boxes(curline)
	update_output()
end --}}}

local function change_color_value(increment, modify) --{{{
	local curline = api.nvim_win_get_cursor(0)[1]
	local colorValue = color_values[curline]

	if modify == "increase" then
		increment = increment or 1
	else
		increment = -increment or -1
	end

	local pass = false

	if modify == "increase" then
		if color_mode == "rgb" and (colorValue + increment <= 255) then
			pass = true
		elseif color_mode == "hsl" then
			if curline == 1 and (colorValue + increment <= 360) then
				pass = true
			elseif colorValue + increment <= 100 then
				pass = true
			end
		end
	else
		if color_mode == "rgb" and (colorValue + increment >= 0) then
			pass = true
		elseif color_mode == "hsl" and (colorValue + increment >= 0) then
			pass = true
		end
	end

	if pass then
		update_number(curline, increment)
	end
end --}}}

local function change_color_mode() --{{{
	if color_mode == "rgb" then
		color_mode = "hsl"
		output_type = "hsl"
		color_values = RGBToHSL(color_values[1], color_values[2], color_values[3])
	else
		color_mode = "rgb"
		output_type = "rgb"
		color_values = HSLToRGB(color_values[1], color_values[2], color_values[3])
	end

	set_color_marks(color_mode)
	update_number(1, 0)
	update_number(2, 0)
	update_number(3, 0)
end --}}}

local function setup_virt_text() ---create initial virtual text{{{
	-- first column
	set_color_marks(color_mode)

	-- third column
	local boxes_text = { "", "", "" }
	for i, value in ipairs(boxes_text) do
		boxes_extmarks[i] = ext(i - 1, 0, value, nil, "right_align")
	end

	-- second column
	local color_values_text = { "   0", "   0", "   0" }

	for i, value in ipairs(color_values_text) do
		color_value_extmarks[i] = ext(i - 1, 0, value)
	end

	--- last row
	output_extmark = ext(3, 0, "rgb(0,0,0)", nil, "right_align")
end --}}}

-------------------------------------
local function detect_colors(str) --{{{
	local hex_pattern = "#%x%x%x%x%x%x"
	local rgb_pattern = "rgb%(%s*%d+%s*,%s*%d+%s*,%s*%d+%s*%)"
	local hsl_pattern = "hsl%(%s*%d+%s*,%s*%d+%s*,%s*%d+%s*%)"

	local results = {}
	local patterns = { hex_pattern, rgb_pattern, hsl_pattern }

	for _, pattern in ipairs(patterns) do
		local start_index = 1
		while true do
			local _start, _end = string.find(str, pattern, start_index)
			local _match = string.match(str, pattern, start_index)

			if _start == nil then
				break
			end

			table.insert(results, { _start, _end, _match })
			start_index = _end + 1
		end
	end

	return results
end --}}}

local function sandwich(cur_buf, cur_line, cur_pos, replace_text) --{{{
	N(cur_line)
	-- get cur_line, cur_pos
	local cur_pos_row = cur_pos[1]
	local cur_pos_col = cur_pos[2]

	-- get colorRanges
	local colorRanges = detect_colors(cur_line)

	-- loop through colorRanges, find if any sandwiches the cursor
	for _, color in ipairs(colorRanges) do
		local start_pos = color[1] - 1
		local end_pos = color[2]

		if start_pos <= cur_pos_col and end_pos >= cur_pos_col then
			-- api.nvim_buf_set_text(0, cur_pos_row - 1, start_pos, cur_pos_row - 1, end_pos, { color[3] })
			api.nvim_buf_set_text(cur_buf, cur_pos_row - 1, start_pos, cur_pos_row - 1, end_pos, { replace_text })
		end
	end
end --}}}

-------------------------------------
local function apply_color()
	sandwich(target_buf, target_line, target_pos, output)
	api.nvim_win_hide(win)
end

local function set_mappings() ---set default mappings for popup window{{{
	local mappings = {
		["q"] = ":q<cr>",
		["<Esc>"] = ":q<cr>",
		["h"] = function()
			change_color_value(1, "decrease")
		end,
		["l"] = function()
			change_color_value(1, "increase")
		end,
		["o"] = function()
			change_output_type()
		end,
		["r"] = function()
			change_color_mode()
		end,
		["<CR>"] = function()
			apply_color()
		end,
	}

	for key, mapping in pairs(mappings) do
		vim.keymap.set("n", key, mapping, { buffer = buf, silent = true })
	end
end --}}}

M.pop = function() --{{{
	target_buf = api.nvim_get_current_buf()
	target_line = api.nvim_get_current_line()
	target_pos = api.nvim_win_get_cursor(0)

	buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_option(buf, "filetype", "color-picker")

	win = vim.api.nvim_open_win(buf, true, {
		relative = "cursor",
		width = 18,
		col = 0,
		row = 0,
		style = "minimal",
		height = 4,
		border = "rounded",
	})

	-- reset color values
	color_values = { 0, 0, 0 }

	set_mappings()
	create_empty_lines()
	setup_virt_text()

	vim.api.nvim_buf_set_option(buf, "modifiable", false)
end --}}}
return M
