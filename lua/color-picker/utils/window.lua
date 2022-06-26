local M = {}
local api = vim.api

local win = nil
local buf = nil

local function set_mappings(buf)
	local mappings = {
		["q"] = ":q<cr>",
		["<Esc>"] = ":q<cr>",
	}

	for key, mapping in pairs(mappings) do
		vim.keymap.set("n", key, mapping, { buffer = buf, silent = true })
	end
end

local function center_my_text(str, width)
	return string.rep(" ", math.floor(width - #str) / 2) .. str
end

local function create_lines(buf)
	api.nvim_buf_set_lines(buf, 0, -1, false, {
		"R",
		"G",
		"B",
		center_my_text("rgb(0,0,0)", 20),
	})
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

	set_mappings(buf)
	create_lines(buf)

	vim.api.nvim_buf_set_option(buf, "modifiable", false)
end

return M
