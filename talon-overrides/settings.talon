-
settings():
    user.tmux_prefix_key = "ctrl-a"

    # disable talon's built-in subtitle, use custom one instead
    speech._subtitles = false

    # disable circle indicator (replaced by bottom line in mode_line.py)
    user.mode_indicator_show = false

    # subtitles - disabled in favor of custom right-aligned version in ejfox_subtitles.py
    user.subtitles_show = false
