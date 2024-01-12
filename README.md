# NeoTasks

NeoTasks is a simple and efficient todo list manager for Neovim, designed to integrate seamlessly into your development workflow.
It allows you to quickly add, complete, and archive tasks without leaving the comfort of your Neovim environment.
The plugin offers a customizable interface, ensuring it fits well with your personal setup.

## Features

* **Easy Task Management**: Quickly add new tasks, mark tasks as complete, and archive completed tasks.
* **Visual Mode Support**: Perform actions on multiple tasks simultaneously using Neovim's visual mode.
* **Archive Functionality**: Automatically stores completed tasks in daily archive files for future reference.
* **Customizable Interface**: Configure text markers for tasks, panel width, and file paths according to your preferences.

## Packer Installation

To install NeoTasks using [packer.nvim](https://github.com/wbthomason/packer.nvim), add the following line to your Neovim configuration:

```lua
use('hinkers/neotasks')
```

## Config

NeoTasks can be easily configured to suit your preferences. Below is an example configuration with all the available options and their default values:

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

## Keybindings

You can set custom keybindings to interact with NeoTasks. Here are some example keybindings:

```lua
vim.keymap.set("n", "<leader>tl", "<cmd>TodoList<CR>", { desc="Open NeoTasks todo list" })
vim.keymap.set("n", "<leader>to", "<cmd>TodoArchives<CR>", { desc="Open NeoTasks archives" })
```

In these examples, **`<leader>tl`** opens the todo list, and **`<leader>to`** opens the archives.
