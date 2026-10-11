"""Rebuild the selected r004 tile/button painted sources after pilot cleanup.

The original paint separation masks, color variants and ORA assembly are retained.
Only the three selected raw paintings in this revision are inputs. This recipe
has no dependency on rejected r002 UI materials or an obsolete gameplay layout.
The current gameplay composition is rebuilt by ../r006/build_review.py.

An explicit output directory is required. Canonical retained r006 assets are not
silently overwritten. Regenerated pixels can be reviewed before replacing them.
"""
from pathlib import Path
from PIL import Image,ImageDraw,ImageOps,ImageChops,ImageCms
from html import escape
from io import BytesIO
import argparse,json,hashlib,os,xml.etree.ElementTree as ET,zipfile

P=Path(__file__).resolve().parent
UI=None
ICC=ImageCms.ImageCmsProfile(ImageCms.createProfile('sRGB')).tobytes()

def raw_ref(name):
    return os.path.relpath(P/'raw'/name,UI).replace(os.sep,'/')

def document(w,h,s,title):
    return f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}"><title>{escape(title)}</title><metadata>Selected r004 painted-source separation recipe. Original generation attribution is unchanged. No gameplay composition or acceptance claim.</metadata>'+s+'</svg>'


def poly(points,fill,stroke='none',sw=1):
    pts=' '.join(f'{x:.3f},{y:.3f}' for x,y in points) if not isinstance(points,str) else points
    return f'<polygon points="{pts}" fill="{fill}" stroke="{stroke}" stroke-width="{sw}" stroke-linejoin="round"/>'

def prepare_painted_buttons():
    for rawname,name,points in [
        ('navy-panel','navy-panel',[(52,40),(972,40),(994,88),(994,180),(972,216),(52,216),(28,181),(28,86)]),
        ('cast-button','cast-button',[(101,30),(923,30),(974,128),(923,226),(101,226),(49,128)])]:
        raw=Image.open(P/'raw'/f'{rawname}.png').convert('RGBA');a=raw.getchannel('A').point(lambda v:255 if v>170 else 0);crop=a.getbbox()
        im=raw.crop(crop).resize((1024,256),Image.Resampling.LANCZOS)
        mask=Image.new('L',im.size);ImageDraw.Draw(mask).polygon(points,fill=255)
        face=im.copy();face.putalpha(ImageChops.multiply(im.getchannel('A'),mask))
        rim=im.copy();rim.putalpha(ImageChops.multiply(im.getchannel('A'),ImageOps.invert(mask)))
        for suffix,part in [('base',im),('face',face),('rim',rim)]:part.save(UI/f'{name}-{suffix}.png',icc_profile=ICC)
        make_ora(UI/f'{name}.ora',(1024,256),[('Generated painted face with transparent complement',face,True),('Generated painted gold and dark rim',rim,True)])
        (UI/f'{name}-mask.svg').write_text(document(1024,256,poly(points,'white'),'Editable paint separation mask; rim uses complement'),encoding='utf-8')
        (UI/f'{name}-metadata.json').write_text(json.dumps({'raw':raw_ref(f'{rawname}.png'),'prompt':raw_ref(f'{rawname}.prompt.txt'),'crop_bbox':list(crop),'master':[1024,256],'source_method':'Genuine complementary face/rim separation of generated artwork; pixels not duplicated. Detailed strokes are flattened paint.','raw_sha256':hashlib.sha256((P/'raw'/f'{rawname}.png').read_bytes()).hexdigest(),'status':'r004 candidate; no approval inferred'},indent=2),encoding='utf-8')
    # Use complete generated material under general UI, preserving depth variation.
    navy=Image.open(UI/'navy-panel-face.png').crop((85,46,940,211)).convert('RGB');navy.save(UI/'materials/navy.png',icc_profile=ICC)

def prepare_painted_frame():
    raw=Image.open(P/'raw/empty-tile.png').convert('RGBA')
    a=raw.getchannel('A').point(lambda v:255 if v>170 else 0)
    crop=a.getbbox();im=raw.crop(crop).resize((512,512),Image.Resampling.LANCZOS)
    # Genuine complementary masks, traced around the inward edge of the frame.
    cut=Image.new('L',(512,512));d=ImageDraw.Draw(cut)
    pts=[(75,39),(435,39),(475,81),(475,427),(434,472),(77,472),(36,429),(36,80)]
    d.polygon(pts,fill=255)
    face=im.copy();face.putalpha(ImageChops.multiply(im.getchannel('A'),cut))
    frame=im.copy();frame.putalpha(ImageChops.multiply(im.getchannel('A'),ImageOps.invert(cut)))
    im.save(UI/'painted-tile-source.png',icc_profile=ICC);frame.save(UI/'painted-frame.png',icc_profile=ICC)
    face.save(UI/'painted-face.png',icc_profile=ICC)
    gray=ImageOps.grayscale(im);low,high=gray.crop((75,75,436,436)).getextrema()
    tone=gray.point(lambda v:max(0,min(255,round((v-low)*255/max(1,high-low)))))
    for name,lo,hi in [('navy','#142237','#3e5271'),('amber','#211309','#744611'),('turquoise','#05282b','#0c6255'),('green','#0a260f','#2e6826'),('violet','#1a1031','#572675')]:
        tint=ImageOps.colorize(tone,lo,hi).convert('RGBA');tint.putalpha(face.getchannel('A'))
        tint.save(UI/f'painted-face-{name}.png',icc_profile=ICC)
        merged=tint.copy();merged.alpha_composite(frame);merged.resize((256,256),Image.Resampling.LANCZOS).save(UI/f'tile-{name}.png',icc_profile=ICC)
        # Painted face center reused as a quiet textured material, from generated art only.
        tint.crop((75,75,436,436)).convert('RGB').save(UI/'materials'/f'{name}.png',icc_profile=ICC)
        if name=='navy':tint.crop((75,75,436,436)).convert('RGB').save(UI/'materials/board-stone.png',icc_profile=ICC)
    for name,lo,hi in [('green','#082812','#a9ef72'),('violet','#21102c','#d18bf7')]:
        colored=ImageOps.colorize(ImageOps.grayscale(frame),lo,hi).convert('RGBA');colored.putalpha(frame.getchannel('A'));colored.save(UI/f'painted-frame-{name}.png',icc_profile=ICC)
    layers=[('Original painted stone face',face,False)]
    for name in ['amber','turquoise','green','violet']:
        layers.append((f'{name} material variant',Image.open(UI/f'painted-face-{name}.png').convert('RGBA'),name=='amber'))
    layers.append(('Painted sculpted gold and dark rim',frame,True))
    make_ora(UI/'painted_tile.ora',(512,512),layers)
    (UI/'painted-frame-mask.svg').write_text(document(512,512,poly(pts,'white'),'Editable inner-face separation mask; gold rim uses complement'),encoding='utf-8')
    meta={'raw':raw_ref('empty-tile.png'),'prompt':raw_ref('empty-tile.prompt.txt'),'crop_alpha_threshold':170,'crop_bbox':list(crop),'master':[512,512],'export':[256,256],'separation':'Complementary interior-face and gold/dark-rim masks; alternate material recolors hidden. No duplicated full composite layers. Underlying strokes remain flattened generated paint.','raw_sha256':hashlib.sha256((P/'raw/empty-tile.png').read_bytes()).hexdigest(),'reference_pixels_used':False,'nine_slice_proposal':'Painted bevel requires24exportpixel caps for this candidate;16px draft is insufficient. Responsive vector composition used where dimensions vary. Owner acceptance not inferred.'}
    (UI/'painted-frame-metadata.json').write_text(json.dumps(meta,indent=2),encoding='utf-8')

def make_ora(dest,size,layers):
    tree=ET.Element('image',{'w':str(size[0]),'h':str(size[1]),'name':'r004 UI painted construction','version':'0.0.3'});stack=ET.SubElement(tree,'stack')
    merge=Image.new('RGBA',size)
    for name,im,vis in layers:
        if vis:merge.alpha_composite(im)
    with zipfile.ZipFile(dest,'w') as z:
        z.writestr('mimetype','image/openraster',compress_type=zipfile.ZIP_STORED)
        for i,(name,im,vis) in reversed(list(enumerate(layers))):
            src=f'data/layer{i:02}.png';b=BytesIO();im.save(b,format='PNG',icc_profile=ICC);z.writestr(src,b.getvalue())
            ET.SubElement(stack,'layer',{'name':name,'src':src,'x':'0','y':'0','opacity':'1','visibility':'visible' if vis else 'hidden','composite-op':'svg:src-over'})
        z.writestr('stack.xml',ET.tostring(tree));b=BytesIO();merge.save(b,format='PNG',icc_profile=ICC);z.writestr('mergedimage.png',b.getvalue())

def build(output_dir):
    global UI
    UI=Path(output_dir).resolve()
    UI.mkdir(parents=True,exist_ok=True)
    (UI/'materials').mkdir(exist_ok=True)
    prepare_painted_frame()
    prepare_painted_buttons()
    exports=UI/'exports';exports.mkdir(exist_ok=True)
    for src,dst,size in [('tile-amber.png','spark_tile.png',(256,256)),('cast-button-base.png','button_primary.png',(512,128)),('navy-panel-base.png','button_secondary.png',(512,128))]:
        Image.open(UI/src).convert('RGBA').resize(size,Image.Resampling.LANCZOS).save(exports/dst,icc_profile=ICC)
    print('Selected paint sources rebuilt in '+str(UI))

if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output-dir',type=Path,required=True,help='Explicit destination for rebuilt layers, ORAs and exports')
    build(parser.parse_args().output_dir)
