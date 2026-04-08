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

# === RECTANGLE PRO WINDOW MANAGEMENT ===
^snap left$: key(cmd-alt-left)
^snap right$: key(cmd-alt-right)
^snap full$: key(alt-ctrl-up)
^snap down$: key(cmd-alt-down)
^window bigger$: key(cmd-ctrl-=)
^window smaller$: key(cmd-ctrl--)
^window grid$: key(f1)
^window cascade$: key(f12)

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

# === QUICK FOCUS ===
^switch app$: key(cmd-tab)
^show desktop$: key(f11)
^mission control$: key(ctrl-up)
^app windows$: key(ctrl-down)
