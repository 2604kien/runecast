"""RC-011 r002 candidate. Original editable geometry over retained generated paint.
No gameplay or r001 files are changed. Call render_button/render_tile for reviews.
"""
from pathlib import Path
from io import BytesIO
import json, zipfile, hashlib, importlib.util
import xml.etree.ElementTree as ET
from PIL import Image, ImageDraw, ImageOps, ImageFilter, ImageEnhance, ImageFont, ImageCms

HERE=Path(__file__).resolve().parent
PILOT=HERE.parents[2]
PROJECT=HERE.parents[4]
OUT=PROJECT/'output/art/rc-011/r002/ui'
ICC=ImageCms.ImageCmsProfile(ImageCms.createProfile('sRGB')).tobytes()
R=Image.Resampling.LANCZOS
spec=importlib.util.spec_from_file_location('r001_materials',PILOT/'button/build_materials.py')
old=importlib.util.module_from_spec(spec);spec.loader.exec_module(old)

def save(im,path):
    Path(path).parent.mkdir(parents=True,exist_ok=True)
    im.save(path,icc_profile=ICC)

def poly(w,h,inset,cut,shape='box'):
    if shape=='cast':
        return [(inset+cut,inset),(w-inset-cut,inset),(w-inset,h/2),
                (w-inset-cut,h-inset),(inset+cut,h-inset),(inset,h/2)]
    return [(inset+cut,inset),(w-inset-cut,inset),(w-inset,inset+cut),
            (w-inset,h-inset-cut),(w-inset-cut,h-inset),(inset+cut,h-inset),
            (inset,h-inset-cut),(inset,inset+cut)]

def materials():
    folder=HERE/'materials';folder.mkdir(parents=True,exist_ok=True)
    navy=Image.open(PILOT/'spark_tile/raw/navy_material_r001.png').convert('RGB')
    teal=Image.open(PILOT/'button/raw/turquoise_material_r001.png').convert('RGB')
    # Suppress the icy, high-contrast cracks of r001. No reference image is sampled.
    navy=ImageOps.fit(navy,(512,512),method=R).filter(ImageFilter.GaussianBlur(1.3))
    navy=Image.blend(navy,Image.new('RGB',navy.size,'#26374d'),.50)
    teal=ImageOps.fit(teal,(1024,256),method=R).filter(ImageFilter.GaussianBlur(1.4))
    teal=Image.blend(teal,Image.new('RGB',teal.size,'#05646a'),.56)
    amber=ImageOps.colorize(ImageOps.autocontrast(ImageOps.grayscale(navy),cutoff=1),black='#24150b',white='#78501d')
    amber=Image.blend(amber,Image.new('RGB',amber.size,'#44270d'),.38)
    for name,im in [('navy',navy),('turquoise',teal),('amber',amber)]:save(im,folder/f'{name}.png')

def construction(size,material='navy',shape='box',u=1,role='button'):
    """Vector layers and one paint layer; u is export pixels per logical pixel."""
    w,h=size
    tile=role=='tile'
    bevel=4.8*u if tile else 5.6*u
    outside=1.2*u if tile else 1.9*u
    cut=5.4*u if tile else (max(12*u,h*.30) if shape=='cast' else 9.5*u)
    inner=outside+bevel+1.3*u
    po=poly(w,h,outside,cut,shape)
    innercut=max(.25*u,cut-2*(inner-outside)) if shape!='cast' else max(1.5*u,cut-2.5*u)
    pi=poly(w,h,inner,innercut,shape)
    if shape=='cast':
        pi[2]=(w-outside-13*u,h/2);pi[-1]=(outside+13*u,h/2)
    # Layer tuple: name, primitive, points, fill, stroke, stroke width.
    ops=[('Dark sculpted silhouette','polygon',poly(w,h,.25*u,cut+.4*u,shape),'#080e19',None,0),
         ('Deep outer gold shadow','polygon',po,'#4b301a',None,0),
         ('Painted inset material','paint',pi,material,None,0)]
    colors=['#e4b963','#c99549','#815323','#93602b','#b9823c','#d3a35b','#e6bd73','#f0c979'] if shape!='cast' else ['#d8a454','#b67b37','#765024','#ab7739','#d0a161','#ebbc70']
    for i in range(len(po)):
        j=(i+1)%len(po)
        ops.append((f'Gold bevel facet {i+1}','polygon',[po[i],po[j],pi[j],pi[i]],colors[i],None,0))
    # Bright slim outer lip, dark inner cut and colored material lip are distinct.
    upper=[po[-1],po[0],po[1],po[2]] if shape!='cast' else [po[-1],po[0],po[1]]
    ops.append(('Upper gold catching edge','line',upper,None,'#f7d993',1.5*u))
    lower=[po[2],po[3],po[4],po[5]] if shape!='cast' else [po[2],po[3],po[4]]
    ops.append(('Lower bevel shadow','line',lower,None,'#523620',1.7*u))
    ops.append(('Dark recessed cut','line',pi+[pi[0]],None,'#061822',2.8*u))
    pj=poly(w,h,inner+(.2*u if tile else .4*u),innercut,shape)
    if shape=='cast':
        pj[2]=(w-outside-14*u,h/2);pj[-1]=(outside+14*u,h/2)
    rim={'navy':'#59718d','turquoise':'#22ccc3','amber':'#ad742b'}[material]
    ops.append(('Matte inset color edge','line',pj+[pj[0]],None,rim,(.8 if tile else 1.1)*u))
    # Sculpted corners are broad gold wedges and stay within corner cap areas.
    if shape!='cast':
        corner=[(outside+cut,outside),(outside+cut+.4*u,outside+.6*u),
                (inner,inner),(outside+.5*u,outside+cut)]
        for ix,iy,c in [(0,0,'#d2a05a'),(1,0,'#b78643'),(0,1,'#b8823e'),(1,1,'#9b672f')]:
            points=[(w-x if ix else x,h-y if iy else y) for x,y in corner]
            ops.append(('Sculpted corner wedge','polygon',points,c,'#59401e',.55*u))
    else:
        # Substantial gold end plates are the characteristic approved Cast profile.
        for flipped in [False,True]:
            p=[(outside+cut,outside+1.0*u),(outside+cut+4*u,inner),
               (outside+13*u,h/2),(outside+cut+4*u,h-inner),
               (outside+cut,h-outside-1*u),(outside,h/2)]
            if flipped:p=[(w-x,y) for x,y in p]
            ops.append(('Cast sculpted gold end plate','polygon',p,'#ab7637','#38251a',1.0*u))
            q=[(outside+cut,outside+1.5*u),(outside+cut+2*u,inner),
               (outside+13*u,h/2),(outside+2*u,h/2)]
            if flipped:q=[(w-x,y) for x,y in q]
            ops.append(('Cast end plate light plane','polygon',q,'#d99f53',None,0))
    return ops

def render_layers(size,ops):
    aa=4;wh=(size[0]*aa,size[1]*aa);layers=[]
    for name,kind,points,fill,stroke,width in ops:
        layer=Image.new('RGBA',wh);d=ImageDraw.Draw(layer)
        pp=[(round(x*aa),round(y*aa)) for x,y in points]
        if kind=='paint':
            raw=Image.open(HERE/'materials'/f'{fill}.png').convert('RGBA')
            face=ImageOps.fit(raw,wh,method=R)
            alpha=Image.new('L',wh);ImageDraw.Draw(alpha).polygon(pp,fill=255)
            face.putalpha(alpha);layer=face
        elif kind=='polygon':
            d.polygon(pp,fill=fill)
            if stroke:d.line(pp+[pp[0]],fill=stroke,width=max(1,round(width*aa)),joint='curve')
        else:d.line(pp,fill=stroke,width=max(1,round(width*aa)),joint='curve')
        layers.append((name,layer.resize(size,R)))
    return layers

def flatten(size,layers):
    im=Image.new('RGBA',size)
    for name,layer in layers:im.alpha_composite(layer)
    return im

def render_tile(size,kind='empty'):
    if isinstance(size,int):size=(size,size)
    material='amber' if kind=='spark' else ('turquoise' if kind in ['begin','end','powered'] else 'navy')
    return flatten(size,render_layers(size,construction(size,material,role='tile')))

def render_button(size,variant='primary',states=(),shape='menu'):
    material='turquoise' if variant=='primary' else 'navy'
    im=flatten(size,render_layers(size,construction(size,material,shape='cast' if shape=='cast' else 'box')))
    if isinstance(states,str):states=(states,)
    for state in states:
        if state!='normal':im.alpha_composite(old.responsive_overlay(size,state))
    return im

def vector_source(size,ops):
    chunks=[];defs=[]
    for idx,(name,kind,points,fill,stroke,width) in enumerate(ops):
        pts=' '.join(f'{x:.3f},{y:.3f}' for x,y in points)
        if kind=='paint':
            defs.append(f'<clipPath id="face{idx}"><polygon points="{pts}"/></clipPath>')
            content=f'<image href="materials/{fill}.png" width="{size[0]}" height="{size[1]}" preserveAspectRatio="xMidYMid slice" clip-path="url(#face{idx})"/>'
        else:
            tag='polygon' if kind=='polygon' else 'polyline'
            content=f'<{tag} points="{pts}" fill="{fill or "none"}" stroke="{stroke or "none"}" stroke-width="{width:.3f}" stroke-linejoin="round"/>'
        chunks.append(f'<g id="layer{idx}" aria-label="{name}">{content}</g>')
    return f'<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="{size[0]}" height="{size[1]}" viewBox="0 0 {size[0]} {size[1]}"><title>RC-011 r002 UI candidate; not owner approved; no live labels</title><defs>'+''.join(defs)+'</defs>'+''.join(chunks)+'</svg>'

def ora(path,size,layers):
    tree=ET.Element('image',{'w':str(size[0]),'h':str(size[1]),'name':'RC-011 r002 candidate','version':'0.0.3'})
    stack=ET.SubElement(tree,'stack')
    with zipfile.ZipFile(path,'w') as z:
        z.writestr('mimetype','image/openraster',compress_type=zipfile.ZIP_STORED)
        for idx,(name,im) in reversed(list(enumerate(layers))):
            src=f'data/layer{idx:02}.png';buff=BytesIO();im.save(buff,format='PNG',icc_profile=ICC);z.writestr(src,buff.getvalue())
            ET.SubElement(stack,'layer',{'name':name,'src':src,'x':'0','y':'0','opacity':'1','visibility':'visible','composite-op':'svg:src-over'})
        z.writestr('stack.xml',ET.tostring(tree))
        buff=BytesIO();flatten(size,layers).save(buff,format='PNG',icc_profile=ICC);z.writestr('mergedimage.png',buff.getvalue())

def build():
    OUT.mkdir(parents=True,exist_ok=True);materials()
    assets=[('tile_empty',(256,256),'navy','box','tile'),('tile_spark',(256,256),'amber','box','tile'),
            ('tile_powered',(256,256),'turquoise','box','tile'),('button_primary',(512,128),'turquoise','box','button'),
            ('button_secondary',(512,128),'navy','box','button'),('button_cast',(512,128),'turquoise','cast','button')]
    for name,size,material,shape,role in assets:
        ops=construction(size,material,shape,u=2,role=role)
        (HERE/f'{name}.svg').write_text(vector_source(size,ops),encoding='utf-8')
        layers=render_layers(size,ops);im=flatten(size,layers)
        save(im,OUT/f'{name}.png')
        source=(size[0]*2,size[1]*2)
        ora(HERE/f'{name}.ora',source,render_layers(source,construction(source,material,shape,u=4,role=role)))
    preview()
    data={'revision':'r002','status':'candidate; owner rejected r001; r002 not approved',
          'source':'Original parametric SVG/Python geometry with refined r001 generated material; no reference pixels sampled',
          'retained_generated_materials':{'navy':'source-assets/pilot/spark_tile/raw/navy_material_r001.png','turquoise':'source-assets/pilot/button/raw/turquoise_material_r001.png'},
          'refinement':'Blur and low-contrast color blend suppress r001 sharp veins; amber recoloring supplies Spark face. Broad independently editable bevel planes, dark cut and turquoise inset replace r001 hairline frames.',
          'tile_slice_export_LTRB':[16,16,16,16],'menu_button_slice_export_LTRB':[24,20,24,20],
          'cast_shape':'Responsive hexagon/end plates. Diagonals extend beyond24px source cap; use vector construction at control size, not24px raster slicing. No proposal to change global button slice contract.',
          'api':['render_tile(size,kind=empty/spark/powered) -> PIL.Image','render_button(size,variant=primary/secondary,states=(),shape=menu/cast) -> PIL.Image'],
          'source_sizes':{'tiles':[512,512],'buttons':[1024,256]},'export_sizes':{'tiles':[256,256],'buttons':[512,128]},
          'review':'Candidate only. Actual files inspected; owner aesthetic acceptance and Godot/device behavior not determined.',
          'limits':['Generated material brushwork remains flattened; geometric bevels/material/edge layers are separable.','r001 interaction overlays are reused for synthetic state coverage; final state art needs review over r002 geometry.','No labels, glyphs, circuit ports or live values are baked into export textures.']}
    (HERE/'candidate-metadata.json').write_text(json.dumps(data,indent=2),encoding='utf-8')
    print(json.dumps({'exports':str(OUT),'preview':str(OUT/'ui-candidate-sheet.png'),'api':str(HERE/'build_ui.py')}))

def preview():
    page=Image.new('RGBA',(1080,1020),'#101b2c');d=ImageDraw.Draw(page)
    serif='C:/Windows/Fonts/georgiab.ttf';sans='C:/Windows/Fonts/segoeui.ttf'
    def txt(pos,s,n=20,display=False,fill='#efe1b9'):
        d.text(pos,s,font=ImageFont.truetype(serif if display else sans,n),fill=fill,stroke_width=1 if display else 0,stroke_fill='#070f17')
    def label_button(x,y,wh,text,variant='primary',shape='menu'):
        page.alpha_composite(render_button(wh,variant,shape=shape),(x,y))
        fs=15 if wh[0]<100 else (round(wh[1]*.45) if wh[1]>=70 else 22)
        f=ImageFont.truetype(serif,fs);b=d.textbbox((0,0),text,font=f)
        d.text((x+(wh[0]-b[2])/2,y+(wh[1]-(b[3]-b[1]))/2-b[1]),text,font=f,fill='#fff0bc',stroke_width=2,stroke_fill='#071017')
    txt((28,18),'RC-011 / r002 UI construction candidate',27,True)
    txt((28,59),'Owner review pending. Live labels below are review text, separate from assets.',17)
    for idx,kind in enumerate(['empty','spark','powered']):
        page.alpha_composite(render_tile((190,190),kind),(35+idx*238,114))
        txt((35+idx*238,320),{'empty':'Calmer indigo stone','spark':'Spark amber / brown','powered':'Turquoise endpoint context'}[kind],17)
    page.alpha_composite(render_tile((137,137),'spark'),(782,116));txt((782,268),'137 px cell',16)
    page.alpha_composite(render_tile((72,72),'empty'),(957,116));txt((936,208),'72 px cell',16)
    txt((28,369),'Cast: long hexagonal ends / turquoise inset / sculpted gold plates',20)
    label_button(60,412,(940,98),'CAST     2',shape='cast')
    txt((28,543),'Home / Menu: shared construction, turquoise primary and navy secondary',20)
    label_button(60,584,(450,78),'Resume')
    label_button(550,584,(450,78),'Options','secondary')
    label_button(60,682,(450,78),'Continue')
    label_button(550,682,(450,78),'Quit','secondary')
    txt((28,793),'Compact and action sizes use the same geometry; rectangular hit regions stay full size.',18)
    label_button(36,837,(66,50),'Undo','secondary')
    label_button(130,833,(200,58),'Inspect','secondary')
    label_button(366,828,(292,64),'Cast  2',shape='cast')
    label_button(700,828,(302,64),'Resume')
    txt((28,934),'Original geometry and reused generated paint. No reference screenshot crop is used.',17)
    txt((28,963),'Structural revision only; broader composition, glyph and actor matching are reviewed together.',17)
    save(page,OUT/'ui-candidate-sheet.png')

if __name__=='__main__':build()
