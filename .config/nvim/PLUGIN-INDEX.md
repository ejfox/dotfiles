# Nvim Plugin Index - What Does What

Comprehensive reference for all installed plugins, organized by what they actually do for you.

---

## 🤖 AI Coding Assistants

### **copilot.lua** - Your inline ghost text buddy
- Shows AI suggestions as gray ghost text while you type
- `Tab` to accept, `Ctrl-Right` for one word, `Ctrl-l` for one line
- `]s` / `[s` to cycle through suggestions
- `Alt-Enter` opens panel to browse multiple suggestions
- Fast (75ms debounce), works in all file types

### **avante.nvim** - Claude in your sidebar
- Full Claude chat inside nvim (Sonnet 4)
- `<leader>aa` - Ask Claude about code
- `<leader>ae` - Edit/refactor with Claude
- `<leader>ar` - Refresh suggestions
- Opens in right sidebar, lets you review before applying

### **codeium.nvim** - Alternative AI completions
- Another AI completion option (not actively used with Copilot enabled)
- Free, similar to Copilot

### **blink.cmp** + **blink-copilot** - Smart completion engine
- Handles LSP completions (types, functions, imports)
- Integrates Copilot suggestions into completion menu
- `Ctrl-n` / `Ctrl-p` to navigate, `Enter` to accept

---

## 📁 File Navigation

### **oil.nvim** - Edit your filesystem like a buffer
- Press `-` to edit parent directory as if it's a text file
- Move/rename/delete files by editing text and saving
- `Enter` to open, `-` to go up, `g.` to toggle hidden files
- Way faster than traditional file trees

### **telescope.nvim** - Fuzzy finder for everything
- Find files, grep code, search buffers, etc.
- Core of LazyVim's `<leader>` commands
- `<leader>ff` - Find files
- `<leader>fg` - Grep in files
- `<leader>fb` - Find buffers

### **harpoon** - Bookmark key files
- Mark 1-4 most important files, jump instantly
- `<leader>ha` - Add current file
- `<leader>hh` - Show menu
- `<leader>h1` through `<leader>h4` - Jump to marks
- Perfect for "main file + test + config + notes" workflow

### **flash.nvim** - Jump anywhere on screen
- Press `s` + two chars → jumps to that location
- Lightspeed replacement, super fast visual jumping

---

## 🎨 UI & Appearance

### **LazyVim** - The whole framework
- Preconfigured base that everything builds on
- Sensible defaults, extensible structure
- Manages plugin loading, keybinds, LSP setup

### **catppuccin** + **tokyonight.nvim** - Color schemes
- Your theme options
- LazyVim lets you switch between them

### **auto-dark-mode.nvim** - Follows macOS dark mode
- Automatically switches theme when macOS does
- No manual theme switching needed

### **lualine.nvim** - Bottom status bar
- Shows mode, git branch, file info, LSP status
- Custom config in `minimal-statusline.lua`

### **bufferline.nvim** - Top tab bar
- Shows open buffers as tabs
- `Shift-H` / `Shift-L` to switch buffers

### **mini.icons** - Pretty file icons
- Provides icons for filetypes throughout nvim
- Used by telescope, oil, statusline, etc.

### **which-key.nvim** - Keymap hints
- Shows available keys when you pause (e.g., after `<leader>`)
- Self-documenting interface
- How you discover what `]` or `<leader>g` can do

### **noice.nvim** - Better UI for messages
- Prettier command line, messages, and popups
- Cleaner than default vim messages

### **nui.nvim** - UI component library
- Backend for noice, avante, and other modern UIs
- Not user-facing, just infrastructure

---

## 🔧 Code Editing Tools

### **nvim-surround** - Manipulate surrounding chars
- `ysiw"` - Surround word with quotes
- `cs"'` - Change double quotes to single
- `ds"` - Delete surrounding quotes
- Works with brackets, tags, etc.

### **mini.pairs** - Auto-close brackets/quotes
- Type `(` → automatically adds `)`
- Smart: doesn't double-close if `)` already exists

### **mini.ai** - Better text objects
- Enhanced `ci"`, `da(`, etc.
- Smarter about finding matching pairs

### **dial.nvim** - Increment/decrement anything
- `Ctrl-a` / `Ctrl-x` on numbers, dates, booleans, hex colors
- LazyVim extra that makes `++` smart

### **yanky.nvim** - Better yank/paste
- Remembers yank history
- Cycle through previous yanks
- LazyVim extra for paste improvements

### **ts-comments.nvim** - Language-aware commenting
- `gcc` - Toggle comment on line
- `gc` + motion - Comment region
- Knows correct comment syntax per language

### **conform.nvim** - Code formatter
- Runs prettier, black, gofmt, etc.
- Auto-formats on save (configured in `formatting.lua`)

### **nvim-lint** - Linter integration
- Runs eslint, shellcheck, etc.
- Shows errors/warnings in gutter

---

## 🌳 Language Intelligence (Treesitter & LSP)

### **nvim-treesitter** - Syntax understanding
- Parses code into AST for smart highlighting
- Powers text objects, folding, navigation
- Way better than regex-based syntax highlighting

### **nvim-treesitter-context** - Sticky function header
- Shows function/class name at top when scrolling
- Always know what scope you're in

### **nvim-treesitter-textobjects** - Smart text objects
- `]f` / `[f` - Jump to next/prev function
- `]a` / `[a` - Jump to next/prev argument
- Powers your code navigation

### **nvim-ts-autotag** - Auto-close HTML/JSX tags
- Type `<div>` → auto-adds `</div>`
- Works in Vue, React, Svelte, HTML

### **nvim-lspconfig** - LSP client
- Connects to language servers (tsserver, rust-analyzer, etc.)
- Powers `gd`, `gr`, `K` (hover), code actions
- Core of "IDE features"

### **mason.nvim** + **mason-lspconfig.nvim** - LSP installer
- `:Mason` to install language servers, linters, formatters
- Bridges mason packages to nvim-lspconfig

### **lazydev.nvim** - Lua development
- Better completion for nvim config writing
- Understands vim API

---

## 🐛 Debugging

### **nvim-dap** - Debug adapter protocol
- Run debuggers inside nvim (like VSCode)
- Set breakpoints, step through code, inspect variables

### **nvim-dap-ui** - Debug UI
- Pretty windows for watch, stack, variables
- Makes DAP usable

### **nvim-dap-virtual-text** - Inline variable values
- Shows variable values next to code while debugging
- No need to check watch window

---

## 🔀 Git Integration

### **gitsigns.nvim** - Git gutter signs
- Shows +/- for added/deleted lines in gutter
- `]h` / `[h` to jump between hunks
- Stage/unstage hunks with `<leader>hs`, `<leader>hu`

### **diffview.nvim** - Review changes like a pro
- `<leader>gd` - Opens side-by-side diff view
- Review all Claude Code changes at once
- `]c` / `[c` to jump between files
- Auto-refreshes when files change

### **git-conflict.nvim** - Merge conflict helper
- Highlights conflicts with `<<<<<<< HEAD`
- Commands to choose ours/theirs/both
- Makes resolving conflicts visual

---

## 📝 Writing & Note-Taking

### **obsidian.nvim** - Obsidian integration
- Link to Obsidian vault from nvim
- Follow `[[wiki-links]]`, create notes
- Sync with your Obsidian knowledge base

### **todo-comments.nvim** - Highlight TODOs
- Highlights `TODO:`, `FIXME:`, `NOTE:` in comments
- `]t` / `[t` to jump between them
- Shows in Trouble and Telescope

### **zen-mode.nvim** - Distraction-free writing
- `<leader>Z` - Full-screen, centered, minimal UI
- Perfect for writing docs or focusing

### **twilight.nvim** - Dim inactive code
- Highlights only the function/block you're in
- Dims everything else
- Pairs with zen-mode for deep focus

---

## 🔍 Search & Replace

### **grug-far.nvim** - Project-wide find/replace
- Visual search and replace across files
- Preview changes before applying
- Way better than `:s///g` across files

### **trouble.nvim** - Better quickfix/diagnostics
- Pretty list of errors, warnings, TODOs, references
- `<leader>xx` - Toggle trouble
- `<leader>xd` - Document diagnostics
- Replaces default quickfix window

---

## 🌐 Language-Specific

### **kulala.nvim** - HTTP client (like Postman)
- Make HTTP requests from `.http` files
- Test APIs without leaving nvim
- Response shows inline

### **svelte** config - Svelte support
- Custom LSP + treesitter for Svelte files
- Configured in `svelte.lua`

---

## 🎯 Workflow & Productivity

### **persistence.nvim** - Session management
- Auto-saves session on exit
- `<leader>qs` - Restore last session
- `<leader>ql` - Restore session for cwd

### **snacks.nvim** - Misc UI goodies
- Dashboard, notifications, scroll animations
- LazyVim's opinionated extras
- Configured in `snacks.lua`

### **mini.animate** - Smooth animations
- Animates cursor, scroll, window resize
- Makes nvim feel fluid (config in `mini-animate.lua`)

### **vim-tmux-navigator** - Seamless tmux navigation
- `Ctrl-h/j/k/l` works across vim and tmux panes
- Treat nvim + tmux as one big window manager

### **hardtime.nvim** - Break bad vim habits
- Disables `hjkl` spam, forces better motions
- Training wheels for efficient vim usage

### **vim-be-good** - Vim training game
- Practice motions in a game
- Makes learning vim movement fun

---

## 🧩 Extras & Dependencies

### **plenary.nvim** - Lua utilities
- Required by telescope, harpoon, gitsigns, etc.
- Provides async, path, window helpers
- Not user-facing, just infrastructure

### **friendly-snippets** - Snippet collection
- Provides snippets for blink.cmp
- Common patterns for all languages

### **nvim-web-devicons** - Icon library
- Used by statusline, oil, telescope, etc.
- Fallback if mini.icons isn't available

### **lazy.nvim** - Plugin manager
- Loads all these plugins
- `:Lazy` to manage plugins
- Handles updates, profiling, health checks

---

## 🛠️ Your Custom Workflow Plugins

### **claude-code-workflow.lua** - Custom Claude Code setup
- Hot reload when Claude Code edits files
- Diffview keybinds (`<leader>gd`, `<leader>gc`)
- Copy code with file paths (`<leader>yr`, `<leader>ya`)
- Git diff auto-refresh for watching Claude work

### **custom/hotreload.lua** - File watcher
- Auto-reloads files when external tools change them
- Enables seamless tmux + Claude Code workflow

### **custom/git-diff-hotreload.lua** - Diffview auto-refresh
- Watches `.git/` for changes
- Updates diffview when Claude commits
- Real-time code review

---

## Key Takeaways

**AI Coding:**
- Copilot = inline ghost text (fast, local)
- Avante = Claude chat (deep refactors)

**Navigation:**
- Oil = file editing
- Harpoon = quick bookmarks
- Flash = visual jumping
- Telescope = fuzzy everything

**Git:**
- Gitsigns = gutter changes
- Diffview = review all changes
- `]c`/`[c` = jump between files in diff

**Writing Code:**
- LSP = go to def, hover, rename
- Treesitter = smart syntax, text objects
- Surround = manipulate brackets/quotes
- Conform = auto-format

**Pro Tips:**
- `<leader>` → wait → which-key shows options
- `]` / `[` → jump to next/prev (errors, functions, files)
- `-` → open parent dir in oil
- `<leader>gd` → review git changes
