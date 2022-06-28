local M = {}
local api = vim.api
local utils = require("color-picker.utils")

-------------------------------------

local win = nil
local buf = nil
local ns = api.nvim_create_namespace("color-picker-popup")

local user_mappings = {}

-------------------------------------

local rgbToHex = utils.rgbToHex
local round = utils.round
local HSLToRGB = utils.HSLToRGB
local RGBToHSL = utils.RGBToHSL
local hslToHex = utils.hslToHex
local HexToRGB = utils.HexToRGB

-------------------------------------

M.user_settings = {
	-- ["icons"] = { "ﮊ", "" },
	["icons"] = { "ﱢ", "" },
}

-------------------------------------

vim.cmd(":highlight ColorPickerOutput guifg=#white")
vim.cmd(":highlight ColorPickerActionGroup guifg=#00F1F5")

local output_type = "rgb"
local color_mode = "rgb"

---@diagnostic disable-next-line: unused-local
local alpha_slider_A = nil
local potential_win_width = 6
local global_space_relativity = 17

local color_mode_extmarks = {}
local color_value_extmarks = {}
local color_values = { 0, 0, 0, nil, 100 }
local boxes_extmarks = {}
local output_extmark = {}
local output = nil
local action_group = {}
local print_output_mode = nil
local sandwich_mode = false

local transparency_mode = false

local target_buf = nil
local target_line = nil
local target_pos = nil

-------------------------------------

local function create_empty_lines() ---create empty lines in the popup so we can set extmarks{{{
	api.nvim_buf_set_lines(buf, 0, -1, false, {
		"",
		"",
		"",
		"",
		"",
	})
end --}}}

local function delete_ext(id) -- shortcut for delete extmarks given an id{{{
	if id then
		api.nvim_buf_del_extmark(buf, ns, id)
	end
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

	alpha_slider_A = ext(4, 0, "A", nil, "overlay")

	-- action_group highlighting --
	if #action_group > 0 then
		for _, line in ipairs(action_group) do
			delete_ext(color_mode_extmarks[line])
			color_mode_extmarks[line] = ext(line - 1, 0, string.upper(t[line]), "ColorPickerActionGroup", "overlay")
		end
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

	if line == 5 then --> for alpha slider
		floor = math.floor(color_values[line] / 10)
		arithmetic = color_values[line] / 10 - floor
	end

	-- transparency slider implementation
	local space_relativity = 10
	if transparency_mode == true then
		space_relativity = global_space_relativity
		arithmetic = math.ceil(arithmetic * space_relativity / 10)
		floor = math.ceil(floor * space_relativity / 10)
	end

	local box_string = " "

	if arithmetic ~= 0 then
		box_string = M.user_settings.icons[2]
	end

	for _ = 1, floor, 1 do
		-- box_string = "ﱢ" .. box_string
		box_string = M.user_settings.icons[1] .. box_string
	end

	for _ = 1, space_relativity - floor do
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
	local alpha_value = tostring(color_values[5] / 100)

	local alpha_string = ""
	local alpha_value_string = ""
	if transparency_mode == true then
		alpha_string = "a"
		alpha_value_string = ", " .. alpha_value
	end

	if output_type == "rgb" then
		if color_mode == "hsl" then
			local converted_rgb = HSLToRGB(arg1, arg2, arg3)
			output = "rgb("
				.. alpha_string
				.. converted_rgb[1]
				.. ", "
				.. converted_rgb[2]
				.. ", "
				.. converted_rgb[3]
				.. ")"
		else
			output = "rgb" .. alpha_string .. "(" .. arg1 .. ", " .. arg2 .. ", " .. arg3 .. alpha_value_string .. ")"
		end
	elseif output_type == "hex" then
		if color_mode == "rgb" then
			output = rgbToHex(arg1, arg2, arg3)
		else
			output = hslToHex(arg1, arg2, arg3)
		end
	elseif output_type == "hsl" then
		output = "hsl"
			.. alpha_string
			.. "("
			.. arg1
			.. ", "
			.. arg2
			.. "%, "
			.. arg3
			.. "%"
			.. alpha_value_string
			.. ")"
	end

	local fg_color = get_fg_color()

	if color_mode == "rgb" then
		vim.cmd(":highlight ColorPickerOutput guifg=" .. fg_color .. " guibg=" .. rgbToHex(arg1, arg2, arg3))
	elseif color_mode == "hsl" then
		vim.cmd(":highlight ColorPickerOutput guifg=" .. fg_color .. " guibg=" .. hslToHex(arg1, arg2, arg3))
	end

	output_extmark = ext(3, 0, output:gsub("%s+", ""), "ColorPickerOutput", "right_align")
end --}}}

local function change_output_type() --{{{
	if transparency_mode == true then
		if output_type == "rgb" then
			output_type = "hsl"
		elseif output_type == "hsl" then
			output_type = "rgb"
		end
	else
		if output_type == "rgb" then
			output_type = "hsl"
		elseif output_type == "hsl" then
			output_type = "hex"
		elseif output_type == "hex" then
			output_type = "rgb"
		end
	end

	update_output()
end --}}}

local function check_valid_number(curline) --{{{
	if curline == 5 and color_values[curline] > 100 then
		color_values[curline] = 100
	else
		if color_mode == "rgb" then
			if color_values[curline] > 255 or color_values[curline] < 0 then
				color_values[curline] = 0
			end
		else -- hsl
			if curline == 1 then
				if color_values[curline] > 360 or color_values[curline] < 0 then
					color_values[curline] = 0
				end
			else
				if (color_values[curline] > 100 or color_values[curline]) < 0 then
					color_values[curline] = 0
				end
			end
		end
	end

	return color_values[curline]
end --}}}

local function update_number(curline, increment) --{{{
	local colorValue = check_valid_number(curline)
	delete_ext(color_value_extmarks[curline])

	local new_value = colorValue + increment
	color_value_extmarks[curline] = ext(curline - 1, 0, string_fix_right(new_value, 4))
	color_values[curline] = new_value

	update_boxes(curline)
	update_output()
end --}}}

local function change_color_value(increment, modify, line) --{{{
	local curline = line or api.nvim_win_get_cursor(0)[1]
	local colorValue = color_values[curline]

	if modify == "increase" then
		increment = increment or 1
	else
		increment = -increment or -1
	end

	local pass = false

	if modify == "increase" then
		if curline == 5 then --> modifying transparency slider
			if colorValue + increment <= 100 then
				pass = true
			end
		else
			if color_mode == "rgb" and (colorValue + increment <= 255) then
				pass = true
			elseif color_mode == "hsl" then
				if curline == 1 and (colorValue + increment <= 360) then
					pass = true
				elseif colorValue + increment <= 100 then
					pass = true
				end
			end
		end
	else -- decrease
		if curline == 5 then
			if colorValue + increment >= 0 then
				pass = true
			end
		else
			if color_mode == "rgb" and (colorValue + increment >= 0) then
				pass = true
			elseif color_mode == "hsl" and (colorValue + increment >= 0) then
				pass = true
			end
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
		local converted_color = RGBToHSL(color_values[1], color_values[2], color_values[3])
		color_values = { converted_color[1], converted_color[2], converted_color[3], color_values[4], color_values[5] }
	else
		color_mode = "rgb"
		output_type = "rgb"
		local converted_color = HSLToRGB(color_values[1], color_values[2], color_values[3])
		color_values = { converted_color[1], converted_color[2], converted_color[3], color_values[4], color_values[5] }
	end

	set_color_marks(color_mode)
	update_number(1, 0)
	update_number(2, 0)
	update_number(3, 0)
	update_number(5, 0)
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
	local color_values_text = { "   0", "   0", "   0", " 100" }

	for i, value in ipairs(color_values_text) do
		if i == 4 then
			color_value_extmarks[5] = ext(4, 0, value)
		else
			color_value_extmarks[i] = ext(i - 1, 0, value)
		end
	end

	--- last row
	output_extmark = ext(3, 0, "rgb(0,0,0)", nil, "right_align")
end --}}}

-------------------------------------

local function toggle_transparency_slider() --{{{
	local win_width = api.nvim_win_get_width(win)
	local win_height = api.nvim_win_get_height(win)

	if transparency_mode == false then
		transparency_mode = true

		api.nvim_win_set_width(win, win_width + potential_win_width)
		api.nvim_win_set_height(win, win_height + 1)

		if output_type == "hex" then
			output_type = color_mode
		end
	else
		transparency_mode = false

		api.nvim_win_set_width(win, win_width - potential_win_width)
		api.nvim_win_set_height(win, win_height - 1)
	end

	update_number(1, 0)
	update_number(2, 0)
	update_number(3, 0)
	update_number(5, 0)
end --}}}

-------------------------------------

local function set_color_line_value(value, line) --{{{
	if color_mode == "rgb" then
		if value > 255 then
			value = 255
		end
	else -- color_mode == "hsl"
		if line == 1 then
			if value > 360 then
				value = 360
			end
		else
			if value > 100 then
				value = 100
			end
		end
	end

	if line == 5 and value > 100 then
		value = 100
	end

	local increment = value - color_values[line]
	change_color_value(increment, "increase", line)
end --}}}

local function set_color_line_percent(percent, line) --{{{
	local value = 0
	if color_mode == "rgb" then
		value = round(percent / 100 * 255)
	else
		if line == 1 then
			value = round(percent / 100 * 360)
		else
			value = percent
		end
	end

	if line == 5 then
		value = percent
	end

	local increment = value - color_values[line]
	change_color_value(increment, "increase", line)
end --}}}

-------------------------------------

local function action_color_percent(percent, line) --{{{
	if #action_group > 0 then
		for _, cur_line in ipairs(action_group) do
			set_color_line_percent(percent, cur_line)
		end
	else
		if line == 4 then
			set_color_line_percent(percent, 1)
			set_color_line_percent(percent, 2)
			set_color_line_percent(percent, 3)
		else
			set_color_line_percent(percent, line)
		end
	end
end --}}}

local function action_color_increment(increment, modify) --{{{
	if #action_group > 0 then
		for _, line in ipairs(action_group) do
			change_color_value(increment, modify, line)
		end
	else
		local curline = api.nvim_win_get_cursor(0)[1]
		if curline == 4 then
			for line = 1, 3 do
				change_color_value(increment, modify, line)
			end
		else
			change_color_value(increment, modify)
		end
	end
end --}}}

local function action_color_value(value, line) --{{{
	if #action_group > 0 then
		for _, cur_line in ipairs(action_group) do
			set_color_line_value(value, cur_line)
		end
	else
		if line == 4 then
			set_color_line_value(value, 1)
			set_color_line_value(value, 2)
			set_color_line_value(value, 3)
		else
			set_color_line_value(value, line)
		end
	end
end --}}}

local function set_action_group(group) --{{{
	action_group = group

	set_color_marks(color_mode)
end --}}}

-------------------------------------

local manual_numeric_input_count = 0

local function manual_numeric_input_process(line) --{{{
	local ok, keynum = pcall(vim.fn.getchar)

	if ok then
		local actual_key = keynum - 48

		if actual_key >= 0 and actual_key <= 9 then -- key pressed is 0 to 9
			line = line or api.nvim_win_get_cursor(0)[1]
			local new_value = actual_key

			if manual_numeric_input_count > 0 then
				if #action_group > 0 then
					new_value = actual_key + color_values[action_group[1]] * 10
				else
					if line ~= 4 then
						new_value = actual_key + color_values[line] * 10
					else
						new_value = actual_key + color_values[1] * 10
					end
				end
			end

			action_color_value(new_value, line)

			if manual_numeric_input_count < 2 then
				manual_numeric_input_count = manual_numeric_input_count + 1
				vim.cmd([[redraw]])
				manual_numeric_input_process()
			end
		else
			local actual_char = vim.fn.nr2char(keynum)
			if actual_char ~= "n" then
				api.nvim_feedkeys(actual_char, "n", true)
			end
		end
	end
end --}}}

local function manual_numeric_input_start() --{{{
	manual_numeric_input_count = 0
	manual_numeric_input_process()
end --}}}

-------------------------------------

local function detect_colors(str) --{{{
	local hex_pattern = "#%x%x%x%x%x%x"
	local rgb_pattern = "rgba?%(%s*%d+%s*,%s*%d+%s*,%s*%d+%s*.*%)"
	local hsl_pattern = "hsla?%(%s*%d+%s*,%s*%d+%s*%%*,%s*%d+%s*%%*.*%)"

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

local function sandwich_detector(cur_buf, cur_line, cur_pos, replace_text) --{{{
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
			return color[3]
		end
	end
end --}}}

local function sandwich(cur_buf, cur_line, cur_pos, replace_text) --{{{
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

local function sandwich_processor(str) --{{{
	local hex_capture_pattern = "#(%x%x%x%x%x%x)"
	local rgba_capture_pattern = "rgba%(%s*(%d+)%s*,%s*(%d+)%s*,%s*(%d+)%s*,?%s*(%d+%.?%d*)%s*%)"
	local hsla_capture_pattern = "hsla%(%s*(%d+)%s*,%s*(%d+)%s*%%*,%s*(%d+)%s*%%,?%s*(%d+%.?%d*)%s*%)"
	local rgb_capture_pattern = "rgb%(%s*(%d+)%s*,%s*(%d+)%s*,%s*(%d+)%s*,?%s*%)"
	local hsl_capture_pattern = "hsl%(%s*(%d+)%s*,%s*(%d+)%s*%%*,%s*(%d+)%s*%%,?%s*%)"

	local _, _, hex = string.find(str, hex_capture_pattern)
	local _, _, ra, ga, ba, rgba = string.find(str, rgba_capture_pattern)
	local _, _, ha, sa, la, hsla = string.find(str, hsla_capture_pattern)
	local _, _, r, g, b = string.find(str, rgb_capture_pattern)
	local _, _, h, s, l = string.find(str, hsl_capture_pattern)

	if hex then
		return { "hex", hex }
	elseif ra then
		return { "rgb", tonumber(ra), tonumber(ga), tonumber(ba), tonumber(rgba) }
	elseif ha then
		return { "hsl", tonumber(ha), tonumber(sa), tonumber(la), tonumber(hsla) }
	elseif r then
		return { "rgb", tonumber(r), tonumber(g), tonumber(b) }
	elseif h then
		return { "hsl", tonumber(h), tonumber(s), tonumber(l) }
	end
end --}}}

-------------------------------------

local function print_output_no_sandwich() --{{{
	if print_output_mode == "normal" then
		vim.cmd("normal! a" .. output)
	else
		vim.cmd("startinsert")
		vim.cmd("norm i" .. output)

		local key = vim.api.nvim_replace_termcodes("<Right>", true, true, true)
		vim.api.nvim_feedkeys(key, "i", false)
	end
end --}}}

local function apply_color() --{{{
	api.nvim_win_hide(win)

	if sandwich_mode == true then
		sandwich(target_buf, target_line, target_pos, output)
	else
		print_output_no_sandwich()
	end
end --}}}

local function set_mappings() ---set default mappings for popup window{{{
	local mappings = {
		["j"] = function() --{{{ --> limit the user if transparency_mode == false
			local line = api.nvim_win_get_cursor(0)[1]
			if (transparency_mode == false and line < 4) or transparency_mode == true then
				vim.cmd([[norm! j]])
			else
				-- do something
			end
		end, --}}}

		["<Plug>Slider50Percent"] = function() --{{{ HML percent set
			local line = api.nvim_win_get_cursor(0)[1]
			action_color_percent(50, line)
		end,
		["<Plug>Slider0Percent"] = function()
			local line = api.nvim_win_get_cursor(0)[1]
			action_color_percent(0, line)
		end,
		["<Plug>Slider100Percent"] = function()
			local line = api.nvim_win_get_cursor(0)[1]
			action_color_percent(100, line)
		end, --}}}

		["H"] = "<Plug>Slider0Percent",
		["M"] = "<Plug>Slider50Percent",
		["L"] = "<Plug>Slider100Percent",

		["<Plug>Slider10Percent"] = function() --{{{
			local line = api.nvim_win_get_cursor(0)[1]
			action_color_percent(10, line)
		end,
		["<Plug>Slider20Percent"] = function()
			local line = api.nvim_win_get_cursor(0)[1]
			action_color_percent(20, line)
		end,
		["<Plug>Slider30Percent"] = function()
			local line = api.nvim_win_get_cursor(0)[1]
			action_color_percent(30, line)
		end,
		["<Plug>Slider40Percent"] = function()
			local line = api.nvim_win_get_cursor(0)[1]
			action_color_percent(40, line)
		end,
		["<Plug>Slider60Percent"] = function()
			local line = api.nvim_win_get_cursor(0)[1]
			action_color_percent(60, line)
		end,
		["<Plug>Slider70Percent"] = function()
			local line = api.nvim_win_get_cursor(0)[1]
			action_color_percent(70, line)
		end,
		["<Plug>Slider80Percent"] = function()
			local line = api.nvim_win_get_cursor(0)[1]
			action_color_percent(80, line)
		end,
		["<Plug>Slider90Percent"] = function()
			local line = api.nvim_win_get_cursor(0)[1]
			action_color_percent(90, line)
		end, --}}}
		["0"] = "<Plug>Slider0Percent", --{{{
		["1"] = "<Plug>Slider10Percent",
		["2"] = "<Plug>Slider20Percent",
		["3"] = "<Plug>Slider30Percent",
		["4"] = "<Plug>Slider40Percent",
		["5"] = "<Plug>Slider50Percent",
		["6"] = "<Plug>Slider60Percent",
		["7"] = "<Plug>Slider70Percent",
		["8"] = "<Plug>Slider80Percent",
		["9"] = "<Plug>Slider90Percent", --}}}

		["<Plug>Slider10Decrease"] = function() --{{{ wasd hl increment
			action_color_increment(10, "decrease")
		end,
		["<Plug>Slider10Increase"] = function()
			action_color_increment(10, "increase")
		end,

		["<Plug>Slider5Decrease"] = function()
			action_color_increment(5, "decrease")
		end,
		["<Plug>Slider5Increase"] = function()
			action_color_increment(5, "increase")
		end,

		["<Plug>Slider1Decrease"] = function()
			action_color_increment(1, "decrease")
		end,
		["<Plug>Slider1Increase"] = function()
			action_color_increment(1, "increase")
		end, --}}}
		["h"] = "<Plug>Slider1Decrease", --{{{
		["l"] = "<Plug>Slider1Increase",
		["u"] = "<Plug>Slider5Decrease",
		["i"] = "<Plug>Slider5Increase",
		["a"] = "<Plug>Slider5Decrease",
		["d"] = "<Plug>Slider5Increase",
		["A"] = "<Plug>Slider5Decrease",
		["D"] = "<Plug>Slider5Increase",
		["s"] = "<Plug>Slider10Decrease",
		["w"] = "<Plug>Slider10Increase",
		["S"] = "<Plug>Slider10Decrease",
		["W"] = "<Plug>Slider10Increase", --}}}

		["<Plug>SetActionGroup1and2"] = function() --{{{
			set_action_group({ 1, 2 })
		end,
		["<Plug>SetActionGroup2and3"] = function()
			set_action_group({ 2, 3 })
		end,
		["<Plug>SetActionGroup123"] = function()
			set_action_group({ 1, 2, 3 })
		end,
		["<Plug>SetActionGroup1and3"] = function()
			set_action_group({ 1, 3 })
		end,
		["<Plug>ClearActionGroup"] = function()
			set_action_group({})
		end, --}}}
		["gu"] = "<Plug>SetActionGroup1and2", --{{{
		["gd"] = "<Plug>SetActionGroup2and3",
		["go"] = "<Plug>SetActionGroup123",
		["gm"] = "<Plug>SetActionGroup1and3",
		["x"] = "<Plug>ClearActionGroup", --}}}

		["q"] = ":q<cr>",
		["<Esc>"] = ":q<cr>",

		["<Plug>ChangeOutputType"] = function()
			change_output_type()
		end,
		["o"] = "<Plug>ChangeOutputType",

		["<Plug>ChangeColorMode"] = function()
			change_color_mode()
		end,
		["r"] = "<Plug>ChangeColorMode",

		["<Plug>ApplyColor"] = function()
			apply_color()
		end,
		["<cr>"] = "<Plug>ApplyColor",

		["<Plug>ToggleTransparency"] = function()
			toggle_transparency_slider()
		end,
		["t"] = "<Plug>ToggleTransparency",

		["<Plug>NumericInput"] = function()
			manual_numeric_input_start()
		end,
		["n"] = "<Plug>NumericInput",
	}

	for key, mapping in pairs(mappings) do
		vim.keymap.set("n", key, mapping, { buffer = buf, silent = true })
	end

	for key, mapping in pairs(user_mappings) do
		vim.keymap.set("n", key, mapping, { buffer = buf, silent = true })
	end
end --}}}

M.pop = function(insert_or_normal_mode) --{{{
	target_buf = api.nvim_get_current_buf()
	target_line = api.nvim_get_current_line()
	target_pos = api.nvim_win_get_cursor(0)

	buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_option(buf, "filetype", "color-picker")

	api.nvim_buf_clear_namespace(buf, ns, 0, -1)

	win = vim.api.nvim_open_win(buf, true, {
		relative = "cursor",
		width = 18,
		col = 0,
		row = 0,
		style = "minimal",
		height = 4,
		border = "rounded",
	})

	-- reset color values, action_group & initialize the UI
	color_values = { 0, 0, 0, nil, 100 }
	transparency_mode = false
	action_group = {}
	set_mappings()
	create_empty_lines()
	setup_virt_text()
	update_boxes(5)

	-- detect & try to parse cursor colors {{{
	local detected_sandwich = sandwich_detector(target_buf, target_line, target_pos)

	if detected_sandwich then
		local new_sandwich = sandwich_processor(detected_sandwich)

		if new_sandwich then
			if new_sandwich[1] == "rgb" or new_sandwich[1] == "hsl" then
				color_mode = new_sandwich[1]
				output_type = new_sandwich[1]
				color_values = { new_sandwich[2], new_sandwich[3], new_sandwich[4], color_values[4], color_values[5] }

				if #new_sandwich == 5 then --> if rgba or hsla
					color_values[5] = new_sandwich[5] * 100
					if color_values[5] > 100 then
						color_values[5] = 100
					end

					update_number(5, 0)
					toggle_transparency_slider()
				end
			else
				local converted_hex = HexToRGB(new_sandwich[2])
				color_mode = "rgb"
				output_type = "hex"
				color_values = {
					converted_hex[1],
					converted_hex[2],
					converted_hex[3],
					color_values[4],
					color_values[5],
				}
			end
		end

		set_color_marks(color_mode)
		update_number(1, 0)
		update_number(2, 0)
		update_number(3, 0)

		sandwich_mode = true
	else
		sandwich_mode = false
	end

	if insert_or_normal_mode == "insert" then
		vim.cmd("stopinsert")
	end

	print_output_mode = insert_or_normal_mode --}}}

	vim.api.nvim_win_set_option(win, "scrolloff", 0)
	vim.api.nvim_buf_set_option(buf, "modifiable", false)
end --}}}

-------------------------------------

M.setup = function(user_settings) --{{{
	if user_settings then
		for key, value in pairs(user_settings) do
			if key == "keymap" then
				user_mappings = value
			else
				M.user_settings[key] = user_settings[key]
			end
		end
	end
end --}}}

return M
