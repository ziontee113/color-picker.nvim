---@diagnostic disable: undefined-global
local M = {}
local api = vim.api
local utils_window = require("color-picker.utils.window")

-------------------------------------

vim.api.nvim_create_user_command("PickColor", function()
	utils_window.pop("normal")
end, {})
vim.api.nvim_create_user_command("PickColorInsert", function()
	utils_window.pop("insert")
end, {})

M.setup = utils_window.setup

return M
