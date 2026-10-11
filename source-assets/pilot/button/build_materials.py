"""RC-011 isolated editable material construction, r001.

Rebuilds only the button and painted tile frame. Generated material swatches remain
untouched in raw/. Geometry is original, deterministic and independently editable.
Pillow is used for assembly/refinement explicitly requested by the owner.
"""
from pathlib import Path
from io import BytesIO
import json
import zipfile
import xml.etree.ElementTree as ET
from PIL import Image, ImageDraw, ImageOps, ImageCms

ROOT = Path(__file__).resolve().parents[1]
BUTTON = ROOT / 'button'
TILE = ROOT / 'spark_tile'
EXPORTS = ROOT / 'exports'
ICC = ImageCms.ImageCmsProfile(ImageCms.createProfile('sRGB')).tobytes()
RESAMPLE = Image.Resampling.LANCZOS

def png_bytes(im):
    out = BytesIO()
    im.save(out, format='PNG', icc_profile=ICC)
    return out.getvalue()

def save(im, path):
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(png_bytes(im))

def polygon(w, h, inset=0, cut=20):
    r, b = w-1-inset, h-1-inset
    return [(inset+cut,inset),(r-cut,inset),(r,inset+cut),(r,b-cut),
            (r-cut,b),(inset+cut,b),(inset,b-cut),(inset,inset+cut)]

def blank(size):
    return Image.new('RGBA', size, (0,0,0,0))

def mask(size, inset, cut):
    result = Image.new('L', size, 0)
    ImageDraw.Draw(result).polygon(polygon(*size,inset,cut), fill=255)
    return result

def solid(size, color, inset, cut):
    result = Image.new('RGBA', size, color)
    result.putalpha(mask(size,inset,cut))
    return result

def ring(size, color, inset, cut, thickness):
    result = solid(size,color,inset,cut)
    ImageDraw.Draw(result).polygon(polygon(*size,inset+thickness,max(0,cut-thickness//2)),fill=(0,0,0,0))
    return result

def paint(size, raw, inset, cut):
    result = ImageOps.fit(Image.open(raw).convert('RGBA'), size, method=RESAMPLE)
    result.putalpha(mask(size,inset,cut))
    return result

def composite(layers, size):
    result=blank(size)
    for name,im,visible in layers:
        if visible: result.alpha_composite(im)
    return result

def ora(path, size, layers, name):
    """layers are bottom to top. Different meaningful content; no flat duplicates."""
    merged=composite(layers,size)
    root=ET.Element('image', {'w':str(size[0]),'h':str(size[1]),'name':name,'version':'0.0.3'})
    stack=ET.SubElement(root,'stack')
    with zipfile.ZipFile(path,'w') as z:
        z.writestr('mimetype','image/openraster',compress_type=zipfile.ZIP_STORED)
        for idx,(layer_name,im,visible) in reversed(list(enumerate(layers))):
            src=f'data/layer{idx:02d}.png'
            z.writestr(src,png_bytes(im))
            ET.SubElement(stack,'layer',{'name':layer_name,'src':src,'x':'0','y':'0','opacity':'1.0',
                'visibility':'visible' if visible else 'hidden','composite-op':'svg:src-over'})
        z.writestr('stack.xml',ET.tostring(root,encoding='utf-8',xml_declaration=True))
        z.writestr('mergedimage.png',png_bytes(merged))
        thumb=merged.copy();thumb.thumbnail((256,256),RESAMPLE)
        z.writestr('Thumbnails/thumbnail.png',png_bytes(thumb))
    return merged

def trim_layers(size, kind):
    w,h=size
    button=kind=='button'
    cut=28 if button else 22
    outer=solid(size,'#080f1d',3,cut)
    gold=ring(size,'#916638',9,cut-2,9 if button else 8)
    hilite=blank(size);d=ImageDraw.Draw(hilite)
    pts=polygon(w,h,11,cut-3)
    d.line([pts[7],pts[0],pts[1],pts[2]],fill='#d3ad68',width=4,joint='curve')
    d.line([pts[3],pts[4],pts[5],pts[6]],fill='#4e3c29',width=5,joint='curve')
    # Four angular corner facets stay entirely inside the declared slice margins.
    for flipx,flipy in [(False,False),(True,False),(False,True),(True,True)]:
        p=[(8,27),(28,8),(36,10),(17,32)] if button else [(8,25),(25,8),(32,10),(16,31)]
        p=[(w-1-x if flipx else x,h-1-y if flipy else y) for x,y in p]
        d.polygon(p, fill='#bd9659' if not flipy else '#765330')
    edge=ring(size,'#1a2732',19,cut-7,5)
    return outer,gold,hilite,edge

def button_state_svg(state):
    """SVG state masters, independent of primary/secondary material and live text."""
    path='M18 3H494L509 18V110L494 125H18L3 110V18Z'
    inner='M25 15H487L497 25V103L487 113H25L15 103V25Z'
    if state=='pressed':
        s=f'<path d="{inner}" fill="#020d18" opacity=".34"/><path d="M25 16H487L496 25" fill="none" stroke="#071827" stroke-width="5"/>'
    elif state=='focused':
        s=f'<path d="{path}" fill="none" stroke="#fff1c8" stroke-width="3" stroke-dasharray="10 5"/>'
    elif state=='selected':
        s=f'<path d="{inner}" fill="none" stroke="#63ded2" stroke-width="3"/><path d="M22 23l4 4 7-8" fill="none" stroke="#fff1c8" stroke-width="3"/>'
    elif state=='disabled':
        s=f'<path d="{path}" fill="#69737d" opacity=".52"/><path d="{inner}" fill="#102034" opacity=".28"/><path d="M20 63H29" stroke="#bbc3c8" stroke-width="3"/>'
    elif state=='invalid':
        s=f'<path d="{inner}" fill="none" stroke="#ef9668" stroke-width="3" stroke-dasharray="14 6"/><path d="M20 54L31 69M31 54L20 69" fill="none" stroke="#ffe0b6" stroke-width="3"/>'
    elif state=='unavailable':
        s=f'<path d="{inner}" fill="#071222" opacity=".24"/><path d="M17 34V22H31M481 22H495V34M17 94V106H31M481 106H495V94" fill="none" stroke="#d6be86" stroke-width="3"/><circle cx="25" cy="64" r="8" fill="#172b40" stroke="#ead7ad" stroke-width="2"/><path d="M25 63v6M25 58v2" stroke="#ead7ad" stroke-width="2"/>'
    else: raise ValueError(state)
    return f'<svg xmlns="http://www.w3.org/2000/svg" width="512" height="128" viewBox="0 0 512 128"><title>Shared button {state} overlay; no live label</title>{s}</svg>'

def state_layer(state,size=(1024,256)):
    """Raster counterpart drawn at master resolution; geometry matches SVG masters."""
    # Draw at 2x source resolution for smooth compositing.
    factor=size[0]/512
    hi=4
    out=blank((size[0]*hi,size[1]*hi));d=ImageDraw.Draw(out)
    def pts(ps):return [(round(x*factor*hi),round(y*factor*hi)) for x,y in ps]
    def line(ps,color,width=3):d.line(pts(ps),fill=color,width=round(width*factor*hi),joint='curve')
    def poly(ps,color):d.polygon(pts(ps),fill=color)
    outer=[(18,3),(494,3),(509,18),(509,110),(494,125),(18,125),(3,110),(3,18)]
    inner=[(25,15),(487,15),(497,25),(497,103),(487,113),(25,113),(15,103),(15,25)]
    if state=='pressed':poly(inner,(2,13,24,87));line([(25,16),(487,16),(496,25)],'#071827',5)
    elif state=='focused':
        # focus has a shape cue: alternating edge segments
        for y in [3,125]:
            for x in range(21,486,15):line([(x,y),(min(x+10,491),y)],'#fff1c8',3)
        for x in [3,509]:
            for y in range(22,104,15):line([(x,y),(x,min(y+10,107))],'#fff1c8',3)
        for p in [[(3,18),(18,3)],[(494,3),(509,18)],[(509,110),(494,125)],[(18,125),(3,110)]]:line(p,'#fff1c8',3)
    elif state=='selected':line(inner+[inner[0]],'#63ded2',3);line([(22,23),(26,27),(33,19)],'#fff1c8',3)
    elif state=='disabled':poly(outer,(105,115,125,133));poly(inner,(16,32,52,72));line([(20,63),(29,63)],'#bbc3c8',3)
    elif state=='invalid':
        for y in [15,113]:
            for x in range(25,483,20):line([(x,y),(min(x+14,487),y)],'#ef9668',3)
        for x in [15,497]:
            for y in range(28,101,20):line([(x,y),(x,min(y+14,103))],'#ef9668',3)
        line([(20,54),(31,69)],'#ffe0b6',3);line([(31,54),(20,69)],'#ffe0b6',3)
    elif state=='unavailable':
        poly(inner,(7,18,34,61))
        for p in [[(17,34),(17,22),(31,22)],[(481,22),(495,22),(495,34)],[(17,94),(17,106),(31,106)],[(481,106),(495,106),(495,94)]]:line(p,'#d6be86',3)
        box=pts([(17,56),(33,72)]);d.ellipse(box,fill='#172b40',outline='#ead7ad',width=round(2*factor*hi))
        line([(25,63),(25,69)],'#ead7ad',2);line([(25,58),(25,60)],'#ead7ad',2)
    return out.resize(size,RESAMPLE)

def nine_slice(image,size,margins=(24,20,24,20),scale=0.5):
    """margins are source export px L,T,R,B; scale=.5 gives logical corners.
    Nine patches retain cap shape; fill stretches. This is a review-only helper.
    """
    if not isinstance(image,Image.Image): image=Image.open(image)
    image=image.convert('RGBA');iw,ih=image.size;ow,oh=map(int,size)
    l,t,r,b=margins
    dl,dt,dr,db=[max(1,round(v*scale)) for v in margins]
    if ow<dl+dr or oh<dt+db: raise ValueError('Target too small for slice caps')
    xs=[0,l,iw-r,iw];ys=[0,t,ih-b,ih]
    xd=[0,dl,ow-dr,ow];yd=[0,dt,oh-db,oh]
    out=blank((ow,oh))
    for j in range(3):
        for i in range(3):
            patch=image.crop((xs[i],ys[j],xs[i+1],ys[j+1]))
            patch=patch.resize((xd[i+1]-xd[i],yd[j+1]-yd[j]),RESAMPLE)
            out.paste(patch,(xd[i],yd[j]))
    return out

def render_button(size,variant='secondary',states=()):
    if isinstance(states,str): states=(states,)
    out=nine_slice(EXPORTS/f'button_{variant}_normal.png',size)
    # Derive shape overlays at logical target size so marks remain a readable size.
    for state in states:
        if state=='normal':continue
        overlay=responsive_overlay(size,state)
        out.alpha_composite(overlay)
    return out

def state_operations(size,state):
    """Logical vector state resource. Markers stay constant size at every control."""
    w,h=size;ops=[]
    outside=polygon(w,h,1,7);inside=polygon(w,h,4,6)
    def line(p,c,width=1.5):ops.append(('line',p,c,width))
    def poly(p,c):ops.append(('polygon',p,c,0))
    if state=='pressed':
        poly(inside,'#020d1857');line([(10,5),(w-11,5)],'#071827',2)
    elif state=='focused':
        for y in [1,h-2]:
            for x in range(9,w-9,8):line([(x,y),(min(x+5,w-9),y)],'#fff1c8',1.5)
        for x in [1,w-2]:
            for y in range(10,h-9,8):line([(x,y),(x,min(y+5,h-9))],'#fff1c8',1.5)
        for p in [[(1,8),(8,1)],[(w-9,1),(w-2,8)],[(w-2,h-9),(w-9,h-2)],[(8,h-2),(1,h-9)]]:line(p,'#fff1c8',1.5)
    elif state=='selected':
        line(inside+[inside[0]],'#63ded2',1.5)
        line([(8,10),(11,13),(16,7)],'#fff1c8',2)
    elif state=='disabled':
        poly(outside,'#69737d85');poly(inside,'#10203448');line([(7,h/2),(13,h/2)],'#bbc3c8',1.5)
    elif state=='invalid':
        for y in [5,h-6]:
            for x in range(12,w-11,10):line([(x,y),(min(x+6,w-12),y)],'#ef9668',1.5)
        for x in [5,w-6]:
            for y in range(12,h-11,10):line([(x,y),(x,min(y+6,h-12))],'#ef9668',1.5)
        line([(7,h/2-4),(13,h/2+4)],'#ffe0b6',1.5);line([(13,h/2-4),(7,h/2+4)],'#ffe0b6',1.5)
    elif state=='unavailable':
        poly(inside,'#0712223d')
        for p in [[(6,17),(6,10),(13,10)],[(w-14,10),(w-7,10),(w-7,17)],[(6,h-18),(6,h-11),(13,h-11)],[(w-14,h-11),(w-7,h-11),(w-7,h-18)]]:line(p,'#d6be86',1.5)
        ops.append(('ellipse',[(5,h/2-5),(15,h/2+5)],'#ead7ad',1.25))
        line([(10,h/2),(10,h/2+3)],'#ead7ad',1.25);line([(10,h/2-3),(10,h/2-2)],'#ead7ad',1.25)
    else: raise ValueError(state)
    return ops

def responsive_overlay(size,state):
    hi=4;out=blank((size[0]*hi,size[1]*hi))
    for kind,p,color,width in state_operations(size,state):
        part=blank(out.size);d=ImageDraw.Draw(part)
        p=[(round(x*hi),round(y*hi)) for x,y in p]
        if kind=='polygon':d.polygon(p,fill=color)
        elif kind=='ellipse':d.ellipse(p,fill='#172b40',outline=color,width=round(width*hi))
        else:d.line(p,fill=color,width=max(1,round(width*hi)),joint='curve')
        out.alpha_composite(part)
    return out.resize(size,RESAMPLE)

def responsive_overlay_svg(size,state):
    chunks=[]
    for kind,p,color,width in state_operations(size,state):
        opacity=''
        if len(color)==9:
            opacity=f' opacity="{int(color[-2:],16)/255:.6f}"';color=color[:7]
        points=' '.join(f'{x:g},{y:g}' for x,y in p)
        if kind=='polygon':chunks.append(f'<polygon points="{points}" fill="{color}"{opacity}/>')
        elif kind=='ellipse':
            (x1,y1),(x2,y2)=p
            chunks.append(f'<ellipse cx="{(x1+x2)/2:g}" cy="{(y1+y2)/2:g}" rx="{(x2-x1)/2:g}" ry="{(y2-y1)/2:g}" fill="#172b40" stroke="{color}" stroke-width="{width:g}"/>')
        else:chunks.append(f'<polyline points="{points}" fill="none" stroke="{color}" stroke-width="{width:g}" stroke-linejoin="round"{opacity}/>')
    return f'<svg xmlns="http://www.w3.org/2000/svg" width="{size[0]}" height="{size[1]}" viewBox="0 0 {size[0]} {size[1]}"><title>Shared button {state}; regenerate geometry at control size, markers do not stretch</title>'+''.join(chunks)+'</svg>'

def build():
    EXPORTS.mkdir(parents=True,exist_ok=True)
    (BUTTON/'overlays').mkdir(exist_ok=True)
    size=(1024,256)
    outer,gold,hilite,edge=trim_layers(size,'button')
    primary=paint(size,BUTTON/'raw/turquoise_material_r001.png',23,19)
    secondary=paint(size,TILE/'raw/navy_material_r001.png',23,19)
    # Narrow inner rim supplies separation without adding an assumed connection.
    rim=ring(size,'#19968e',24,19,3)
    secondary_rim=ring(size,'#3d556f',24,19,3)
    common=[('01 dark outer silhouette',outer,True),('02 painted turquoise material',primary,True),
        ('03 painted navy alternate material',secondary,False),('04 restrained gold trim',gold,True),
        ('05 angular gold highlight and shadow facets',hilite,True),('06 dark inner bevel',edge,True),
        ('07 turquoise inner rim',rim,True),('08 navy alternate inner rim',secondary_rim,False)]
    states=['pressed','focused','selected','disabled','invalid','unavailable']
    layers=common.copy()
    for state in states:
        layer=responsive_overlay((256,64),state).resize(size,RESAMPLE)
        layers.append((f'state {state} independent shared overlay',layer,False))
        save(layer.resize((512,128),RESAMPLE),BUTTON/'overlays'/f'{state}.png')
        (BUTTON/'overlays'/f'{state}.svg').write_text(responsive_overlay_svg((256,64),state),encoding='utf-8')
    primary_merged=ora(BUTTON/'button.ora',size,layers,'pilot_button r001 turquoise visible; navy and states hidden')
    save(primary_merged.resize((512,128),RESAMPLE),EXPORTS/'button_primary_normal.png')
    sec=[(n,i,n not in ['02 painted turquoise material','07 turquoise inner rim']) for n,i,v in common]
    save(composite(sec,size).resize((512,128),RESAMPLE),EXPORTS/'button_secondary_normal.png')
    for idx,(name,im,visible) in enumerate(layers):save(im,BUTTON/'layers'/f'{idx:02d}_{name.replace(" ","_")}.png')

    size=(512,512)
    outer,gold,hilite,edge=trim_layers(size,'tile')
    material=paint(size,TILE/'raw/navy_material_r001.png',23,15)
    tilelayers=[('01 dark outer silhouette',outer,True),('02 painted navy slate material',material,True),
        ('03 restrained gold trim',gold,True),('04 corner highlight and shadow facets',hilite,True),('05 dark inner bevel',edge,True)]
    merged=ora(TILE/'spark_tile.ora',size,tilelayers,'pilot_spark_tile r001 painted frame only')
    save(merged.resize((256,256),RESAMPLE),EXPORTS/'spark_tile.png')
    for idx,(name,im,visible) in enumerate(tilelayers):save(im,TILE/'layers'/f'{idx:02d}_{name.replace(" ","_")}.png')
    metadata={
        'revision':'r001','date':'2026-10-11','assets':['pilot_button','pilot_spark_tile'],
        'button':{'source':[1024,256],'export':[512,128],'slice_LTRB':[24,20,24,20],
          'texture_to_logical_scale':0.5,'standard_padding_xy':[16,10],'compact_padding_xy':[8,6],
          'min_hitbox':[66,50],'state_composition':{'normal':'base','pressed':'base + pressed (live label offset 0,1 logical px)',
          'focused':'base + focused','selected':'base + selected','disabled':'base + disabled; input disabled',
          'invalid':'base + invalid; live explanation required','unavailable':'base + unavailable; input remains inspectable',
          'focused_selected':'base + selected + focused','focused_unavailable':'base + unavailable + focused'},
          'overlay_exports':'button/overlays/<state>.png; same shared files for both materials. SVG masters use viewBox256x64; production must regenerate state geometry responsively at actual control size using state_operations, not nine-slice a marker.',
          'live_text':'NOT included; control bounds never move or shrink'},
        'tile':{'source':[512,512],'export':[256,256],'slice_LTRB':[16,16,16,16],
          'ports':'Separate exact live geometry; frame has no painted connections or sockets',
          'text_glyph_states':'Separate assets by geometry task; not baked into material'},
        'colour':'sRGB profile embedded; 8-bit RGBA straight alpha','source_method':'Generated raw material paintings clipped with editable polygon masks. Genuine individual paint, silhouette, trim, facet, bevel and state layers; no duplicated flattened art.',
        'decoded_bytes':{'button_primary_RGBA8':512*128*4,'button_secondary_RGBA8':512*128*4,'shared_button_overlays_6_RGBA8':6*512*128*4,'tile_RGBA8':256*256*4,'total_export_RGBA8':9*256*1024},
        'limits':['Material paintings are flattened generated strokes, not individual brush-stroke layers. Shape, trim, material and states remain independently editable.',
          'ORA rasterizes vector trim/state copies; SVG overlays and this parametric Python source retain editable geometry.',
          'Review-only outputs. Godot import, device readability, input behavior and final font embedding are not verified.']}
    (BUTTON/'material_metadata.json').write_text(json.dumps(metadata,indent=2),encoding='utf-8')
    print(json.dumps({'masters':[str(BUTTON/'button.ora'),str(TILE/'spark_tile.ora')],'exports':['button_primary_normal.png','button_secondary_normal.png','spark_tile.png'],'shared_overlays':states}))

if __name__=='__main__':build()
