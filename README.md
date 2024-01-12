# NeoTasks

## Packer Installation

```
use('hinkers/neotasks')
```

## Config

The below is an example of all the config values and there default values.

```lua
require('neotasks').setup({
    -- Text inserted at the start of an incomplete todo item
    new_item_text = "[ ] ",
    -- Text inserted at the start of a completed todo item
    complete_item_text = "[x] ",
    -- Starting width of the todo list
    panel_width = 60,
    -- Base directory where the "todo.txt" file will be stored
    base_path = "~/NeoTasks/",
    -- Directory that will store all archived todo lists
    archive_base_path = "~/NeoTasks/archives/"
})
```

## Example keybinds

```
vim.keymap.set("n", "<leader>tl", "<cmd>TodoList<CR>", { desc="Open NeoTasks todo list" })
vim.keymap.set("n", "<leader>to", "<cmd>TodoArchives<CR>", { desc="Open NeoTasks archives" })
```
