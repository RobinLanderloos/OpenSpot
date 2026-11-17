"""Draws OpenSpot's project logo (five party slots, four taken and one open
and glowing) to media/logo.png. Original artwork, no game assets.

    python tools/make_logo.py
"""
import math
import os

from PIL import Image, ImageDraw, ImageFilter

S = 4  # supersampling
W = 400 * S
img = Image.new("RGB", (W, W), (22, 28, 40))

def p(x, y):
    return (x * S, y * S)

# Soft backdrop glow.
glow = Image.new("L", (W, W), 0)
ImageDraw.Draw(glow).ellipse((W * 0.08, W * 0.1, W * 0.92, W * 0.94), fill=255)
glow = glow.filter(ImageFilter.GaussianBlur(70 * S))
img.paste(Image.new("RGB", (W, W), (44, 58, 84)), (0, 0), glow)

d = ImageDraw.Draw(img)

def person(cx, cy, scale, color):
    # Head and shoulders silhouette.
    r = 22 * scale
    d.ellipse((p(cx - r, cy - 58 * scale - r) + p(cx + r, cy - 58 * scale + r)), fill=color)
    d.pieslice((p(cx - 44 * scale, cy - 26 * scale) + p(cx + 44 * scale, cy + 62 * scale)), 180, 360, fill=color)

# Five slots on an arc: four filled, the middle one open.
slots = [(80, 250), (140, 222), (200, 210), (260, 222), (320, 250)]
colors = [(70, 110, 170), (70, 150, 90), None, (170, 70, 60), (170, 70, 60)]
for (cx, cy), color in zip(slots, colors):
    if color:
        person(cx, cy, 0.62, color)

# The open slot: a glowing ring with a dashed outline of a person.
cx, cy = slots[2]
halo = Image.new("L", (W, W), 0)
ImageDraw.Draw(halo).ellipse((p(cx - 70, cy - 120) + p(cx + 70, cy + 30)), fill=255)
halo = halo.filter(ImageFilter.GaussianBlur(26 * S))
img.paste(Image.new("RGB", (W, W), (255, 214, 110)), (0, 0), halo.point(lambda v: int(v * 0.55)))
d = ImageDraw.Draw(img)
for i in range(36):
    if i % 2:
        continue
    a0, a1 = i * 10, i * 10 + 7
    d.arc((p(cx - 22, cy - 80) + p(cx + 22, cy - 36)), a0, a1, fill=(255, 236, 170), width=4 * S)
    d.arc((p(cx - 44, cy - 26) + p(cx + 44, cy + 62)), 180 + a0 / 2, 180 + a1 / 2, fill=(255, 236, 170), width=4 * S)

# Plus sign above the open slot.
d.rounded_rectangle((p(cx - 6, cy - 150) + p(cx + 6, cy - 102)), radius=3 * S, fill=(255, 236, 170))
d.rounded_rectangle((p(cx - 24, cy - 132) + p(cx + 24, cy - 120)), radius=3 * S, fill=(255, 236, 170))

# Ground line.
d.rounded_rectangle((p(56, 300) + p(344, 308)), radius=4 * S, fill=(60, 74, 100))

out = os.path.join(os.path.dirname(__file__), "..", "media", "logo.png")
img.resize((400, 400), Image.LANCZOS).save(out)
print(os.path.normpath(out))
