mode: command
mode: dictation
-
^go ahead$: key(enter)
^go head$: key(enter)
^send it$: key(enter)

# shorter mode switches
^talk$:
    mode.disable("sleep")
    mode.disable("command")
    mode.enable("dictation")
^cmd$:
    mode.disable("sleep")
    mode.disable("dictation")
    mode.enable("command")
