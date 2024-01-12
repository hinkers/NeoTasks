local api = vim.api
local M = {}

local new_item_text = "[ ] "
local complete_item_text = "[x] "

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
        vim.fn.writefile({"# Todo List", "", ""}, todo_file_path)
    end
    api.nvim_command('edit ' .. todo_file_path)

    local bufnr = api.nvim_get_current_buf()

    api.nvim_command('setlocal filetype=todolist')

    -- Set buffer-local keymaps
    api.nvim_buf_set_keymap(bufnr, 'n', '<leader>td', '<cmd>lua require("neotasks").add_todo_item()<CR>', {noremap = true, silent = true, desc = "Add new todo item"})
    api.nvim_buf_set_keymap(bufnr, 'n', '<leader>tc', '<cmd>lua require("neotasks").complete_todo_item()<CR>', {noremap = true, silent = true, desc = "Complete todo item"})
    api.nvim_buf_set_keymap(bufnr, 'n', '<leader>ta', '<cmd>lua require("neotasks").archive_todo_item()<CR>', {noremap = true, silent = true, desc = "Archive todo item"})
end

-- Function to save Todo list
local function save_todo_list()
    vim.cmd('write')
end

-- Function to add new Todo item
function M.add_todo_item()
    local row, col = unpack(api.nvim_win_get_cursor(0))
    -- Insert new line with "[ ] " right below the current line
    api.nvim_buf_set_lines(0, row, row, false, {new_item_text, ""})
    
    -- Move cursor to the beginning of the new line
    api.nvim_win_set_cursor(0, {row + 1, #new_item_text - 1})

    -- Enter insert mode
    api.nvim_command("startinsert!")
    save_todo_list()
end

-- Function to mark Todo item as complete
function M.complete_todo_item()
    local row, col = unpack(api.nvim_win_get_cursor(0))
    local line = api.nvim_buf_get_lines(0, row - 1, row, false)[1]
    local total_lines = api.nvim_buf_line_count(0)
    local last_line = api.nvim_buf_get_lines(0, total_lines - 1, total_lines, false)[1]

    -- Check if the last line is a completed item, if not add a newline
    if not last_line:find("^" .. vim.pesc(complete_item_text)) then
        api.nvim_buf_set_lines(0, total_lines, total_lines, false, {""})
        total_lines = api.nvim_buf_line_count(0)
    end

    -- Move the completed item to the bottom of the file
    api.nvim_buf_set_lines(0, total_lines, total_lines, false, {line})

    -- Delete the original line of the completed item
    if row ~= total_lines then  -- Only delete the original line if it's not the last line
        api.nvim_buf_set_lines(0, row - 1, row, false, {})
    end

    -- Update variables
    api.nvim_win_set_cursor(0, {total_lines, 0})
    row, col = unpack(api.nvim_win_get_cursor(0))
    line = api.nvim_buf_get_lines(0, row - 1, row, false)[1]

    -- Mark the current line as complete
    api.nvim_buf_set_lines(0, row - 1, row, false, {complete_item_text .. line})

    save_todo_list()
end

-- Function to archive Todo item
function M.archive_todo_item()
    local row, col = unpack(api.nvim_win_get_cursor(0))
    local line = api.nvim_buf_get_lines(0, row - 1, row, false)[1]
    local date = os.date("%Y-%m-%d")
    local archive_file_path = archive_base_path .. "archive_" .. date .. ".txt"

    -- Check if the archive file exists and create it if it doesn't
    if vim.fn.filereadable(archive_file_path) == 0 then
        vim.fn.writefile({}, archive_file_path)
    end
    local archive_content = vim.fn.readfile(archive_file_path)
    table.insert(archive_content, line)
    vim.fn.writefile(archive_content, archive_file_path)

    -- Delete the current line
    api.nvim_buf_set_lines(0, row - 1, row, false, {})
    save_todo_list()
end

-- Function to list and select archive files
function M.open_archive_selector()
    local archives = vim.fn.globpath(archive_base_path, "*.txt", false, true)
    local options = { relative = 'editor', width = 60, height = 20, row = 10, col = 10 }
    local bufnr = api.nvim_create_buf(false, true)
    api.nvim_open_win(bufnr, true, options)
    api.nvim_buf_set_lines(bufnr, 0, -1, false, archives)

    -- Set buffer-local keymap for Enter key
    api.nvim_buf_set_keymap(bufnr, 'n', '<CR>', ':lua require("neotasks").open_selected_archive()<CR>', {noremap = true, silent = true})
end

-- Function to open the selected archive file
function M.open_selected_archive()
    local winnr = api.nvim_get_current_win()
    local bufnr = api.nvim_win_get_buf(winnr)
    local row = api.nvim_win_get_cursor(winnr)[1]
    local file_path = api.nvim_buf_get_lines(bufnr, row - 1, row, false)[1]

    -- Close the archive selector window
    api.nvim_win_close(winnr, true)

    -- Open the selected file
    api.nvim_command('edit ' .. file_path)
end

-- Initialization function to create necessary directories
local function init()
    if vim.fn.isdirectory(todo_base_path) == 0 then
        vim.fn.mkdir(todo_base_path, "p")  -- 'p' flag to create parent directories as needed
        vim.fn.mkdir(archive_base_path, "p")
    end

    -- Create syntax highlighting
    local complete_item_pattern = vim.pesc(complete_item_text)
    local new_item_pattern = vim.pesc(new_item_text)

    vim.cmd("syntax match TodoNew '^" .. vim.pesc(new_item_text) .. ".*$'")
    vim.cmd("syntax match TodoComplete '^" .. vim.pesc(complete_item_text) .. ".*$'")
    vim.cmd([[
        syntax match TodoHeader /^#.*$/
        syntax match TodoSubHeader /^##.*$/
        highlight link TodoNew Normal
        highlight link TodoComplete Comment
        highlight link TodoHeader Statement
        highlight link TodoSubHeader Type
    ]])


    vim.cmd([[
        augroup TodoListSyntax
        autocmd!
        autocmd FileType todolist syntax match TodoNew '^]] .. new_item_pattern .. [[.*$'
        autocmd FileType todolist syntax match TodoComplete '^]] .. complete_item_pattern .. [[.*$'
        autocmd FileType todolist syntax match TodoHeader /^#.*$/
        autocmd FileType todolist syntax match TodoSubHeader /^##.*$/
        autocmd FileType todolist highlight link TodoNew Normal
        autocmd FileType todolist highlight link TodoComplete Comment
        autocmd FileType todolist highlight link TodoHeader Statement
        autocmd FileType todolist highlight link TodoSubHeader Type
        augroup END
    ]])
    
    -- Register commands and keybindings
    api.nvim_create_user_command('TodoList', M.open_todo_list, {})
    api.nvim_create_user_command('TodoArchives', M.open_archive_selector, {})
end

-- Run the initalization function
init()


return M
