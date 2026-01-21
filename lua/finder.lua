local api = vim.api
local fn = vim.fn
local ns_id = api.nvim_create_namespace('SimpleFinder')

api.nvim_set_hl(0, 'FinderSelection', { bg = '#ffffff', fg = '#000000', bold = true })
api.nvim_set_hl(0, 'FinderMatch', { fg = '#569CD6', bold = true })
api.nvim_set_hl(0, 'FinderBorder', { fg = '#000000' })

local list_start_index = 3

local State = {
    mode = 'files',
    buf_input = api.nvim_create_buf(false, true),
    buf_list = nil,
    win_input = nil,
    win_list = nil,
    root_dir = nil,
    all_data = {},
    filtered_data = {},
    selection_idx = list_start_index,
    query = ""
}

local function get_git_root()
    local current_dir = fn.expand('%:p:h')
    local git_dir = fn.finddir('.git', current_dir .. ';')

    if git_dir ~= "" then
        return fn.fnamemodify(git_dir, ':h')
    end

    return fn.getcwd()
end

local function shell_escape(str)
    return "'" .. string.gsub(str, "'", "'\"'\"'") .. "'"
end

local function fuzzy_match(str, pattern)
    if pattern == "" then return true end

    local str_lower = string.lower(str)
    local s_idx = 1

    for part in string.gmatch(pattern, "%S+") do
        local pat_lower = string.lower(part)
        local p_idx = 1

        while p_idx <= #pat_lower and s_idx <= #str_lower do
            if string.sub(str_lower, s_idx, s_idx) == string.sub(pat_lower, p_idx, p_idx) then
                p_idx = p_idx + 1
            end
            s_idx = s_idx + 1
        end

        if p_idx <= #pat_lower then
            return false
        end
    end

    return true
end

local function close_window()
    if State.win_input and api.nvim_win_is_valid(State.win_input) then api.nvim_win_close(State.win_input, true) end
    if State.win_list and api.nvim_win_is_valid(State.win_list) then api.nvim_win_close(State.win_list, true) end

    vim.cmd('stopinsert')

    State.all_data = {}
    State.filtered_data = {}
end

local function parse_ansi(line, lnum)
    local clean_line = ""
    local highlights = {}
    local current_idx = 0
    local last_idx = 1
    
    -- Iterate over the string finding ANSI sequences
    -- Pattern matches: \27[...m
    for start_seq, content, end_seq in line:gmatch("()\27%[([0-9;]+)m()") do
        -- 1. Append text before the sequence
        local text_segment = line:sub(last_idx, start_seq - 1)
        clean_line = clean_line .. text_segment
        current_idx = current_idx + #text_segment

        -- 2. Parse the color code (Simplified for standard RG output)
        -- RG usually uses: 31 (Red), 32 (Green), 35 (Magenta), 1 (Bold)
        local hl_group = nil
        if content == "31" then hl_group = "FinderMatch"      -- Red (Matches)
        elseif content == "32" then hl_group = "String"       -- Green (Lines)
        elseif content == "35" then hl_group = "Directory"    -- Magenta (Files)
        elseif content == "1" then hl_group = "Bold"          -- Bold
        end
        
        -- 3. Record the highlight start
        if hl_group then
            table.insert(highlights, {
                group = hl_group,
                line = lnum,
                col_start = current_idx, 
                -- We don't know col_end yet, will resolve when we hit the reset code "0"
            })
        elseif content == "0" then
            -- Reset code: Close all open highlights
            for i = #highlights, 1, -1 do
                if not highlights[i].col_end then
                    highlights[i].col_end = current_idx
                end
            end
        end
        
        last_idx = end_seq
    end
    
    -- Append remaining text
    clean_line = clean_line .. line:sub(last_idx)
    
    return clean_line, highlights
end

local function render_list()
    if not State.buf_list or not api.nvim_buf_is_valid(State.buf_list) then return end
    
    api.nvim_buf_clear_namespace(State.buf_list, ns_id, 0, -1)
    
    local display_lines = {}
    local all_highlights = {}

    for i, raw_item in ipairs(State.filtered_data) do
        local clean_text, highlights = parse_ansi(raw_item, i - 1)
        
        if #clean_text > 200 then 
            clean_text = string.sub(clean_text, 1, 197) .. "..." 
        end

        table.insert(display_lines, clean_text)
        
        for _, hl in ipairs(highlights) do
            table.insert(all_highlights, hl)
        end
    end
    
    api.nvim_buf_set_lines(State.buf_list, 0, -1, false, display_lines)
    
    for _, hl in ipairs(all_highlights) do
        local line_len = #display_lines[hl.line + 1]
        local end_col = hl.col_end or -1
        if end_col > line_len then end_col = line_len end

        api.nvim_buf_add_highlight(State.buf_list, ns_id, hl.group, hl.line, hl.col_start, end_col)
    end
    
    if #State.filtered_data > 0 then
        if State.selection_idx > #State.filtered_data then State.selection_idx = list_start_index end
        if State.selection_idx < list_start_index then State.selection_idx = list_start_index end
        
        api.nvim_buf_add_highlight(State.buf_list, ns_id, 'FinderSelection', State.selection_idx - 1, 0, -1)
        
        if State.win_list and api.nvim_win_is_valid(State.win_list) then
            local line_count = api.nvim_buf_line_count(State.buf_list)
            
            local safe_lnum = math.min(State.selection_idx, line_count)
            
            if safe_lnum < 1 then safe_lnum = 1 end

            api.nvim_win_set_cursor(State.win_list, { safe_lnum, 0 })
        end
    end
end

local function execute_search()
    -- Initialize results container
    local stdout = {}
    local cmd = ""

    if #State.query < 2 then 
      State.filtered_data = {}
      render_list()
      return 
    end

    if State.mode == 'files' then
      local regex = State.query:gsub(" ", ".*")

      cmd = string.format("rg --files --color never . | rg --smart-case --color always %s", shell_escape(regex))
    elseif State.mode == 'grep' then

      cmd = string.format("rg --no-heading --line-number --color always --smart-case %s .", shell_escape(State.query))
    end

    fn.jobstart(cmd, {
        cwd = State.root_dir,
        on_stdout = function(_, data)
            if data then
                for _, line in ipairs(data) do
                    if line ~= "" then table.insert(stdout, line) end
                end
            end
        end,
        on_exit = function()
            State.filtered_data = stdout
            State.selection_idx = list_start_index
            vim.schedule(render_list)
        end
    })
end

local function on_key_action(action)
    if action == 'up' then
        if State.selection_idx > list_start_index then
            State.selection_idx = State.selection_idx - 1

            render_list()
        end
    elseif action == 'down' then
        if State.selection_idx < #State.filtered_data then
            State.selection_idx = State.selection_idx + 1

            render_list()
        end
    elseif action == 'enter' then
        local item = State.filtered_data[State.selection_idx]

        if item then
            close_window()

            local filename = item
            local lnum = nil
            
            if State.mode == 'grep' then
                local parts = vim.split(item, ":")

                filename = parts[1]
                lnum = tonumber(parts[2])
            end

            vim.cmd('e ' .. State.root_dir .. '/' .. filename)

            if lnum then
                api.nvim_win_set_cursor(0, { lnum, 0 })
                vim.cmd('normal! zz')
            end
            
            vim.cmd('stopinsert')
        end
    end
end

local function setup_input_buffer()
    local opts = { noremap = true, silent = true, buffer = State.buf_input }
    
    vim.keymap.set('i', '<Up>', function() on_key_action('up') end, opts)
    vim.keymap.set('i', '<Down>', function() on_key_action('down') end, opts)
    vim.keymap.set('i', '<CR>', function() on_key_action('enter') end, opts)
    vim.keymap.set('n', '<Esc>', close_window, opts)
    vim.keymap.set('i', '<Esc>', close_window, opts)
    
    api.nvim_create_autocmd("TextChangedI", {
        buffer = State.buf_input,

        callback = function()
            local lines = api.nvim_buf_get_lines(State.buf_input, 0, 1, false)
            local new_query = lines[1] or ""

            if new_query ~= State.query then
                State.query = new_query
                execute_search()
            end
        end
    })
end

local function create_windows()
    local width = vim.o.columns
    local height = vim.o.lines
    
    local input_height = 1
    local remaining_height = height - input_height - 2 -- minus borders/padding
    local list_height = remaining_height

    local win_opts = {
        style = "minimal",
        relative = "editor",
        border = "single"
    }

    State.buf_list = api.nvim_create_buf(false, true)

    local input_opts = vim.tbl_extend("force", win_opts, {
        row = 0, col = 0, width = width, height = input_height,
        title = (State.mode == 'files' and " Find File " or " Grep "),
        title_pos = "center"
    })
    State.win_input = api.nvim_open_win(State.buf_input, true, input_opts)

    local list_opts = vim.tbl_extend("force", win_opts, {
        row = input_height + 2, col = 0, width = width, height = list_height,
    })
    State.win_list = api.nvim_open_win(State.buf_list, false, list_opts)

    api.nvim_set_option_value('bufhidden', 'hide', { buf = State.buf_input })
    api.nvim_set_option_value('bufhidden', 'wipe', { buf = State.buf_list })
    
    setup_input_buffer()

    vim.cmd('startinsert!')
end

local function start(mode)
    State.mode = mode
    State.root_dir = get_git_root()
   
    State.all_data = {}
    State.filtered_data = {}

    create_windows()
    execute_search()
end

vim.keymap.set('n', '<leader>f', function() start('files') end, { noremap = true, silent = true })
vim.keymap.set('n', '<leader>g', function() start('grep') end, { noremap = true, silent = true })

return {
    start = start
}
