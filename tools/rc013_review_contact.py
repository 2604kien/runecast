"""Combine unmodified native Godot captures for a compact review; no new artwork."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

root = Path(__file__).resolve().parents[1]
art = root / 'output/art/rc-013'
font = ImageFont.truetype(str(root / 'assets/fonts/ui/NotoSerif-Variable.ttf'), 18)
sheet = Image.new('RGB', (720, 1352), '#0c1524')
draw = ImageDraw.Draw(sheet)
for index, (name, label) in enumerate([
    ('home-save-360x640.png', 'Home · saved run'),
    ('menu-button-revert/menu-locked-360x640.png', 'Menu · unavailable Store'),
    ('components-bottom-360x640.png', 'Live forecast / Cast / navigation'),
    ('map-360x640.png', 'Map · four node states'),
]):
    x, y = index % 2 * 360, index // 2 * 676
    draw.text((x + 12, y + 6), label, font=font, fill='#fff0c5')
    with Image.open(art / name) as img:
        assert img.size == (360, 640)
        sheet.paste(img, (x, y + 36))
sheet.save(art / 'screen-state-contact.png')
print('Saved review contact: four native Godot captures at original pixel size.')
