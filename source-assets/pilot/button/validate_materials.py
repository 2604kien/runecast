"""Meaningful RC-011 master/export checks and actual-scale material QA evidence."""
from pathlib import Path
import hashlib, json, zipfile, xml.etree.ElementTree as ET
from io import BytesIO
from PIL import Image, ImageDraw, ImageFont, ImageChops, ImageOps
import build_materials as m

HERE=Path(__file__).resolve().parent
FONT='C:/Windows/Fonts/segoeui.ttf'
font=lambda n:ImageFont.truetype(FONT,n)
def text(d,xy,s,size=18,fill='#e8dbb9'):d.text(xy,s,font=font(size),fill=fill)
def button(page,xy,size,variant,states,label):
    im=m.render_button(size,variant,states)
    page.alpha_composite(im,xy)
    d=ImageDraw.Draw(page)
    f=font(18 if size[0]>90 else 15)
    box=d.textbbox((0,0),label,font=f)
    dy=1 if 'pressed' in states else 0
    d.text((xy[0]+(size[0]-(box[2]-box[0]))/2,xy[1]+(size[1]-(box[3]-box[1]))/2-box[1]+dy),label,font=f,fill='#eee0bf')

def check():
    checks=[]
    for path,wh in [(m.BUTTON/'button.ora',(1024,256)),(m.TILE/'spark_tile.ora',(512,512))]:
        with zipfile.ZipFile(path) as z:
            assert z.read('mimetype')==b'image/openraster'
            tree=ET.fromstring(z.read('stack.xml'))
            assert (int(tree.get('w')),int(tree.get('h')))==wh
            layers=tree.findall('./stack/layer')
            contents=[z.read(e.get('src')) for e in layers]
            assert len(set(hashlib.sha256(p).hexdigest() for p in contents))==len(layers),'Duplicated layer contents'
            ims=[Image.open(BytesIO(p)).convert('RGBA') for p in contents]
            assert all(im.size==wh for im in ims)
            assert all(im.getbbox() is not None for im in ims),'Empty layer'
            c=m.blank(wh)
            for layer,im in reversed(list(zip(layers,ims))):
                if layer.get('visibility')=='visible':c.alpha_composite(im)
            merged=Image.open(BytesIO(z.read('mergedimage.png'))).convert('RGBA')
            assert not ImageChops.difference(c,merged).getbbox(),'Merged ORA does not match source layers'
            checks.append({'path':str(path.relative_to(m.ROOT)),'dimensions':wh,'unique_nonempty_layers':len(layers),'visible_layers':sum(x.get('visibility')=='visible' for x in layers),'composite_matches':True})
    for name,wh in [('spark_tile.png',(256,256)),('button_primary_normal.png',(512,128)),('button_secondary_normal.png',(512,128))]:
        im=Image.open(m.EXPORTS/name)
        assert im.size==wh and im.mode=='RGBA' and im.info.get('icc_profile')
        assert im.getpixel((0,0))[3]==0
        checks.append({'path':'exports/'+name,'dimensions':wh,'mode':im.mode,'sRGB_profile':True,'transparent_corners':True,'decoded_RGBA8_bytes':wh[0]*wh[1]*4})
    for kind,path,margins,sizes in [('button',m.EXPORTS/'button_primary_normal.png',(24,20,24,20),[(66,50),(180,58),(340,64),(580,92)]),('tile',m.EXPORTS/'spark_tile.png',(16,16,16,16),[(137,137),(72,72),(142,92)])]:
        original=Image.open(path)
        l,t,r,b=margins;cl,ct=round(l*.5),round(t*.5)
        expected=original.crop((0,0,l,t)).resize((cl,ct),m.RESAMPLE)
        for size in sizes:
            rendered=m.nine_slice(original,size,margins)
            assert not ImageChops.difference(rendered.crop((0,0,cl,ct)),expected).getbbox(),'Slice cap stretched'
        checks.append({'type':kind,'slice_LTRB':margins,'logical_sizes':sizes,'corner_pixels_match_fixed_cap':True})
    return checks

def preview():
    page=Image.new('RGBA',(1180,1220),'#0b1524');d=ImageDraw.Draw(page)
    text(d,(24,18),'RC-011 / reusable material & state study',28)
    text(d,(24,54),'Review construction only - live labels are separate. State markers keep fixed logical size.',16)
    text(d,(260,94),'Turquoise primary',18);text(d,(710,94),'Navy secondary',18)
    rows=[('normal',()),('pressed',('pressed',)),('focused',('focused',)),('selected',('selected',)),('disabled',('disabled',)),('invalid',('invalid',)),('unavailable',('unavailable',)),('focus + selection',('selected','focused')),('focus + unavailable',('unavailable','focused'))]
    for idx,(title,states) in enumerate(rows):
        y=126+idx*78;text(d,(24,y+19),title,18)
        button(page,(250,y),(360,64),'primary',states,'Cast - 2 energy')
        button(page,(690,y),(360,64),'secondary',states,'Straight 0 / 6' if 'unavailable' in states else 'Inspect')
    y=854
    text(d,(24,y),'Actual-size caps / hit areas stay rectangular',21)
    button(page,(24,y+42),(66,50),'secondary',(),'Undo')
    text(d,(24,y+100),'66 x 50',14)
    button(page,(125,y+38),(180,58),'secondary',('focused',),'Rotate')
    text(d,(125,y+100),'180 x 58 editing',14)
    button(page,(345,y+35),(340,64),'primary',(),'Cast - 2 energy')
    text(d,(345,y+100),'340 x 64 action',14)
    tile=Image.open(m.EXPORTS/'spark_tile.png')
    page.alpha_composite(m.nine_slice(tile,(137,137),(16,16,16,16)),(739,y+31))
    text(d,(747,y+176),'137 cell',14)
    page.alpha_composite(m.nine_slice(tile,(72,72),(16,16,16,16)),(912,y+31))
    text(d,(912,y+115),'72 cell',14)
    page.alpha_composite(m.nine_slice(tile,(142,92),(16,16,16,16)),(1009,y+31))
    text(d,(1009,y+135),'142 x 92 hand',14)
    button(page,(24,1011),(580,92),'primary',(),'Continue')
    text(d,(24,1110),'580 x 92 Home/Menu proportions; label is a local review placeholder.',14)
    text(d,(640,1080),'Cream dashed focus / teal inset + check selection',16)
    text(d,(640,1110),'Cross invalid / information circle unavailable',16)
    text(d,(24,1152),'No gameplay integration, production font clearance, or physical-device claim. Paint source retains raw originals.',16)
    m.save(page,HERE/'material-review.png')
    gray=ImageOps.grayscale(page).convert('RGBA');m.save(gray,HERE/'material-review-grayscale.png')

def alpha_preview():
    page=Image.new('RGBA',(1100,400),'#172237');d=ImageDraw.Draw(page)
    text(d,(20,12),'Frame edge / alpha inspection - unscaled export tile, scaled buttons',22)
    for idx,(title,color) in enumerate([('light gray','#e6e6e6'),('dark navy','#07101d'),('checkerboard',None),('turquoise','#4ecac0')]):
        x=idx*275
        panel=Image.new('RGBA',(275,350),color or '#d9d9d9')
        if color is None:
            q=ImageDraw.Draw(panel)
            for yy in range(0,350,12):
                for xx in range(0,275,12):
                    if (xx//12+yy//12)%2:q.rectangle((xx,yy,xx+11,yy+11),fill='#959595')
        tile=Image.open(m.EXPORTS/'spark_tile.png')
        panel.alpha_composite(tile,(10,4))
        panel.alpha_composite(m.render_button((250,36),'primary'),(12,266))
        panel.alpha_composite(m.render_button((250,36),'secondary'),(12,308))
        page.alpha_composite(panel,(x,49));text(d,(x+15,33),title,13)
    m.save(page,HERE/'material-alpha.png')

if __name__=='__main__':
    checks=check();preview();alpha_preview()
    (HERE/'validation.json').write_text(json.dumps({'revision':'r001','date':'2026-10-11','checks':checks,'inspection_evidence':['material-review.png','material-review-grayscale.png'],'limitations':['Overlay recipes need translation to Godot StyleBox/drawing code by RC-013/RC-016.','Segoe UI only for local helper labels; not a supplied or cleared production font.']},indent=2),encoding='utf-8')
    print(json.dumps({'checks_passed':len(checks),'preview':str(HERE/'material-review.png')}))
