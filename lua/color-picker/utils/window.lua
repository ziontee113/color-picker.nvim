local M = {}
local api = vim.api

local win = nil
local buf = nil
local ns = api.nvim_create_namespace("color-picker-popup")

local color_value_extmarks = {}
local color_values = { 0, 0, 0 }
local boxes_extmarks = {}

---create empty lines in the popup so we can set extmarks
local function create_empty_lines()
	api.nvim_buf_set_lines(buf, 0, -1, false, {
		"",
		"",
		"",
		"",
	})
end

---shortcut to create extmarks
local function ext(row, col, text, hl_group, virt_text_pos)
	return api.nvim_buf_set_extmark(buf, ns, row, col, {
		virt_text = { { text, hl_group or "Normal" } },
		virt_text_pos = virt_text_pos or "eol",
	})
end

---create initial virtual text
local function setup_virt_text()
	-- first column
	local rgb = { "R", "G", "B" }

	for i, value in ipairs(rgb) do
		ext(i - 1, 0, value, nil, "overlay")
	end

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
	ext(3, 0, "rgb(0, 0, 0)", nil, "right_align")
end

---shortcut for delete extmarks given an id
local function delete_ext(id)
	api.nvim_buf_del_extmark(buf, ns, id)
end

local function string_fix_right(str, width)
	if type(str) == "number" then
		str = tostring(str)
	end

	local number_of_spaces = width - #str

	return string.rep(" ", number_of_spaces) .. str
end

local function update_boxes(line)
	delete_ext(boxes_extmarks[line])

	local floor = math.floor(color_values[line] / 25.5)
	local arithmetic = color_values[line] / 25.5 - floor

	local box_string = ""

	if arithmetic ~= 0 then
		box_string = ""
	end

	for i = 1, floor, 1 do
		box_string = "ﱢ" .. box_string
	end

	for i = 2, 10 - floor do
		box_string = box_string .. " "
	end

	boxes_extmarks[line] = ext(line - 1, 0, box_string, nil, "right_align")
end

local function decrease_color_value(increment)
	local curline = api.nvim_win_get_cursor(0)[1]
	local colorValue = color_values[curline]

	increment = increment or 1

	if colorValue - increment >= 0 then
		delete_ext(color_value_extmarks[curline])

		local new_value = colorValue - increment
		color_value_extmarks[curline] = ext(curline - 1, 0, string_fix_right(new_value, 4))
		color_values[curline] = new_value

		update_boxes(curline)
	end
end

local function increase_color_value(increment)
	local curline = api.nvim_win_get_cursor(0)[1]
	local colorValue = color_values[curline]

	increment = increment or 1

	if colorValue + increment <= 255 then
		delete_ext(color_value_extmarks[curline])

		local new_value = colorValue + increment
		color_value_extmarks[curline] = ext(curline - 1, 0, string_fix_right(new_value, 4))
		color_values[curline] = new_value

		update_boxes(curline)
	end
end

local function set_mappings() ---set default mappings for popup window
	local mappings = {
		["q"] = ":q<cr>",
		["<Esc>"] = ":q<cr>",
		["h"] = function()
			decrease_color_value(5)
		end,
		["l"] = function()
			increase_color_value(5)
		end,
	}

	for key, mapping in pairs(mappings) do
		vim.keymap.set("n", key, mapping, { buffer = buf, silent = true })
	end
end

M.pop = function()
	buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_option(buf, "filetype", "color-picker")

	win = vim.api.nvim_open_win(buf, true, {
		relative = "cursor",
		width = 17,
		col = 0,
		row = 0,
		style = "minimal",
		height = 4,
		border = "rounded",
	})

	set_mappings()
	create_empty_lines()
	setup_virt_text()

	vim.api.nvim_buf_set_option(buf, "modifiable", false)
end

return M
