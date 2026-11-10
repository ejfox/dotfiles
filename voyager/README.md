# Voyager: waiting tmux windows glow their number key

When a Claude pane in tmux window N finishes or asks you something, the **N** key on the
Voyager's base layer glows teal. Focus that pane and it goes dark. It is the same signal
as the teal ✳ in the tmux window list, moved to your fingers.

## The pieces

| Piece | Where | Job |
|---|---|---|
| Flag | `bin/claude-waiting` (Claude Code hooks) | sets/clears `@claude_unseen` on the tmux pane |
| Lights | `bin/tmux-kb-lights` | turns the flags into LED calls via `kontroll` and Keymapp |
| Firmware patch | `voyager/patch-keymap.py` | host LEDs overlay the layer colors instead of replacing them |
| Build | `.github/workflows/voyager-firmware.yml` | Oryx source + patch, built in GitHub Actions |
| Command | `bin/voyager-firmware` | trigger the build, download the `.bin` |

## Why a firmware patch

Stock Oryx firmware stops drawing layer colors the moment the host sets any LED
(`if (rawhid_state.rgb_control) return false;` in the generated `keymap.c`). The patch
draws the layer colors as usual, then paints every non-black host LED on top. Black from
the host means "transparent". Keys, layers, timing and macros are untouched.

## Changing the layout (Oryx stays the editor)

1. Edit at configure.zsa.io and hit **Compile** there (the build pulls the latest compiled revision).
2. `voyager-firmware build` (about 3 minutes). The `.bin` lands in `~/Downloads/voyager-firmware/run-<id>/`.
3. Flash it from Keymapp. Flash mode: tap STAGE, then the right inner thumb.

Flashing straight from Oryx still works; it just drops the patch until the next `voyager-firmware build`.
If Oryx ever changes the generated code, the build fails at the patch step with a clear message.

## Day to day

- `tmux-kb-lights test 3` lights the 3 key for 3 seconds (mapping check).
- `tmux-kb-lights clear` hands all LEDs back to the firmware.
- Off switch: `touch ~/.config/tmux-kb-lights.off`.
- Keymapp must be running (its API is how the Mac reaches the keyboard).
- Number keys 1-9 and 0 map to LEDs 1-5 and 26-30 (layout EJ 0.0.9). If the number row moves, edit `led()` in `bin/tmux-kb-lights`.

## Rollback

Flash any stock build from Oryx/Keymapp, and `touch ~/.config/tmux-kb-lights.off`.
