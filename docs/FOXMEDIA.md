# foxmedia - Screenshot Auto-Upload to R2

Personal media asset CLI that auto-uploads screenshots to Cloudflare R2 and logs them in Obsidian.

## How It Works

```
Take screenshot → ~/screenshots/ → macOS Folder Action → foxmedia CLI → Cloudflare R2
                                                                      → Obsidian weekly note
                                                                      → clipboard (URL)
```

### The Pipeline

1. **macOS screenshot** saves to `~/screenshots/` (set in System Settings > Keyboard > Screenshots)
2. **Automator Folder Action** (`Screenshots to R2.workflow`) watches that folder
3. **Shell script** (`upload-screenshots-obsidian.sh`) loads R2 creds and calls foxmedia
4. **foxmedia CLI** uploads original + generates mobile/HD/WebP variants → R2
5. **Post-upload**: URL copied to clipboard, markdown image appended to `week-notes/YYYY-WW-raw.md`

### File Locations

| What | Where |
|------|-------|
| foxmedia source | `~/.local/lib/foxmedia/` |
| R2 credentials | `~/.local/lib/foxmedia/.env` (NOT in git) |
| Upload script | `~/.local/lib/foxmedia/automator-scripts/upload-screenshots-obsidian.sh` |
| Folder Action | `~/Library/Workflows/Applications/Folder Actions/Screenshots to R2.workflow/` |
| Upload log | `/tmp/foxmedia-screenshot-upload.log` |
| Screenshots dir | `~/screenshots/` |
| Weekly notes | `~/Library/Mobile Documents/iCloud~md~obsidian/Documents/ejfox/week-notes/` |

### R2 Bucket

- **Bucket**: `ejfox-media`
- **Public URL**: `https://pub-54d629604fe94ce68a81b5079b673529.r2.dev/`
- **Screenshot prefix**: `screenshots/`
- **Upload prefix**: `uploads/`

### Variants Generated

For each screenshot, foxmedia creates:
- Original (full size PNG)
- Mobile (800px wide, original format)
- HD (1920px wide, original format)
- Mobile WebP (800px, WebP)
- HD WebP (1920px, WebP)

## Setup on a New Machine

```bash
bash ~/.dotfiles/scripts/setup-foxmedia.sh
```

Then edit `~/.local/lib/foxmedia/.env` with your R2 credentials from Cloudflare Dashboard > R2 > Manage R2 API Tokens.

### Required .env Variables

```
R2_ACCOUNT_ID=       # Cloudflare account ID
R2_ACCESS_KEY_ID=    # R2 API token access key
R2_SECRET_ACCESS_KEY=# R2 API token secret
R2_BUCKET_NAME=      # ejfox-media
R2_PUBLIC_URL=       # https://pub-XXXX.r2.dev
DATABASE_URL=        # postgres connection (optional, for metadata)
```

## Debugging

```bash
# Watch the upload log in real time
tail -f /tmp/foxmedia-screenshot-upload.log

# Test upload manually
foxmedia upload ~/screenshots/some-file.png

# Check Folder Actions are enabled
defaults read com.apple.FolderActionsDispatcher folderActionsEnabled
# Should return: 1

# Check R2 bucket
npx wrangler r2 bucket list
```

### Common Issues

- **Script not found**: foxmedia moved or npm link broken → `cd ~/.local/lib/foxmedia && npm link`
- **No .env**: R2 credentials missing → edit `~/.local/lib/foxmedia/.env`
- **Folder Action not firing**: System Settings > General > Login Items & Extensions > Extensions > Folder Actions (or run `defaults write com.apple.FolderActionsDispatcher folderActionsEnabled -bool true`)
- **Node not found in Automator**: Script uses absolute nvm path — update if nvm version changes

## Future Ideas

- 1Password CLI for .env management across machines (`op inject`)
- Replace Automator Folder Action with launchd + fswatch (more reliable)
