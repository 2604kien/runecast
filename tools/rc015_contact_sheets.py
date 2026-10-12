"""Lay out actual RC-015 Godot captures without retouching their image content.

Overview uses proportional thumbnails only. Motion and lighting/scale sheets
paste original captures at native pixel size. Individual captures are authoritative.
"""
from pathlib import Path
import hashlib
import json
from PIL import Image, ImageDraw, ImageFont, ImageCms

ROOT = Path(__file__).resolve().parents[1]
ART = ROOT / 'output/art/rc-015'
FONT = ROOT / 'assets/fonts/ui/NotoSerif-Variable.ttf'
ICC = ImageCms.ImageCmsProfile(ImageCms.createProfile('sRGB')).tobytes()
BG = '#0e1729'
INK = '#ffedc4'
MUTED = '#b9c9df'
RECORDS = []

def font(size):
    return ImageFont.truetype(str(FONT), size)

def label(sheet, text, xy, size=20, fill=INK):
    d = ImageDraw.Draw(sheet)
    box = d.textbbox(xy, text, font=font(size))
    assert box[0] >= 0 and box[2] < sheet.width and box[3] < sheet.height, (text, box)
    d.text(xy, text, font=font(size), fill=fill)

def make_sheet(size, title, subtitle):
    out = Image.new('RGB', size, BG)
    label(out, title, (26, 12), 28)
    label(out, subtitle, (27, 51), 17, MUTED)
    return out

def paste_capture(sheet, filename, xy, target_width=None):
    path = ART / filename
    with Image.open(path) as original:
        capture = original.convert('RGB')
        original_size = capture.size
        if target_width is not None and target_width != capture.width:
            capture.thumbnail((target_width, round(capture.height*target_width/capture.width)), Image.Resampling.LANCZOS)
        assert xy[0] >= 0 and xy[1] >= 0
        assert xy[0] + capture.width <= sheet.width
        assert xy[1] + capture.height <= sheet.height
        sheet.paste(capture, xy)
    RECORDS.append({'file':filename,'sha256':hashlib.sha256(path.read_bytes()).hexdigest(),'original_size':original_size,'placed_size':capture.size,'placed_at':xy,'process':'native pixel paste' if original_size == capture.size else 'proportional LANCZOS thumbnail'})
    return capture.size

def save(sheet, filename):
    sheet.save(ART / filename, icc_profile=ICC)
    print(f'{filename}: {sheet.width}x{sheet.height}')

def main():
    overview = make_sheet((1200,1326), 'Rune Cast · RC-015 environment overview', 'Derived Godot contact sheet · proportional thumbnails · individual captures remain authoritative')
    for col,(preset,name) in enumerate([('base_cool','Base cool'),('warm_candle','Warm candle'),('dark','Dark')]):
        x=30+390*col
        label(overview, name, (x,94), 23)
        paste_capture(overview, f'crypt-{preset}-720.png', (x,133), target_width=360)
    label(overview,'Separate Home illustration + existing RC-013 wordmark and live controls',(30,350),23)
    for col,(height,aspect) in enumerate([(1280,'9:16'),(1600,'9:20'),(1720,'9:21.5')]):
        x=30+390*col
        label(overview,f'Home {aspect} · center-cover', (x,391),20)
        paste_capture(overview, f'home-{height}-composed.png',(x,432),target_width=360)
    save(overview,'overview.png')

    motion=make_sheet((1498,1420),'Crypt · retained Shadeling motion coverage','Derived Godot contact sheet · original 720 × 385 captures · shared crop, scale and fixed foot')
    specimens=[('idle-060','Idle · t = 0.60 s'),('attack-046','Attack · t = 0.46 s'),('hit-018','Retained hit pose · t = 0.18 s'),('defeat-068','Defeat collapse · t = 0.68 s'),('defeat-125','Defeat endpoint · t = 1.25 s')]
    for idx,(state,caption) in enumerate(specimens):
        x=20+(idx%2)*738;y=94+(idx//2)*440
        label(motion,caption,(x,y),22)
        paste_capture(motion,f'crypt-motion-720-{state}.png',(x,y+38))
    label(motion,'Shared actor envelope and floor contact',(758,974),22)
    paste_capture(motion,'crypt-motion-guides-720.png',(758,1012))
    save(motion,'crypt-motion-contact.png')

    scales=make_sheet((1626,1436),'Crypt · three presets at proportional 720 / 450 / 360 framing','Derived Godot contact sheet · every capture pasted at original pixel size · no independently resized actor')
    for row,(preset,name) in enumerate([('base_cool','Base cool'),('warm_candle','Warm candle'),('dark','Dark')]):
        y=98+440*row
        for width,x,h in [(720,24,385),(450,768,241),(360,1242,193)]:
            label(scales,f'{name} · {width} × {h}',(x,y),21)
            paste_capture(scales,f'crypt-{preset}-{width}.png',(x,y+37))
    label(scales,'All widths: crop Rect(0,60,841,450), uniform W/841 scale; character texture scale 0.75 × W/841.',(24,1400),18,MUTED)
    save(scales,'lighting-and-scale.png')
    (ART/'contact-sheet-record.json').write_text(json.dumps({'purpose':'Mechanical derived Godot contact sheets; no artwork/UI retouching','outputs':['overview.png','crypt-motion-contact.png','lighting-and-scale.png'],'sources':RECORDS},indent=2)+'\n',encoding='utf-8')

if __name__ == '__main__':
    main()
