#!/bin/bash
# setup-foxmedia.sh - Set up the foxmedia screenshot-to-R2 auto-upload pipeline
#
# What this does:
#   1. Clones foxmedia to ~/.local/lib/foxmedia (if not already there)
#   2. Installs dependencies and npm-links the CLI
#   3. Prompts you to create the .env with R2 credentials
#   4. Sets up the macOS Folder Action on ~/screenshots
#   5. Verifies everything works
#
# Prerequisites:
#   - Node.js (via nvm)
#   - Cloudflare R2 bucket named "ejfox-media" (create at dash.cloudflare.com)
#   - R2 API token with read/write access
#   - Screenshots set to save to ~/screenshots (System Settings > Keyboard > Screenshots)
#
# Usage:
#   bash ~/.dotfiles/scripts/setup-foxmedia.sh

set -euo pipefail

FOXMEDIA_DIR="$HOME/.local/lib/foxmedia"
SCREENSHOTS_DIR="$HOME/screenshots"
ENV_FILE="$FOXMEDIA_DIR/.env"
WORKFLOW_DIR="$HOME/Library/Workflows/Applications/Folder Actions"
WORKFLOW_NAME="Screenshots to R2.workflow"

echo "=== foxmedia screenshot auto-upload setup ==="
echo ""

# --- Step 1: Check prerequisites ---
echo "[1/5] Checking prerequisites..."

if ! command -v node &>/dev/null; then
  echo "  ERROR: node not found. Install via nvm first."
  exit 1
fi
NODE_BIN=$(dirname "$(which node)")
echo "  node: $(node --version) at $NODE_BIN"

if [ ! -d "$SCREENSHOTS_DIR" ]; then
  echo "  Creating ~/screenshots..."
  mkdir -p "$SCREENSHOTS_DIR"
fi
echo "  screenshots dir: $SCREENSHOTS_DIR"

# --- Step 2: Install foxmedia ---
echo ""
echo "[2/5] Setting up foxmedia..."

if [ ! -d "$FOXMEDIA_DIR" ]; then
  echo "  Cloning foxmedia..."
  mkdir -p "$(dirname "$FOXMEDIA_DIR")"
  git clone https://github.com/ejfox/foxmedia.git "$FOXMEDIA_DIR" 2>/dev/null || {
    echo "  ERROR: Could not clone foxmedia. If it's a private repo, copy it manually to $FOXMEDIA_DIR"
    exit 1
  }
fi

echo "  Installing dependencies..."
cd "$FOXMEDIA_DIR" && npm install --silent 2>/dev/null

echo "  Linking CLI globally..."
npm link --silent 2>/dev/null
echo "  foxmedia CLI linked: $(which foxmedia 2>/dev/null || echo "$NODE_BIN/foxmedia")"

# --- Step 3: Environment file ---
echo ""
echo "[3/5] Checking .env..."

if [ ! -f "$ENV_FILE" ]; then
  echo "  No .env found. Creating template..."
  cat > "$ENV_FILE" << 'ENVEOF'
# Cloudflare R2 Configuration
# Get these from: Cloudflare Dashboard > R2 > Manage R2 API Tokens
R2_ACCOUNT_ID=your-account-id
R2_ACCESS_KEY_ID=your-access-key
R2_SECRET_ACCESS_KEY=your-secret-key
R2_BUCKET_NAME=ejfox-media
R2_PUBLIC_URL=https://pub-YOUR-HASH.r2.dev

# Postgres Database (optional - for metadata tracking)
# Set up an SSH tunnel first: ssh -L 15432:localhost:5432 your-vps
DATABASE_URL=postgresql://user:pass@localhost:15432/dbname
ENVEOF
  echo ""
  echo "  !! IMPORTANT: Edit $ENV_FILE with your R2 credentials !!"
  echo "  !! Get them from: Cloudflare Dashboard > R2 > Manage R2 API Tokens !!"
  echo ""
  read -p "  Press Enter after editing .env (or Ctrl-C to do it later)..."
else
  echo "  .env exists"
fi

# --- Step 4: Folder Action ---
echo ""
echo "[4/5] Setting up Folder Action..."

# Create the Automator workflow programmatically
mkdir -p "$WORKFLOW_DIR/$WORKFLOW_NAME/Contents"

# Get the current node binary path (handles different nvm versions)
NODE_PATH=$(which node)
FOXMEDIA_PATH=$(which foxmedia 2>/dev/null || echo "$NODE_BIN/foxmedia")

cat > "$WORKFLOW_DIR/$WORKFLOW_NAME/Contents/document.wflow" << WFEOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>AMApplicationBuild</key>
	<string>528</string>
	<key>AMApplicationVersion</key>
	<string>2.10</string>
	<key>AMDocumentVersion</key>
	<string>2</string>
	<key>actions</key>
	<array>
		<dict>
			<key>action</key>
			<dict>
				<key>AMAccepts</key>
				<dict>
					<key>Container</key>
					<string>List</string>
					<key>Optional</key>
					<true/>
					<key>Types</key>
					<array>
						<string>com.apple.cocoa.string</string>
					</array>
				</dict>
				<key>AMActionVersion</key>
				<string>2.0.3</string>
				<key>AMApplication</key>
				<array>
					<string>Automator</string>
				</array>
				<key>AMParameterProperties</key>
				<dict>
					<key>COMMAND_STRING</key>
					<dict/>
					<key>CheckedForUserDefaultShell</key>
					<dict/>
					<key>inputMethod</key>
					<dict/>
					<key>shell</key>
					<dict/>
					<key>source</key>
					<dict/>
				</dict>
				<key>AMProvides</key>
				<dict>
					<key>Container</key>
					<string>List</string>
					<key>Types</key>
					<array>
						<string>com.apple.cocoa.string</string>
					</array>
				</dict>
				<key>ActionBundlePath</key>
				<string>/System/Library/Automator/Run Shell Script.action</string>
				<key>ActionName</key>
				<string>Run Shell Script</string>
				<key>ActionParameters</key>
				<dict>
					<key>COMMAND_STRING</key>
					<string>$HOME/.local/lib/foxmedia/automator-scripts/upload-screenshots-obsidian.sh "\$@"</string>
					<key>CheckedForUserDefaultShell</key>
					<true/>
					<key>inputMethod</key>
					<integer>1</integer>
					<key>shell</key>
					<string>/bin/bash</string>
					<key>source</key>
					<string></string>
				</dict>
				<key>BundleIdentifier</key>
				<string>com.apple.RunShellScript</string>
				<key>CFBundleVersion</key>
				<string>2.0.3</string>
				<key>CanShowSelectedItemsWhenRun</key>
				<false/>
				<key>CanShowWhenRun</key>
				<true/>
				<key>Category</key>
				<array>
					<string>AMCategoryUtilities</string>
				</array>
				<key>Class Name</key>
				<string>RunShellScriptAction</string>
				<key>InputUUID</key>
				<string>1A107063-8F6B-41C8-966C-4899E2A0C97D</string>
				<key>Keywords</key>
				<array>
					<string>Shell</string>
					<string>Script</string>
					<string>Command</string>
					<string>Run</string>
					<string>Unix</string>
				</array>
				<key>OutputUUID</key>
				<string>7577E05E-2DBB-4147-8C5A-5B570D1E26DF</string>
				<key>UUID</key>
				<string>8683F708-B019-464B-81F0-998B613D9648</string>
				<key>UnlocalizedApplications</key>
				<array>
					<string>Automator</string>
				</array>
				<key>arguments</key>
				<dict>
					<key>0</key>
					<dict>
						<key>default value</key>
						<integer>0</integer>
						<key>name</key>
						<string>inputMethod</string>
						<key>required</key>
						<string>0</string>
						<key>type</key>
						<string>0</string>
						<key>uuid</key>
						<string>0</string>
					</dict>
					<key>1</key>
					<dict>
						<key>default value</key>
						<false/>
						<key>name</key>
						<string>CheckedForUserDefaultShell</string>
						<key>required</key>
						<string>0</string>
						<key>type</key>
						<string>0</string>
						<key>uuid</key>
						<string>1</string>
					</dict>
					<key>2</key>
					<dict>
						<key>default value</key>
						<string></string>
						<key>name</key>
						<string>source</string>
						<key>required</key>
						<string>0</string>
						<key>type</key>
						<string>0</string>
						<key>uuid</key>
						<string>2</string>
					</dict>
					<key>3</key>
					<dict>
						<key>default value</key>
						<string></string>
						<key>name</key>
						<string>COMMAND_STRING</string>
						<key>required</key>
						<string>0</string>
						<key>type</key>
						<string>0</string>
						<key>uuid</key>
						<string>3</string>
					</dict>
					<key>4</key>
					<dict>
						<key>default value</key>
						<string>/bin/sh</string>
						<key>name</key>
						<string>shell</string>
						<key>required</key>
						<string>0</string>
						<key>type</key>
						<string>0</string>
						<key>uuid</key>
						<string>4</string>
					</dict>
				</dict>
				<key>isViewVisible</key>
				<integer>1</integer>
				<key>location</key>
				<string>369.750000:252.000000</string>
				<key>nibPath</key>
				<string>/System/Library/Automator/Run Shell Script.action/Contents/Resources/Base.lproj/main.nib</string>
			</dict>
			<key>isViewVisible</key>
			<integer>1</integer>
		</dict>
	</array>
	<key>connectors</key>
	<dict/>
	<key>workflowMetaData</key>
	<dict>
		<key>folderActionFolderPath</key>
		<string>~/screenshots</string>
		<key>workflowTypeIdentifier</key>
		<string>com.apple.Automator.folderAction</string>
	</dict>
</dict>
</plist>
WFEOF

cat > "$WORKFLOW_DIR/$WORKFLOW_NAME/Contents/Info.plist" << 'IPEOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>NSServices</key>
	<array/>
</dict>
</plist>
IPEOF

echo "  Workflow installed at: $WORKFLOW_DIR/$WORKFLOW_NAME"

# Enable Folder Actions
defaults write com.apple.FolderActionsDispatcher folderActionsEnabled -bool true 2>/dev/null
echo "  Folder Actions enabled"

# --- Step 5: Verify ---
echo ""
echo "[5/5] Verifying setup..."

if command -v foxmedia &>/dev/null || [ -x "$FOXMEDIA_PATH" ]; then
  echo "  foxmedia CLI: OK"
else
  echo "  foxmedia CLI: MISSING (try: cd $FOXMEDIA_DIR && npm link)"
fi

if [ -f "$ENV_FILE" ] && grep -q "your-account-id" "$ENV_FILE"; then
  echo "  .env: NEEDS EDITING (still has placeholder values)"
elif [ -f "$ENV_FILE" ]; then
  echo "  .env: OK"
else
  echo "  .env: MISSING"
fi

if [ -f "$WORKFLOW_DIR/$WORKFLOW_NAME/Contents/document.wflow" ]; then
  echo "  Folder Action: OK"
else
  echo "  Folder Action: MISSING"
fi

echo ""
echo "=== Setup complete ==="
echo ""
echo "How it works:"
echo "  1. Take a screenshot (Cmd+Shift+4 etc)"
echo "  2. macOS saves it to ~/screenshots/"
echo "  3. Folder Action fires, uploads to R2 via foxmedia"
echo "  4. URL copied to clipboard + appended to Obsidian weekly note"
echo ""
echo "Debug: tail -f /tmp/foxmedia-screenshot-upload.log"
echo "Test:  foxmedia upload ~/screenshots/some-screenshot.png"
