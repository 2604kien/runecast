"""Compose actual-size glyph/rotation evidence from authored vector assets."""
from pathlib import Path
import json, importlib.util, xml.etree.ElementTree as ET
from PIL import Image, ImageDraw, ImageFont

HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[2]
OUT=ROOT/'output/art/rc-011'
FONT=HERE.parent/'typography/engine-fallback-preview-only.woff2'
RASTER=HERE/'inspection_rasters'
spec=importlib.util.spec_from_file_location('materials',HERE.parent/'button/build_materials.py')
materials=importlib.util.module_from_spec(spec)
spec.loader.exec_module(materials)
im=Image.new('RGB',(1000,880),'#101b2b')
d=ImageDraw.Draw(im)
def text(x,y,s,size=17,color='#eee0bf'):
    d.text((x,y),s,font=ImageFont.truetype(str(FONT),size),fill=color)
text(32,22,'SPARK / EXACT GEOMETRY',30)
text(32,66,'RC-011  ·  1 image pixel = 1 logical design pixel  ·  original editable SVG',16,'#adb9c9')
text(32,107,'COLOR / DARK BACKDROP',15,'#d6ad67')
for i,n in enumerate([24,32,48,128]):
    x=40+i*142
    text(x,137,f'{n} px',15)
    icon=Image.open(RASTER/f'spark-{n}.png').convert('RGBA')
    im.paste(icon,(x,170),icon)
d.rectangle((640,107,968,314),fill='#e5d7b6')
text(659,124,'SINGLE INK + NEGATIVE SPACE',14,'#142535')
for i,n in enumerate([24,32,48]):
    x=659+i*90
    icon=Image.open(RASTER/f'spark-monochrome-{n}.png').convert('RGBA')
    im.paste(icon,(x,176),icon)
    text(x,240,f'{n} px',15,'#142535')

text(32,339,'137 PX CELLS / CLOCKWISE ROTATION; LIVE LABELS REMAIN UPRIGHT',16,'#d6ad67')
ports=['W to E','N to S','E to W','S to N']
def cell(n,r,x,y):
    tile=materials.nine_slice(HERE.parent/'exports/spark_tile.png',(n,n),(16,16,16,16),scale=.5)
    im.paste(tile,(x,y),tile)
    port=Image.open(RASTER/f'ports-r{r}-{n}.png').convert('RGBA')
    im.paste(port,(x,y),port)
    sz=48 if n==137 else 32
    icon=Image.open(RASTER/f'spark-{sz}.png').convert('RGBA')
    im.paste(icon,(x+(n-sz)//2,y+(n-sz)//2),icon)
    text(x+10 if n==137 else x+8,y+7,'Spark' if n==137 else 'SPK',15 if n==137 else 12)
    text(x+n-24 if n==137 else x+n-17,y+7 if n==137 else y+n-23,'2',17 if n==137 else 14)
    text(x+10 if n==137 else x+8,y+n-29 if n==137 else y+n-25,'6',21 if n==137 else 18)
for r in range(4):
    x=40+r*188
    cell(137,r,x,382)
    text(x,531,f'r{r}  {ports[r]}',17)
text(32,579,'72 PX CELLS / NATIVE NARROW SCALE',16,'#d6ad67')
for r in range(4):
    x=40+r*114
    cell(72,r,x,620)
    text(x,705,f'r{r} {ports[r]}',13)
text(544,592,'Separate TEMP tag',17,'#d6ad67')
for i,n in enumerate([24,32,48]):
    icon=Image.open(RASTER/f'temporary-marker-{n}.png').convert('RGBA')
    im.paste(icon,(550+i*95,628),icon)
    text(550+i*95,694,f'{n} px',14)
text(32,762,'Ports: N(64,0)  E(128,64)  S(64,128)  W(0,64). No port is painted into the frame.',16)
text(32,792,'Glyph: 128 viewBox; art16–112; outer8 / inner6 units. Spark and Free Spark share it.',16)
text(32,822,'72px: SPK12 label, value18 left, cost14 right; full Spark name remains in the inspector.',16,'#adb9c9')
OUT.mkdir(parents=True,exist_ok=True)
im.save(OUT/'pilot-glyphs.png')

glyph_root=ET.parse(HERE/'spark.svg').getroot()
forbidden={'image','text','filter','foreignObject'}
tags=[el.tag.rsplit('}',1)[-1] for el in glyph_root.iter()]
bounds={}
for n in [24,32,48,128]:
    bounds[str(n)]=Image.open(RASTER/f'spark-{n}.png').getchannel('A').getbbox()
report={'svg_viewBox':glyph_root.attrib['viewBox'],'forbidden_elements_found':sorted(set(tags)&forbidden),
        'groups':[el.attrib.get('id') for el in glyph_root if el.tag.endswith('}g')],
        'raster_alpha_bounds':bounds,'essential_geometry_safe_bounds':[16,16,112,112],
        'inspection_sheet':'output/art/rc-011/pilot-glyphs.png',
        'text_source':'engine-fallback-preview-only.woff2 extracted from existing Godot fallback',
        'note':'Measured128px alpha bounds16..112 (right/bottom exclusive). Analytical path radius44 plus half-outline4 =48 gives essential extent16..112. Narrow cell label uses SPK12; full name remains in inspector.'}
(HERE/'geometry-checks.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf8')
print(json.dumps(report,indent=2))
