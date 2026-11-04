"""Deep sleep in video-playback apps.

Playing back recordings of yourself in QuickTime / Final Cut Pro lets the
audio hit the mic, and "talon wake" / "wake up" in the recording wakes Talon.
With the user.deep_sleep tag active, community disables the short wake phrases
(sleep_mode_not_dragon.talon + sleep_mode_wakeup.talon carry
`not tag: user.deep_sleep`) and only "wake up and listen" works.

Sleeping ("go to sleep") is unaffected.
"""
from talon import Context

ctx = Context()
ctx.matches = r"""
app.name: QuickTime Player
app.name: Final Cut Pro
"""
ctx.tags = ["user.deep_sleep"]
