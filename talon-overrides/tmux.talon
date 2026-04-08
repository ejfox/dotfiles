tag: terminal
mode: command
mode: dictation
-
tag(): user.tmux

# === WINDOW NAVIGATION ===
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

# === PANE NAVIGATION ===
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
^mux next pane$:
    key(ctrl-a)
    sleep(100ms)
    key(o)

# === PANE MANAGEMENT ===
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

# === LAYOUTS ===
^mux workspace$:
    key(ctrl-a)
    sleep(100ms)
    key(shift-c)
^mux alert$:
    key(ctrl-a)
    sleep(100ms)
    key(alt-n)
