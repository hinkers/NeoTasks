# NeoTasks

NeoTasks is an intuitive and powerful task management plugin for Neovim, crafted to blend seamlessly into your development workflow.
It offers an elegant way to manage your tasks directly within your Neovim environment, enabling you to stay focused and productive.
With NeoTasks, you can effortlessly create, manage, and organize your tasks without ever needing to switch context.

## Features

* **Easy Task Management**: Quickly add new tasks, mark tasks as complete, and archive completed tasks.
* **Visual Mode Support**: Perform actions on multiple tasks simultaneously using Neovim's visual mode.
* **Archive Functionality**: Automatically stores completed tasks in daily archive files for future reference.
* **Customizable Interface**: Configure text markers for tasks, panel width, and file paths according to your preferences.
* **Grouping by Headers**: Organize tasks into groups using header lines and easily move tasks between groups.
* **Floating Window for Archives**: Browse your archived tasks in a neatly presented floating window.

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
    archive_base_path = "~/NeoTasks/archives/",
    -- Name of the group that completed todo items will be moved to
    completed_group = "Completed",
    -- Keybinds inside the todo list
    keybinds = {
        -- Create a new todo item above the cursor
        append_todo = "gtn",
        -- Create a new todo item below the cursor
        prepend_todo = "gtN",
        -- Mark all selected todo items as complete
        complete_todo = "gtc",
        -- Move all selected todo items to an archive file
        archive_todo = "gta",
        -- Move all selected todo items to a new or existing group
        group_todo = "gtg"
    }
})
```

## Keybindings

You can set custom keybindings to interact with NeoTasks. Here are some example keybindings:

```lua
vim.keymap.set("n", "<leader>tl", "<cmd>TodoList<CR>", { desc="Open NeoTasks todo list" })
vim.keymap.set("n", "<leader>to", "<cmd>TodoArchives<CR>", { desc="Open NeoTasks archives" })
```

In these examples, **`<leader>tl`** opens the todo list, and **`<leader>to`** opens the archive selector.

Enjoy managing your tasks efficiently with NeoTasks!
