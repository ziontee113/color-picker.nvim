local M = {}
local api = vim.api

local win = nil
local buf = nil
local ns = api.nvim_create_namespace("color-picker-popup")

local color_values = {}
local boxes = {}

local function delete_ext(id)
	api.nvim_buf_del_extmark(buf, ns, id)
end

local function set_mappings()
	local mappings = {
		["q"] = ":q<cr>",
		["<Esc>"] = ":q<cr>",
		["h"] = function()
			delete_ext(boxes[1])
		end,
		["l"] = ":q<cr>",
	}

	for key, mapping in pairs(mappings) do
		vim.keymap.set("n", key, mapping, { buffer = buf, silent = true })
	end
end

local function center_my_text(str, width)
	return string.rep(" ", math.floor(width - #str) / 2) .. str
end

local function align_right_text(str, width)
	return string.rep(" ", width - #str) .. str
end

local function create_empty_lines()
	api.nvim_buf_set_lines(buf, 0, -1, false, {
		"",
		"",
		"",
		"",
	})
end

---a shortcut to create extmarks
local function ext(row, col, text, hl_group, virt_text_pos)
	return api.nvim_buf_set_extmark(buf, ns, row, col, {
		virt_text = { { text, hl_group or "Normal" } },
		virt_text_pos = virt_text_pos or "eol",
	})
end

---call this function to create initial virtual text
local function create_virt_text()
	-- first column
	local rgb = { "R", "G", "B" }

	for i, value in ipairs(rgb) do
		ext(i - 1, 0, value, nil, "overlay")
	end

	-- third column
	local boxes_text = { "", "           ", "           " }
	for i, value in ipairs(boxes_text) do
		boxes[i] = ext(i - 1, 0, value)
	end

	-- second column
	local color_values_text = { "   0", "   0", "   0" }

	for i, value in ipairs(color_values_text) do
		color_values[i] = ext(i - 1, 0, value)
	end

	--- last row
	ext(3, 0, "rgb(0, 0, 0)", nil, "right_align")
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
	create_virt_text()

	vim.api.nvim_buf_set_option(buf, "modifiable", false)
end

return M
