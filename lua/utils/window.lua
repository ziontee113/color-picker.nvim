local M = {}

local win = nil
local buf = nil

local function set_mappings(win)
	local mappings = {
		["q"] = ":q<cr>",
	}

	for key, mapping in ipairs(mappings) do
		N({ key, mapping })
		vim.keymap.set("n", key, mapping, { noremap = true, silent = true })
	end
end

M.pop = function()
	buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_option(buf, "modifiable", false)
	vim.api.nvim_buf_set_option(buf, "filetype", "color-picker")

	win = vim.api.nvim_open_win(buf, true, {
		relative = "cursor",
		width = 50,
		col = 0,
		row = 0,
		style = "minimal",
		height = 4,
		border = "rounded",
	})

	set_mappings(win)
end

return M
