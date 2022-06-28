# color-picker.nvim

A powerful plugin that lets Neovim Users choose & modify colors. This plugin supports RGB, HSL and HEX colors.

![color picker 1v2](https://user-images.githubusercontent.com/102876811/175996319-58bd7237-9fe2-428a-ba86-f10df440c0a9.jpg)

## Usage:

You can watch the full demo of the plugin here: [Color Picker for Neovim! - color-picker.nvim Plugin Showcase](https://youtu.be/eWRoxJatH8A)

![color picker 2](https://user-images.githubusercontent.com/102876811/176300677-7f12b1f7-1bc2-421b-8944-af45f01088fe.png)

Transparency Slider & Numeric Input Update: [Transparency Slider Support! - color-picker.nvim Development Update](https://youtu.be/lm7LAOFkceA)

## Requirements:

Neovim `0.7` or higher.

## Installation:

For Packer

```lua
use "ziontee113/color-picker.nvim"
```

## Set Things Up:

```lua
local opts = { noremap = true, silent = true }

vim.keymap.set("n", "<C-c>", "<cmd>PickColor<cr>", opts)
vim.keymap.set("i", "<C-c>", "<cmd>PickColorInsert<cr>", opts)

-- only need setup() if you want to change progress bar icons or set / remap the picker's keymaps
require("color-picker").setup({
	-- ["icons"] = { "ﱢ", "" },
	-- ["icons"] = { "ﮊ", "" },
	-- ["icons"] = { "", "ﰕ" },
	-- ["icons"] = { "", "" },
	-- ["icons"] = { "", "" },
	["icons"] = { "ﱢ", "" },
	["keymap"] = { -- mapping example:
		["U"] = "<Plug>Slider5Decrease",
		["O"] = "<Plug>Slider5Increase",
	},
})

vim.cmd([[hi FloatBorder guibg=NONE]]) -- if you don't want weird border background colors around the popup.
```

## Todo:

- Write README properly instead of relying on the Youtube video.
- Write Help Docs.

## Feedback

If you run into issues or come up with an awesome idea, please feel free to open an issue or PR.

## License

The project is licensed under MIT license. See [LICENSE](./LICENSE) file for details.

## Credits

### @max397574 for creating https://github.com/max397574/colortils.nvim. I learned a lot how to do Neovim UI from his work.

### And I'm very sorry I didn't credit him in my initial post.
