local api = vim.api
local M = {}

local todo_file_name = "todo.txt"
local todo_base_path = vim.fn.expand("~/NeoTasks/")
local todo_file_path = todo_base_path .. todo_file_name
local archive_base_path = vim.fn.expand("~/NeoTasks/archives/")

-- Function to open Todo list pane
function M.open_todo_list()
    vim.cmd("vsplit")
    vim.cmd("vertical resize 60")
    vim.cmd("wincmd h")
    if vim.fn.filereadable(todo_file_path) == 0 then
        vim.fn.writefile({}, todo_file_path)
    end
    api.nvim_command('edit ' .. todo_file_path)

    local bufnr = api.nvim_get_current_buf()

    -- Set buffer-local keymaps
    api.nvim_buf_set_keymap(bufnr, 'n', '<leader>td', '<cmd>lua require("neotasks").add_todo_item()<CR>', {noremap = true, silent = true})
    api.nvim_buf_set_keymap(bufnr, 'n', '<leader>tc', '<cmd>lua require("neotasks").complete_todo_item()<CR>', {noremap = true, silent = true})
    api.nvim_buf_set_keymap(bufnr, 'n', '<leader>ta', '<cmd>lua require("neotasks").archive_todo_item()<CR>', {noremap = true, silent = true})
end

-- Function to save Todo list
local function save_todo_list()
    vim.cmd('write')
end

-- Function to add new Todo item
function M.add_todo_item()
    -- Add new line at the end of the buffer
    api.nvim_buf_set_lines(0, -1, -1, false, {""})
    -- Go to the new line
    api.nvim_win_set_cursor(0, {api.nvim_buf_line_count(0), 0})
    -- Switch to insert mode
    api.nvim_command("startinsert")
    save_todo_list()
end

-- Function to mark Todo item as complete
function M.complete_todo_item()
    local row, col = unpack(api.nvim_win_get_cursor(0))
    local line = api.nvim_buf_get_lines(0, row - 1, row, false)[1]
    -- Mark the current line as complete
    api.nvim_buf_set_lines(0, row - 1, row, false, {"[x] " .. line})
    save_todo_list()
end

-- Function to archive Todo item
function M.archive_todo_item()
    local row, col = unpack(api.nvim_win_get_cursor(0))
    local line = api.nvim_buf_get_lines(0, row - 1, row, false)[1]
    local date = os.date("%Y-%m-%d")
    local archive_file_path = archive_base_path .. "archive_" .. date .. ".txt"
    local archive_content = vim.fn.readfile(archive_file_path)
    table.insert(archive_content, line)
    vim.fn.writefile(archive_content, archive_file_path)
    -- Delete the current line
    api.nvim_buf_set_lines(0, row - 1, row, false, {})
    save_todo_list()
end

-- Initialization function to create necessary directories
local function init()
    if vim.fn.isdirectory(todo_base_path) == 0 then
        vim.fn.mkdir(todo_base_path, "p")  -- 'p' flag to create parent directories as needed
        vim.fn.mkdir(archive_base_path, "p")
    end
end

-- Run the initalization function
init()

-- Register commands and keybindings
api.nvim_create_user_command('TodoList', M.open_todo_list, {})

return M
