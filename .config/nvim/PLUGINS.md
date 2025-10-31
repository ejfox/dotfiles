# Neovim Plugins Documentation

Comprehensive guide to all installed Neovim plugins and their configurations.

**Setup**: LazyVim 4 + nvim 0.10.4 + blink.cmp (native LSP completion)

---

## Core Plugins

### LazyVim (`LazyVim/LazyVim`)
- **Purpose**: Opinionated Neovim distro with sensible defaults
- **Includes**: LSP, treesitter, telescope, UI plugins
- **Config**: Imported in `lua/config/lazy.lua`

### Lazy.nvim (`folke/lazy.nvim`)
- **Purpose**: Plugin manager with lazy-loading
- **Features**: On-demand loading, dependency resolution, version control

---

## AI/Completion Layer

### Copilot (`zbirenbaum/copilot.lua`)
- **Purpose**: GitHub Copilot integration with inline suggestions
- **Keybindings**:
  - `<M-]>` - Next suggestion
  - `<M-[>` - Previous suggestion
  - `<C-]>` - Dismiss suggestion
  - `<Tab>` / `<CR>` - Accept (via nvim-cmp)
- **Config**: `lua/plugins/copilot.lua`
- **Features**:
  - Tab-completion style (not auto-popup)
  - 150ms debounce before showing
  - Panel mode: 3 max suggestions
  - Inline mode: 2 max suggestions
  - Temperature: 0 (deterministic)

### Blink.cmp (`saghen/blink.cmp`)
- **Purpose**: Fast completion engine with native LSP
- **Keybindings**:
  - `<C-n>` - Next item
  - `<C-p>` - Previous item
  - `<Tab>` / `<CR>` - Accept
- **Config**: `lua/plugins/nvim-cmp.lua` (legacy name, actually blink.cmp)
- **Sources**:
  1. Copilot (priority: 100) - AI suggestions
  2. LSP (priority: 90) - Language server completions
  3. Buffer (priority: 70) - Words from open buffers
  4. Path (priority: 60) - File paths

### Avante (`yetone/avante.nvim`)
- **Purpose**: Claude Sonnet 4 chat integration (Cursor-like)
- **Keybindings**:
  - `<leader>aa` - Ask (explain code)
  - `<leader>ae` - Edit (refactor selected code)
  - `<leader>ar` - Refresh
- **Config**: `lua/plugins/avante.lua`
- **Features**:
  - Sidebar chat interface
  - Project-aware via `avante.md` file
  - Full context from buffer
  - Uses Claude Sonnet 4

### Blink-cmp-copilot (`zbirenbaum/blink-cmp-copilot`)
- **Purpose**: Bridge between blink.cmp and Copilot
- **Integrates**: Copilot suggestions into blink completion menu

---

## Navigation & Search

### Telescope (`nvim-telescope/telescope.nvim`)
- **Purpose**: Fuzzy finder for files, buffers, text
- **Keybindings**:
  - `<leader>ff` - Find files
  - `<leader>fb` - Find buffers
  - `<leader>fw` - Live grep (text search)
  - `<leader>fh` - Help tags
  - `<C-d>` - Delete buffer in picker
- **Config**: `lua/plugins/minimal-telescope.lua`
- **Features**:
  - Borderless minimal UI
  - Ripgrep integration for fast search
  - Sorts buffers by last used

### Flash (`folke/flash.nvim`)
- **Purpose**: Enhanced f/F/t/T motions
- **Keybindings**:
  - `f` / `F` - Jump to char (forward/backward)
  - `t` / `T` - Jump before char (forward/backward)
  - `;` / `,` - Repeat search
- **Features**: Label-based jumping, multi-char search

### Harpoon (`ThePrimeagen/harpoon`)
- **Purpose**: Quick access to 4 marked files (hotbar)
- **Keybindings**:
  - `<leader>ha` - Add file to harpoon
  - `<leader>hh` - Toggle harpoon menu
  - `<leader>h1` - Jump to file 1
  - `<leader>h2` - Jump to file 2
  - `<leader>h3` - Jump to file 3
  - `<leader>h4` - Jump to file 4
- **Config**: `lua/plugins/harpoon.lua`
- **Features**: Persistent bookmarks, UI menu

---

## Code Editing

### nvim-surround (`kylechui/nvim-surround`)
- **Purpose**: Surround text objects with brackets, quotes, etc
- **Keybindings**:
  - `ys<motion><target>` - Wrap motion with target (ysiw" = wrap word in quotes)
  - `yss<target>` - Wrap entire line
  - `ds<target>` - Delete surrounding
  - `cs<old><new>` - Change surrounding
  - Visual `S<target>` - Wrap selection
- **Config**: `lua/plugins/surround.lua`
- **Examples**:
  - `ysw"` - Wrap word with quotes
  - `cs"'` - Change quotes from " to '
  - `ds"` - Delete surrounding quotes

### Conform (`stevearc/conform.nvim`)
- **Purpose**: Code formatting (prettier, black, stylua, etc)
- **Config**: `lua/plugins/formatting.lua`
- **Features**:
  - Prettier for JS/TS
  - Respects `.prettierrc` configs
  - Format on save capability

### Mini.pairs (`echasnovski/mini.nvim`)
- **Purpose**: Auto-close brackets and pairs
- **Features**: Smart pairing that understands context

### Mini.ai (`echasnovski/mini.ai`)
- **Purpose**: Extended text objects (a/i with more targets)
- **Features**: More granular code selection

### Dial.nvim (`monaqa/dial.nvim`)
- **Purpose**: Increment/decrement for numbers, dates, words
- **Examples**:
  - `<C-a>` on `true` → `false`
  - `<C-a>` on `1` → `2`
  - `<C-a>` on date → next date

### ts-comments (`folke/ts-comments.nvim`)
- **Purpose**: Smart comment toggling via treesitter
- **Keybindings**:
  - `gcc` - Toggle line comment
  - `gc<motion>` - Toggle comment block
- **Features**: Context-aware (understands code structure)

### Yanky.nvim (`gbprod/yanky.nvim`)
- **Purpose**: Yank history with repeat and navigation
- **Features**: Browse previous yanked text, `:Yankies` command

---

## Git Integration

### Gitsigns (`lewis6991/gitsigns.nvim`)
- **Purpose**: Show git changes in sign column
- **Display**:
  - `│` - Added line
  - `┆` - Untracked line
  - `_` - Deleted line
- **Config**: `lua/plugins/minimal-git.lua`
- **Features**: Minimal visual indicators, no virtual text

### Diffview (`sindrets/diffview.nvim`)
- **Purpose**: Side-by-side git diff viewer
- **Features**: Compare branches, commits, file history

### Git-conflict (`akinsho/git-conflict.nvim`)
- **Purpose**: Visual merge conflict handling
- **Display**:
  - Green highlights = incoming changes
  - Gray highlights = current changes
- **Features**: Commands for conflict resolution

---

## Code Quality & Diagnostics

### nvim-lspconfig (`neovim/nvim-lspconfig`)
- **Purpose**: Language server protocol configuration
- **Includes**:
  - TypeScript (`tsserver`)
  - Lua (`lua-ls`)
  - Python (`pyright`)
  - Go (`gopls`)
  - More via mason.nvim
- **Config**: Handled by LazyVim + mason-lspconfig

### Mason (`williamboman/mason.nvim`)
- **Purpose**: Package manager for LSP servers, formatters, linters
- **Keybindings**: `:Mason` to open UI

### Mason-lspconfig (`williamboman/mason-lspconfig.nvim`)
- **Purpose**: Bridge between mason and lspconfig
- **Auto-installs**: Configured LSPs on startup

### Trouble (`folke/trouble.nvim`)
- **Purpose**: Better diagnostic list
- **Keybindings**: `:Trouble` to open
- **Features**: Organized diagnostics with filtering

### nvim-lint (`mfussenegger/nvim-lint`)
- **Purpose**: Linting integration (eslint, pylint, etc)

---

## Syntax & Parsing

### Treesitter (`nvim-treesitter/nvim-treesitter`)
- **Purpose**: Syntax tree parsing for all languages
- **Features**:
  - Better highlighting than regex
  - Code structure awareness
  - Powers flash.nvim, textobjects, etc
- **Parsers**: Auto-installed for common languages

### Treesitter-textobjects (`nvim-treesitter/nvim-treesitter-textobjects`)
- **Purpose**: Text objects based on code structure
- **Examples**:
  - `if` - Inner function
  - `af` - Around function
  - `ic` - Inner class
  - `ac` - Around class

### Treesitter-context (`nvim-treesitter/nvim-treesitter-context`)
- **Purpose**: Show code context at top of window
- **Display**: Current function/class name always visible

### nvim-ts-autotag (`windwp/nvim-ts-autotag`)
- **Purpose**: Auto-close HTML/JSX tags
- **Features**: Context-aware tag closing

---

## UI & Appearance

### Vulpes-Reddish Colorscheme
- **Purpose**: Custom warm reddish theme across all tools
- **Location**: `colors/vulpes_reddish_dark.lua`, `colors/vulpes_reddish_light.lua`
- **Features**:
  - Dark variant: Warm reds on #121212 background
  - Light variant: Deep reds on #ebebeb background
  - Full syntax highlighting + treesitter support
  - LSP diagnostics, git signs, UI elements
  - Consistent with Ghostty, Tmux, Lazygit, Yazi

### Auto-dark-mode (`f-person/auto-dark-mode.nvim`)
- **Purpose**: Auto-switch theme based on system appearance
- **Config**: `lua/plugins/auto-dark-mode.lua`
- **Features**:
  - Monitors system dark mode every 1 second
  - Switches between vulpes_reddish_dark (dark) and vulpes_reddish_light (light)
  - Tied to Ghostty's auto-switching for seamless theme transitions
- **How it works**: Sets `vim.o.background` which triggers the appropriate colorscheme

### Lualine (`nvim-lualine/lualine.nvim`)
- **Purpose**: Minimal statusline
- **Display**: `filename [+]=line:col` with LSP status
- **Config**: `lua/plugins/minimal-statusline.lua`
- **Integrations**: Git info, LSP status, mode

### Snacks.nvim (`folke/snacks.nvim`)
- **Purpose**: Dashboard and startup screen
- **Features**:
  - Custom ASCII header (EJF logo)
  - Quick actions (new file, find file, etc)
  - Recent files list
  - Session restoration
- **Config**: `lua/plugins/snacks.lua`

### Which-key (`folke/which-key.nvim`)
- **Purpose**: Show available keybindings on keypress
- **Features**:
  - Leader key hints
  - Organized groups
  - Searchable

### Noice (`folke/noice.nvim`)
- **Purpose**: Better UI for messages, commands, notifications
- **Features**:
  - Cleaner command line
  - Better search display
  - Smooth animations

### Zen-mode (`folke/zen-mode.nvim`)
- **Purpose**: Distraction-free writing mode
- **Keybindings**: `:ZenMode` command
- **Features**:
  - 120 char width
  - 95% backdrop dimming
  - Integrates with twilight and tmux

### Twilight (`folke/twilight.nvim`)
- **Purpose**: Dim inactive code blocks
- **Features**: 0.15 alpha, 4 lines context
- **Works with**: Zen-mode

### Mini.icons (`echasnovski/mini.icons`)
- **Purpose**: Nerd font icons throughout UI
- **Features**: File type detection + icons

### Mini.hipatterns (`echasnovski/mini.hipatterns`)
- **Purpose**: Highlight patterns (hex colors, TODO, etc)
- **Examples**: Hex colors are highlighted with actual color

---

## Navigation Across Tools

### Vim-tmux-navigator (TO BE INSTALLED)
- **Purpose**: Seamless navigation between nvim windows and tmux panes
- **Keybindings**:
  - `Ctrl-h` - Left (window or pane)
  - `Ctrl-j` - Down (window or pane)
  - `Ctrl-k` - Up (window or pane)
  - `Ctrl-l` - Right (window or pane)
  - `Ctrl-\` - Previous (window or pane)
- **Status**: Pending installation

---

## Special Tools

### Obsidian.nvim (`epwalsh/obsidian.nvim`)
- **Purpose**: Obsidian vault integration
- **Vault**: `~/Documents/ejfox` (iCloud)
- **Features**:
  - Follow links with `<leader>on`
  - Create daily/weekly notes
  - Full vault search
- **Config**: `lua/plugins/obsidian.lua`

### Vim-be-good (`ThePrimeagen/vim-be-good`)
- **Purpose**: Game for practicing vim motions
- **Command**: `:VimBeGood`

### Hardtime.nvim (`takac/vim-hardtime`)
- **Purpose**: Learn vim by blocking inefficient keys
- **Status**: Installed but disabled (`enabled = false`)
- **Config**: `lua/plugins/hardtime.lua`
- **Reason**: Disabled due to active development work

---

## Dev Experience Plugins

### LazyDev (`folke/lazydev.nvim`)
- **Purpose**: Full signature help in nvim config
- **Features**: Type hints for vim module

### Plenary (`nvim-lua/plenary.nvim`)
- **Purpose**: Lua utility library (required by many plugins)

### NUI (`MunifTanjim/nui.nvim`)
- **Purpose**: UI component library
- **Used by**: Noice, avante, etc

### Todo-comments (`folke/todo-comments.nvim`)
- **Purpose**: Highlight and search TODO/FIXME/NOTE/HACK comments
- **Keybindings**: `:TodoTelescope` to find all TODOs

### Persistence.nvim (`folke/persistence.nvim`)
- **Purpose**: Automatic session saving and restoration
- **Features**:
  - Save current session
  - Restore on startup
  - `:SessionStart`, `:SessionStop` commands

### Grug-far.nvim (`MagicDust/grug-far.nvim`)
- **Purpose**: Better search and replace UI
- **Features**: Live preview, context display

---

## Optional/Experimental Plugins

### Codeium.nvim (`Exafunction/codeium.nvim`)
- **Status**: Installed but unused (prefer Copilot)
- **Purpose**: Free alternative to Copilot

### Ayu (`ayu-theme/ayu-vim`)
- **Status**: Installed but unused (using Catppuccin)
- **Reason**: Replaced by Catppuccin for consistency

### Tokyonight (`folke/tokyonight.nvim`)
- **Status**: Installed but unused
- **Reason**: Fallback theme option

---

## Keybinding Groups

### Leader Bindings
- `<leader>f*` - Telescope find commands
- `<leader>h*` - Harpoon quick files
- `<leader>a*` - Avante AI commands
- `<leader>t*` - Trouble diagnostics (LazyVim default)
- `<leader>?` - Which-key help

### Window/Pane Navigation
- `Ctrl-h/j/k/l` - Move window (nvim) or pane (tmux)

### Motion Enhancements
- `f/F/t/T` - Flash.nvim jumping
- `y/d/c + surround` - Text object operations

---

## Installation Notes

**To install new plugins:**
1. Create `lua/plugins/<name>.lua` with plugin spec
2. Lazy.nvim auto-discovers in `lua/plugins/`
3. Run `:Lazy sync` to install

**To remove a plugin:**
1. Delete the plugin file
2. Run `:Lazy clean` to remove from disk

**To check plugin health:**
1. `:LazyHealth` - Plugin status
2. `:checkhealth` - All health checks
3. `:LazyExtras` - Available LazyVim extras

---

## Performance Notes

- Total plugins: 45+ (all lazy-loaded)
- Startup time: < 100ms
- Idle memory: ~50MB
- Parsing (treesitter): On-demand per file

---

## Related Configuration

- **Theme**: See `lua/plugins/colorscheme.lua` for light/dark mode
- **Keybindings**: See `which-key.nvim` integration
- **LSP**: Configured via LazyVim + mason
- **Formatting**: `lua/plugins/formatting.lua`
- **Statusline**: `lua/plugins/minimal-statusline.lua`
