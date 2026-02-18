"""Thin 1px line at the very bottom of the screen showing current mode color."""

from talon import Module, app, cron, registry, scope, settings, ui
from talon.canvas import Canvas
from talon.skia.canvas import Canvas as SkiaCanvas

canvas = None
current_mode = ""


def get_mode_color() -> str:
    if current_mode == "sleep":
        return "735865"
    elif current_mode == "dictation":
        return "6eedf7"
    elif current_mode == "mixed":
        return "6eedf7"
    elif current_mode == "command":
        return "e60067"
    else:
        return "666666"


def on_draw(c: SkiaCanvas):
    color = get_mode_color()
    c.paint.style = c.paint.Style.FILL
    c.paint.color = f"{color}cc"
    # Draw a 1px line across the full width at the bottom
    c.draw_rect(c.rect)


def update_indicator():
    global canvas
    if canvas:
        canvas.close()

    screen = ui.main_screen()
    rect = screen.rect
    line_height = 2
    canvas = Canvas(rect.x, rect.bot - line_height, rect.width, line_height)
    canvas.register("draw", on_draw)
    canvas.freeze()


def on_update_contexts():
    global current_mode
    modes = scope.get("mode")
    if "sleep" in modes:
        mode = "sleep"
    elif "dictation" in modes:
        if "command" in modes:
            mode = "mixed"
        else:
            mode = "dictation"
    elif "command" in modes:
        mode = "command"
    else:
        mode = "other"

    if current_mode != mode:
        current_mode = mode
        update_indicator()


def on_ready():
    registry.register("update_contexts", on_update_contexts)
    ui.register("screen_change", lambda _: update_indicator())


app.register("ready", on_ready)
