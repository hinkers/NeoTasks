local api = vim.api
local M = {}

M.archive  = nil
M.border_win = nil

-- Default values
M.config = {
    new_item_text = "[ ] ",
    complete_item_text = "[x] ",
    panel_width = 60,
    base_path = "~/NeoTasks/",
    archive_base_path = "~/NeoTasks/archives/"
}

local todo_file_name = "todo.txt"
local todo_base_path = vim.fn.expand(M.config.base_path)
local todo_file_path = todo_base_path .. todo_file_name
local archive_base_path = vim.fn.expand(M.config.archive_base_path)

local function update_paths()
    todo_base_path = vim.fn.expand(M.config.base_path)
    todo_file_path = todo_base_path .. todo_file_name
    archive_base_path = vim.fn.expand(M.config.archive_base_path)
end

function M.setup(user_config)
    if user_config ~= nil then
        M.config = vim.tbl_extend('force', M.config, user_config)
    end
    update_paths()
end

-- Function to open Todo list pane
function M.open_todo_list()
    vim.cmd("vsplit")
    vim.cmd("vertical resize " .. M.config.panel_width)
    vim.cmd("wincmd h")
    if vim.fn.filereadable(todo_file_path) == 0 then
        vim.fn.writefile({"# Todo List", "", ""}, todo_file_path)
    end
    api.nvim_command('edit ' .. todo_file_path)

    local bufnr = api.nvim_get_current_buf()

    api.nvim_win_set_cursor(0, {1, 0})
    api.nvim_command('setlocal filetype=todolist')

    -- Set buffer-local keymaps for normal mode
    api.nvim_buf_set_keymap(bufnr, 'n', '<leader>tn', '<cmd>lua require("neotasks").add_todo_item()<CR>', {noremap = true, silent = true, desc = "Add new todo item"})
    api.nvim_buf_set_keymap(bufnr, 'n', '<leader>tc', '<cmd>lua require("neotasks").complete_todo()<CR>', {noremap = true, silent = true, desc = "Complete todo item"})
    api.nvim_buf_set_keymap(bufnr, 'n', '<leader>ta', '<cmd>lua require("neotasks").archive_todo()<CR>', {noremap = true, silent = true, desc = "Archive todo item"})
    api.nvim_buf_set_keymap(bufnr, 'n', '<leader>tg', [[:TodoGroup ]], { noremap = true, silent = false })

    -- Set buffer-local keymaps for visual mode
    api.nvim_buf_set_keymap(bufnr, 'v', '<leader>tc', ':<C-u>lua require("neotasks").complete_todo()<CR>', {noremap = true, silent = true, desc = "Complete selected todo items"})
    api.nvim_buf_set_keymap(bufnr, 'v', '<leader>ta', ':<C-u>lua require("neotasks").archive_todo()<CR>', {noremap = true, silent = true, desc = "Archive selected todo items"})
    api.nvim_buf_set_keymap(bufnr, 'v', '<leader>tg', [[:TodoGroup ]], { noremap = true, silent = false })
end

-- Function to save Todo list
local function save_todo_list()
    vim.cmd('write')
end

-- Function to add new Todo item
function M.add_todo_item()
    local row, col = unpack(api.nvim_win_get_cursor(0))
    -- Insert new line with "[ ] " right below the current line
    api.nvim_buf_set_lines(0, row, row, false, {M.config.new_item_text}) 
    
    -- M.configove cursor to the beginning of the new line
    api.nvim_win_set_cursor(0, {row + 1, #M.config.new_item_text - 1})

    -- Enter insert mode
    api.nvim_command("startinsert!")
    save_todo_list()
end

-- Function to mark Todo item as complete
local function complete_todo_item()
    local row, col = unpack(api.nvim_win_get_cursor(0))
    local line = api.nvim_buf_get_lines(0, row - 1, row, false)[1]

    -- Remove the new item text from the line
    line = line:gsub(vim.pesc(M.config.new_item_text), "", 1)

    local total_lines = api.nvim_buf_line_count(0)
    local last_line = api.nvim_buf_get_lines(0, total_lines - 1, total_lines, false)[1]

    -- Check if the last line is a completed item, if not add a newline
    if not last_line:find("^" .. vim.pesc(M.config.complete_item_text)) then
        api.nvim_buf_set_lines(0, total_lines, total_lines, false, {""})
        total_lines = total_lines + 1
    end

    -- M.configove the completed item to the bottom of the file
    api.nvim_buf_set_lines(0, total_lines, total_lines, false, {M.config.complete_item_text .. line})

    -- Delete the original line of the completed item
    if row < total_lines then  -- Only delete the original line if it's not the last line
        api.nvim_buf_set_lines(0, row - 1, row, false, {})
    end

    save_todo_list()
end

-- Function to archive Todo item
local function archive_todo_item()
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

-- Function to handle archiving of single or multiple lines
function M.archive_todo()
    local start_row, _ = unpack(api.nvim_buf_get_mark(0, '<'))
    local end_row, _ = unpack(api.nvim_buf_get_mark(0, '>'))

    if start_row == 1 and end_row == 1 then
        -- If no visual selection, just archive the current line
        archive_todo_item()
    else
        -- Iterate over each line in the visual selection
        for row = start_row, end_row do
            archive_todo_item(row)
        end
    end
end

-- Function to handle completion of single or multiple lines
function M.complete_todo()
    local start_row, _ = unpack(api.nvim_buf_get_mark(0, '<'))
    local end_row, _ = unpack(api.nvim_buf_get_mark(0, '>'))

    if start_row == 1 and end_row == 1 then
        -- If no visual selection, just complete the current line
        complete_todo_item()
    else
        -- Iterate over each line in the visual selection
        for row = start_row, end_row do
            complete_todo_item(row)
        end
    end
end

local function create_border(options)
    -- Define the characters to use for the border
    local border_chars = {"╭", "─", "╮", "│", "╯", "─", "╰", "│"}
    
    -- Calculate the size and position of the border
    local border_opts = {
        relative = options.relative,
        width = options.width + 2,
        height = options.height + 2,
        row = options.row - 1,
        col = options.col - 1,
        style = 'minimal'
    }

    -- Create a buffer and window for the border
    local border_buf = vim.api.nvim_create_buf(false, true)
    local border_win = vim.api.nvim_open_win(border_buf, false, border_opts)

    -- Fill the border buffer with border characters
    local top = border_chars[1] .. string.rep(border_chars[2], options.width) .. border_chars[3]
    local mid = border_chars[4] .. string.rep(" ", options.width) .. border_chars[4]
    local btm = border_chars[7] .. string.rep(border_chars[6], options.width) .. border_chars[5]
    local lines = {top}
    for i = 1, options.height do
        table.insert(lines, mid)
    end
    table.insert(lines, btm)
    vim.api.nvim_buf_set_lines(border_buf, 0, -1, false, lines)

    return border_buf, border_win
end

-- Define an autocommand group for neotasks
vim.cmd([[
  augroup neotasks
    autocmd!
    autocmd WinClosed * lua require('neotasks').on_win_close(vim.fn.expand('<afile>'))
  augroup END
]])

-- Function to be called when a window is closed
function M.on_win_close(closed_win_id)
    if closed_win_id == tostring(M.archive_win) and M.border_win and vim.api.nvim_win_is_valid(M.border_win) then
        vim.api.nvim_win_close(M.border_win, true)
        M.border_win = nil
    end
end

-- Function to list and select archive files
function M.open_archive_selector()
    local editor_width = vim.api.nvim_get_option('columns')
    local editor_height = vim.api.nvim_get_option('lines')

    local panel_width = M.config.panel_width
    local panel_height = 20

    local options = {
        relative = 'editor',
        width = panel_width,
        height = panel_height,
        row = math.floor((editor_height - panel_height) / 2),
        col = math.floor((editor_width - panel_width) / 2)
    }

    -- Create the main window buffer and window
    local bufnr = vim.api.nvim_create_buf(false, true)
    local win = vim.api.nvim_open_win(bufnr, true, options)
    M.archive_win = win

    -- Fill the buffer with archive file names
    local archives = vim.fn.globpath(archive_base_path, "archive_*.txt", false, true)
    local file_names = {}
    for _, path in ipairs(archives) do
        local name = path:match("([^\\/]+)$")
        table.insert(file_names, name)
    end
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, file_names)

    -- Set buffer-local keymap for Enter key
    vim.api.nvim_buf_set_keymap(bufnr, 'n', '<CR>', ':lua require("neotasks").open_selected_archive()<CR>', {noremap = true, silent = true})
    vim.api.nvim_buf_set_keymap(bufnr, 'n', 'q', ':q<CR>', {noremap = true, silent = true})

    -- Create the border
    local border_buf, border_win = create_border(options)
    M.border_win = border_win
end

-- Function to open the selected archive file
function M.open_selected_archive()
    local winnr = api.nvim_get_current_win()
    local bufnr = api.nvim_win_get_buf(winnr)
    local row = api.nvim_win_get_cursor(winnr)[1]
    local file_path = archive_base_path .. api.nvim_buf_get_lines(bufnr, row - 1, row, false)[1]

    -- Close the archive selector window
    api.nvim_win_close(winnr, true)

    -- Open the selected file
    api.nvim_command('vsplit' .. file_path)
end

local escape_lua_pattern
do
    local matches =
    {
        ["^"] = "%^";
        ["$"] = "%$";
        ["("] = "%(";
        [")"] = "%)";
        ["%"] = "%%";
        ["."] = "%.";
        ["["] = "\\[";
        ["]"] = "\\]";
        ["*"] = "%*";
        ["+"] = "%+";
        ["-"] = "%-";
        ["?"] = "%?";
    }

    escape_lua_pattern = function(s)
        return (s:gsub(".", matches))
    end
end

local function find_or_create_group_header(bufnr, group_name)
    local header = "## " .. group_name
    local complete_header = "## Complete"
    local lines = api.nvim_buf_get_lines(bufnr, 0, -1, false)

    local complete_line_index = nil
    for i, line in ipairs(lines) do
        if line:lower() == header:lower() then
            return i  -- Return line number where the group header is found
        elseif line:lower() == complete_header:lower() then
            complete_line_index = i  -- Note the line number of the 'Complete' group
        end
    end

    -- Determine where to create the new group header
    local insert_line = #lines + 1
    local header_lines = {header}
    if complete_line_index ~= nil then
        insert_line = complete_line_index - 1 
        header_lines = {header, ""}
    end

    -- Create the new group header
    api.nvim_buf_set_lines(bufnr, insert_line, insert_line, false, header_lines) 
    return insert_line + 1  -- Return new header line number (right after the header)
end

local function move_task_to_group(bufnr, task_line, group_line)
    -- Get the task
    local task = api.nvim_buf_get_lines(bufnr, task_line - 1, task_line, false)[1]

    -- Adjust group_line if task_line comes before group_line
    local adjust = 0
    if task_line < group_line then
        group_line = group_line - 1
        adjust = 1  -- We need to adjust because the lines will shift up
    end

    -- Insert the task under the group header
    api.nvim_buf_set_lines(bufnr, group_line, group_line, false, {task})

    -- Remove the task from its original position
    api.nvim_buf_set_lines(bufnr, task_line - 1 + adjust, task_line + adjust, false, {})

    return adjust  -- Return how much we have adjusted
end

function M.move_to_group(group_name, start_line, end_line)
    local bufnr = api.nvim_get_current_buf()

    -- If no range is provided, use the current line
    if not start_line or not end_line then
        start_line = api.nvim_win_get_cursor(0)[1]
        end_line = start_line
    end

    -- Find or create the group header
    local header_line = find_or_create_group_header(bufnr, group_name)

    -- Collect the tasks
    local tasks = api.nvim_buf_get_lines(bufnr, start_line - 1, end_line, false)

    -- Insert the tasks under the group header
    api.nvim_buf_set_lines(bufnr, header_line, header_line, false, tasks)

    -- Correct start_line and end_line if tasks are moved above their original position
    if header_line < start_line then
        start_line = start_line + #tasks
        end_line = end_line + #tasks
    end

    -- Remove the original tasks
    -- Use reverse order to ensure line numbers don't shift unexpectedly
    for line = end_line, start_line, -1 do
        api.nvim_buf_set_lines(bufnr, line - 1, line, false, {})
    end
end

-- Initialization function to create necessary directories
local function init()
    if vim.fn.isdirectory(todo_base_path) == 0 then
        vim.fn.mkdir(todo_base_path, "p")  -- 'p' flag to create parent directories as needed
        vim.fn.mkdir(archive_base_path, "p")
    end

    -- Escape special characters for Vim regex
    local new_item_pattern = escape_lua_pattern(M.config.new_item_text)
    local complete_item_pattern = escape_lua_pattern(M.config.complete_item_text)

    -- Adjust the syntax matching commands
    vim.cmd("syntax match TodoNew /^" .. new_item_pattern .. ".*$/")
    vim.cmd("syntax match TodoComplete '^" .. complete_item_pattern .. ".*$'")
    vim.cmd([[
        syntax match TodoHeader /^#.*$/
        syntax match TodoSubHeader /^##.*$/
        highlight link TodoNew Normal
        highlight link TodoComplete Comment
        highlight link TodoHeader Statement
        highlight link TodoSubHeader Type
    ]])

    -- Adjust the autocommands
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
    api.nvim_create_user_command('TodoGroup', function(opts)
        M.move_to_group(opts.args, opts.line1, opts.line2)
    end, { nargs = 1, range = true })
end

-- Run the initalization function
init()

return M
