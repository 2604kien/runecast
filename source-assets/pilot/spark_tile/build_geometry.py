"""RC-011 code-native SVG artwork and preview-only port geometry. No runtime edits."""
from pathlib import Path
import json, math, shutil

HERE = Path(__file__).resolve().parent
EXPORT = HERE.parent / 'exports'
OVERLAYS = HERE / 'overlays'
PREVIEW = HERE / 'preview_geometry'
for folder in (HERE, EXPORT, OVERLAYS, PREVIEW, EXPORT / 'spark_tile_overlays'):
    folder.mkdir(parents=True, exist_ok=True)

def svg(body, title, metadata=None):
    meta = json.dumps(metadata or {'asset_id': 'pilot_spark_tile', 'revision': 'r1', 'role': title})
    return f'''<svg xmlns="http://www.w3.org/2000/svg" xmlns:inkscape="http://www.inkscape.org/namespaces/inkscape" width="128" height="128" viewBox="0 0 128 128">
  <title>{title}</title>
  <metadata>{meta}</metadata>
{body}
</svg>\n'''

points=[]
for i in range(24):
    angle = math.radians(-90+i*15)
    radius = 44 if i%2==0 else 27
    points.append(f'{64+radius*math.cos(angle):.3f},{64+radius*math.sin(angle):.3f}')
path='M '+' L '.join(points)+' Z'
contract = {
    'asset_id':'pilot_spark_tile','revision':'r1','viewBox':[0,0,128,128],
    'glyph_center':[64,64],'essential_safe_bounds':[16,16,112,112],
    'outline_units':8,'internal_stroke_units':6,
    'ports':{'N':[64,0],'E':[128,64],'S':[64,128],'W':[0,64]},
    'rotation_zero':{'input':['W'],'output':['E']},
    'rotation_clockwise_degrees':[0,90,180,270],
    'art_contains_ports':False,'art_contains_text':False,
    'live_text_rotation':'upright; never rotate with port geometry',
    'source':'original code-native geometry authored for RC-011; no image-generation provenance',
}
glyph=f'''  <g id="fill"><path d="{path}" fill="#efb24d"/></g>
  <g id="outline"><path d="{path}" fill="none" stroke="#141726" stroke-width="8" stroke-linejoin="round"/></g>
  <g id="detail"><circle cx="64" cy="64" r="19" fill="#ffe3a0" stroke="#141726" stroke-width="6"/><path d="M 49 64 A 15 15 0 0 1 79 64 Z" fill="#fff0bd"/></g>'''
(HERE/'spark.svg').write_text(svg(glyph,'Spark — shared permanent and temporary glyph',contract),encoding='utf8')
mono=f'''  <g id="fill"><path d="{path}" fill="#142535"/></g>
  <g id="outline"><path d="{path}" fill="none" stroke="#142535" stroke-width="8" stroke-linejoin="round"/></g>
  <g id="detail"><circle cx="64" cy="64" r="18" fill="#eee0bf"/><circle cx="64" cy="64" r="11" fill="#142535"/></g>'''
(HERE/'spark-monochrome.svg').write_text(svg(mono,'Spark — single ink with negative-space center',contract),encoding='utf8')
shutil.copy2(HERE/'spark.svg',EXPORT/'spark.svg')
shutil.copy2(HERE/'spark-monochrome.svg',EXPORT/'spark-monochrome.svg')

corners='M 4 36 V 12 L 12 4 H 36 M 92 4 H 116 L 124 12 V 36 M 124 92 V 116 L 116 124 H 92 M 36 124 H 12 L 4 116 V 92'
inner='M 10 35 V 16 L 16 10 H 35 M 93 10 H 112 L 118 16 V 35 M 118 93 V 112 L 112 118 H 93 M 35 118 H 16 L 10 112 V 93'
overlays={
    'focused': f'<g id="focus-brackets" fill="none" stroke="#f5efdb" stroke-width="3" stroke-linejoin="bevel"><path d="{corners}"/></g>',
    'selected': f'<g id="selection-inset" fill="none" stroke="#61dccf" stroke-width="3"><path d="{inner}"/></g><g id="persistent-notch"><path d="M 9 9 H 28 L 9 28 Z" fill="#61dccf" stroke="#141726" stroke-width="2"/></g>',
    'invalid': f'<g id="broken-warning-border" fill="none" stroke="#edaa82" stroke-width="3" stroke-dasharray="8 5"><path d="{inner}"/></g><g id="warning-shape"><path d="M 95 103 L 113 121 H 95 Z" fill="#edaa82"/><path d="M 16 104 L 27 115 M 27 104 L 16 115" stroke="#edaa82" stroke-width="4"/></g>',
    'unavailable': '<g id="unavailable-hatching" stroke="#a4adbb" stroke-width="3"><path d="M 93 110 L 105 98 M 99 116 L 117 98 M 105 120 L 121 104"/></g><g id="inspection-dot"><circle cx="110" cy="90" r="7" fill="#182535" stroke="#a4adbb" stroke-width="2"/><circle cx="110" cy="90" r="2" fill="#eee0bf"/></g>',
    'powered': '<g id="powered-center-collar" fill="none" stroke="#ffe3a0" stroke-width="3"><path d="M 39 43 L 43 39 M 85 39 L 89 43 M 89 85 L 85 89 M 43 89 L 39 85"/></g>',
    'eligible': f'<g id="eligible-border" fill="none" stroke="#61dccf" stroke-width="2"><path d="{inner}"/></g><g id="eligible-plus" stroke="#61dccf" stroke-width="4"><path d="M 13 109 H 27 M 20 102 V 116"/></g>',
    'protected': f'<g id="protected-border" fill="none" stroke="#c19890" stroke-width="2"><path d="{inner}"/></g><g id="protected-cross" stroke="#c19890" stroke-width="4"><path d="M 14 103 L 26 115 M 26 103 L 14 115"/></g>',
}
for name,body in overlays.items():
    (OVERLAYS/f'{name}.svg').write_text(svg(body,f'Spark tile overlay: {name}; no live label'),encoding='utf8')
    shutil.copy2(OVERLAYS/f'{name}.svg',EXPORT/'spark_tile_overlays'/f'{name}.svg')
temporary='''<g id="tag-outline"><path d="M 28 18 H 100 V 91 L 64 111 L 28 91 Z" fill="#141726" stroke="#141726" stroke-width="8" stroke-linejoin="round"/></g>
<g id="tag-fill"><path d="M 31 21 H 97 V 89 L 64 107 L 31 89 Z" fill="#cba05c"/></g>
<g id="temporary-hourglass" fill="none" stroke="#141726" stroke-width="8" stroke-linejoin="round"><path d="M 46 38 H 82 L 46 82 H 82 Z"/></g>'''
(HERE/'temporary-marker.svg').write_text(svg(temporary,'Temporary marker — hourglass tag; live TEMP wording remains separate'),encoding='utf8')
shutil.copy2(HERE/'temporary-marker.svg',EXPORT/'temporary-marker.svg')

for r in range(4):
    body=f'''<g id="live-port-geometry" transform="rotate({r*90} 64 64)" fill="none" stroke="#efb24d" stroke-width="4.672" stroke-linecap="butt"><path d="M 0 64 H 128"/></g>
<g id="live-output-arrow" transform="rotate({r*90} 64 64)"><path d="M 128 64 L 116.79 58.39 L 116.79 69.61 Z" fill="#ffe3a0"/></g>'''
    (PREVIEW/f'spark-ports-r{r}.svg').write_text(svg(body,f'PREVIEW ONLY — Spark exact ports rotation {r}', {**contract,'rotation':r,'art_contains_ports':True}),encoding='utf8')
(HERE/'geometry-contract.json').write_text(json.dumps(contract,indent=2)+'\n',encoding='utf8')
print('Wrote Spark SVG, monochrome, separate TEMP tag, 7 overlays, 4 preview-only rotations and contract.')
