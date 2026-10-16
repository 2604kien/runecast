"""RC-013 deterministic production promotion. No pilot/reference files are changed.

Python + Pillow + NumPy; SVG rasterization uses the bundled Node sharp module.
Rebuilds painted pack ORAs, masks, RGBA8/sRGB exports, original vector state
overlays, custom vector wordmark, and exact source/export provenance.
"""
from pathlib import Path
from io import BytesIO
import argparse, hashlib, json, math, os, subprocess, zipfile
import xml.etree.ElementTree as ET
from PIL import Image, ImageChops, ImageCms, ImageDraw, ImageFont, ImageOps
import numpy as np

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / 'source-assets/ui'
RUN = ROOT / 'assets/ui'
PILOT = ROOT / 'source-assets/pilot/revisions/r006/ui'
RAW = ROOT / 'source-assets/pilot/revisions/r004/raw'
ICC = ImageCms.ImageCmsProfile(ImageCms.createProfile('sRGB')).tobytes()
LZ = Image.Resampling.LANCZOS
NODE = Path(os.environ.get('RC_NODE', str(Path.home() / '.cache/codex-runtimes/codex-primary-runtime/dependencies/node/bin/node.exe')))
SHARP = NODE.parent.parent / 'node_modules/sharp'
records, source_records = [], []
RETIRED_RUNTIME_FILES = ['frames/pile.png'] + [
    'states/' + name + '.svg' for name in
    ['eligible', 'focused', 'invalid', 'powered', 'protected', 'selected', 'unavailable', 'upgrade']
]


def rel(p): return Path(p).relative_to(ROOT).as_posix()
def sha(p): return hashlib.sha256(Path(p).read_bytes()).hexdigest()
def blank(size): return Image.new('RGBA', size, (0, 0, 0, 0))
def png(im):
    out = BytesIO(); im.save(out, format='PNG', icc_profile=ICC); return out.getvalue()
def save(im, path):
    path = Path(path); path.parent.mkdir(parents=True, exist_ok=True); path.write_bytes(png(im))
def load(name): return Image.open(PILOT / name).convert('RGBA')
def merged(layers, size):
    out = blank(size)
    for name, im, visible in layers:
        if visible: out.alpha_composite(im)
    return out


def ora(name, size, layers):
    """Meaningful bottom-to-top parts; each separately exported with alpha mask."""
    path = SRC / (name + '.ora'); composite = merged(layers, size)
    root = ET.Element('image', w=str(size[0]), h=str(size[1]), name='RC-013 '+name, version='0.0.3')
    stack = ET.SubElement(root, 'stack')
    layer_paths = []
    with zipfile.ZipFile(path, 'w', compression=zipfile.ZIP_DEFLATED) as z:
        z.writestr('mimetype', 'image/openraster', compress_type=zipfile.ZIP_STORED)
        for i, (label, im, visible) in reversed(list(enumerate(layers))):
            src = f'data/layer{i:02d}.png'
            z.writestr(src, png(im))
            ET.SubElement(stack, 'layer', name=label, src=src, x='0', y='0', opacity='1.0',
                          visibility='visible' if visible else 'hidden', **{'composite-op': 'svg:src-over'})
            lp = SRC / 'layers' / name / f'{i:02d}-{label.lower().replace(" ", "-")}.png'
            save(im, lp)
            mask = SRC / 'masks' / name / (lp.stem + '-alpha.png')
            mask.parent.mkdir(parents=True, exist_ok=True); im.getchannel('A').save(mask)
            layer_paths.append({'name':label,'visible':visible,'layer':rel(lp),'mask':rel(mask),'sha256':sha(lp)})
        z.writestr('stack.xml', ET.tostring(root, encoding='utf-8', xml_declaration=True))
        z.writestr('mergedimage.png', png(composite))
        thumb=composite.copy(); thumb.thumbnail((256,256),LZ); z.writestr('Thumbnails/thumbnail.png',png(thumb))
    source_records.append({'id':name,'master':rel(path),'size':list(size),'sha256':sha(path),'layers':list(reversed(layer_paths))})
    return composite


def export(im, path, master, upstream, caps=(24,24,24,24), method='Composite selected face and rim, then Lanczos downsample at 2x.'):
    path = RUN / path; save(im, path)
    records.append({'runtime':rel(path),'master':rel(SRC/master),'upstream':[rel(PILOT/p) for p in upstream],
                    'method':method,'size':list(im.size),'mode':'RGBA8','alpha':'straight','colour':'embedded sRGB',
                    'slice_caps_LTRB':list(caps),'alpha_bbox':list(im.getbbox()),'decoded_bytes':im.width*im.height*4,'sha256':sha(path)})


def recolour(im, low, high):
    arr=np.asarray(im).copy(); lum=(arr[:,:,:3].astype(float)*[.2126,.7152,.0722]).sum(2)/255
    # Preserve the broad retained brush planes; no new brushwork is claimed.
    for ch in range(3): arr[:,:,ch]=np.clip(low[ch]+lum*(high[ch]-low[ch]),0,255)
    return Image.fromarray(arr)


def nine(im,size,caps,destcaps):
    w,h=size;l,t,r,b=caps;dl,dt,dr,db=destcaps
    xs=[0,l,im.width-r,im.width];ys=[0,t,im.height-b,im.height]
    xd=[0,dl,w-dr,w];yd=[0,dt,h-db,h];out=blank(size)
    for y in range(3):
        for x in range(3):
            patch=im.crop((xs[x],ys[y],xs[x+1],ys[y+1])).resize((xd[x+1]-xd[x],yd[y+1]-yd[y]),LZ)
            out.paste(patch,(xd[x],yd[y]))
    return out


def paint_packs():
    navy=load('painted-face-navy.png'); rim=load('painted-frame.png')
    faces={n:load('painted-face-'+n+'.png') for n in ['navy','amber','green','violet','turquoise']}
    base=[('Navy painted stone face',navy,True),('Sculpted gold and dark rim',rim,True)]
    board=ora('board_cells',(512,512),base)
    export(board.resize((256,256),LZ),'board/socket.png','board_cells.ora',['painted-face-navy.png','painted-frame.png'])
    frame=ora('ui_frames',(512,512),base)
    # Panel/dialog/inspector/navigation and pile share exactly the same texture.
    export(frame.resize((256,256),LZ),'frames/panel.png','ui_frames.ora',['painted-face-navy.png','painted-frame.png'])
    # Piles consume panel.png directly; do not recreate its retired duplicate.
    layers=[]
    for name,col in [('Damage','amber'),('Shield','green'),('Technique','violet'),('Mixed','turquoise')]:
        layers.append((name+' painted face',faces[col],name=='Damage'))
    layers += [('Gold rim',rim,True),('Shield green rim',load('painted-frame-green.png'),False),('Technique violet rim',load('painted-frame-violet.png'),False)]
    ora('rune_frames',(512,512),layers)
    for name,col,rimfile in [('damage','amber','painted-frame.png'),('shield','green','painted-frame-green.png'),('technique','violet','painted-frame-violet.png'),('mixed','turquoise','painted-frame.png')]:
        im=faces[col].copy();im.alpha_composite(load(rimfile))
        export(im.resize((256,256),LZ),f'runes/{name}.png','rune_frames.ora',[f'painted-face-{col}.png',rimfile])
    primary=[('Turquoise Cast face',load('cast-button-face.png'),True),('Pointed Cast gold rim',load('cast-button-rim.png'),True)]
    secondary=[('Navy secondary face',load('navy-panel-face.png'),False),('Navy secondary gold rim',load('navy-panel-rim.png'),False)]
    ora('button_frames',(1024,256),primary+secondary)
    for name,basefile,caps in [('primary','cast-button',(56,18,56,18)),('secondary','navy-panel',(38,20,38,20))]:
        im=load(basefile+'-face.png');im.alpha_composite(load(basefile+'-rim.png'))
        export(im.resize((512,128),LZ),f'buttons/{name}.png','button_frames.ora',[basefile+'-face.png',basefile+'-rim.png'],caps)
    track=nine(load('navy-panel-base.png'),(512,128),(76,40,76,40),(32,16,32,16))
    fillface=faces['navy'].crop((48,48,464,464)).resize((512,128),LZ)
    m=Image.new('L',(512,128));ImageDraw.Draw(m).polygon([(18,12),(494,12),(506,64),(494,116),(18,116),(6,64)],fill=255)
    fillface.putalpha(m)
    fills={name:recolour(fillface,lo,hi) for name,lo,hi in [
        ('health',(77,9,24),(255,87,74)),('energy',(0,53,81),(62,233,255)),('shield',(13,45,31),(105,232,123))]}
    ora('ui_bars',(512,128),[('Painted track with gold rim',track,True)]+[(n+' painted fill',im,False) for n,im in fills.items()])
    export(track.resize((256,64),LZ),'bars/track.png','ui_bars.ora',['navy-panel-base.png'],(16,8,16,8),'Nine-slice retained navy panel into 512x128 bar master, then half-size export.')
    for name,im in fills.items():export(im.resize((256,64),LZ),f'bars/{name}.png','ui_bars.ora',['painted-face-navy.png'],(16,8,16,8),'Recolour retained painted luminance; separate value-driven fill with polygon alpha.')
    for name in ['painted-frame','cast-button','navy-panel']:
        (SRC/'masks'/f'{name}-separation.svg').write_bytes((PILOT/f'{name}-mask.svg').read_bytes())


def svg_doc(body,w=128,h=128,title='RC-013 editable state'):
    return f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}"><title>{title}</title>{body}</svg>'
def svg_image(path):
    # Rasterization is a transient build step, not an extra source export.
    script="const sharp=require(process.argv[1]);sharp(process.argv[2]).withIccProfile('srgb').png().toBuffer().then(data=>process.stdout.write(data)).catch(e=>{console.error(e);process.exit(1)});"
    rendered=subprocess.run([str(NODE),'-e',script,str(SHARP),str(path)],check=True,capture_output=True)
    with Image.open(BytesIO(rendered.stdout)) as image:
        return image.convert('RGBA')


def state_packs():
    # Corner-only board cues reserve the central 20-unit channel at every edge.
    corner='M44 5H18L5 18V44 M84 5H110L123 18V44 M123 84V110L110 123H84 M44 123H18L5 110V84'
    inner='M41 12H21L12 21V41 M87 12H107L116 21V41 M116 87V107L107 116H87 M41 116H21L12 107V87'
    p=lambda d,c,w=3,extra='':f'<path d="{d}" fill="none" stroke="{c}" stroke-width="{w}" stroke-linejoin="round" {extra}/>'
    state={
      'focused':p(corner,'#fff1bd',3,'stroke-dasharray="5 3"'),
      'selected':p(inner,'#6ffff0')+p('M18 23L23 28L34 16','#fff1bd',4),
      'powered':p(inner,'#ffd86b',4)+p('M15 35L21 41L27 35 M93 107L99 113L105 107','#fff0bb',3),
      'invalid':p(inner,'#f2a080',3,'stroke-dasharray="8 4"')+p('M99 96L113 110M113 96L99 110','#ffe5c1',4),
      'unavailable':p(inner,'#b9c5ca',2)+ '<circle cx="25" cy="104" r="10" fill="#152237" stroke="#e2d3b4" stroke-width="2"/>'+p('M19 110L31 98','#e2d3b4',3),
      'eligible':p('M25 16V34M16 25H34','#96fff0',4),
      'protected':p('M17 17L33 33M33 17L17 33','#ffcea4',4),
      'upgrade': '<path d="M64 12L101 40L91 95L64 116L37 95L27 40Z" fill="#192837" stroke="#e9bf62" stroke-width="6"/>'+p('M44 67L64 43L84 67M64 43V88','#ffe4a0',7),
      'node_current':'<circle cx="64" cy="69" r="47" fill="none" stroke="#071d2b" stroke-width="12"/><circle cx="64" cy="69" r="46" fill="none" stroke="#67e9de" stroke-width="5"/><path d="M64 3L76 17L64 31L52 17Z" fill="#e4ffed" stroke="#176877" stroke-width="3"/>',
      'node_available':'<circle cx="64" cy="64" r="52" fill="none" stroke="#152337" stroke-width="10"/><circle cx="64" cy="64" r="51" fill="none" stroke="#f1b850" stroke-width="4"/><circle cx="64" cy="64" r="44" fill="none" stroke="#fff1ba" stroke-width="2"/>',
      'node_completed':'<circle cx="64" cy="64" r="46" fill="none" stroke="#122838" stroke-width="6"/><circle cx="98" cy="101" r="21" fill="#164630" stroke="#f7efd2" stroke-width="3"/>'+p('M86 101L95 110L111 91','#e8ffd5',5),
      'node_locked':'<circle cx="64" cy="64" r="46" fill="none" stroke="#596169" stroke-width="5" stroke-dasharray="16 7"/><path d="M91 97V88C91 72 111 72 111 88V97" fill="none" stroke="#182b37" stroke-width="5"/><rect x="85" y="94" width="32" height="25" rx="3" fill="#d6c49a" stroke="#182b37" stroke-width="4"/>'+p('M101 102V111','#182b37',4)
    }
    atlas_layers=[]
    for i,(name,body) in enumerate(state.items()):
        source=SRC/'states'/f'{name}.svg';source.write_text(svg_doc(body,title=f'RC-013 {name}; no live labels'),encoding='utf-8')
        layer=blank((512,384));layer.alpha_composite(svg_image(source),((i%4)*128,(i//4)*128))
        atlas_layers.append((name.replace('_',' ')+' vector raster preview',layer,True))
        # Keep every editable source layer, but only Map nodes have texture
        # consumers. The live StateLayer renders the other cues directly.
        if name.startswith('node_'):
            dst=RUN/'states'/source.name;dst.write_bytes(source.read_bytes())
            records.append({'runtime':rel(dst),'master':rel(SRC/'ui_state_overlays.ora'),'editable_vector':rel(source),'method':'Original deterministic SVG geometry; ORA has one isolated layer per state.','size':[128,128],'mode':'SVG','alpha':'transparent','sha256':sha(dst),'decoded_bytes':128*128*4,'scope':'Map nodes consumed dynamically by Ui.map_node; other state vectors remain editable source only.'})
    ora('ui_state_overlays',(512,384),atlas_layers)


# Custom hand-drawn serif letter paths. They are original geometry, not traced
# reference pixels and not converted font outlines. Curves remain editable.
LETTERS={
 'R':('M0 100V92L11 88V12L1 8V0H49Q78 0 78 27Q78 48 56 53L82 89L94 93V100H65L36 57H30V88L41 92V100ZM30 13V44H44Q57 44 57 28Q57 13 42 13Z',94),
 'U':('M0 0H43V8L33 12V67Q33 88 51 88Q72 88 72 65V12L59 8V0H96V8L86 12V64Q86 103 48 103Q11 103 11 68V12L0 8Z',96),
 'N':('M0 100V92L11 88V13L0 8V0H30L79 66V13L65 8V0H102V8L92 13V100H77L25 29V87L40 92V100Z',102),
 'E':('M0 100V92L11 88V12L0 8V0H81L83 28H73L64 13H32V42H54L60 31H68V67H60L54 56H32V87H65L77 67H87L82 100Z',87),
 'C':('M86 5L89 33H78Q69 11 52 11Q29 11 29 49Q29 89 54 89Q73 89 82 67L93 72Q84 103 51 103Q5 103 5 52Q5 -3 54 -3Q72 -3 86 5Z',97),
 'A':('M0 100V92L10 87L41 0H59L91 88L102 92V100H56V92L67 89L61 72H29L24 89L35 92V100ZM34 58H56L45 26Z',102),
 'S':('M76 5L80 31H69Q61 11 43 11Q25 11 25 24Q25 34 49 43Q82 54 82 73Q82 104 45 104Q22 104 6 96L3 66H14Q23 91 44 91Q63 91 63 78Q63 67 38 59Q5 48 5 29Q5 -3 44 -3Q62 -3 76 5Z',88),
 'T':('M1 0H98L101 30H90L79 13H61V87L75 92V100H26V92L40 87V13H21L10 30H0Z',101)
}


def wordmark():
    w,h=1200,384
    defs='''<defs>
      <linearGradient id="stone" x2=".25" y2="1"><stop stop-color="#263c58"/><stop offset=".5" stop-color="#111f32"/><stop offset="1" stop-color="#080e19"/></linearGradient>
      <linearGradient id="gold" x2=".1" y2="1"><stop stop-color="#fff1a0"/><stop offset=".2" stop-color="#e7b544"/><stop offset=".55" stop-color="#d79329"/><stop offset=".7" stop-color="#f4ca57"/><stop offset="1" stop-color="#9d581c"/></linearGradient>
      <linearGradient id="facet" x2="1" y2="1"><stop stop-color="#fff2b2"/><stop offset=".35" stop-color="#e3ac42"/><stop offset="1" stop-color="#70421c"/></linearGradient>
    </defs>'''
    stonepath='M24 112L63 97L60 70L146 85L169 58L239 86L415 71L466 47L516 61L552 33L570 57L601 8L630 58L650 39L685 66L735 46L783 75L963 84L1006 62L1042 84L1134 74L1130 105L1176 115L1164 245L1183 265L1140 281L1135 308L961 285L875 311L758 302L651 340L601 376L548 340L442 308L315 315L233 288L69 305L64 277L22 261L37 225Z'
    backing=f'<path d="{stonepath}" fill="url(#stone)" stroke="#050b12" stroke-width="10" stroke-linejoin="round"/>'
    # Original facets and crevices add sculpted stone without sampling an image.
    backing += '<path d="M63 97L81 125L146 85M169 58L187 108L239 86M415 71L440 112L516 61M552 33L565 103L601 8L609 98L650 39M685 66L721 106L783 75M963 84L1000 109L1006 62M1042 84L1103 122L1134 74M37 225L89 249L64 277M1130 105L1120 149L1176 115M1135 308L1091 263L1140 281M651 340L641 304L601 376L577 316L548 340" fill="none" stroke="#344359" stroke-width="4"/>'
    backing += '<path d="M110 117L172 137L208 108L337 113L356 91M829 102L895 125L941 105M136 270L218 251L278 272M856 278L916 250L1059 266M456 308L483 270M726 286L758 302" fill="none" stroke="#080d17" stroke-width="5"/>'
    trim='<path d="M76 122L459 98L546 79M655 79L741 101L1122 120M85 268L405 270L480 296M721 296L796 270L1116 267" fill="none" stroke="#050d18" stroke-width="12"/><path d="M76 118L459 94L546 75M655 75L741 97L1122 116M85 264L405 266L480 292M721 292L796 266L1116 263" fill="none" stroke="url(#facet)" stroke-width="6"/>'
    trim += '<path d="M600 44L622 78L600 108L578 78Z" fill="url(#gold)" stroke="#402817" stroke-width="5"/><path d="M600 47V101L583 78Z" fill="#ffe6a0" opacity=".7"/>'
    glyphs=[];x=75
    for i,ch in enumerate('RUNE CAST'):
        if ch==' ':x+=36;continue
        d,advance=LETTERS[ch];sc=1.26 if ch in ['R','C'] else 1.05
        y=123 if ch in ['R','C'] else 144
        glyphs.append((ch,d,x,y,sc));x+=advance*sc+7
    # Center precisely, keeping custom capital height contrast.
    shift=(w-(x-75-7))/2-75
    letters=''.join(f'<path id="letter-{i}-{ch}" transform="translate({x+shift:.3f} {y}) scale({sc})" d="{d}" fill-rule="evenodd"/>' for i,(ch,d,x,y,sc) in enumerate(glyphs))
    textdefs='<defs><g id="lettering">'+letters+'</g><clipPath id="letterClip">'+letters.replace('id="letter-','id="clip-letter-')+'</clipPath></defs>'
    shadow=textdefs+'<use href="#lettering" transform="translate(2 8)" fill="#050b13" stroke="#050b13" stroke-width="13" stroke-linejoin="round"/>'
    bevel=textdefs+'<use href="#lettering" fill="url(#facet)" stroke="#452918" stroke-width="8" stroke-linejoin="round"/><use href="#lettering" fill="url(#gold)" stroke="#ffe6a0" stroke-width="2.7" stroke-linejoin="round"/>'
    facets=textdefs+'<g clip-path="url(#letterClip)"><path d="M0 164L1200 135V165L0 215Z" fill="#fff0a5" opacity=".2"/><path d="M0 232L1200 209V228L0 263Z" fill="#693916" opacity=".2"/>'
    for x in [135,294,439,722,877,1015]:
        facets+=f'<path d="M{x} 135L{x-7} 159L{x+3} 174L{x-6} 198M{x-7} 159L{x-20} 162" fill="none" stroke="#70441e" stroke-width="1.7" opacity=".6"/>'
    facets+='</g>'
    medallions=''
    for cx,cy,rx,ry in [(468,300,32,37),(600,307,48,58),(732,300,32,37)]:
        medallions+=f'<path d="M{cx} {cy-ry}L{cx+rx} {cy}L{cx} {cy+ry}L{cx-rx} {cy}Z" fill="#0c1828" stroke="#090d15" stroke-width="13"/><path d="M{cx} {cy-ry}L{cx+rx} {cy}L{cx} {cy+ry}L{cx-rx} {cy}Z" fill="#362218" stroke="url(#facet)" stroke-width="6"/>'
        medallions+=f'<path d="M{cx} {cy-ry+13}L{cx+rx-13} {cy}L{cx} {cy+ry-13}L{cx-rx+13} {cy}Z" fill="url(#gold)"/><path d="M{cx} {cy-ry+13}V{cy+ry-13}L{cx-rx+13} {cy}Z" fill="#f9d26c"/>'
    layers=[('Indigo sculpted stone backing',backing),('Gold architecture and crest',trim),('Letter dark extrusion',shadow),('Custom gold serif lettering',bevel),('Letter facets and engraved fractures',facets),('Three faceted identity diamonds',medallions)]
    layer_images=[]
    master_size=(1280,480)
    for name,body in layers:
        file=SRC/'wordmark-layers'/(name.lower().replace(' ','-')+'.svg');file.parent.mkdir(exist_ok=True)
        file.write_text(svg_doc(defs+'<g transform="translate(40 48)">'+body+'</g>',*master_size,name),encoding='utf-8')
        layer_images.append((name,svg_image(file),True))
    # Combined editable source has all six vector groups and unique shared glyphs.
    combined=defs+textdefs+''.join(f'<g id="{i}-{name.lower().replace(" ","-")}">{body.replace(textdefs,"")}</g>' for i,(name,body) in enumerate(layers))
    source=SRC/'wordmark.svg';source.write_text(svg_doc('<g transform="translate(40 48)">'+combined+'</g>',*master_size,'Rune Cast — custom editable serif lettering and stone identity'),encoding='utf-8')
    im=ora('wordmark',master_size,layer_images)
    export(im.resize((1024,384),LZ),'wordmark.png','wordmark.ora',[],(0,0,0,0),'Composite six original vector-defined parts; transparent 1280x480 master reduced proportionally to 1024x384, with at least32px clear outer padding.')
    records[-1]['editable_vector']=rel(source);records[-1]['lettering']='Original eight editable hand-drawn serif letter paths, large R/C capitals; no font binary or traced reference pixels.'
    preview=Image.new('RGBA',(1120,820),'#101c2d');preview.alpha_composite(im.resize((1024,384),LZ),(48,12))
    preview.alpha_composite(im.resize((640,240),LZ),(240,406));preview.alpha_composite(im.resize((256,96),LZ),(50,692))
    save(preview,SRC/'wordmark-preview.png')


def main():
    for p in [SRC,RUN,SRC/'layers',SRC/'masks',SRC/'states',RUN/'states']:p.mkdir(parents=True,exist_ok=True)
    paint_packs();state_packs();wordmark()
    input_names=sorted({p for item in records for p in item.get('upstream',[])})
    upstream=[{'path':p,'sha256':sha(ROOT/p)} for p in input_names]
    provenance={'schema':1,'task':'RC-013','created':'2026-10-11','status':'Reference-guided production source and import candidates; approval and device integration separate.',
      'builder':'tools/build_ui_assets.py','paint_origin':{'revision':'r004','canonical_retained_copy':'source-assets/pilot/revisions/r006/ui/',
      'raw_generation_record':'source-assets/pilot/revisions/r004/raw/generation-record.json','tool':'built-in image_gen.imagegen','model':None,'seed':None,
      'reference_actually_used':'output/imagegen/approved/combat-final.png','current_composition_target':'output/imagegen/approved/combat-final-v2-clean-board.png',
      'reference_pixels_used':False,'new_generation':False,'licence_status':'unresolved','rights_note':'Retained paint inherits the explicit unresolved provenance/rights status from r004/r006. This promotion does not imply clearance.'},
      'original_vector_work':{'creator':'Codex for Rune Cast, RC-013','method':'Original deterministic geometry authored for this task. No third-party traced art, font outlines, linked art, or image generation for wordmark/state vectors.','wordmark_font':'None; custom hand-drawn serif paths. Live UI continues to use RC-012 Noto Serif.'},
      'import_contract':{'compression':'lossless','mipmaps':False,'filter':'linear','repeat':'disabled','png_mode':'RGBA8 with straight alpha and sRGB','svg_scale':1},
      'sources':source_records,'exports':records,'retained_inputs':upstream,
      'unique_decoded_rgba8_bytes':sum(v for _,v in {r['sha256']:r['decoded_bytes'] for r in records}.items()),
      'all_export_decoded_rgba8_bytes':sum(r['decoded_bytes'] for r in records),
      'sharing':'Piles share panel.png directly; the unused pile.png alias is retired. Only Map node state vectors are exported; other cues use the live StateLayer. Font atlases and engine buffers excluded.',
      'editing_limit':'Retained brush strokes are flattened within complementary face/rim regions. ORAs and layer PNGs support repaint/recolour/replacement; they do not fabricate brush history. SVG wordmark layers remain fully geometric.'}
    (SRC/'source-export-map.json').write_text(json.dumps(provenance,indent=2)+'\n',encoding='utf-8')
    print(json.dumps({'masters':len(source_records),'exports':len(records),'decoded_bytes':provenance['all_export_decoded_rgba8_bytes'],'metadata':rel(SRC/'source-export-map.json')}))


def validate(report):
    """Focused real failure checks for source integrity, export mapping and alpha."""
    meta=json.loads((SRC/'source-export-map.json').read_text(encoding='utf-8'))
    checks=[]
    def check(name,ok,details=''):checks.append({'check':name,'pass':bool(ok),'details':details})
    for source in meta['sources']:
        path=ROOT/source['master'];check(source['id']+' recorded master hash',sha(path)==source['sha256'])
        with zipfile.ZipFile(path) as z:
            check(source['id']+' ORA mimetype first and stored',z.namelist()[0]=='mimetype' and z.getinfo('mimetype').compress_type==zipfile.ZIP_STORED and z.read('mimetype')==b'image/openraster')
            tree=ET.fromstring(z.read('stack.xml'));size=(int(tree.attrib['w']),int(tree.attrib['h']))
            composite=blank(size);layers=list(tree.find('stack'));hashes=[]
            for layer in reversed(layers):
                im=Image.open(BytesIO(z.read(layer.attrib['src']))).convert('RGBA')
                check(source['id']+'/'+layer.attrib['name']+' canvas and nonempty alpha',im.size==size and im.getchannel('A').getbbox() is not None)
                hashes.append(hashlib.sha256(im.tobytes()).hexdigest())
                if layer.attrib.get('visibility')!='hidden':composite.alpha_composite(im)
            stored=Image.open(BytesIO(z.read('mergedimage.png'))).convert('RGBA')
            check(source['id']+' meaningful distinct layers',len(layers)>=2 and len(set(hashes))==len(hashes),f'{len(layers)} distinct editable parts')
            check(source['id']+' default visible layers exactly reconstruct merged PNG',composite.tobytes()==stored.tobytes())
        for layer in source['layers']:
            im=Image.open(ROOT/layer['layer']).convert('RGBA');mask=Image.open(ROOT/layer['mask']).convert('L')
            check(source['id']+'/'+layer['name']+' external layer and mask',sha(ROOT/layer['layer'])==layer['sha256'] and im.getchannel('A').tobytes()==mask.tobytes())
    for exp in meta['exports']:
        path=ROOT/exp['runtime'];check(exp['runtime']+' hash',sha(path)==exp['sha256'])
        if path.suffix=='.png':
            im=Image.open(path)
            check(exp['runtime']+' RGBA dimensions and embedded colour profile',im.mode=='RGBA' and list(im.size)==exp['size'] and len(im.info.get('icc_profile',b''))>0)
            alpha=im.getchannel('A');check(exp['runtime']+' transparent and opaque coverage',alpha.getextrema()==(0,255),str(alpha.getextrema()))
            l,t,r,b=exp['slice_caps_LTRB'];check(exp['runtime']+' slice center remains nonempty',l+r<im.width and t+b<im.height)
        else:
            tree=ET.parse(path);check(exp['runtime']+' SVG no embedded art or fonts',not any(e.tag.endswith(('image','text')) for e in tree.iter()))
    for dep in meta['retained_inputs']:check(dep['path']+' retained source hash',sha(ROOT/dep['path'])==dep['sha256'])
    retained_layer_inputs={
      'board_cells':{'Navy painted stone face':'painted-face-navy.png','Sculpted gold and dark rim':'painted-frame.png'},
      'ui_frames':{'Navy painted stone face':'painted-face-navy.png','Sculpted gold and dark rim':'painted-frame.png'},
      'button_frames':{'Turquoise Cast face':'cast-button-face.png','Pointed Cast gold rim':'cast-button-rim.png','Navy secondary face':'navy-panel-face.png','Navy secondary gold rim':'navy-panel-rim.png'},
      'rune_frames':{'Damage painted face':'painted-face-amber.png','Shield painted face':'painted-face-green.png','Technique painted face':'painted-face-violet.png','Mixed painted face':'painted-face-turquoise.png','Gold rim':'painted-frame.png','Shield green rim':'painted-frame-green.png','Technique violet rim':'painted-frame-violet.png'}}
    for source in meta['sources']:
        for layer in source['layers']:
            retained=retained_layer_inputs.get(source['id'],{}).get(layer['name'])
            if retained:
                actual=Image.open(ROOT/layer['layer']).convert('RGBA');canonical=load(retained)
                check(source['id']+'/'+layer['name']+' exactly preserves retained painted pixels',actual.tobytes()==canonical.tobytes())
    for file in [SRC/'wordmark.svg',*(SRC/'wordmark-layers').glob('*.svg'),*(SRC/'states').glob('*.svg')]:
        tree=ET.parse(file);links=[v for e in tree.iter() for k,v in e.attrib.items() if k.endswith('href')]
        check(rel(file)+' vector contains only internal references',all(v.startswith('#') for v in links) and not any(e.tag.endswith(('image','text')) for e in tree.iter()))
    direct=svg_image(SRC/'wordmark.svg')
    with zipfile.ZipFile(SRC/'wordmark.ora') as z:layered=Image.open(BytesIO(z.read('mergedimage.png'))).convert('RGBA')
    difference=np.abs(np.asarray(direct).astype(int)-np.asarray(layered).astype(int))
    check('editable wordmark SVG matches layered raster within alpha rounding',difference.max()<=2,{'max_channel_difference':int(difference.max()),'mean_channel_difference':float(difference.mean())})
    expected={
      'board/socket.png':('board_cells',None),'frames/panel.png':('ui_frames',None),
      'runes/damage.png':('rune_frames',['Damage painted face','Gold rim']),
      'runes/shield.png':('rune_frames',['Shield painted face','Shield green rim']),
      'runes/technique.png':('rune_frames',['Technique painted face','Technique violet rim']),
      'runes/mixed.png':('rune_frames',['Mixed painted face','Gold rim']),
      'buttons/primary.png':('button_frames',['Turquoise Cast face','Pointed Cast gold rim']),
      'buttons/secondary.png':('button_frames',['Navy secondary face','Navy secondary gold rim']),
      'bars/track.png':('ui_bars',['Painted track with gold rim']),
      'bars/health.png':('ui_bars',['health painted fill']),'bars/energy.png':('ui_bars',['energy painted fill']),'bars/shield.png':('ui_bars',['shield painted fill']),
      'wordmark.png':('wordmark',None)}
    for runtime,(master,selection) in expected.items():
        with zipfile.ZipFile(SRC/(master+'.ora')) as z:
            tree=ET.fromstring(z.read('stack.xml'));comp=blank((int(tree.attrib['w']),int(tree.attrib['h'])))
            for layer in reversed(list(tree.find('stack'))):
                visible=layer.attrib['name'] in selection if selection else layer.attrib.get('visibility')!='hidden'
                if visible:comp.alpha_composite(Image.open(BytesIO(z.read(layer.attrib['src']))).convert('RGBA'))
        actual=Image.open(RUN/runtime).convert('RGBA');wanted=comp.resize(actual.size,LZ)
        check(runtime+' exactly derives from named ORA layers',wanted.tobytes()==actual.tobytes(),selection or 'default visible stack')
    # Read editable master layers directly. The former per-state PNGs were
    # redundant build intermediates and are not source-validation inputs.
    with zipfile.ZipFile(SRC/'ui_state_overlays.ora') as z:
        state_layers=list(ET.fromstring(z.read('stack.xml')).find('stack'))
        for index,state in enumerate(['focused','selected','powered','invalid','unavailable','eligible','protected']):
            layer=next(item for item in state_layers if item.attrib['name']==state+' vector raster preview')
            origin=((index%4)*128,(index//4)*128)
            im=Image.open(BytesIO(z.read(layer.attrib['src']))).getchannel('A').crop((origin[0],origin[1],origin[0]+128,origin[1]+128))
            ports=[(54,0,74,16),(112,54,128,74),(54,112,74,128),(0,54,16,74)]
            check(state+' unobstructed exact edge-port channels',all(im.crop(box).getextrema()==(0,0) for box in ports))
    im=Image.open(RUN/'wordmark.png');x1,y1,x2,y2=im.getbbox();padding=[x1,y1,im.width-x2,im.height-y2]
    check('wordmark transparent outer padding >=32px',min(padding)>=32,padding)
    for retired in RETIRED_RUNTIME_FILES:
        check(retired+' unused runtime export remains retired',not (RUN/retired).exists() and not (RUN/(retired+'.import')).exists())
    components=(ROOT/'scenes/ui/theme/components.gd').read_text(encoding='utf-8-sig')
    pile_constructor=components.split('static func pile(',1)[1].split('\nstatic func ',1)[0]
    check('pile constructor shares the active panel texture','res://assets/ui/frames/panel.png' in pile_constructor)
    result={'task':'RC-013','date':'2026-10-12','pass':all(c['pass'] for c in checks),'checks':checks,
            'summary':{'total':len(checks),'passed':sum(c['pass'] for c in checks),'masters':len(meta['sources']),'runtime_exports':len(meta['exports']),
                       'all_exports_RGBA8_bytes':meta['all_export_decoded_rgba8_bytes'],'unique_pixels_RGBA8_bytes':meta['unique_decoded_rgba8_bytes'],
                       'limitation':'Dimensional estimate excludes dynamic font atlases, engine buffers and caches; shared pixel hashes do not guarantee separate Texture2D resources deduplicate in Godot.'}}
    report=ROOT/report;report.parent.mkdir(parents=True,exist_ok=True);report.write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8')
    print(json.dumps(result['summary']));print('PASS' if result['pass'] else 'FAIL')
    if not result['pass']:raise SystemExit(1)


if __name__=='__main__':
    parser=argparse.ArgumentParser();parser.add_argument('--validate',action='store_true');parser.add_argument('--report',default='output/qa/rc-013/source-validation.json');args=parser.parse_args()
    if args.validate:validate(args.report)
    else:main()
