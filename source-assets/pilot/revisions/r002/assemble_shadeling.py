"""RC-011 source assembly and unintegrated transform study. Run from any cwd.

Generated painting remains immutable in raw/. Polygon masks and this script are
the native editable source for deterministic layer separation, not new painting.
No Godot resource or game code is read or written.
"""
from pathlib import Path
import json, math, hashlib, io, zipfile, xml.etree.ElementTree as ET
import numpy as np
from PIL import Image, ImageDraw, ImageFont, ImageChops, ImageFilter, ImageCms

HERE = Path(__file__).resolve().parent
PILOT = HERE
ROOT = HERE.parents[3]
EXPORT = PILOT / 'exports'
PARTS = EXPORT / 'shadeling_parts'
OUT = ROOT / 'output/art/rc-011/r002'
FRAMES = OUT / 'pilot-motion-frames'
for p in [PARTS, OUT, FRAMES, HERE/'layers']:
    p.mkdir(parents=True, exist_ok=True)
SRGB_ICC = ImageCms.ImageCmsProfile(ImageCms.createProfile('sRGB')).tobytes()
def save_png(im, path):
    # Source pixels are authored/displayed in sRGB. Attach that explicit profile
    # without transforming pixels, for reproducible colour interpretation.
    im.save(path, icc_profile=SRGB_ICC)

raw = Image.open(HERE/'raw/shadeling.png').convert('RGBA')
W,H = raw.size
arr = np.array(raw)
# Sparse nearly invisible generation residue is outside the actor silhouette.
# Preserve genuine edge alpha, remove only alpha <= 3; original remains in raw/.
residue = int(((arr[:,:,3] > 0) & (arr[:,:,3] <= 3)).sum())
arr[arr[:,:,3] <= 3] = 0
raw = Image.fromarray(arr)

# Masks are in immutable raw-image pixel coordinates and exported as SVG.
polys = {
 'lantern': [(134,348),(193,344),(189,385),(245,333),(282,323),(311,353),(300,399),(293,448),(334,473),(338,522),(328,564),(335,649),(356,681),(337,714),(317,735),(274,754),(197,743),(143,712),(123,685),(128,650),(142,510),(125,499),(112,574),(96,568),(105,476)],
 'lantern_arm': [(147,252),(232,227),(273,236),(315,280),(381,304),(425,284),(470,300),(510,340),(526,401),(500,470),(461,483),(424,521),(392,579),(361,604),(329,575),(292,459),(286,409),(244,381),(180,381),(142,343)],
 'glass': [(154,521),(170,516),(166,637),(147,646)],
 'glass_main': [(176,517),(290,506),(310,650),(171,665)],
 'shoulder_underlap': [(432,295),(479,306),(510,341),(524,399),(502,463),(462,479),(440,424)],
}

def pmask(points):
    m=Image.new('L',(W,H),0);ImageDraw.Draw(m).polygon(points,fill=255);return m
lantern_m=pmask(polys['lantern'])
arm_m=ImageChops.subtract(pmask(polys['lantern_arm']),lantern_m)
glass_m=ImageChops.lighter(pmask(polys['glass']),pmask(polys['glass_main']))
glass_m=ImageChops.multiply(glass_m,lantern_m)
# Bright warm core is independent from the surrounding generated glass light.
core=(arr[:,:,0]>190)&(arr[:,:,1]>105)&(arr[:,:,0]>arr[:,:,2]*1.5)
flame_m=ImageChops.multiply(glass_m,Image.fromarray(core.astype('uint8')*255))
light_m=ImageChops.subtract(glass_m,flame_m)
body_m=ImageChops.subtract(Image.new('L',(W,H),255),ImageChops.lighter(lantern_m,arm_m))
shell_m=ImageChops.subtract(lantern_m,glass_m)
def cut(mask):
    p=raw.copy();p.putalpha(ImageChops.multiply(raw.getchannel('A'),mask));return p

scale=720/(1176-83)
origin=(695.0,1175.0)
offset=(512-origin[0]*scale,896-origin[1]*scale)
def normalize(im):
    return im.transform((1024,1024),Image.Transform.AFFINE,
        (1/scale,0,-offset[0]/scale,0,1/scale,-offset[1]/scale),
        Image.Resampling.BICUBIC)
def vector_patch(points, color):
    p=Image.new('RGBA',(W,H));ImageDraw.Draw(p).polygon(points,fill=color);return p

source={
 'body_cloak': normalize(cut(body_m)),
 'shoulder_underlap': normalize(vector_patch(polys['shoulder_underlap'],'#32243c')),
 'lantern_arm': normalize(cut(arm_m)),
 'lantern_glass_backing': normalize(vector_patch(polys['glass_main'],'#332115')),
 'lantern_shell': normalize(cut(shell_m)),
 'lantern_glass_light': normalize(cut(light_m)),
 'flame': normalize(cut(flame_m)),
}
draw_order=['body_cloak','shoulder_underlap','lantern_arm','lantern_glass_backing','lantern_shell','lantern_glass_light','flame']
for key,p in source.items():save_png(p,HERE/'layers'/f'{key}.png')

def compose(parts,order=draw_order):
    o=Image.new('RGBA',next(iter(parts.values())).size)
    for k in order:o.alpha_composite(parts[k])
    return o
merged=compose(source)
save_png(merged,HERE/'neutral-reference.png')
parts={k:p.resize((512,512),Image.Resampling.LANCZOS) for k,p in source.items()}
for k,p in parts.items():save_png(p,PARTS/f'{k}.png')
neutral=compose(parts)
save_png(neutral,EXPORT/'shadeling.png')

# Editable geometric refinement source and separation boundaries.
svg=['<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="1024" height="1024" viewBox="0 0 1024 1024">',
 '<title>Shadeling source separation and underlap geometry</title>',
 f'<g id="raw-coordinate-system" transform="translate({offset[0]} {offset[1]}) scale({scale})">',
 '<image id="generated-neutral-reference" xlink:href="raw/shadeling.png" width="%s" height="%s"/>'%(W,H)]
for k,points in polys.items():
    svg.append(f'<polygon id="mask-{k}" points="'+ ' '.join(f'{x},{y}' for x,y in points)+'" fill="none" stroke="#40ddcf" stroke-width="2"/>')
svg+=['</g>','<path id="foot-anchor" d="M496 896H528M512 880V912" stroke="#ffca6b" fill="none"/>','</svg>']
(HERE/'separation-masks.svg').write_text('\n'.join(svg),encoding='utf-8')

# Full-canvas OpenRaster: genuine disjoint extracted parts plus new vector patches.
imgroot=ET.Element('image',{'version':'0.0.3','w':'1024','h':'1024','name':'RC-011 Shadeling r002'})
stack=ET.SubElement(imgroot,'stack',{'name':'Separated neutral illustration'})
with zipfile.ZipFile(HERE/'shadeling.ora','w',zipfile.ZIP_DEFLATED) as z:
    z.writestr('mimetype','image/openraster',compress_type=zipfile.ZIP_STORED)
    for k in reversed(draw_order):
        ET.SubElement(stack,'layer',{'name':k,'src':f'data/{k}.png','opacity':'1.0','visibility':'visible','composite-op':'svg:src-over','x':'0','y':'0'})
        b=io.BytesIO();source[k].save(b,format='PNG',icc_profile=SRGB_ICC);z.writestr(f'data/{k}.png',b.getvalue())
    z.writestr('stack.xml',ET.tostring(imgroot,encoding='utf-8',xml_declaration=True))
    for name,im in [('mergedimage.png',merged),('Thumbnails/thumbnail.png',merged.resize((256,256),Image.Resampling.LANCZOS))]:
        b=io.BytesIO();im.save(b,format='PNG',icc_profile=SRGB_ICC);z.writestr(name,b.getvalue())

def raw_to_export(x,y):return ((x*scale+offset[0])/2,(y*scale+offset[1])/2)
pivots={'foot':[256,448],'body_center':list(raw_to_export(642,660)),
        'head':list(raw_to_export(598,290)),'attack_origin':list(raw_to_export(247,352)),
        'lantern_arm':list(raw_to_export(474,352)),'held_item':list(raw_to_export(265,354)),
        'flame':list(raw_to_export(240,605))}

fontpath=Path('C:/Windows/Fonts/arial.ttf')
boldpath=Path('C:/Windows/Fonts/arialbd.ttf')
def font(n,b=False):return ImageFont.truetype(str(boldpath if b else fontpath),n)
def text(draw,xy,s,n=22,fill='#eadcba',b=False):draw.text(xy,s,font=font(n,b),fill=fill)
def checker(size):
    im=Image.new('RGBA',size,'#d2d2d2');d=ImageDraw.Draw(im)
    for y in range(0,size[1],16):
        for x in range(0,size[0],16):
            if (x//16+y//16)%2:d.rectangle((x,y,x+15,y+15),fill='#eeeeee')
    return im

alpha=Image.new('RGB',(1280,730),'#0b1322');d=ImageDraw.Draw(alpha)
text(d,(30,20),'SHADELING / ALPHA AND LAYER REVIEW',30,b=True)
for i,(name,color) in enumerate([('LIGHT GRAY','#e5e7eb'),('DARK NAVY','#0c1525'),('TURQUOISE','#39b4ac'),('CHECKERBOARD',None)]):
    bg=checker((300,480)) if color is None else Image.new('RGBA',(300,480),color)
    display=neutral.resize((300,300),Image.Resampling.LANCZOS)
    bg.alpha_composite(display,(0,70));alpha.paste(bg.convert('RGB'),(20+i*315,80))
    text(d,(27+i*315,580),name,19,b=True)
text(d,(30,622),'Straight alpha; shared 512 canvas. No baked name, intent, health, environment or shadow.',21)
text(d,(30,658),'Raw generation retained. Independent body, arm, shell, glass light and flame; small shoulder underlap.',19)
alpha.save(OUT/'pilot-shadeling-alpha.png')

# Flat-color part silhouettes expose real separation, never flattened duplicates.
layer_sheet=Image.new('RGB',(1280,690),'#0c1525');d=ImageDraw.Draw(layer_sheet)
text(d,(24,20),'SHADELING / EDITABLE PARTS',30,b=True)
for i,k in enumerate(draw_order):
    x=20+(i%4)*315;y=80+(i//4)*300
    panel=checker((294,230));p=parts[k].resize((230,230),Image.Resampling.LANCZOS)
    panel.alpha_composite(p,(32,0));layer_sheet.paste(panel.convert('RGB'),(x,y))
    text(d,(x+4,y+240),k.replace('_',' '),18)
text(d,(24,650),'Each part retains 512 x 512 origin; ORA layers are 1024 x 1024. Raw is separate provenance.',20)
layer_sheet.save(OUT/'pilot-shadeling-layers.png')

scale_sheet=Image.new('RGB',(1280,430),'#0c1525');d=ImageDraw.Draw(scale_sheet)
text(d,(24,18),'SHADELING / PROPOSED ARENA SCALE',28,b=True)
for i,s in enumerate([.46,.62,.66]):
    x=35+i*420;ground=330
    ns=neutral.resize((round(512*s),round(512*s)),Image.Resampling.LANCZOS)
    scale_sheet.paste(ns,(round(x+200-256*s),round(ground-448*s)),ns)
    d.line((x,ground,x+390,ground),fill='#c4a36a',width=1)
    text(d,(x+95,355),f'{s:.2f} design px / texture px',19,b=s==.66)
text(d,(24,396),'Reference comparison requires larger art: 0.62–0.66. Foot anchor remains (256,448).',19)
scale_sheet.save(OUT/'pilot-shadeling-scale.png')

def affine(im,angle=0,pivot=(256,448),move=(0,0),yscale=1,opacity=1):
    # Forward M = translate(move+pivot) * rotate * scaleY * translate(-pivot).
    t=math.radians(angle);c=math.cos(t);s=math.sin(t)
    a,b,d,e=c,-s*yscale,s,c*yscale
    tx=move[0]+pivot[0]-a*pivot[0]-b*pivot[1]
    ty=move[1]+pivot[1]-d*pivot[0]-e*pivot[1]
    det=a*e-b*d
    inv=(e/det,-b/det,(b*ty-e*tx)/det,-d/det,a/det,(d*tx-a*ty)/det)
    o=im.transform((512,512),Image.Transform.AFFINE,inv,Image.Resampling.BICUBIC)
    if opacity<1:o.putalpha(o.getchannel('A').point(lambda v:round(v*opacity)))
    return o

def state_at(t):
    if t<1.5:return 'IDLE',t/1.5
    if t<2:return 'ATTACK / anticipation',(t-1.5)/.5
    if t<2.5:return 'ATTACK / action',(t-2)/.5
    if t<3.5:return 'HIT / recoil',(t-2.5)
    return 'DEFEAT',(t-3.5)/2.5

def actor_frame(t,reduced=False):
    state,p=state_at(t);angle=0;dy=0;arm=0;lantern=0;opacity=1;ys=1
    if not reduced:
        if state=='IDLE':dy=-2*math.sin(2*math.pi*t/1.5);lantern=2*math.sin(2*math.pi*t/1.5)
        elif 'anticipation' in state:angle=3*p;arm=-4*p;lantern=-3*p
        elif 'action' in state:angle=3-8*math.sin(math.pi*p);arm=-4+9*math.sin(math.pi*p);lantern=-3+8*math.sin(math.pi*p)
        elif state.startswith('HIT'):angle=5*math.sin(math.pi*p)*max(0,1-p);dy=-2*math.sin(math.pi*p)
        else:ys=1-.12*min(1,p*1.8);angle=6*min(1,p*1.8);opacity=max(0,1-p*1.45)
    elif state=='DEFEAT':opacity=1 if p<.3 else max(0,1-(p-.3)*20)
    elif state=='ATTACK / action':opacity=.84 if p<.2 else 1
    elif state.startswith('HIT'):opacity=.74 if p<.1 else 1
    actorparts={k:v.copy() for k,v in parts.items()}
    actorparts['lantern_arm']=affine(actorparts['lantern_arm'],arm,pivots['lantern_arm'])
    for k in ['lantern_glass_backing','lantern_shell','lantern_glass_light','flame']:
        # Held item first swings at the grip, then inherits its parent's arm
        # transform. Without inheritance the handle visibly detaches at action.
        actorparts[k]=affine(affine(actorparts[k],lantern,pivots['held_item']),arm,pivots['lantern_arm'])
    o=compose(actorparts)
    return affine(o,angle,move=(0,dy),yscale=ys,opacity=opacity),state

frames=[];records=[];motion_bbox=None;motion_bbox_all=None
fps=8;duration=6
for n in range(fps*duration):
    t=n/fps;im=Image.new('RGB',(1280,720),'#0c1525');d=ImageDraw.Draw(im)
    text(d,(30,18),'SHADELING / TRANSFORM FEASIBILITY',29,b=True)
    text(d,(980,24),f'{t:04.2f}s / 06.00s',22)
    state=''
    for i,reduced in enumerate([False,True]):
        actor,state=actor_frame(t,reduced);x=62+i*640;y=110
        d.rectangle((x+32,y+32,x+480,y+480),outline='#477a7e',width=1)
        d.line((x+32,y+448,x+480,y+448),fill='#806c4b',width=1)
        im.paste(actor,(x,y),actor)
        d.line((x+248,y+448,x+264,y+448),fill='#ffd282',width=2)
        d.line((x+256,y+440,x+256,y+456),fill='#ffd282',width=2)
        text(d,(x+25,75),'TRANSFORMS / ' + state if not reduced else 'REDUCED / '+state,20,b=True)
        text(d,(x+60,640),'Anchor (256,448)  |  envelope32..480',19)
        box=actor.getchannel('A').point(lambda v:255 if v>16 else 0).getbbox()
        box_all=actor.getchannel('A').getbbox()
        records.append({'frame':n,'t':t,'reduced':reduced,'state':state,'alpha_bounds_gt16':box,'alpha_bounds_all':box_all})
        if box_all and not reduced:
            motion_bbox_all=box_all if motion_bbox_all is None else tuple([min(box_all[0],motion_bbox_all[0]),min(box_all[1],motion_bbox_all[1]),max(box_all[2],motion_bbox_all[2]),max(box_all[3],motion_bbox_all[3])])
        if box and not reduced:
            motion_bbox=box if motion_bbox is None else tuple([min(box[0],motion_bbox[0]),min(box[1],motion_bbox[1]),max(box[2],motion_bbox[2]),max(box[3],motion_bbox[3])])
    text(d,(30,688),'Unintegrated study: no gameplay events. Reduced: static pose, brief action/hit opacity cue, then fade.',19)
    im.save(FRAMES/f'frame_{n:03}.png');frames.append(im)
frames[0].save(OUT/'pilot-motion.gif',save_all=True,append_images=frames[1:],duration=[120 if n%2==0 else 130 for n in range(len(frames))],loop=0,optimize=False)
contact=Image.new('RGB',(1280,940),'#0c1525');cd=ImageDraw.Draw(contact)
text(cd,(25,15),'MOTION / KEY MOMENTS',28,b=True)
for i,n in enumerate([0,14,18,23,30,38]):
    thumb=frames[n].resize((620,349),Image.Resampling.LANCZOS)
    x=15+(i%2)*635;y=60+(i//2)*280
    # A concise actor-only key frame is clearer than six reduced full screen frames.
    contact.paste(thumb.crop((0,38,620,300)),(x,y))
    text(cd,(x+8,y+238),f'Frame {n:02} / {n/fps:0.3f}s',16)
contact.save(OUT/'pilot-motion-sheet.png')

alpha_bbox=neutral.getchannel('A').point(lambda v:255 if v>16 else 0).getbbox()
metadata={
 'asset_id':'pilot_shadeling','revision':'r002','date':'2026-10-11',
 'creator':'Built-in imagegen painting; Codex deterministic source separation and preview assembly',
 'generation':{'tool':'image_gen.imagegen','model_version':None,'model_version_status':'not exposed by tool',
  'prompt_path':'raw/shadeling.prompt.txt','raw_path':'raw/shadeling.png','raw_dimensions':[W,H],
  'raw_sha256':hashlib.sha256((HERE/'raw/shadeling.png').read_bytes()).hexdigest()},
 'source_size':[1024,1024],'export_size':[512,512],'source_foot':[512,896],'export_foot':[256,448],
 'colour':{'space':'sRGB','profile':'embedded standard sRGB ICC in source layers, ORA PNG members and runtime-format review PNGs','alpha':'straight/unassociated','profile_assignment':'Explicit sRGB interpretation; no pixel conversion; raw generation unchanged'},
 'raw_to_source':{'scale':scale,'translate':list(offset),'raw_foot':list(origin)},
 'shared_origin':[0,0],'draw_order':draw_order,'export_pivots':pivots,
 'neutral_alpha_bounds_gt16':alpha_bbox,'motion_alpha_bounds_gt16':motion_bbox,
 'neutral_alpha_bounds_all':neutral.getchannel('A').getbbox(),'motion_alpha_bounds_all':motion_bbox_all,
 'allowed_envelope':[32,32,480,480],
 'envelope_pass':motion_bbox[0]>=32 and motion_bbox[1]>=32 and motion_bbox[2]<=480 and motion_bbox[3]<=480,
 'alpha_cleanup':{'removed_alpha_lte':3,'raw_pixels_removed':residue,'reason':'sparse effectively invisible residue; original retained'},
 'layer_pixel_counts':{k:int((np.array(p)[:,:,3]>16).sum()) for k,p in source.items()},
 'rgba8_neutral_bytes':512*512*4,'rgba8_parts_bytes':len(parts)*512*512*4,
 'motion':{'format':'PNG image sequence','frames':len(frames),'fps':fps,'duration_seconds':duration,
 'gif':'output/art/rc-011/r002/pilot-motion.gif','sequence':'output/art/rc-011/r002/pilot-motion-frames',
 'video_status':'No video encoder was available in PATH; permitted PNG sequence substitute with GIF convenience preview.',
 'recommendation':'Lean transform method is sufficient for pilot feasibility; RC-014 must refine final attack/hit silhouettes and underlaps, RC-017 owns timing, cancellation, event callbacks and reduced-motion integration.'},
 'limitations':['Generated shoulder has limited hidden anatomy; shoulder underlap is a deliberate flat indigo patch supporting modest rotations only.',
 'Flame is extracted generated bright glass content, with independent generated glass-light and vector dark backing; not a final animated flame sheet.',
 'Inspector/type source fonts on motion/technical sheets are local Arial annotations, not the proposed game font package.',
 'No Godot import, physical-device, animation-event or owner aesthetic acceptance is claimed.'],
 'rights_status':'unresolved; raw prompt/tool provenance retained, no model/version or third-party licence invented'}
(HERE/'metadata.json').write_text(json.dumps(metadata,indent=2)+'\n',encoding='utf-8')
(OUT/'pilot-motion-timing.json').write_text(json.dumps({'fps':fps,'frame_duration_ms':125,'frames':records},indent=2)+'\n',encoding='utf-8')
print(json.dumps({'neutral_bounds':alpha_bbox,'motion_bounds':motion_bbox,'envelope_pass':metadata['envelope_pass'],'layer_count':len(parts),'raw_size':[W,H],'ora':str(HERE/'shadeling.ora')},indent=2))
