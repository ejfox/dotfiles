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
^cancel$: key(ctrl-c)
^nope$: key(ctrl-c)
^bail$: key(ctrl-c)
^clear$:
    insert("clear")
    key(enter)

# === CURSOR NAV ===
^word left$: key(alt-b)
^word right$: key(alt-f)
^line start$: key(ctrl-a)
^line end$: key(ctrl-e)

# === HISTORY ===
^previous$: key(up)
^older$: key(up)
^newer$: key(down)
^again$: key(up enter)
^search history$: key(ctrl-r)

# === QUICK LAUNCH ===
# claude (most used command by far)
^run claude$:
    insert("claude")
    key(enter)
^run claude skip$:
    insert("claude --dangerously-skip-permissions")
    key(enter)
^run codex$:
    insert("codex")
    key(enter)

# editors / tools
^run neovim$:
    insert("nvim .")
    key(enter)
^edit$:
    insert("nvim .")
    key(enter)
^run lazygit$:
    insert("lazygit")
    key(enter)
^lazy$:
    insert("lazygit")
    key(enter)
^run yazi$:
    insert("y")
    key(enter)
^files$:
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

# project shortcuts (from your actual history)
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
^connect$:
    insert("ssh vps")
    key(enter)

# === GIT ===
^git status$:
    insert("git status")
    key(enter)
^git push$:
    insert("git push")
    key(enter)
^git pull$:
    insert("git pull")
    key(enter)
^git log$:
    insert("git log --oneline -20")
    key(enter)
^git diff$:
    insert("git diff")
    key(enter)
^git add all$:
    insert("git add -A")
    key(enter)
^git stash$:
    insert("git stash")
    key(enter)
^git pop$:
    insert("git stash pop")
    key(enter)

# === DEV SERVERS ===
^dev server$:
    insert("npm run dev")
    key(enter)
^yarn dev$:
    insert("yarn dev")
    key(enter)
^install$:
    insert("npm install")
    key(enter)

# === UTILITIES ===
^note <user.text>$:
    insert("note {text}")
    key(enter)
^tips$:
    insert("tips")
    key(enter)
^refresh$:
    insert("source ~/.zshrc")
    key(enter)

# === TMUX SESSION MANAGEMENT ===
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
