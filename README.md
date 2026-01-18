# 🛠️ Clinton Neovim Configuration

## 🔑 Key Mappings

q and w have Q and W aliases because I keep accidentally hitting those.
bd, bD, Bd, BD are aliases as well

> `Leader key`: `Space`

### 🔍 Telescope (Fuzzy Finder)

| Mapping         | Mode | Action                         |
|-----------------|------|--------------------------------|
| `<leader>f`     | `n`  | Find files                     |
| `<leader>g`     | `n`  | Live grep                      |
| `<leader>r`     | `n`  | Go to last query               |

<leader>+r opens the last (f) or (g) you did with the text you used to avoid
having to re-write the text.

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

I use list and close buffer native commands :ls, :bd

## 📜 Status Line Extras

Shows:
- Diagnostic count (🔴 for issues)
- First 3 lines with diagnostics (e.g. `Lines 4, 10, 22...`)

### Binds and everything else

Read the Neovim docs.
