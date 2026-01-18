-- Lazyvim setup
local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'

if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    'git',
    'clone',
    '--filter=blob:none',
    'https://github.com/folke/lazy.nvim.git',
    '--branch=stable', -- latest stable release
    lazypath,
  })
end

vim.opt.rtp:prepend(lazypath)

-- plugin install
require('lazy').setup({
  { 'mluders/comfy-line-numbers.nvim' },
  { 'jghauser/mkdir.nvim' },
  { 'petertriho/nvim-scrollbar' },
  { 'rmagatti/auto-session' },
  {
    'nvim-treesitter/nvim-treesitter',
    config = function()
      require('nvim-treesitter.config').setup({
        -- Add svelte to this list
        ensure_installed = { 'lua', 'javascript', 'typescript', 'html', 'css', 'svelte', 'prisma', 'bash' },
        sync_install = false,
        auto_install = true,
        highlight = {
          enable = true,
        },
        indent = { enable = true }
      })
    end,
  },
  { 'nvim-tree/nvim-web-devicons', lazy = true },
  {
    'nvim-telescope/telescope.nvim',
    dependencies = { 'nvim-lua/plenary.nvim' },
    config = function()
      -- This is where you would configure telescope, if you wanted to
        -- For now, we'll just load the fzf extension
        require('telescope').setup({
          defaults = {
			path_display = { 'full' },
		    
		    -- 1. Use Vertical Layout (Stacks windows)
		    layout_strategy = 'vertical',
		    
		    -- 2. Configuration for the layout
		    layout_config = {
		      -- "Entire Screen" (95% of width/height)
		      width = 0.95,
		      height = 0.95,
		      
		      -- Specific settings for vertical mode
		      vertical = {
		        -- mirror = true puts the Search/Results on TOP and Preview on BOTTOM
		        mirror = true,
		        
		        -- Adjust how much space the preview takes (0.6 = 60%)
		        preview_height = 0.6,
		      }
		    },
          }
  	})
        require('telescope').load_extension('fzf')
      end
    },
    {
      'nvim-telescope/telescope-fzf-native.nvim',
      -- This is a build command that lazy.nvim will run
      build = 'make',
    },
    { 'lukas-reineke/indent-blankline.nvim', main = 'ibl', opts = {} },
    { 'akinsho/toggleterm.nvim', version = "*", 
    config = function()
      require('toggleterm').setup({
        direction = 'float' -- The main option to make it float
      })
    end
  },
  -- Smooth scrolling
  {
    'karb94/neoscroll.nvim', opts = {
    },
 },
  -- The completion engine
  { 'hrsh7th/nvim-cmp' },
  -- Source for nvim-cmp: buffer words
  { 'hrsh7th/cmp-buffer' },
  -- Source for nvim-cmp: file paths
  { 'hrsh7th/cmp-path' },

  -- LSP Configuration
  { 'neovim/nvim-lspconfig' },
  -- Source for nvim-cmp: LSP
  { 'hrsh7th/cmp-nvim-lsp' },

  -- LSP Installer
  { 'williamboman/mason.nvim' },
  { 'williamboman/mason-lspconfig.nvim' },

  -- Icons for completion menu
  { 'onsails/lspkind.nvim' },
})

vim.o.sessionoptions="blank,buffers,curdir,folds,help,tabpages,winsize,winpos,terminal,localoptions"

require("comfy-line-numbers").setup();
require("auto-session").setup();
require("scrollbar").setup();

local keymap = vim.keymap.set

-- Key mappings
vim.g.mapleader = ' '
vim.g.localleader = ' '

local neoscroll = require('neoscroll')

local _keymap = {
  ["<C-u>"] = function() neoscroll.scroll(-0.15, { duration = 100 }) end;
  ["<C-d>"] = function() neoscroll.scroll(0.15, { duration = 100 }) end;
}

local modes = { 'n', 'v', 'x' }

for key, func in pairs(_keymap) do
  keymap(modes, key, func)
end

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

vim.diagnostic.config({
  underline = true,
  virtual_text = true,
  signs = true
});

-- LSP
local cmp = require('cmp')
local lspkind = require('lspkind')
local types = require('cmp.types')

cmp.setup({
  mapping = cmp.mapping.preset.insert({
    ['<Tab>'] = cmp.mapping.select_next_item({ behavior = types.cmp.SelectBehavior.Select }),
    ['<S-Tab>'] = cmp.mapping.select_prev_item({ behavior = types.cmp.SelectBehavior.Select }),
    ['<Enter>'] = cmp.mapping.confirm({ select = false }),
  }),
  sources = cmp.config.sources({
    {
      name = 'nvim_lsp',
      entry_filter = function(entry)
        local kind = entry:get_kind()
        return kind ~= types.lsp.CompletionItemKind.Text
           and kind ~= types.lsp.CompletionItemKind.Keyword
           and kind ~= types.lsp.CompletionItemKind.Constant
      end
    },
  }, {
    { name = 'path' },
  }),
  formatting = {
    format = lspkind.cmp_format({
      mode = 'symbol_text',
      maxwidth = 50,
    })
  }
})

-- Setup mason so it can manage LSP servers
require('mason').setup()
require('mason-lspconfig').setup()

-- Setup language servers.
require('mason-lspconfig').setup({
	ensure_installed = { 'html', 'cssls', 'prismals', 'svelte', 'vtsls', 'jsonls', 'lua_ls', 'bashls' }
})

keymap('n', '<leader>d', '<cmd>lua vim.diagnostic.open_float()<CR>', { desc = "Toggle diagnotic" })

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

-- Appearance
vim.cmd.colorscheme 'habamax'
vim.opt.clipboard = "unnamedplus"
vim.opt.number = true
vim.opt.relativenumber = true

vim.opt.cursorline = true
vim.opt.termguicolors = true      -- Enable true color support
vim.opt.syntax = 'on'             -- Enable syntax highlighting
vim.o.showtabline = 0

-- Line numbers that one can see
vim.api.nvim_set_hl(0, 'LineNrAbove', { fg = 'lightgray' })
vim.api.nvim_set_hl(0, 'LineNrBelow', { fg = 'lightgray' })
vim.api.nvim_set_hl(0, 'CursorLineNr', { fg = 'orange', bold = true })

-- Behavior
vim.opt.hlsearch = true           -- Highlight search results
vim.opt.incsearch = true          -- Show search results as you type
vim.opt.ignorecase = true         -- Ignore case in search
vim.opt.smartcase = true          -- But be case-sensitive if the query has uppercase letters
vim.o.confirm = true

-- Tabs & Indentation
vim.opt.tabstop = 2               -- Number of spaces a <Tab> in the file counts for
vim.opt.shiftwidth = 2            -- Size of an indent
vim.opt.softtabstop = 2           -- Number of spaces to insert for a <Tab>
vim.opt.expandtab = true          -- Use spaces instead of tabs
vim.opt.autoindent = true         -- Copy indent from current line when starting a new line

-- Status bar
vim.opt.statusline = '%F%=%{v:lua.GetErrorLines()}%{v:lua.GetDiagnosisCounts()}'
-- Turn off mouse
vim.opt.mouse = ''

-- Define :Q to run the existing :q command
vim.api.nvim_create_user_command("Q", "quit", { nargs = 0 })

-- Define :W to run the existing :w command
vim.api.nvim_create_user_command("W", "write", { nargs = 0 })

-- See open buffers
keymap('n', '<leader>b', '<cmd>Telescope buffers<CR>', { desc = 'Open new tab' })

-- Navigate between buffers
keymap('n', '<Tab>', '<cmd>bnext<CR>', { desc = 'Go to next buffer' })
keymap('n', '<S-Tab>', '<cmd>bprevious<CR>', { desc = 'Go to previous buffer' })
