# MCP Server Configuration Backup

**Created:** December 3, 2025
**Purpose:** Easy recovery of MCP server configs

## Installed MCP Servers

### obsidian-mcp
- **Package:** `obsidian-mcp` (via uvx)
- **Purpose:** Direct filesystem access to Obsidian vault
- **Vault path:** `/Users/ejfox/Library/Mobile Documents/iCloud~md~obsidian/Documents/ejfox`

**Capabilities:**
- Read/write markdown files
- Search notes by content, tags, metadata
- List files and directory operations
- Manage TODOs
- Frontmatter/metadata management

## Quick Restore

### Option 1: Claude CLI (Easiest)
```bash
cd ~/path/to/your/project
claude mcp add -e OBSIDIAN_VAULT_PATH="/Users/ejfox/Library/Mobile Documents/iCloud~md~obsidian/Documents/ejfox" --transport stdio obsidian uvx obsidian-mcp
```

### Option 2: Manual JSON Edit
Add to `.claude.json` in your project directory:
```json
{
  "projects": {
    "/your/project/path": {
      "mcpServers": {
        "obsidian": {
          "type": "stdio",
          "command": "uvx",
          "args": ["obsidian-mcp"],
          "env": {
            "OBSIDIAN_VAULT_PATH": "/Users/ejfox/Library/Mobile Documents/iCloud~md~obsidian/Documents/ejfox"
          }
        }
      }
    }
  }
}
```

### Option 3: Copy From Backup
```bash
# The exact config is saved in:
cat ~/.dotfiles/.claude/mcp-servers-backup.json

# Copy to your project's MCP config
# Then run: claude mcp list
```

## Verify Installation

```bash
# Check server is connected
claude mcp list

# Should show:
# obsidian: uvx obsidian-mcp - ✓ Connected
```

## Dependencies

**Required:**
- `uvx` (uv package manager) - `brew install uv`
- `obsidian-mcp` package (auto-installed by uvx)

**Notes:**
- Each project directory can have its own MCP servers
- Config lives in `~/.claude.json` under the project path
- Obsidian vault path is specific to your iCloud Drive
- Server auto-starts when Claude Code runs in that directory

## Troubleshooting

**MCP server not connecting:**
```bash
# Check uvx is installed
which uvx

# Test obsidian-mcp manually
uvx --from obsidian-mcp obsidian-mcp --help

# Check vault path exists
ls -la "/Users/ejfox/Library/Mobile Documents/iCloud~md~obsidian/Documents/ejfox"
```

**Connection shows but tools not available:**
- Restart Claude Code session
- Check `claude mcp list` shows ✓ Connected
- Verify no error messages in terminal

## Related

- MCP Official Docs: https://modelcontextprotocol.io/
- obsidian-mcp PyPI: https://pypi.org/project/obsidian-mcp/
- Claude Code MCP Docs: https://code.claude.com/docs/en/mcp

---

*Backup created automatically - safe to commit to dotfiles repo*
