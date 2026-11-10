#!/usr/bin/env python3
"""Génère les visuels du README à partir de la VRAIE sortie de skill/statusline.sh.

Usage : python3 docs/render.py   (requiert google-chrome et ImageMagick)
"""
import html, json, os, re, shutil, subprocess, tempfile, time

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SCRIPT = os.path.join(ROOT, "skill", "statusline.sh")
OUT = os.path.join(ROOT, "docs")
CHROME = shutil.which("google-chrome") or shutil.which("chromium")

PALETTE = {"32": "#3fb950", "33": "#e3b341", "38;5;208": "#ff8a1f", "31": "#ff5555"}


def statusline(data):
    return subprocess.run([SCRIPT], input=json.dumps(data), capture_output=True,
                          text=True, check=True).stdout.rstrip("\n")


def ansi_to_html(s):
    out, color, bold, dim = [], None, False, False
    for part in re.split(r"(\x1b\[[0-9;]*m)", s):
        m = re.fullmatch(r"\x1b\[([0-9;]*)m", part)
        if m:
            code = m.group(1)
            if code in ("0", ""):
                color, bold, dim = None, False, False
            elif code == "2":
                dim = True
            elif code == "1;31":
                color, bold = PALETTE["31"], True
            elif code in PALETTE:
                color = PALETTE[code]
            continue
        if not part:
            continue
        style = []
        if color: style.append(f"color:{color}")
        if bold: style.append("font-weight:700")
        if dim: style.append("color:#3a4250")
        text = html.escape(part)
        out.append(f'<span style="{";".join(style)}">{text}</span>' if style else text)
    return "".join(out)


CSS = """
body{margin:0;padding:48px;background:transparent;font-family:'DejaVu Sans Mono',monospace;
     font-size:15px;line-height:1.55;color:#c9d1d9;display:inline-block}
.win{background:#0d1117;border-radius:12px;border:1px solid #30363d;
     box-shadow:0 24px 60px rgba(0,0,0,.45),0 0 0 1px rgba(255,255,255,.03);overflow:hidden}
.bar{height:38px;background:#161b22;border-bottom:1px solid #30363d;display:flex;align-items:center;padding:0 14px;gap:8px}
.dot{width:12px;height:12px;border-radius:50%}
.title{flex:1;text-align:center;color:#7d8590;font-size:13px;margin-right:52px}
.body{padding:18px 22px 20px;white-space:pre}
.muted{color:#7d8590}.accent{color:#d9825b}.white{color:#e6edf3}
.box{border:1px solid #4a5260;border-radius:8px;padding:6px 12px;margin:14px 0 8px;color:#e6edf3}
.mode{color:#c792ea}
.lbl{display:inline-block;width:64px;color:#7d8590}
"""


def page(body, title="claude — ~/mon-projet"):
    return f"""<!doctype html><meta charset=utf-8><style>{CSS}</style>
<div class=win><div class=bar><span class=dot style="background:#ff5f57"></span>
<span class=dot style="background:#febc2e"></span><span class=dot style="background:#28c840"></span>
<span class=title>{html.escape(title)}</span></div><div class=body>{body}</div></div>"""


def shoot(markup, dest):
    with tempfile.TemporaryDirectory() as tmp:
        src, png = os.path.join(tmp, "p.html"), os.path.join(tmp, "p.png")
        open(src, "w").write(markup)
        subprocess.run([CHROME, "--headless=new", "--disable-gpu", "--hide-scrollbars",
                        "--force-device-scale-factor=2", "--default-background-color=00000000",
                        "--window-size=2400,900", f"--screenshot={png}", f"file://{src}"],
                       check=True, capture_output=True)
        subprocess.run(["magick", png, "-trim", "+repage", "-bordercolor", "none",
                        "-border", "40", dest], check=True)


reset = int(time.time()) + 4 * 3600 + 12 * 60
real = {"context_window": {"context_window_size": 1000000, "used_percentage": 38,
                           "current_usage": {"input_tokens": 12, "cache_creation_input_tokens": 4100,
                                             "cache_read_input_tokens": 377900}},
        "rate_limits": {"five_hour": {"used_percentage": 82, "resets_at": reset},
                        "seven_day": {"used_percentage": 41, "resets_at": reset + 3 * 86400}}}

# 1. Vue d'ensemble : la barre dans une session Claude Code
hero = "\n".join([
    '<span class=accent>&gt;</span> <span class=white>ajoute des tests au module de paiement</span>',
    "",
    '<span class=accent>●</span> J\'ai ajouté 14 tests dans <span class=white>tests/test_payment.py</span>, tous au vert.',
    '  <span class=muted>⎿  pytest : 14 passed in 0.82s</span>',
    '<div class=box><span class=accent>&gt;</span> <span style="background:#c9d1d9"> </span></div>'
    + "  " + ansi_to_html(statusline(real)),
    '  <span class=mode>⏵⏵ auto mode on</span> <span class=muted>(shift+tab to cycle)</span>',
])
shoot(page(hero), os.path.join(OUT, "hero.png"))

# 2. Les paliers de couleur
rows = []
for pct, txt in [(30, "tranquille"), (65, "à surveiller"), (85, "pense à /compact"), (97, "ça va compacter")]:
    line = statusline({"context_window": {"context_window_size": 200000, "used_percentage": pct,
                                          "current_usage": {"input_tokens": pct * 2000}}})
    pad = " " * (48 - len(re.sub(r"\x1b\[[0-9;]*m", "", line)))
    rows.append(f"{ansi_to_html(line)}{pad}<span class=muted>← {txt}</span>")
shoot(page("\n".join(rows), "paliers de couleur"), os.path.join(OUT, "paliers.png"))

# 3. Animation : la fenêtre de contexte qui se remplit
with tempfile.TemporaryDirectory() as tmp:
    frames = []
    for i, pct in enumerate(list(range(0, 101, 5)) + [100] * 6):
        line = statusline({"context_window": {"context_window_size": 200000, "used_percentage": pct,
                                              "current_usage": {"input_tokens": pct * 2000}}})
        f = os.path.join(tmp, f"{i:03}.png")
        shoot(page("  " + ansi_to_html(line) + "\n  <span class=mode>⏵⏵ auto mode on</span>",
                   "claude — token-bar"), f)
        frames.append(f)
    # cadres de taille identique, posés sur un dégradé opaque (le GIF gère mal la transparence)
    sizes = [tuple(map(int, subprocess.run(["magick", "identify", "-format", "%w %h", f],
                                           capture_output=True, text=True).stdout.split())) for f in frames]
    w, h = max(x for x, _ in sizes), max(y for _, y in sizes)
    bg = os.path.join(tmp, "bg.png")
    subprocess.run(["magick", "-size", f"{h}x{w}", "gradient:#3b2a6b-#0f4c75", "-rotate", "90", bg], check=True)
    flat = []
    for f in frames:
        g = f[:-4] + "-bg.png"
        subprocess.run(["magick", bg, f, "-gravity", "west", "-geometry", "+0+0", "-composite", g], check=True)
        flat.append(g)
    subprocess.run(["magick", "-delay", "18", "-loop", "0", *flat, "-resize", "50%",
                    "-layers", "Optimize", os.path.join(OUT, "demo.gif")], check=True)
print("ok :", ", ".join(sorted(os.listdir(OUT))))
