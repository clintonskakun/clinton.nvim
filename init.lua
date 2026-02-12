-- Key mappings
vim.g.mapleader = ' '
vim.g.localleader = ' '

vim.pack.add({
	{
		src = 'https://github.com/nvim-treesitter/nvim-treesitter',
		version = 'v0.10.0',
	},
})

require("nvim-treesitter.configs").setup({
	ensure_installed = { "html", "svelte", "javascript", "typescript", "bash", "json", "prisma", "sql", "markdown", "csv", "gitignore", "css", "yaml", "c", "lua", "python" },
	sync_install = false,
	auto_install = true,
	highlight = {
		enable = true
	},
  indent = {
    enable = true,
  },
	additional_vim_regex_highlighting = false
})

local function make_capabilities()
  local capabilities = vim.lsp.protocol.make_client_capabilities()
  
  -- Enable snippet support (crucial for auto-imports)
  capabilities.textDocument.completion.completionItem.snippetSupport = true
  
  -- Tell the server we support 'resolve', which lazy-loads the import data
  capabilities.textDocument.completion.completionItem.resolveSupport = {
    properties = {
      'documentation',
      'detail',
      'additionalTextEdits',
    },
  }
  
  return capabilities
end

vim.lsp.config['ts'] = {
  cmd = {
    'typescript-language-server',
    '--stdio',
    '--tsserver-log-verbosity',
    'off',
    '--max-old-space-size=1096'
  },
  filetypes = { 'typescript' },
  root_markers = { 'package.json', 'tsconfig.json', '.git' },
  capabilities = make_capabilities()
}

vim.lsp.enable("ts");

vim.lsp.config['svelte'] = {
  cmd = {
    'svelteserver',
    '--stdio',
    '--max-old-space-size=2096'
  },
  filetypes = { 'svelte' },
  root_markers = { 'svelte.config.js', 'package.json', '.git' },
  capabilities = make_capabilities()
}

vim.lsp.enable("svelte");

vim.lsp.config['prisma'] = {
  cmd = { 'prisma-language-server', '--stdio' },
  filetypes = { 'prisma' },
  root_markers = { 'schema.prisma', '.git' },
}

vim.lsp.enable("prisma");

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
    vim.keymap.set('n', '<leader>c', vim.lsp.buf.code_action, { buffer = buf, desc = "LSP: Code Action" })
  end,
})

-- Diagnostic popup
vim.diagnostic.config({
	underline = true,
	virtual_text = true,
	signs = true,
	float = {
		border = "single",
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


local state = { buf = -1, win = -1 }

local function open_float()
    if not vim.api.nvim_buf_is_valid(state.buf) then
	    state.buf = vim.api.nvim_create_buf(false, true) 
    end

    if vim.api.nvim_win_is_valid(state.win) then 
	    return
    end

    local width,
    	  height = math.floor(vim.o.columns * 0.8),
                   math.floor(vim.o.lines * 0.8)

    state.win = vim.api.nvim_open_win(state.buf, true, {
        relative = "editor", style = "minimal", border = "single",
        width = width,
	height = height,
	col = (vim.o.columns - width)/2,
	row = (vim.o.lines - height)/2
    })
    
    if vim.bo[state.buf].buftype ~= "terminal" then 
	    vim.cmd.terminal() 
    end

    vim.cmd("startinsert")
end

local function toggle_term()
    if vim.api.nvim_win_is_valid(state.win) then 
	    vim.api.nvim_win_hide(state.win) 
    else 
	    open_float() 
    end
end

local function term_in_dir()
    local dir = vim.fn.expand('%:p:h') -- Get directory of current buffer

    open_float()

    -- Send 'cd <dir>' and 'Enter' (\r) to the terminal job
    vim.api.nvim_chan_send(vim.b[state.buf].terminal_job_id, "cd " .. dir .. "\r")
end

-- Keymaps
vim.keymap.set("n", "<leader>t", toggle_term, { noremap = true, silent = true })
vim.keymap.set("n", "<leader>p", term_in_dir, { noremap = true, silent = true })

-- Create an autocommand that runs our function on the TermOpen event
vim.api.nvim_create_autocmd('TermOpen', {
	pattern = 'term://*',
	callback = function()
		local opts = { buffer = 0 }
		vim.keymap.set('t', '<Esc>', [[<C-\><C-n>]], opts)
	end,
	desc = 'Set terminal keymaps on open',
})

-- Makedir -P on creating new files
vim.api.nvim_create_autocmd("BufWritePre", {
  group = vim.api.nvim_create_augroup("AutoMkdir", { clear = true }),
  pattern = "*",
  callback = function(ctx)
    local dir = vim.fn.fnamemodify(ctx.file, ":p:h")
    -- If the directory doesn't exist, create it (mkdir -p behavior)
    if vim.fn.isdirectory(dir) == 0 then
      vim.fn.mkdir(dir, "p")
    end
  end,
})

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
vim.keymap.set('n', '<Tab>', '<cmd>bnext<CR>', { desc = 'Go to next buffer' })
vim.keymap.set('n', '<S-Tab>', '<cmd>bprevious<CR>', { desc = 'Go to previous buffer' })

vim.opt.list = true
vim.opt.completeopt = { "menu", "menuone", "noselect" }

vim.opt.listchars = {
    tab = '│ ',
    leadmultispace = '│ ',
    trail = '·',
}

vim.g.loaded_ruby_provider = 0
vim.g.loaded_perl_provider = 0

require("finder")
