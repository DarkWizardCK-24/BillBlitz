"""Generates this app's logo and launcher-icon artwork.

Run from the project root (needs `pip install pillow numpy`):

    python tool/generate_logo.py

Writes into assets/images/:
    logo.png                 512 x 512  rounded-square logo (README + in-app)
    launcher_icon.png        1024 x 1024  full-bleed icon (iOS / legacy Android)
    launcher_foreground.png  1024 x 1024  transparent glyph (Android adaptive icon)
    launcher_background.png  1024 x 1024  background (Android adaptive icon)

Then regenerate the platform icons with:

    dart run flutter_launcher_icons

Artwork is drawn at 2x and scaled down, so edges are smooth. Coordinates in
the drawing code use a 1024 x 1024 design space.
"""
import math
import os

import numpy as np
from PIL import Image, ImageChops, ImageDraw, ImageFilter

DESIGN = 1024          # design-space size
K = 2                  # supersampling factor
S = DESIGN * K         # working canvas size
OUT_DIR = os.path.join("assets", "images")


def P(points):
    """Design-space points -> working-canvas points."""
    return [(x * K, y * K) for x, y in points]


def lin_gradient(c1, c2, angle=45, size=S):
    """Linear gradient from c1 to c2. angle 45 = top-left to bottom-right."""
    a = math.radians(angle)
    ys, xs = np.mgrid[0:size, 0:size]
    dx, dy = math.cos(a), math.sin(a)
    half = size / 2
    t = ((xs - half) * dx + (ys - half) * dy) / (abs(half * dx) + abs(half * dy))
    t = np.clip(t * 0.5 + 0.5, 0, 1)[..., None]
    c1 = np.array(c1[:3], dtype=float)
    c2 = np.array(c2[:3], dtype=float)
    rgb = c1 * (1 - t) + c2 * t
    out = np.dstack([rgb, np.full((size, size, 1), 255.0)])
    return Image.fromarray(out.astype("uint8"), "RGBA")


def radial_glow(center, radius, color, strength=0.35):
    """Soft circular highlight (RGBA layer)."""
    ys, xs = np.mgrid[0:S, 0:S]
    cx, cy = center[0] * K, center[1] * K
    d = np.sqrt((xs - cx) ** 2 + (ys - cy) ** 2) / (radius * K)
    a = np.clip(1 - d, 0, 1) ** 2 * strength * 255
    out = np.zeros((S, S, 4), dtype="uint8")
    out[..., 0], out[..., 1], out[..., 2] = color[:3]
    out[..., 3] = a.astype("uint8")
    return Image.fromarray(out, "RGBA")


def blank():
    return Image.new("RGBA", (S, S), (0, 0, 0, 0))


def mask_from(draw_fn):
    """Build an 'L' mask by drawing white shapes with draw_fn(ImageDraw)."""
    m = Image.new("L", (S, S), 0)
    draw_fn(ImageDraw.Draw(m))
    return m


def paint(canvas, mask, fill, opacity=1.0):
    """Composite `fill` (RGBA tuple or image) onto canvas through `mask`.

    The mask only drives the alpha channel, so colours are never darkened by
    partial transparency.
    """
    if isinstance(fill, tuple):
        src = Image.new("RGBA", (S, S), fill if len(fill) == 4 else fill + (255,))
    else:
        src = fill.copy()
    if opacity < 1.0:
        mask = mask.point(lambda v: int(v * opacity))
    src.putalpha(ImageChops.multiply(src.getchannel("A"), mask))
    canvas.alpha_composite(src)


def drop_shadow(canvas, mask, offset=(0, 18), blur=26, opacity=0.35, color=(0, 0, 0)):
    shadow = mask.filter(ImageFilter.GaussianBlur(blur * K))
    shadow = ImageChops.offset(shadow, offset[0] * K, offset[1] * K)
    paint(canvas, shadow, color, opacity)


def rounded_rect(draw, box, radius, fill=255):
    x0, y0, x1, y1 = box
    draw.rounded_rectangle([x0 * K, y0 * K, x1 * K, y1 * K], radius * K, fill=fill)


def ellipse(draw, cx, cy, rx, ry=None, fill=255):
    ry = rx if ry is None else ry
    draw.ellipse([(cx - rx) * K, (cy - ry) * K, (cx + rx) * K, (cy + ry) * K], fill=fill)


def polygon(draw, pts, fill=255):
    draw.polygon(P(pts), fill=fill)


def thick_line(draw, pts, width, fill=255):
    """Smooth stroke with round caps and joins (dots stamped along the path)."""
    pts = P(pts)
    r = width * K / 2
    step = max(r / 4, 1.0)
    for (x0, y0), (x1, y1) in zip(pts, pts[1:]):
        n = max(int(math.hypot(x1 - x0, y1 - y0) / step), 1)
        for i in range(n + 1):
            x = x0 + (x1 - x0) * i / n
            y = y0 + (y1 - y0) * i / n
            draw.ellipse([x - r, y - r, x + r, y + r], fill=fill)


def bezier(p0, p1, p2, n=48):
    out = []
    for i in range(n + 1):
        t = i / n
        x = (1 - t) ** 2 * p0[0] + 2 * (1 - t) * t * p1[0] + t**2 * p2[0]
        y = (1 - t) ** 2 * p0[1] + 2 * (1 - t) * t * p1[1] + t**2 * p2[1]
        out.append((x, y))
    return out


def scale_points(pts, k, cx=512, cy=512):
    return [(cx + (x - cx) * k, cy + (y - cy) * k) for x, y in pts]


def rotate_mask(mask, degrees, center=(512, 512)):
    """Rotate clockwise by `degrees` about a design-space point."""
    return mask.rotate(-degrees, center=(center[0] * K, center[1] * K), resample=Image.BICUBIC)


def hex_color(value):
    value = value.lstrip("#")
    return tuple(int(value[i : i + 2], 16) for i in (0, 2, 4))


def vertical_fill(c_top, c_bottom, y_top, y_bottom):
    """A fill image fading from c_top to c_bottom between two design y values."""
    ys = np.arange(S)[:, None]
    t = np.clip((ys - y_top * K) / ((y_bottom - y_top) * K), 0, 1)
    t = np.repeat(t, S, axis=1)[..., None]
    rgb = np.array(c_top[:3], dtype=float) * (1 - t) + np.array(c_bottom[:3], dtype=float) * t
    out = np.dstack([rgb, np.full((S, S, 1), 255.0)])
    return Image.fromarray(out.astype("uint8"), "RGBA")


def scale_canvas(img, k):
    """Zoom artwork about the centre (k > 1 enlarges, k < 1 shrinks)."""
    if k == 1:
        return img
    c = S / 2
    inv = 1 / k
    return img.transform(
        img.size, Image.AFFINE, (inv, 0, c * (1 - inv), 0, inv, c * (1 - inv)), resample=Image.BICUBIC
    )


def to_size(img, px):
    return img.resize((px, px), Image.LANCZOS)


def rounded_corners(img, radius_fraction=0.225):
    """Apply rounded-square transparency (like a store icon)."""
    px = img.size[0]
    mask = Image.new("L", (px * 4, px * 4), 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        [0, 0, px * 4 - 1, px * 4 - 1], radius=int(px * 4 * radius_fraction), fill=255
    )
    mask = mask.resize((px, px), Image.LANCZOS)
    out = img.copy()
    out.putalpha(ImageChops.multiply(out.getchannel("A"), mask))
    return out


def build_all():
    os.makedirs(OUT_DIR, exist_ok=True)
    background = draw_background()          # noqa: F821 (defined by the design)
    glyph = draw_glyph()                    # noqa: F821

    # Glyph is drawn inside the adaptive-icon safe zone; the full-bleed icon
    # can show it a little larger.
    full = background.copy()
    full.alpha_composite(scale_canvas(glyph, ICON_SCALE))  # noqa: F821

    to_size(full, 1024).convert("RGB").save(os.path.join(OUT_DIR, "launcher_icon.png"))
    to_size(background, 1024).convert("RGB").save(os.path.join(OUT_DIR, "launcher_background.png"))
    to_size(glyph, 1024).save(os.path.join(OUT_DIR, "launcher_foreground.png"))
    rounded_corners(to_size(full, 512)).save(os.path.join(OUT_DIR, "logo.png"))
    print("Wrote logo.png (512), launcher_icon.png, launcher_foreground.png, launcher_background.png")

# ---------------------------------------------------------------------------
# BillBlitz: a torn-edge receipt struck by a lightning bolt.
# Royal purple with an amber bolt.
# ---------------------------------------------------------------------------
ICON_SCALE = 1.15
ADAPTIVE_BACKGROUND = "#4A32BD"
BG_TOP = (48, 28, 140)
BG_BOTTOM = (132, 98, 255)


def draw_background():
    bg = lin_gradient(BG_TOP, BG_BOTTOM, angle=50)
    bg.alpha_composite(radial_glow((700, 260), 560, (255, 255, 255), 0.22))
    return bg


def draw_glyph():
    g = blank()
    left, right, top, bottom = 352, 640, 235, 745

    def receipt(draw):
        rounded_rect(draw, (left, top, right, top + 160), 34)
        # Body with a zig-zag torn bottom edge.
        teeth = 8
        w = (right - left) / teeth
        pts = [(left, top + 100), (right, top + 100), (right, bottom - 36)]
        for i in range(teeth):
            x_end = right - (i + 1) * w
            x_mid = right - (i + 0.5) * w
            pts += [(x_mid, bottom), (x_end, bottom - 36)]
        polygon(draw, pts)

    paper = mask_from(receipt)
    drop_shadow(g, paper, offset=(0, 24), blur=30, opacity=0.38, color=(20, 8, 70))
    paint(g, paper, vertical_fill((255, 255, 255), (232, 226, 255), top, bottom))

    # Store name bar and item lines.
    ink = (150, 134, 214)
    for box, color in [
        ((left + 44, 290, left + 44 + 130, 318), (82, 56, 200)),
        ((left + 44, 372, right - 44, 392), ink),
        ((left + 44, 424, right - 90, 444), ink),
        ((left + 44, 476, right - 60, 496), ink),
    ]:
        m = mask_from(lambda dr, b=box: rounded_rect(dr, b, 10))
        paint(g, m, color)

    # Dashed separator.
    for x in range(left + 44, right - 40, 34):
        m = mask_from(lambda dr, x=x: rounded_rect(dr, (x, 540, x + 18, 548), 4))
        paint(g, m, (196, 186, 236))

    # Total row.
    for box, color in [
        ((left + 44, 590, left + 44 + 96, 612), (82, 56, 200)),
        ((right - 44 - 110, 584, right - 44, 618), (82, 56, 200)),
    ]:
        m = mask_from(lambda dr, b=box: rounded_rect(dr, b, 12))
        paint(g, m, color)

    # Lightning bolt, outlined in the background purple so it pops off the paper.
    bolt = [(692, 412), (532, 640), (618, 640), (548, 846), (778, 572), (684, 572), (748, 412)]
    bolt = scale_points(bolt, 0.9, 640, 640)
    outline = mask_from(lambda dr: dr.polygon(P(bolt), fill=255, outline=255, width=int(30 * K)))
    paint(g, outline, (70, 44, 180))
    bolt_mask = mask_from(lambda dr: polygon(dr, bolt))
    paint(g, bolt_mask, vertical_fill((255, 226, 92), (255, 150, 28), 430, 840))
    # Shine on the bolt.
    shine = mask_from(lambda dr: polygon(dr, scale_points([(700, 430), (620, 540), (650, 540), (730, 430)], 0.9, 640, 640)))
    paint(g, ImageChops.multiply(shine, bolt_mask), (255, 255, 255), 0.45)
    return g


if __name__ == "__main__":
    build_all()
