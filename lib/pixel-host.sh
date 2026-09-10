# pixel-host.sh — single source for locating the pixel canvas.
# Source this; then: DEVICE=$(pixel_host)
# Resolution: env override > cached discovery (pixel find) > last-known default.
PIXEL_HOST_CACHE="$HOME/.config/pixel-canvas-host"
PIXEL_DEFAULT_HOST="10.0.0.103"  # duplicated in lib/pixelkit.py connect() — change BOTH
pixel_host() {
  echo "${PIXEL_CANVAS_HOST:-$(cat "$PIXEL_HOST_CACHE" 2>/dev/null || echo "$PIXEL_DEFAULT_HOST")}"
}
