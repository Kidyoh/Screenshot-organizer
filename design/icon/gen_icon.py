"""Generates the SnapSort adaptive icon (Android vector XML) plus an SVG preview."""
import math, os, sys

out_res = sys.argv[1]
preview = sys.argv[2]

C1, C2 = "#7B5CFF", "#FF5E8E"   # gradient
ROW = ["#7B5CFF", "#FF5E8E", "#FFB23F"]
LINE = "#E4DEFF"

def rrect(x, y, w, h, r):
    return (f"M{x+r},{y} h{w-2*r} a{r},{r} 0 0 1 {r},{r} v{h-2*r} a{r},{r} 0 0 1 {-r},{r} "
            f"h{-(w-2*r)} a{r},{r} 0 0 1 {-r},{-r} v{-(h-2*r)} a{r},{r} 0 0 1 {r},{-r} z")

CARD = (40, 31, 28, 44, 5)
PIVOT = (54, 80)
ANGLE = 15

# safe-zone check: every rotated card corner within r=33 of centre
for a in (-ANGLE, 0, ANGLE):
    x, y, w, h, _ = CARD
    for cx, cy in ((x, y), (x + w, y), (x, y + h), (x + w, y + h)):
        t = math.radians(a)
        dx, dy = cx - PIVOT[0], cy - PIVOT[1]
        rx = PIVOT[0] + dx * math.cos(t) - dy * math.sin(t)
        ry = PIVOT[1] + dx * math.sin(t) + dy * math.cos(t)
        d = math.hypot(rx - 54, ry - 54)
        assert d <= 34.5, (a, cx, cy, d)

# (path, color, alpha, rotation)
fg = [
    (rrect(*CARD), "#FFFFFF", 0.45, -ANGLE),
    (rrect(*CARD), "#FFFFFF", 0.72, ANGLE),
    (rrect(*CARD), "#FFFFFF", 1.0, 0),
]
for i, col in enumerate(ROW):
    y = 39 + i * 10
    fg.append((rrect(44, y, 7, 7, 1.5), col, 1.0, 0))
    fg.append((rrect(54, y + 2, 10, 3, 1.5), LINE, 1.0, 0))
fg.append((rrect(50, 70, 8, 2, 1), LINE, 1.0, 0))

def vec_paths(items, mono=False):
    s = []
    for d, col, a, rot in items:
        if mono and col != "#FFFFFF":
            continue  # monochrome: just the card silhouettes
        p = f'<path android:fillColor="{"#FFFFFFFF" if mono else col}" android:fillAlpha="{a}" android:pathData="{d}"/>'
        if rot:
            p = f'<group android:rotation="{rot}" android:pivotX="{PIVOT[0]}" android:pivotY="{PIVOT[1]}">{p}</group>'
        s.append("    " + p)
    return "\n".join(s)

HDR = ('<vector xmlns:android="http://schemas.android.com/apk/res/android"{extra}\n'
       '    android:width="108dp" android:height="108dp" android:viewportWidth="108" android:viewportHeight="108">\n')

os.makedirs(f"{out_res}/drawable", exist_ok=True)
os.makedirs(f"{out_res}/mipmap-anydpi-v26", exist_ok=True)
with open(f"{out_res}/drawable/ic_launcher_foreground.xml", "w") as f:
    f.write(HDR.format(extra="") + vec_paths(fg) + "\n</vector>\n")
with open(f"{out_res}/drawable/ic_launcher_monochrome.xml", "w") as f:
    f.write(HDR.format(extra="") + vec_paths(fg, mono=True) + "\n</vector>\n")
with open(f"{out_res}/drawable/ic_launcher_background.xml", "w") as f:
    f.write(HDR.format(extra='\n    xmlns:aapt="http://schemas.android.com/aapt"') +
            '    <path android:pathData="M0,0h108v108h-108z">\n'
            '        <aapt:attr name="android:fillColor">\n'
            f'            <gradient android:type="linear" android:startX="0" android:startY="0" android:endX="108" android:endY="108" android:startColor="{C1}" android:endColor="{C2}"/>\n'
            '        </aapt:attr>\n    </path>\n</vector>\n')
for name in ("ic_launcher.xml", "ic_launcher_round.xml"):
    with open(f"{out_res}/mipmap-anydpi-v26/{name}", "w") as f:
        f.write('<?xml version="1.0" encoding="utf-8"?>\n'
                '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
                '    <background android:drawable="@drawable/ic_launcher_background"/>\n'
                '    <foreground android:drawable="@drawable/ic_launcher_foreground"/>\n'
                '    <monochrome android:drawable="@drawable/ic_launcher_monochrome"/>\n'
                '</adaptive-icon>\n')

# SVG preview, masked to a circle like a launcher would
svg = [f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="9 9 90 90" width="512" height="512">',
       f'<defs><linearGradient id="g" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="{C1}"/><stop offset="1" stop-color="{C2}"/></linearGradient>',
       '<clipPath id="c"><circle cx="54" cy="54" r="45"/></clipPath></defs><g clip-path="url(#c)">',
       '<rect width="108" height="108" fill="url(#g)"/>']
for d, col, a, rot in fg:
    t = f' transform="rotate({rot} {PIVOT[0]} {PIVOT[1]})"' if rot else ""
    svg.append(f'<path d="{d}" fill="{col}" fill-opacity="{a}"{t}/>')
svg.append("</g></svg>")
open(preview, "w").write("\n".join(svg))
print("ok")
