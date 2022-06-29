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
use ({"ziontee113/color-picker.nvim",
    config = function()
        require("color-picker")
    end,
})
```

## Set Things Up:

```lua
local opts = { noremap = true, silent = true }

vim.keymap.set("n", "<C-c>", "<cmd>PickColor<cr>", opts)
vim.keymap.set("i", "<C-c>", "<cmd>PickColorInsert<cr>", opts)

require("color-picker").setup({ -- for changing icons & mappings
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

## Features:

#### Picking Colors

By default:
- `h` and `l` will increment the color slider value by 1.
- `u` and `i` / `a` and `d` / `A` and `D` will increment the color slider value by 5.
- `s` and `w` / `S` and `W` will increment the color slider value by 10.

- Number `0` to `9` will set the slider at your cursor to certain percentages. `0` sets to 0%, `9` sets to 90%, `5` sets to 50%.
- `H` sets to 0%, `M` sets to 50%, `L` sets to 100%.

#### Multiple Sliders

By default:
- If your slider is on the `4th` line (the same line as the color output preview), when you increment / set a color value, it will apply that change to all 3 sliders above it.
- `gu` will select the 1st and 2nd sliders, `gd` will select the 2nd and 3rd sliders, `gm` will select the 1st and 3rd sliders.
- Press `x` will deselect the slider group.

#### Converting Colors (RGB/HEX/HSL)
- When your cursor is on a corlor, use `:PickColor` to open up the picker, then press `o` to change the output type to `RGB/HEX/HSL`. Press `Enter` and the color under your cursor will be converted.

#### Transparency Mode
- Press `t` to toggle Transparency Slider. While this mode is active, you will only be able to output the color as `rgba()` or `hsla()`. If you want to output as `HEX`, press `t` to get out of Transparency Mode, and you'll be able to press `o` to output your color as `HEX`.

### Available Commands:

<details>
<summary>Click this Dropdown to see Available Commands</summary>
	
```
<Plug>Slider10Decrease
<Plug>Slider10Increase
<Plug>Slider5Decrease
<Plug>Slider5Increase
<Plug>Slider1Decrease
<Plug>Slider1Increase

<Plug>Slider0Percent
<Plug>Slider10Percent
<Plug>Slider20Percent
<Plug>Slider30Percent
<Plug>Slider40Percent
<Plug>Slider50Percent
<Plug>Slider60Percent
<Plug>Slider70Percent
<Plug>Slider80Percent
<Plug>Slider90Percent
<Plug>Slider100Percent

<Plug>SetActionGroup1and2
<Plug>SetActionGroup2and3
<Plug>SetActionGroup123
<Plug>SetActionGroup1and3
<Plug>ClearActionGroup

<Plug>ChangeOutputType
<Plug>ChangeColorMode
<Plug>ApplyColor
<Plug>ToggleTransparency
<Plug>NumericInput
```
	
</details>

## Todo:

- Write README properly instead of relying on the Youtube video.
- Write Help Docs.

## Feedback

If you run into issues or come up with an awesome idea, please feel free to open an issue or PR.

## License

The project is licensed under MIT license. See [LICENSE](./LICENSE) file for details.

## Credits

### @max397574 for creating https://github.com/max397574/colortils.nvim.
### I learned a lot how to do Neovim UI from his work.
