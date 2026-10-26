return {
  -- WHY fork: epwalsh/obsidian.nvim is unmaintained; community fork has blink support
  "obsidian-nvim/obsidian.nvim",
  version = "*", -- recommended, use latest release instead of latest commit
  lazy = true,
  -- WHY not ft = "markdown": lazy re-fires FileType after loading on it, and nvim 0.12's
  -- markdown ftplugin undo then throws E31 on every .md open. Vault-only also keeps it off
  -- non-vault markdown. Table form because the vault path has a space.
  event = {
    { event = { "BufReadPre", "BufNewFile" }, pattern = "/Users/ejfox/Library/Mobile Documents/iCloud~md~obsidian/Documents/ejfox/*.md" },
  },
  cmd = "Obsidian",
  dependencies = {
    -- Required.
    "nvim-lua/plenary.nvim",

    -- see below for full list of optional dependencies 👇
  },
  opts = {
    legacy_commands = false, -- use :Obsidian <subcommand> syntax
    workspaces = {
      {
        name = "personal",
        path = "/Users/ejfox/Library/Mobile Documents/iCloud~md~obsidian/Documents/ejfox",
      },
    },
    daily_notes = {
      -- Optional, if you keep daily notes in a separate directory.
      -- folder = "week-notes",
      -- we  want the equivalent of YYYY-WW
      --
      -- Optional, if you want to change the date format for the ID of daily notes.
      -- date_format = "%Y-%m-%d",
      date_format = "%Y-%U",
      -- Optional, if you want to change the date format of the default alias of daily notes.
      -- alias_format = "%B %-d, %Y",
      -- Optional, default tags to add to each new daily note created.
      -- default_tags = { "daily-notes" },
      -- Optional, if you want to automatically insert a template from your template directory like 'daily.md'
      template = "weekly.md",
    },
  },
}
