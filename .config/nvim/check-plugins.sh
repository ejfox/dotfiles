#!/usr/bin/env bash
# Auto-validate nvim plugin configs
# Runs silently in background, only reports errors

NVIM_CONFIG="$HOME/.config/nvim"
ERRORS=()

# Check each plugin file for syntax errors
for file in "$NVIM_CONFIG"/lua/plugins/*.lua "$NVIM_CONFIG"/lua/custom/*.lua "$NVIM_CONFIG"/lua/config/*.lua; do
  [[ -f "$file" ]] || continue

  # Try to load the file
  if ! nvim --headless -u NONE -c "luafile $file" -c "q" 2>/dev/null; then
    filename=$(basename "$file")
    ERRORS+=("$filename")
  fi
done

# Only output if there are errors
if [[ ${#ERRORS[@]} -gt 0 ]]; then
  echo "❌ Nvim config errors:"
  for err in "${ERRORS[@]}"; do
    echo "  - $err"
  done
  exit 1
fi

exit 0
