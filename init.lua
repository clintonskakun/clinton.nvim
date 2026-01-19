local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'

if not vim.loop.fs_stat(lazypath) then
	vim.fn.system({
		'git',
		'clone',
		'--filter=blob:none',
		'https://github.com/folke/lazy.nvim.git',
		'--branch=stable',
		lazypath,
	})
end

vim.opt.rtp:prepend(lazypath)

require('lazy').setup({
	-- For creating dirs when creating a file with :e dir-that-doesnt-exist/thing.txt
	{ 'jghauser/mkdir.nvim' },
	-- Icons
	{ 'nvim-tree/nvim-web-devicons' },
	{
		'nvim-treesitter/nvim-treesitter',
		lazy = false,
		build = ':TSUpdate',
		tag = 'v0.10.0',
		config = function()
			require("nvim-treesitter.configs").setup({
				ensure_installed = { "html", "svelte", "javascript", "typescript", "bash", "json", "prisma", "sql", "markdown", "csv", "c", "zig", "rust", "go", "haskell", "lua", "gitignore" },
				sync_install = true,
				auto_install = true,
				highlight = {
					enable = true
				},
				additional_vim_regex_highlighting = false
			})
		end
	},
	-- Obvious why we need this
	{
		'nvim-telescope/telescope.nvim',
		dependencies = { 'nvim-lua/plenary.nvim' },
		config = function()
			require('telescope').setup({
				defaults = {
					path_display = { 'full' },

					layout_strategy = 'vertical',

					layout_config = {
						width = 0.95,
						height = 0.95,
						vertical = {
							mirror = true,
							preview_height = 0.6,
						}
					},
				}
			})
			require('telescope').load_extension('fzf')
		end
	},
	-- To make indexing/searching faster
	{
		'nvim-telescope/telescope-fzf-native.nvim',
		build = 'make',
	},
	-- Our floating terminal
	{ 'akinsho/toggleterm.nvim', version = "*", 
	config = function()
		require('toggleterm').setup({
			direction = 'float'
		})
	end
	},
})

vim.lsp.config['ts_ls'] = {
  cmd = { 'typescript-language-server', '--stdio' },
  filetypes = { 'typescript', 'javascript', 'typescriptreact', 'javascriptreact' },
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
    vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, opts) -- Rename
    vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, opts) -- Code Actions
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
--
-- <leader>a -> Triggers LSP (Omni) Completion
vim.keymap.set('i', '<leader>a', '<C-x><C-o>', { noremap = true, silent = true })

-- <leader>u -> Triggers Path (File) Completion
vim.keymap.set('i', '<leader>u', '<C-x><C-f>', { noremap = true, silent = true })

-- Telescope
local builtin = require('telescope.builtin')

vim.api.nvim_create_user_command(
	'LiveGrepFixed',
	function()
		builtin.live_grep({
			-- This flag tells ripgrep (rg) to treat the pattern as a literal string.
			additional_args = { '--fixed-strings' }
		})
	end,
	{ desc = 'Live Grep (Fixed Strings/No Regex)' }
)

keymap('n', '<leader>f', builtin.find_files, { desc = 'Find files' })
keymap('n', '<leader>g', ':LiveGrepFixed<CR>', { desc = 'Live grep' })
keymap('n', '<leader>r', builtin.resume, { desc = 'Resume last search' })

-- Toggle floating terminal
keymap('n', '<leader>t', '<cmd>ToggleTerm<CR>', { desc = 'Toggle terminal' })

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
