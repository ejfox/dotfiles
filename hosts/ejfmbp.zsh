# ejfmbp (MacBook Pro, Apple Silicon): laptop-only shell config.
# Sourced by .zshrc via hosts/${HOST%%.*}.zsh. Generated 2026-11-04 from the pre-symlink ~/.zshrc.
# Secrets and account IDs stay out of here: ~/.env, ~/.zshrc.local.

# .zshrc pins the iMac node (v22.22.2), absent here; without this, shells fall through to brew node.
export PATH="$NVM_DIR/versions/node/v22.19.0/bin:$PATH"

# Aliases
alias commit='git add -A && diff_output=$(git diff --cached) && if [ ${#diff_output} -gt 100000 ]; then commit_msg=$(echo -e "$(git diff --name-only)\n\n$(echo "$diff_output" | head -c 1024)" | llm -m "gpt-4o-mini" -s "$(cat ~/.llm/git_commit_template.txt) The git diff is too large to process fully. Based on the list of changed files and the first part of the diff, generate 10 concise and informative git commit messages using relevant Conventional Commits types and scopes. Ensure that each commit message is appropriate for the changes made, with no stray newlines between the suggestions. Respond with ONLY the commit messages, each separated by a single newline."); else commit_msg=$(echo "$diff_output" | llm -m "gpt-4o-mini" -s "$(cat ~/.llm/git_commit_template.txt) Based on the following git diff, generate 10 concise and informative git commit messages using relevant Conventional Commits types and scopes. Ensure that each commit message is appropriate for the changes made, with no stray newlines between the suggestions. Respond with ONLY the commit messages, each separated by a single newline."); fi && selected_msg=$(echo "$commit_msg" | fzf --prompt="Select a commit message:") && git commit -m "$selected_msg"'
alias pbjson='pbpaste | jsonfui'
alias jcurl='curl -s "" | jsonfui'
alias obsidian='cd /Users/ejfox/Library/Mobile\ Documents/iCloud~md~obsidian/Documents/ejfox'
alias pico8=/Applications/PICO-8.app/Contents/MacOS/pico8
alias cx='codex --full-auto'
alias sshsmallweb='ssh -i ~/.ssh/2024-mbp.pem smallweb@208.113.130.118'
alias cln='claude --no-approval'
alias ddhq='z ~/client-code/ddhq'
alias cc='z ~/client-code'
alias newsketch=$'\n  ART_DIR=~/art\n  TODAY=$(date +"%m-%d")\n  INDEX=$(ls $ART_DIR | grep $TODAY | awk -F"[-.]" "{print \\$3}" | sort -n | tail -n 1)\n  if [ -z "$INDEX" ]; then\n    INDEX=1\n  else\n    INDEX=$((INDEX+1))\n  fi\n  SKETCH_FILE="$TODAY-$INDEX.js"\n  cp $ART_DIR/template/default-sketch.js $ART_DIR/$SKETCH_FILE\n  echo "Created $ART_DIR/$SKETCH_FILE"\n  cd $ART_DIR\n  npx canvas-sketch-cli $SKETCH_FILE --open &\n  code $ART_DIR/art.code-workspace\n'
alias sw=smallweb
alias m=neomutt
alias ei=email-insights
alias irclog='tail -f ~/.dotfiles/.irssi/logs/**/*.log | head -50'
alias yt='~/.config/cmus/cmus-yt.sh'
alias ytp='~/.config/cmus/yt-playlist.sh'
alias cm=cmus
alias cmp='cmus-remote -u'
alias cmn='cmus-remote -n'
alias cmr='cmus-remote -r'
alias cms='cmus-remote -s'
alias cmq='cmus-remote -Q'
alias mermaid=mermaid-ascii
alias ascii-mermaid=mermaid-ascii
alias mmd=mermaid-ascii
alias elections=/Users/ejfox/client-code/ddhq/ddhq-rust-tui/target/release/ddhq-tui
alias scrap=scrapbook-cli
alias weekly-summary='/Users/ejfox/Library/Mobile\ Documents/iCloud~md~obsidian/Documents/ejfox/scripts/weekly-summary'
alias weekly-interview='/Users/ejfox/Library/Mobile\ Documents/iCloud~md~obsidian/Documents/ejfox/scripts/weekly-interview'
alias weekly-batch='$HOME/Library/Mobile\ Documents/iCloud~md~obsidian/Documents/ejfox/scripts/weekly-batch-screenshots'
alias weekly-context='$HOME/Library/Mobile\ Documents/iCloud~md~obsidian/Documents/ejfox/scripts/weekly-session-context'

# Functions
scraps () {
	local limit=${1:-10} 
	local filter=${2:-""} 
	curl -s "$PERSONAL_SUPABASE_URL/rest/v1/scraps?select=id,content,summary,created_at,updated_at,tags,relationships,metadata,scrap_id,graph_imported,url,screenshot_url,location,title,latitude,longitude,type,published_at,shared,processing_instance_id,processing_started_at,source&order=id.desc&limit=$limit&$filter" -H "apikey: $PERSONAL_SUPABASE_ANON_KEY" -H "Authorization: Bearer $PERSONAL_SUPABASE_ANON_KEY" -H "Content-Type: application/json" | jq
}

summarize_commits () {
	local default_since="48.hours" 
	local default_commits=5 
	local since="${1:-$default_since}" 
	local num_commits="${2:-$default_commits}" 
	local commits=() 
	while IFS= read -r commit
	do
		commits+=("$commit") 
	done < <(git log --since="$since" --pretty=format:"%H" -n "$num_commits")
	if [ ${#commits[@]} -eq 0 ]
	then
		echo "No commits found in the last $since."
		return 1
	fi
	local diffs="" 
	for commit in "${commits[@]}"
	do
		diffs+="$(git show "$commit")\n\n" 
	done
	echo -e "$diffs" | llm -m "gpt-3.5-turbo-16k" "Summarize the following git diffs in detail, particularly focused on describing the delta, summarizing the changes that were made:"
}

send-mermaid () {
	local target_pane=${1} 
	if [[ -z "$target_pane" ]]
	then
		echo "Usage: send-mermaid <pane_target>"
		echo "Available panes:"
		tmux list-panes -a -F "  #{session_name}:#{window_index}.#{pane_index} - #{pane_title} (#{pane_current_command})"
		echo ""
		echo "Example: echo 'graph TD"$'\n'"A --> B"$'\n'"B --> C' | send-mermaid 0:6.2"
		echo "NOTE: Use multiline syntax, NOT semicolons!"
		return 1
	fi
	local temp_file="/tmp/mermaid_$(date +%s).txt" 
	if mermaid-ascii -a -f - > "$temp_file" 2> /dev/null
	then
		tmux send-keys -t "$target_pane" "clear && echo '🎯 MERMAID DIAGRAM:' && cat '$temp_file' && rm '$temp_file'" Enter
	else
		echo "❌ Error: Failed to generate mermaid diagram"
		echo "Check your syntax - use multiline format:"
		echo "graph TD"
		echo "A --> B"
		echo "B --> C"
		echo ""
		echo "NOT: graph TD; A-->B; B-->C"
		rm -f "$temp_file"
		return 1
	fi
}

_nvmrc_autoload () {
	local dir="$PWD" rc="" 
	while :
	do
		[ -f "$dir/.nvmrc" ] && {
			rc="$dir/.nvmrc" 
			break
		}
		[ "$dir" = "/" ] && break
		dir="${dir:h}" 
	done
	[ "$rc" = "$_NVMRC_LAST" ] && return
	_NVMRC_LAST="$rc" 
	[ -z "$rc" ] && return
	nvm use > /dev/null
}

# Auto-activate a project's pinned Node via .nvmrc on cd.
autoload -U add-zsh-hook
typeset -g _NVMRC_LAST=""
add-zsh-hook chpwd _nvmrc_autoload
_nvmrc_autoload   # apply to the dir this shell starts in
