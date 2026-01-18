# 🛠️ Clinton Neovim Configuration

A modern, minimal, and fast Neovim setup powered by **Lazy.nvim**. This config is optimized for web development, LSP support, terminal workflows, and smooth navigation.

My use of Neovim is very minimalist and very focused on defaults. I also forbid myself to fumble around split screens and tabs.

**Disclaimer: Fork this if you want to use it. I constantly improve my configuration over time so this repo will change slightly.**

## My workflow
### Few new bindings
I want to have to remember only a few bindings. I'm not interested in re-learning 100 bindings. If I can't list the bindings one by one it's probably too many.

### No split screens
I use the floating terminal instead of split screen. When I need two screens I open Neovim in a second monitor. I hate split screens with a passion and find that it overcomplicates my workflow to have to remember how to switch between editor screens when I already by habit switch between monitors and windows with my Hyperland setup.

Hitting <leader>t to open a floating terminal, do what I need there, then :q is perfect and doesn't get in the way.

### No tabs
I switch between buffers instead of tabs (and close buffers when I no longer need them open). More than 3 buffers is usually too much.

### No themes or fancy stuff
Vim already has a bunch of native themes so there's no need to pack in a bunch of extra plugins and heavy downloads.

### Vim fundie
I try to stay very Vim original and not update key bindings for motions.

I want to keep my Neovim setup working for me but also want to preserve the skill to open vi in a remote terminal without my config and not be completely lost.

This is why I try to stay as Vim fundie as possible. Every new change is a new habit I need to learn and I try to avoid needing to reprogram my habits.

### Plugins that save time
I'm ok with plugins as long as they bring large productivity gains. You can see the plugins I use below. If I use a plugin it's because it's almost impossible to live without it.

---

## 🔑 Key Mappings

q and w have Q and W aliases because I keep accidentally hitting those.

> `Leader key`: `<space>`

### 🔍 Telescope (Fuzzy Finder)

| Mapping         | Mode | Action                         |
|-----------------|------|--------------------------------|
| `<leader>f`     | `n`  | Find files                     |
| `<leader>g`     | `n`  | Live grep                      |
| `<leader>b`     | `n`  | List open buffers              |

### 🧠 Diagnostics

| Mapping         | Mode | Action                             |
|-----------------|------|------------------------------------|
| `<leader>d`     | `n`  | Show diagnostic popup              |

### 🖥️ Terminal (toggleterm)

| Mapping         | Mode | Action                                               |
|-----------------|------|------------------------------------------------------|
| `<leader>t`     | `n`  | Toggle floating terminal (default behavior)          |
| `<leader>p`     | `n`  | Open floating terminal in current buffer's directory |
| `<Esc>`         | `t`  | Exit terminal insert mode                            |

### 🔄 Buffer Navigation

| Mapping         | Mode | Action               |
|-----------------|------|----------------------|
| `<Tab>`         | `n`  | Go to next buffer    |
| `<S-Tab>`       | `n`  | Go to previous buffer|

### ⬇️ Smooth Scrolling (Neoscroll)

| Mapping         | Mode    | Action                      |
|-----------------|---------|-----------------------------|
| `<C-d>`         | `n/v/x` | Smooth scroll down          |
| `<C-u>`         | `n/v/x` | Smooth scroll up            |

---

## 🔌 Plugins Used

Plugins are managed with [`lazy.nvim`](https://github.com/folke/lazy.nvim).

### 🌐 Core Tools

- [`lazy.nvim`](https://github.com/folke/lazy.nvim) - Plugin manager

### 🌈 UI/UX

- [`nvim-treesitter`](https://github.com/nvim-treesitter/nvim-treesitter) - Syntax highlighting, indentation
- [`nvim-web-devicons`](https://github.com/nvim-tree/nvim-web-devicons) - File icons
- [`indent-blankline.nvim`](https://github.com/lukas-reineke/indent-blankline.nvim) - Indentation guides
- [`neoscroll.nvim`](https://github.com/karb94/neoscroll.nvim) - Smooth scrolling
- [`toggleterm.nvim`](https://github.com/akinsho/toggleterm.nvim) - Floating and split terminal integration
- Nvim Scrollbar
- Auto Sessions
- Comfy line numbers

### 🔍 Fuzzy Finder

- [`telescope.nvim`](https://github.com/nvim-telescope/telescope.nvim) - File and text search
- [`telescope-fzf-native.nvim`](https://github.com/nvim-telescope/telescope-fzf-native.nvim) - Native sorter (requires `make`)
- [`plenary.nvim`](https://github.com/nvim-lua/plenary.nvim) - Dependency for telescope

### 🧠 LSP & Autocompletion

- [`nvim-lspconfig`](https://github.com/neovim/nvim-lspconfig) - LSP client config
- [`mason.nvim`](https://github.com/williamboman/mason.nvim) - Portable LSP server installer
- [`mason-lspconfig.nvim`](https://github.com/williamboman/mason-lspconfig.nvim) - Mason + LSP integration
- [`nvim-cmp`](https://github.com/hrsh7th/nvim-cmp) - Autocompletion engine
- [`cmp-nvim-lsp`](https://github.com/hrsh7th/cmp-nvim-lsp) - LSP completion source
- [`cmp-buffer`](https://github.com/hrsh7th/cmp-buffer) - Buffer completion source
- [`cmp-path`](https://github.com/hrsh7th/cmp-path) - Path completion source
- [`lspkind.nvim`](https://github.com/onsails/lspkind.nvim) - Icons in completion menu

---

## 🧠 LSP Servers Ensured via Mason

These are automatically installed:

- `html`
- `cssls`
- `prismals`
- `svelte`
- `tsserver`
- `jsonls`
- `lua_ls`
- `bashls`

---

## 🧪 Appearance & Behavior

- **Colorscheme**: `habamax`
- **Line Numbers**: Enabled (absolute + relative)
- **Cursor Line**: Highlighted
- **Search**: Smart case, incremental
- **Tabs**: 2 spaces (expandtab)
- **Mouse**: Disabled
- **Statusline**: Custom diagnostic line & error line indicators

---

## 📦 Treesitter Languages Installed

- `lua`
- `javascript`
- `typescript`
- `html`
- `css`
- `svelte`
- `prisma`
- `bash`

---

## 📜 Status Line Extras

Shows:
- Diagnostic count (🔴 for issues)
- First 3 lines with diagnostics (e.g. `Lines 4, 10, 22...`)

---

> Feel free to extend this setup with additional plugins, keymaps, or colorschemes.

