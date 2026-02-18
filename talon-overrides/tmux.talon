tag: terminal
mode: command
mode: dictation
-
tag(): user.tmux

# window navigation
^mux next$:
    key(ctrl-a)
    sleep(100ms)
    key(n)
^mux previous$:
    key(ctrl-a)
    sleep(100ms)
    key(p)
^mux last$:
    key(ctrl-a)
    sleep(100ms)
    key(l)
^mux <number>$:
    key(ctrl-a)
    sleep(100ms)
    key('{number}')
^mux new$:
    key(ctrl-a)
    sleep(100ms)
    key(c)
^mux rename$:
    key(ctrl-a)
    sleep(100ms)
    key(,)
^mux close$:
    key(ctrl-a)
    sleep(100ms)
    key(&)

# pane navigation
^mux left$:
    key(ctrl-a)
    sleep(100ms)
    key(left)
^mux right$:
    key(ctrl-a)
    sleep(100ms)
    key(right)
^mux up$:
    key(ctrl-a)
    sleep(100ms)
    key(up)
^mux down$:
    key(ctrl-a)
    sleep(100ms)
    key(down)
^mux move <user.arrow_key>$:
    key(ctrl-a)
    sleep(100ms)
    key(arrow_key)
^mux next pane$:
    key(ctrl-a)
    sleep(100ms)
    key(o)
^mux split right$:
    key(ctrl-a)
    sleep(100ms)
    key(%)
^mux split down$:
    key(ctrl-a)
    sleep(100ms)
    key(")
^mux close pane$:
    key(ctrl-a)
    sleep(100ms)
    key(x)
^mux zoom$:
    key(ctrl-a)
    sleep(100ms)
    key(z)

# pane creation (splits + auto-focuses new pane)
^mux pane right$:
    key(ctrl-a)
    sleep(100ms)
    key(%)
^mux pane down$:
    key(ctrl-a)
    sleep(100ms)
    key(")
^mux pane left$:
    key(ctrl-a)
    sleep(100ms)
    key(%)
    sleep(100ms)
    key(ctrl-a)
    sleep(100ms)
    key(left)
^mux pane up$:
    key(ctrl-a)
    sleep(100ms)
    key(")
    sleep(100ms)
    key(ctrl-a)
    sleep(100ms)
    key(up)

# workspace layout (your custom triple-pane setup)
^mux workspace$:
    key(ctrl-a)
    sleep(100ms)
    key(shift-c)

# jump to window with bell/activity alert
^mux alert$:
    key(ctrl-a)
    sleep(100ms)
    key(alt-n)
^mux newest$:
    key(ctrl-a)
    sleep(100ms)
    key(alt-n)
