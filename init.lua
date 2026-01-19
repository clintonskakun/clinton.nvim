-- Add homegrown mkdir, toggle term
-- Add mini pick instead of telescope
vim.pack.add({
	{
		src = 'https://github.com/nvim-treesitter/nvim-treesitter',
		version = 'v0.10.0',
	}
})

require("nvim-treesitter.configs").setup({
	ensure_installed = { "html", "svelte", "javascript", "typescript", "bash", "json", "prisma", "sql", "markdown", "csv", "lua", "gitignore" },
	sync_install = true,
	auto_install = true,
	highlight = {
		enable = true
	},
	additional_vim_regex_highlighting = false
})

vim.lsp.config['ts_ls'] = {
  cmd = { 'typescript-language-server', '--stdio' },
  filetypes = { 'typescript', 'javascript' },
  root_markers = { 'package.json', 'tsconfig.json', '.git' },
}

vim.lsp.config['svelte'] = {
  cmd = { 'svelteserver', '--stdio' },
  filetypes = { 'svelte' },
  root_markers = { 'svelte.config.js', 'package.json', '.git' },
}

vim.lsp.config['prisma'] = {
  cmd = { 'prisma-language-server', '--stdio' },
  filetypes = { 'prisma' },
  root_markers = { 'schema.prisma', '.git' },
}

local servers = { 'ts_ls', 'svelte', 'prisma' }
for _, server in ipairs(servers) do
  vim.lsp.enable(server)
end

vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(args)
    local buf = args.buf

    -- Enable Native Autocomplete via <C-x><C-o>
    vim.bo[buf].omnifunc = 'v:lua.vim.lsp.omnifunc'

    -- Keymaps
    local opts = { buffer = buf }
    vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)     -- Go to Definition
    vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)           -- Hover Documentation
    vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, opts)   -- Previous Error
    vim.keymap.set('n', ']d', vim.diagnostic.goto_next, opts)   -- Next Error
  end,
})

vim.diagnostic.config({
	underline = true,
	virtual_text = true,
	signs = true,
	float = {
		border = "rounded",
	}
});

-- Diagnosis Counts
function GetDiagnosisCounts()
	-- Get counts for ONLY ERRORS in the current buffer
	local errors = vim.diagnostic.get(0, { severity = vim.diagnostic.severity.ERROR })
	local total = #errors

	if total > 0 then
		return "🔴" .. tostring(total) .. " "
	else
		return ""
	end
end

function GetErrorLines()
	local max_lines = 5
	local bufnr = vim.api.nvim_get_current_buf()

	-- Get diagnostics filtered strictly for ERRORS
	local diagnostics = vim.diagnostic.get(bufnr, { severity = vim.diagnostic.severity.ERROR })

	if #diagnostics == 0 then
		return ""
	end

	-- Collect unique line numbers (1-based)
	local lines_seen = {}
	local unique_lines = {}

	for _, diag in ipairs(diagnostics) do
		local line = diag.lnum + 1
		if not lines_seen[line] then
			lines_seen[line] = true
			table.insert(unique_lines, line)
			if #unique_lines == max_lines then
				break
			end
		end
	end

	if #unique_lines == 0 then
		return ""
	end

	table.sort(unique_lines) 

	return "Lines " .. table.concat(unique_lines, ", ") .. "... "
end

local keymap = vim.keymap.set

-- Key mappings
vim.g.mapleader = ' '
vim.g.localleader = ' '

local state = { buf = -1, win = -1 }

local function toggle_terminal()
    if vim.api.nvim_win_is_valid(state.win) then
        vim.api.nvim_win_hide(state.win)
    else
        if not vim.api.nvim_buf_is_valid(state.buf) then
            state.buf = vim.api.nvim_create_buf(false, true) -- Create scratch buffer
        end
        
        local width = math.floor(vim.o.columns * 0.8)
        local height = math.floor(vim.o.lines * 0.8)
        local col = math.floor((vim.o.columns - width) / 2)
        local row = math.floor((vim.o.lines - height) / 2)

        state.win = vim.api.nvim_open_win(state.buf, true, {
            relative = "editor", style = "minimal", border = "rounded",
            width = width, height = height, col = col, row = row
        })

        if vim.bo[state.buf].buftype ~= "terminal" then
            vim.cmd.terminal()
        end
        vim.cmd("startinsert")
    end
end

vim.keymap.set({ "n" }, "<leader>t", toggle_terminal, { noremap = true, silent = true })

-- This function will be called when a terminal is opened
local function set_terminal_keymaps()
	-- Set options for the keymap to be buffer-local
	local opts = { buffer = 0 }
	-- Map <Esc> in terminal mode to exit to normal mode
	vim.keymap.set('t', '<Esc>', [[<C-\><C-n>]], opts)
end

-- Create an autocommand that runs our function on the TermOpen event
vim.api.nvim_create_autocmd('TermOpen', {
	pattern = 'term://*',
	callback = function()
		set_terminal_keymaps()
	end,
	desc = 'Set terminal keymaps on open',
})

local Terminal = require("toggleterm.terminal").Terminal

local function toggle_term_in_buf_dir()
	local buf_dir = vim.fn.expand("%:p:h")
	if vim.fn.isdirectory(buf_dir) == 1 then
		local term = Terminal:new({
			dir = buf_dir,
			direction = "float", 
			close_on_exit = true,
			hidden = true
		})
		term:toggle()
	else
		print("No valid directory for current buffer.")
	end
end

-- Set your keybind (normal mode)
keymap("n", "<leader>p", toggle_term_in_buf_dir, { noremap = true, silent = true, desc = 'Open floating terminal in current buffer directory' })

-- Appearance
vim.cmd.colorscheme 'habamax'
vim.opt.clipboard = "unnamedplus"
vim.opt.number = true
vim.opt.relativenumber = true

vim.opt.cursorline = true
vim.opt.termguicolors = true
vim.opt.syntax = 'off'
vim.o.showtabline = 0

-- Line numbers that one can see
vim.api.nvim_set_hl(0, 'LineNrAbove', { fg = 'lightgray' })
vim.api.nvim_set_hl(0, 'LineNrBelow', { fg = 'lightgray' })
vim.api.nvim_set_hl(0, 'CursorLineNr', { fg = 'orange', bold = true })

-- Behavior
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.confirm = true

-- Tabs & Indentation
vim.opt.tabstop = 2               -- Number of spaces a <Tab> in the file counts for
vim.opt.shiftwidth = 2            -- Size of an indent
vim.opt.softtabstop = 2           -- Number of spaces to insert for a <Tab>
vim.opt.expandtab = true          -- Use spaces instead of tabs
vim.opt.swapfile = false          -- Turn off annoying swapfile behav

-- Status bar
vim.opt.statusline = '%F%=%{v:lua.GetErrorLines()}%{v:lua.GetDiagnosisCounts()}'
-- Turn off mouse
vim.opt.mouse = ''

vim.api.nvim_create_user_command("Q", "quit", { nargs = 0 })
vim.api.nvim_create_user_command("W", "write", { nargs = 0 })

-- Navigate between buffers
keymap('n', '<Tab>', '<cmd>bnext<CR>', { desc = 'Go to next buffer' })
keymap('n', '<S-Tab>', '<cmd>bprevious<CR>', { desc = 'Go to previous buffer' })
