"""The cover for "Five terms under the hood of an AI agent": the post's own diagram on a white card.

Reads the first <svg> from the post, renders it with Lato, and centres it on 1920x1080 narrow enough
that the homepage thumbnail (background-size: cover, about 1.5:1) does not crop it.
"""
import io
import os
import re

import cairosvg
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
POST = os.path.join(ROOT, "_posts", "2026-11-09-five-terms-under-the-hood-of-an-ai-agent.markdown")

svg = re.search(r"<svg .*?</svg>", open(POST, encoding="utf-8").read(), re.S).group(0)
svg = svg.replace("<svg ", '<svg xmlns="http://www.w3.org/2000/svg" font-family="Lato" ', 1)

W, H, DW = 1920, 1080, 1620
png = cairosvg.svg2png(bytestring=svg.encode(), output_width=DW, background_color="white")
diagram = Image.open(io.BytesIO(png)).convert("RGB")

im = Image.new("RGB", (W, H), "white")
im.paste(diagram, ((W - diagram.width) // 2, (H - diagram.height) // 2))
im.save(os.path.join(ROOT, "assets", "img", "five-terms-ai-agent.webp"), quality=90)
print("wrote assets/img/five-terms-ai-agent.webp", diagram.size)
