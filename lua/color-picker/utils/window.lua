local M = {}
local api = vim.api

local win = nil
local buf = nil
local ns = api.nvim_create_namespace("color-picker-popup")

local function set_mappings()
	local mappings = {
		["q"] = ":q<cr>",
		["<Esc>"] = ":q<cr>",
		-- ["h"] = ":q<cr>",
		-- ["l"] = ":q<cr>",
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

---call this function to create initial virtual text
local function create_virt_text()
	local arr = { "R", "G", "B", align_right_text("rgb(0,0,0)", 20) }

	for index, value in ipairs(arr) do
		api.nvim_buf_set_extmark(buf, ns, index - 1, 0, {
			virt_text = { { value, "Normal" } },
			virt_text_pos = "overlay",
		})
	end
end

M.pop = function()
	buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_option(buf, "filetype", "color-picker")

	win = vim.api.nvim_open_win(buf, true, {
		relative = "cursor",
		width = 20,
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
