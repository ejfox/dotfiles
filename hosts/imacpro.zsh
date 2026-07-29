# ============================================================================
# Host config: imacpro (Intel iMac Pro, workstation)
# ============================================================================
# Auto-loaded by ~/.dotfiles/.zshrc when ${HOST%%.*} == "imacpro".
# Tracked in the dotfiles repo (syncs to GitHub), but only THIS machine sources
# it — a new box just adds hosts/<its-short-hostname>.zsh, nothing to symlink.
# Secrets do NOT belong here — those stay in ~/.env (gitignored).
# ============================================================================

# --- Machine identity -------------------------------------------------------
export MACHINE_NAME="imacpro"
export MACHINE_TYPE="workstation"   # vs "laptop"
export MACHINE_POWER="beast"        # high-performance
export IMAC_PRO_ICON="🖥️"           # optional p10k indicator

# --- Build & runtime parallelism (we've got cores to spare) -----------------
export MAKEFLAGS="-j$(sysctl -n hw.ncpu)"     # use all cores for make
export HOMEBREW_MAKE_JOBS=$(sysctl -n hw.ncpu)
export UV_THREADPOOL_SIZE=16                  # node/libuv aggressive threadpool

# --- Consistent dev ports for this machine ----------------------------------
export DEV_PORT=3000
export API_PORT=8080
export PREVIEW_PORT=4173

# --- Desktop-only paths (not present on the laptop) -------------------------
export DESKTOP_PROJECTS="$HOME/projects"
export ARCHIVE_DIR="$HOME/archive"

# --- Machine info / thermals ------------------------------------------------
alias cores='sysctl -n hw.ncpu'
alias temp='sudo powermetrics --samplers smc -i1 -n1 | grep -i "CPU die temperature"'
alias fans='sudo powermetrics --samplers smc -i1 -n1 | grep -i fan'
alias power='powermetrics -s cpu_power -n1'
alias whereami='echo "🖥️  iMac Pro ($(sysctl -n machdep.cpu.brand_string))"'

# --- Big-screen ls variants -------------------------------------------------
alias lt='lsd --tree --depth 3'   # more visual depth than the laptop
alias lll='lsd -lah --blocks permission,size,date,name'

# --- Prebuilt tmux layouts (desktop real estate) ----------------------------
alias tdev='tmux new-session -s dev -d \; split-window -h \; split-window -v \; select-pane -t 0 \; split-window -v \; attach'
alias tbig='tmux new-session -s big -d \; split-window -h \; split-window -h \; select-pane -t 0 \; split-window -v \; select-pane -t 2 \; split-window -v \; select-pane -t 4 \; split-window -v \; attach'
