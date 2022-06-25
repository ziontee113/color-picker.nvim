local M = {}

local buf = vim.api.nvim_create_buf(false, true)

M.pop = function()
	vim.api.nvim_buf_set_option(buf, "modifiable", false)
	vim.api.nvim_buf_set_option(buf, "filetype", "color-picker")

	local win = vim.api.nvim_open_win(buf, true, {
		relative = "cursor",
		width = 20,
		col = 0,
		row = 0,
		style = "minimal",
		height = 4,
		border = "rounded",
	})
end

P("hello")

return M
