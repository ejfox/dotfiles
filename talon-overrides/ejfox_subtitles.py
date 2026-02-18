"""Right-aligned subtitles that sit below sketchybar."""

from talon import app, cron, settings, ui
from talon.canvas import Canvas
from talon.skia.canvas import Canvas as SkiaCanvas
from talon.skia.imagefilter import ImageFilter
from talon.types import Rect

canvases: list[Canvas] = []

# Config
FONT_SIZE = 14
COLOR = "aaaaaa"
COLOR_OUTLINE = "555555"
Y_OFFSET = 38  # pixels from top (below sketchybar)
RIGHT_MARGIN = 12  # pixels from right edge
TIMEOUT_PER_CHAR = 40
TIMEOUT_MIN = 500
TIMEOUT_MAX = 2000


def show_subtitle(text: str):
    clear_canvases()
    screen = ui.active_window().screen
    canvas = Canvas.from_screen(screen)
    canvas.register("draw", lambda c: on_draw(c, screen, text))
    canvas.freeze()
    timeout = min(TIMEOUT_MAX, max(TIMEOUT_MIN, len(text) * TIMEOUT_PER_CHAR))
    cron.after(f"{timeout}ms", canvas.close)
    canvases.append(canvas)


def on_draw(c: SkiaCanvas, screen: ui.Screen, text: str):
    c.paint.textsize = FONT_SIZE
    rect = c.paint.measure_text(text)[1]

    # Right-aligned, offset from top
    x = c.rect.right - rect.width - RIGHT_MARGIN
    y = c.rect.y + Y_OFFSET

    # Drop shadow for readability
    c.paint.imagefilter = ImageFilter.drop_shadow(1, 1, 1, 1, "000000")
    c.paint.style = c.paint.Style.FILL
    c.paint.color = COLOR
    c.draw_text(text, x, y)

    # Outline
    c.paint.imagefilter = None
    c.paint.style = c.paint.Style.STROKE
    c.paint.color = COLOR_OUTLINE
    c.draw_text(text, x, y)


def clear_canvases():
    for canvas in canvases:
        canvas.close()
    canvases.clear()


def on_ready():
    from talon import speech_system

    def on_phrase(d):
        text = d.get("text")
        if text:
            phrase = " ".join(text)
            if phrase.strip():
                show_subtitle(phrase)

    speech_system.register("phrase", on_phrase)


app.register("ready", on_ready)
