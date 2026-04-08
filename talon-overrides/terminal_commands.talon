app: Ghostty
app: com.mitchellh.ghostty
mode: command
mode: dictation
-

# === LINE EDITING ===
^wipe$: key(ctrl-u)
^wipe line$: key(ctrl-u)
^wipe word$: key(ctrl-w)
^wipe back$: key(ctrl-w)
^wipe ahead$: key(ctrl-k)
^chomp$: key(ctrl-w ctrl-w ctrl-w ctrl-w ctrl-w ctrl-w ctrl-w ctrl-w ctrl-w ctrl-w)
^cancel$: key(ctrl-c)
^bail$: key(ctrl-c)
^dismiss$: key(escape)
^close this$: key(q)
^confirm$: key(y)
^deny$: key(n)
^clear screen$:
    insert("clear")
    key(enter)

# === CURSOR NAV ===
^word left$: key(alt-b)
^word right$: key(alt-f)
^line start$: key(ctrl-a)
^line end$: key(ctrl-e)

# === HISTORY ===
^last command$: key(up)
^older$: key(up)
^newer$: key(down)
^run again$: key(up enter)
^search history$: key(ctrl-r)

# === QUICK LAUNCH ===
^run claude$:
    insert("claude")
    key(enter)
^run claude skip$:
    insert("claude --dangerously-skip-permissions")
    key(enter)
^run codex$:
    insert("codex")
    key(enter)
^run neovim$:
    insert("nvim .")
    key(enter)
^run lazygit$:
    insert("lazygit")
    key(enter)
^run yazi$:
    insert("y")
    key(enter)
^run btop$:
    insert("btop")
    key(enter)

# listing
^list files$:
    insert("ls")
    key(enter)
^list all$:
    insert("ll")
    key(enter)

# === NAVIGATION ===
^go home$:
    insert("cd ~")
    key(enter)
^go code$:
    insert("z ~/code")
    key(enter)
^go smallweb$:
    insert("z ~/smallweb")
    key(enter)
^go clients$:
    insert("z ~/client-code")
    key(enter)
^go dotfiles$:
    insert("z ~/.dotfiles")
    key(enter)
^go back$:
    insert("cd -")
    key(enter)
^go up$:
    insert("cd ..")
    key(enter)

# project shortcuts
^go paperclip$:
    insert("z ~/code/paperclip")
    key(enter)
^go website$:
    insert("z ~/code/website2")
    key(enter)
^go coach$:
    insert("z ~/code/coachartie2")
    key(enter)
^go connectology$:
    insert("z ~/code/connectology2")
    key(enter)
^go vulpes$:
    insert("z ~/code/VULPES")
    key(enter)
^go subway$:
    insert("z ~/client-code/metro-maker4")
    key(enter)
^go newswell$:
    insert("z ~/client-code/newswell")
    key(enter)
^go gem$:
    insert("z ~/client-code/global-energy-monitor")
    key(enter)
^go ddhq$:
    insert("z ~/client-code/ddhq")
    key(enter)

# === SSH ===
^connect VPS$:
    insert("ssh vps")
    key(enter)

# === GIT (safe: read-only commands auto-execute, write commands type only) ===
^git status$:
    insert("git status")
    key(enter)
^git log$:
    insert("git log --oneline -20")
    key(enter)
^git diff$:
    insert("git diff")
    key(enter)
^git branch$:
    insert("git branch")
    key(enter)
^git pull$:
    insert("git pull")
    key(enter)
^git stash$:
    insert("git stash")
    key(enter)
^git pop$:
    insert("git stash pop")
    key(enter)
# Write commands: type but DON'T auto-execute
^git push$:
    insert("git push")
^git add all$:
    insert("git add -A")
^git checkout <user.text>$:
    insert("git checkout {text}")
^git commit <user.text>$:
    insert("git commit -m \"{text}\"")
^AI commit$:
    insert("ai-commit")
    key(enter)

# === DEV SERVERS ===
^dev server$:
    insert("npm run dev")
    key(enter)
^yarn dev$:
    insert("yarn dev")
    key(enter)
^run install$:
    insert("npm install")
    key(enter)

# === UTILITIES ===
^note <user.text>$:
    insert("note {text}")
    key(enter)
^show tips$:
    insert("tips")
    key(enter)
^reload shell$:
    insert("source ~/.zshrc")
    key(enter)

# === TMUX - LOCAL (ctrl-a prefix) ===
^mux sessions$:
    key(ctrl-a)
    sleep(100ms)
    key(s)
^mux detach$:
    key(ctrl-a)
    sleep(100ms)
    key(d)
^mux scroll$:
    key(ctrl-a)
    sleep(100ms)
    key([)

# === TMUX POPUPS ===
^mux git$:
    key(ctrl-a)
    sleep(100ms)
    key(g)
^mux files$:
    key(ctrl-a)
    sleep(100ms)
    key(shift-k)
^mux scratch$:
    key(ctrl-a)
    sleep(100ms)
    key(shift-s)
^mux yank$:
    key(ctrl-a)
    sleep(100ms)
    key(ctrl-y)

# === NESTED TMUX - VPS (ctrl-b prefix) ===
# When SSH'd into VPS with a nested tmux session
^remote next$:
    key(ctrl-b)
    sleep(100ms)
    key(n)
^remote previous$:
    key(ctrl-b)
    sleep(100ms)
    key(p)
^remote last$:
    key(ctrl-b)
    sleep(100ms)
    key(l)
^remote <number>$:
    key(ctrl-b)
    sleep(100ms)
    key('{number}')
^remote scroll$:
    key(ctrl-b)
    sleep(100ms)
    key([)
^remote zoom$:
    key(ctrl-b)
    sleep(100ms)
    key(z)
^remote new$:
    key(ctrl-b)
    sleep(100ms)
    key(c)
^remote close$:
    key(ctrl-b)
    sleep(100ms)
    key(x)
