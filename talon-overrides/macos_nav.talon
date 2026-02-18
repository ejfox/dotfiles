mode: command
mode: dictation
-

# === APP SWITCHING (built-in community commands) ===
# "focus chrome" / "focus ghostty" / "focus slack" etc. already work
# "launch chrome" etc. already works
# These are short aliases for your most-used apps:
^open ghosty$: user.switcher_focus("Ghostty")
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
^snap up$: key(alt-ctrl-up)
^snap down$: key(cmd-alt-down)
^snap full$: key(alt-ctrl-up)
^snap half left$: key(cmd-alt-left)
^snap half right$: key(cmd-alt-right)
^snap bottom$: key(cmd-alt-down)
^window bigger$: key(cmd-ctrl-=)
^window smaller$: key(cmd-ctrl--)
^window grid$: key(f1)
^window cascade$: key(f12)

# === SPACES ===
^space left$: key(cmd-ctrl-left)
^space right$: key(cmd-ctrl-right)

# === GENERAL macOS ===
^hide this$: key(cmd-h)
^hide others$: key(cmd-alt-h)
^quit this$: key(cmd-q)
^close window$: key(cmd-w)
^close tab$: key(cmd-w)
^new tab$: key(cmd-t)
^new window$: key(cmd-n)
^next tab$: key(cmd-shift-])
^previous tab$: key(cmd-shift-[)
^spotlight$: key(cmd-space)
^undo$: key(cmd-z)
^redo$: key(cmd-shift-z)
^save$: key(cmd-s)
^select all$: key(cmd-a)
^copy$: key(cmd-c)
^paste$: key(cmd-v)
^cut$: key(cmd-x)
^find$: key(cmd-f)
^screenshot$: key(cmd-shift-4)
^screen record$: key(cmd-shift-5)
