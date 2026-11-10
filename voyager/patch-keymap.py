#!/usr/bin/env python3
"""Patch an Oryx-generated Voyager keymap.c so host-set LEDs overlay the layer colors.

Stock Oryx firmware stops drawing layer colors the moment the host (Keymapp API /
kontroll) sets any LED. This patch keeps the layer colors and paints every
non-black host LED on top, so `tmux-kb-lights` can glow a number key without
blanking the pink/teal layer cues. Black (000000) from the host = transparent.

Usage: patch-keymap.py path/to/keymap.c
Fails loudly (exit 1) if Oryx changed the generated code it anchors on.
"""
import re
import sys

ANCHOR = re.compile(
    r"bool\s+rgb_matrix_indicators_user\s*\(\s*void\s*\)\s*\{\s*"
    r"if\s*\(\s*rawhid_state\.rgb_control\s*\)\s*\{\s*return\s+false\s*;\s*\}"
)

REPLACEMENT = "static bool ej_layer_indicators(void) {"

OVERLAY = """
// --- ej host-LED overlay (voyager/patch-keymap.py in ejfox/dotfiles) ---
// Layer colors first, then any non-black LED the host set through the Keymapp API.
bool rgb_matrix_indicators_user(void) {
  bool result = ej_layer_indicators();
  if (rawhid_state.rgb_control) {
    float f = (float)rgb_matrix_config.hsv.v / UINT8_MAX;
    for (uint8_t i = 0; i < RGB_MATRIX_LED_COUNT; i++) {
      RGB c = webhid_leds[i];
      if (c.r || c.g || c.b) {
        rgb_matrix_set_color(i, c.r * f, c.g * f, c.b * f);
      }
    }
  }
  return result;
}
"""


def main():
    if len(sys.argv) != 2:
        sys.exit("usage: patch-keymap.py path/to/keymap.c")
    path = sys.argv[1]
    with open(path, encoding="utf-8") as fh:
        src = fh.read()
    if "ej_layer_indicators" in src:
        sys.exit("already patched: " + path)
    found = ANCHOR.findall(src)
    if len(found) != 1:
        sys.exit(
            "patch anchor matched %d times (want 1). Oryx changed the generated "
            "rgb_matrix_indicators_user; update voyager/patch-keymap.py." % len(found)
        )
    patched = ANCHOR.sub(REPLACEMENT, src) + OVERLAY
    with open(path, "w", encoding="utf-8") as fh:
        fh.write(patched)
    print("patched " + path)


if __name__ == "__main__":
    main()
