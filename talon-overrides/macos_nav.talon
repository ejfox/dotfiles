mode: command
mode: dictation
-

# === APP SWITCHING ===
# Community "focus <app>" already works. These are shorter aliases:
^open ghostty$: user.switcher_focus("Ghostty")
^open chrome$: user.switcher_focus("Google Chrome")
^open safari$: user.switcher_focus("Safari")
^open messages$: user.switcher_focus("Messages")
^open slack$: user.switcher_focus("Slack")
^open discord$: user.switcher_focus("Discord")
^open signal$: user.switcher_focus("Signal")
^open obsidian$: user.switcher_focus("Obsidian")
^open claude$: user.switcher_focus("Claude")
^open figma$: user.switcher_focus("Figma")
^open finder$: user.switcher_focus("Finder")
^open music$: user.switcher_focus("Music")
^open OBS$: user.switcher_focus("OBS")

# === DIVVY WINDOW MANAGEMENT ===
# Global hotkey: alt-space opens Divvy panel, then shortcut selects layout
# Divvy shortcuts: Space=fullscreen, L=left half, R=right half, S=screen 2 full
^snap full$:
    key(alt-space)
    sleep(150ms)
    key(space)
^window expand$:
    key(alt-space)
    sleep(150ms)
    key(space)
^window left$:
    key(alt-space)
    sleep(150ms)
    key(left)
^window right$:
    key(alt-space)
    sleep(150ms)
    key(right)
^send to screen two$:
    user.move_window_to_screen(2)
    sleep(200ms)
    key(alt-space)
    sleep(150ms)
    key(space)
^window grid$:
    key(alt-space)

# === SPACES ===
^desk left$: key(cmd-ctrl-left)
^desk right$: key(cmd-ctrl-right)

# === macOS (only commands community doesn't cover well) ===
^hide this$: key(cmd-h)
^hide others$: key(cmd-alt-h)
^quit this$: key(cmd-q)
^next window$: key(cmd-`)
^previous window$: key(cmd-shift-`)
^spotlight$: key(cmd-space)
^screenshot$: key(cmd-shift-4)
^screen record$: key(cmd-shift-5)

# === QUICK DICTATION ===
^nope$: user.clear_last_phrase()

# === QUICK FOCUS ===
^switch app$: key(cmd-tab)
^show desktop$: key(f11)
^mission control$: key(ctrl-up)
^app windows$: key(ctrl-down)
