"""The cover for "Five terms under the hood of an AI agent", in the house style: a terminal window and a banner."""
import os
from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FONTS = "/usr/share/fonts/truetype/noto/"
reg = lambda n: ImageFont.truetype(FONTS + "NotoSansMono-Regular.ttf", n)
bold = lambda n: ImageFont.truetype(FONTS + "NotoSansMono-Bold.ttf", n)

im = Image.new("RGB", (1920, 1080), "#1e1f24")
d = ImageDraw.Draw(im)
d.rounded_rectangle((160, 90, 1760, 840), 28, fill="#262a35", outline="#353b4a", width=2)
d.rounded_rectangle((160, 90, 1760, 170), 28, fill="#2d3240")
d.rectangle((160, 140, 1760, 170), fill="#2d3240")
for x, c in ((218, "#ff5f57"), (262, "#febc2e"), (306, "#28c840")):
    d.ellipse((x - 15, 115, x + 15, 145), fill=c)
d.text((360, 107), "~/project  -  agent", font=bold(42), fill="#d6dae3")

BLUE, WHITE, GREY, GREEN, AMBER = "#7aa2f7", "#e6e8ee", "#6b7384", "#6fd17a", "#e5c07b"


def line(x, y, parts, size=44):
    for text, color in parts:
        d.text((x, y), text, font=reg(size), fill=color)
        x += d.textlength(text, font=reg(size))


rows = [
    ("1", "AGENTS.md", "how this project works"),
    ("2", "skills/", "how to do a kind of task"),
    ("3", "MCP", "agent -> tools and data"),
    ("4", "A2A", "agent -> agent"),
    ("5", "subagents", "work that does not fit"),
]
y = 215
for n, term, what in rows:
    line(230, y, [(f"{n}  ", GREY), (f"{term:<12}", BLUE), ("# " + what, GREEN)])
    y += 96
line(230, y + 20, [("-- all five decide what enters the context window", AMBER)], 40)

d.rounded_rectangle((260, 890, 1660, 1000), 22, fill="#1f2b45", outline="#3d5a8a", width=2)
msg = "Five terms under the hood of an AI agent"
w = d.textlength(msg, font=bold(54))
d.text(((1920 - w) / 2, 910), msg, font=bold(54), fill="#cfe0ff")
im.save(os.path.join(ROOT, "assets", "img", "five-terms-ai-agent.webp"), quality=90)
im.save(os.path.join(ROOT, "_tools", "five-terms-linkedin.png"))
print("wrote assets/img/five-terms-ai-agent.webp")
