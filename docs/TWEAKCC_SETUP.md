# tweakcc Setup Guide - Vulpes Theme for Claude Code

This guide walks you through theming Claude Code to match your nvim/tmux vulpes aesthetic.

## Quick Start

```bash
npx tweakcc
```

This opens an interactive color picker. Once you configure your theme, it will auto-apply on every shell startup.

## Vulpes Color Palette

Use these colors from your nvim theme when customizing in tweakcc:

### Core Colors
```
Background:     #0d0d0d  (very dark, almost black)
Foreground:     #f2cfdf  (soft pinkish white)
Base/Accent:    #e60067  (vibrant magenta-pink)
Alt Background: #1a1a1a  (slightly lighter dark)
```

### Syntax Highlighting
```
Keywords:       #ff1aca  (bright magenta)
Strings:        #f5f5f5  (near white)
Numbers:        #ff33c5  (pink)
Booleans:       #ff1043  (red-pink)
Functions:      #ffffff  (pure white - makes functions stand out)
Comments:       #ffffff  (white - unusual but intentional for legibility)
Variables:      #ff0a89  (magenta-pink)
Types:          #ff24ab  (pink)
Operators:      #f92c7a  (pink)
```

### UI Elements
```
Error:          #00ffff  (cyan - for contrast)
Warning:        #ffaa00  (orange)
Success:        #ffffff  (white)
Info:           #ff0095  (magenta)
Selection BG:   #6b1a3d  (darker pink)
Selection FG:   #ffffff  (white for readability)
Cursor:         #e60067  (base magenta-pink)
CursorLine:     #2a1520  (subtle dark pink tint)
```

### Diff Colors (Important!)
```
Added:          #ffffff  (white text)
Removed:        #ff1043  (red-pink)
Changed:        #ff33c5  (pink)
Diff BG Added:  #1a3d1a  (dark green - for contrast)
Diff BG Removed:#3d1a1a  (dark red)
```

## Configuration Steps

1. **Run tweakcc**:
   ```bash
   npx tweakcc
   ```

2. **Navigate to "Themes"** section in the TUI

3. **Create new theme** called "vulpes" or "vulpes-reddishnovember-dark"

4. **Configure colors** using the palette above:
   - Set background to `#0d0d0d`
   - Set foreground to `#f2cfdf`
   - Use the magenta-pink spectrum (`#e60067`, `#ff1aca`, `#ff0a89`, etc.) for syntax elements
   - Set function/method colors to `#ffffff` (white makes them pop)
   - Configure diff colors for readable code reviews

5. **Apply and test**:
   - Save your theme
   - Exit tweakcc
   - The theme will auto-apply on next shell startup via `.tweakcc-apply.sh`

## Auto-Apply on Startup

Already configured in your dotfiles:
- `.tweakcc-apply.sh` - Script that applies theme
- `.zshrc` line 15 - Calls the script on shell startup

Once you've configured tweakcc, your theme will persist across Claude Code updates automatically.

## Troubleshooting

**Theme not applying?**
```bash
# Manually apply
npx tweakcc --apply

# Or check config exists
ls ~/.tweakcc/
# or
ls ~/.config/tweakcc/
```

**Want to reconfigure?**
```bash
npx tweakcc
# Opens the UI again to edit your theme
```

**After Claude Code updates:**
The auto-apply script runs on every shell startup, so your theme will automatically be reapplied after updates.

## Philosophy

The vulpes theme is designed for:
- **Legibility**: White functions/comments stand out against the dark background
- **Focus**: Pink/magenta spectrum creates visual hierarchy without distraction
- **Bloom-friendly**: Dark selections with white text prevent eyestrain
- **Minimal**: Simple palette, maximum readability

Match this philosophy when configuring Claude Code themes.
