mode: command
mode: dictation
-
# === ENTER ===
^slap$: key(enter)
^go ahead$: key(enter)
^send it$: key(enter)
^transmit$: key(enter)

# === QUICK KEYS ===
^tab$: key(tab)
^space$: key(space)

# shorter mode switches
^talk mode$:
    mode.disable("sleep")
    mode.disable("command")
    mode.enable("dictation")
^command mode$:
    mode.disable("sleep")
    mode.disable("dictation")
    mode.enable("command")
