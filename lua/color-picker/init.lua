---@diagnostic disable: undefined-global
local M = {}
local api = vim.api
local utils_window = require("color-picker.utils.window")

-------------------------------------

M.setup = utils_window.setup
M.convert_cursor_color = utils_window.convert_cursor_color

vim.api.nvim_create_user_command("PickColor", function()
	utils_window.pop("normal")
end, {})
vim.api.nvim_create_user_command("PickColorInsert", function()
	utils_window.pop("insert")
end, {})
vim.api.nvim_create_user_command("ConvertHEXandRGB", function()
	utils_window.convert_cursor_color("rgb")
end, {})
vim.api.nvim_create_user_command("ConvertHEXandHSL", function()
	utils_window.convert_cursor_color("hsl")
end, {})

return M
