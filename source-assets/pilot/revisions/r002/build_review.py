"""Reference-led r002 pilot composition; no runtime scene or reference edits."""
from pathlib import Path
from PIL import Image,ImageDraw,ImageFont
from html import escape
import importlib.util, json, re, io, base64, shutil, xml.etree.ElementTree as ET

P=Path(__file__).resolve().parent
ROOT=P.parents[3]
OUT=ROOT/'output/art/rc-011/r002'
RES=P/'review_resources'
RES.mkdir(exist_ok=True)
def load(name,path):
    s=importlib.util.spec_from_file_location(name,path);m=importlib.util.module_from_spec(s);s.loader.exec_module(m);return m
old=load('r001_review',P.parents[1]/'build_review.py')
ui=load('r002_ui',P/'ui/build_ui.py')
CREAM='#ffedb7';GOLD='#d5a252';TEAL='#65eadb';AMBER='#ffd45e';NAVY='#101727';MUTED='#bbc4d2'
FONT=P/'type-geometry/fonts/NotoSerif-Variable.ttf'
rect=old.rect;line=old.line;poly=old.poly;group=old.group;base_image=old.image;base_doc=old.doc
def text(x,y,s,size=20,color=CREAM,anchor='start',weight=600):
    stroke=1.5 if size<18 else 2.5 if size<34 else 3.5
    return f'<text x="{x}" y="{y}" font-family="Noto Serif" font-size="{size}" font-weight="{weight}" fill="{color}" stroke="#101016" stroke-width="{stroke}" stroke-linejoin="round" paint-order="stroke fill" text-anchor="{anchor}">{escape(str(s))}</text>'
def image(href,x,y,w,h):
    if href.startswith('../../output/imagegen/'):
        href='../../../../output/imagegen/'+href.split('../../output/imagegen/')[1]
    return base_image(href,x,y,w,h)
def doc(w,h,content,title):
    return base_doc(w,h,content,title).replace('RC-011 r001','RC-011 r002').replace('Environment and non-Spark symbols are identified vector placeholders.', 'Environment and non-Spark symbols remain labelled vector blockouts; this is not a finished gameplay screen or an exact-match claim.')
def material_image(im,name,x,y,w,h):
    im.save(RES/name)
    return image('review_resources/'+name,x,y,w,h)
def button(x,y,w,h,label,primary=False,state='normal',size=20,sub=None):
    variant='primary' if primary else 'secondary'
    iscast=primary and label.lower().startswith('cast')
    states=() if state=='normal' else tuple(state.split('+'))
    im=ui.render_button((w,h),variant,states,shape='cast' if iscast else 'menu')
    s=material_image(im,f'button_{variant}_{w}x{h}_{state}_{"cast" if iscast else "standard"}.png',x,y,w,h)
    s+=text(x+w/2,y+h/2+(0 if sub else size*.34)+(2 if state=='pressed' else 0),label,size,CREAM if state!='disabled' else '#b5b4ba','middle',600)
    if sub:s+=text(x+w/2,y+h-10,sub,16,MUTED,'middle')
    return s
def tile(x,y,n,kind='empty',rotation=0,powered=False,state='',temp=False,value=6):
    small=n<100;cx=x+n/2;cy=y+n/2
    face='spark' if kind=='spark' else 'empty'
    s=material_image(ui.render_tile((n,n),face),f'tile_{face}_{n}.png',x,y,n,n)
    if kind in ['begin','end']:
        s+=rect(x+8,y+8,n-16,n-16,'#064849','#29918b',1)
    if state:
        for st in state.split('+'):
            if st in ['selected','focused','invalid','unavailable','eligible','protected']:
                s+=image('exports/spark_tile_overlays/'+st+'.svg',x,y,n,n)
    if kind!='empty':
        color=AMBER if powered else '#999885'
        geometry=line(0,64,128,64,color,5)
        if kind=='begin':geometry=line(64,64,128,64,color,5)
        if kind=='end':geometry=line(0,64,64,64,color,5)
        if kind!='end':geometry+=poly('128,64 115,56 115,72',color)
        s+=group(geometry,transform=f'translate({x} {y}) scale({n/128}) rotate({rotation*90 if kind!="end" else 0} 64 64)')
        # Opaque inset hides the path beneath the icon while leaving edge ports precise.
        r=14 if small else 31
        s+=f'<circle cx="{cx}" cy="{cy}" r="{r}" fill="{"#382718" if kind=="spark" else "#064849"}"/>'
        if kind=='spark':
            glyph=34 if small else 80
            s+=image('exports/spark.svg',cx-glyph/2,cy-glyph/2,glyph,glyph)
        else:
            if kind=='end':
                dx=r*.55;dy=r*.835
                s+=f'<path d="M{cx-dx} {cy+dy} A{r} {r} 0 1 1 {cx+dx} {cy+dy}" fill="none" stroke="{TEAL}" stroke-width="{3 if small else 5}"/>'
                s+=poly(f'{cx},{cy+10} {cx+10},{cy} {cx},{cy-10} {cx-10},{cy}','#17424b',TEAL,2)
            else:
                s+=f'<circle cx="{cx}" cy="{cy}" r="{r}" fill="none" stroke="{TEAL}" stroke-width="{3 if small else 5}"/>'
                s+=f'<circle cx="{cx}" cy="{cy}" r="{r-5}" fill="none" stroke="#1d8f93" stroke-width="2"/>'
                s+=poly(f'{cx},{cy-10} {cx+10},{cy} {cx},{cy+10} {cx-10},{cy}',TEAL)
        label=('SPK' if small else 'SPARK') if kind=='spark' else kind.upper()
        if kind=='spark':s+=text(x+10,y+(17 if small else 24),label,12 if small else 16,CREAM,weight=700)
        elif kind=='end':
            s+=text(cx,y+(17 if small else 24),label,12 if small else 18,CREAM,'middle',700)
            s+=text(cx,y+n-10,value,18 if small else 26,CREAM,'middle',700)
        else:s+=text(cx,y+n-(9 if small else 12),label,12 if small else 20,CREAM,'middle',700)
        if kind=='spark':
            vx=x+17 if rotation%2 else cx;vy=y+n-10
            s+=text(vx,vy,value,18 if small else 26,CREAM,'middle',700)
            costx=x+n-12 if small else x+n-20;costy=y+n-16 if small else y+25
            s+=poly(f'{costx},{costy-14} {costx+11},{costy-7} {costx+10},{costy+9} {costx},{costy+15} {costx-10},{costy+9} {costx-11},{costy-7}','#079cec','#011e40',2)
            s+=text(costx,costy+5,0 if temp else 2,12 if small else 20,'#e7fcff','middle',700)
        if powered:s+=image('exports/spark_tile_overlays/powered.svg',x,y,n,n)
    if temp:
        marker=18 if small else 25
        s+=image('exports/temporary-marker.svg',x+7,y+n-marker-6,marker,marker)
    return s

def blockout():
    # Context sketch only, deliberately separate from the three pilot assets.
    s=rect(16,53,688,319,'#14253e')
    for x in [32,160,520,650]:
        s+=poly(f'{x},94 {x+20},73 {x+46},83 {x+40},294 {x-6},295','#233958','#0f182b',4)
        for yy in [111,148,186,230,268]:s+=line(x-2,yy,x+39,yy+4,'#111d32',5)
    for x in [80,265,454]:
        s+=f'<path d="M{x} 274V147Q{x+63} 43 {x+126} 147V274" fill="#182c48" stroke="#0d1c31" stroke-width="8"/>'
    for x in [208,472]:s+=poly(f'{x},102 {x+39},98 {x+33},239 {x+18},226 {x+6},245','#493042')
    s+=poly('16,295 704,295 704,372 16,372','#283144')
    for yy in [308,330,350]:s+=line(16,yy,704,yy,'#171d2d',4)
    for x in [34,82,152,572,638,684]:
        s+=rect(x,272,8,25,'#d29c4d')+poly(f'{x-2},272 {x+4},252 {x+10},272 {x+4},278','#ffc654')
    s+=text(30,66,'Crypt blockout · environment production remains RC-015',9,MUTED)
    return group(s,'placeholder_environment_blockout')
def main():
    s=rect(0,0,720,1600,NAVY)
    s+=text(29,41,'RUNE CAST',35,'#edb45e',weight=700)+text(690,32,'Training Crypt',19,CREAM,'end')+line(23,49,697,49,GOLD,3)
    s+=blockout()
    scale=.64;foot=(372,323)
    s+=image('exports/shadeling.png',foot[0]-256*scale,foot[1]-448*scale,512*scale,512*scale)
    s+=text(372,86,'Attack 8',23,'#ffdba4','middle')
    s+=text(360,343,'Shadeling',22,CREAM,'middle',700)
    s+=poly('266,349 454,349 463,363 454,377 266,377 257,363','#b72430','#160f1c',3)
    s+=poly('268,352 452,352 457,357 263,357','#f55c48')+text(360,371,'32/32',24,'#fff8df','middle',700)
    for x,w,label in [(18,227,'30/30 Health'),(247,227,'3/3 Energy'),(476,226,'Turn 1')]:
        s+=button(x,380,w,40,label,size=21)
    s+=poly('106,423 614,423 606,438 614,451 106,451 114,438','#104c3c','#071d23',3)
    s+=text(360,445,'CIRCUIT COMPLETE',25,'#75f2b1','middle',700)
    s+=rect(62,450,596,574,'#142438','#806039',7)
    s+=group(old.board(77,452,137),'built_training_witness')
    for i,(label,count) in enumerate([('Straight','4 / 4'),('Corner','2 / 2'),('Split','2 / 2'),('Join','2 / 2')]):s+=button(18+i*173,1032,167,58,label,size=17,sub=count)
    for i,(label,state) in enumerate([('Rotate','disabled'),('Flip','disabled'),('Undo','normal'),('Erase','normal')]):s+=button(18+i*173,1097,167,54,label,state=state,size=19)
    for x,w,label in [(18,224,'Inspect'),(248,224,'Cancel selection'),(478,224,'Details / Pass')]:s+=button(x,1158,w,50,label,size=19)
    s+=text(360,1233,'RUNES · tap to use / hold to inspect',18,CREAM,'middle')
    for i,label in enumerate(['Spark','Focus']):
        x=174+i*190
        s+=material_image(ui.render_tile((170,136),'spark' if i==0 else 'empty'),f'hand_{i}.png',x,1244,170,136)
        s+=text(x+85,1270,label,21,CREAM,'middle',700)
        if i==0:s+=image('exports/spark.svg',x+45,1274,80,80)
        else:s+=text(x+85,1319,'?',34,'#c99aff','middle')
        s+=text(x+85,1368,6 if i==0 else 2,25,CREAM,'middle',700)
    s+=text(360,1395,'Hand 2 / draw 5 / discard 0 · Focus symbol placeholder',10,MUTED,'middle')
    s+=material_image(ui.render_button((560,89),'primary',shape='cast'),'cast_main.png',80,1400,560,89)
    s+=text(330,1460,'CAST',48,CREAM,'middle',700)
    s+=poly('451,1419 469,1431 468,1459 451,1473 434,1460 433,1431','#079ff1','#04243f',3)
    s+=poly('451,1420 451,1442 435,1432','#5fe4ff')+poly('451,1442 468,1432 467,1458 451,1470','#0269bd')
    s+=line(451,1442,451,1470,'#41c7ff',2)+text(492,1461,'2',39,CREAM,'middle',700)
    s+=text(360,1513,'Cast ends turn',20,CREAM,'middle')
    for i,label in enumerate(['Menu','Map','Guide','Sound: On']):s+=button(18+i*173,1523,167,50,label,size=20)
    s+=text(360,1590,'RC-011 r002 · Training seed294 built example · isolated review',11,GOLD,'middle')
    (P/'pilot_review.svg').write_text(doc(720,1600,s,'RC-011 r002 reference-led correction; environment blockout'),encoding='utf-8')

def bake_text():
    ns='{http://www.w3.org/2000/svg}';ET.register_namespace('',ns[1:-1]);ET.register_namespace('xlink','http://www.w3.org/1999/xlink')
    dest=RES/'render';dest.mkdir(exist_ok=True)
    for path in P.glob('pilot*.svg'):
        root=ET.fromstring(path.read_text(encoding='utf-8'))
        for parent in root.iter():
            for child in list(parent):
                if child.tag!=ns+'text':continue
                a=child.attrib;value=''.join(child.itertext());size=int(float(a.get('font-size','20')))
                f=ImageFont.truetype(str(FONT),size);f.set_variation_by_axes([float(a.get('font-weight',600)),100])
                sw=max(1,round(float(a.get('stroke-width',2))/2));bbox=f.getbbox(value,anchor='ls',stroke_width=sw);width=f.getlength(value)
                im=Image.new('RGBA',(max(1,bbox[2]-bbox[0]+4),max(1,bbox[3]-bbox[1]+4)))
                ImageDraw.Draw(im).text((2-bbox[0],2-bbox[1]),value,font=f,fill=a.get('fill',CREAM),anchor='ls',stroke_width=sw,stroke_fill='#101016')
                b=io.BytesIO();im.save(b,format='PNG');x=float(a.get('x',0));y=float(a.get('y',0));anchor=a.get('text-anchor','start')
                x-=width/2 if anchor=='middle' else width if anchor=='end' else 0
                node=ET.Element(ns+'image',{'x':str(x+bbox[0]-2),'y':str(y+bbox[1]-2),'width':str(im.width),'height':str(im.height),'{http://www.w3.org/1999/xlink}href':'data:image/png;base64,'+base64.b64encode(b.getvalue()).decode()})
                parent.insert(list(parent).index(child),node);parent.remove(child)
        (dest/path.name).write_text(ET.tostring(root,encoding='unicode'),encoding='utf-8')

def build():
    ex=P/'exports';ex.mkdir(exist_ok=True)
    for fn in ['spark.svg','spark-monochrome.svg']:shutil.copy2(P/'type-geometry'/fn,ex/fn)
    shutil.copy2(P.parents[1]/'exports/temporary-marker.svg',ex/'temporary-marker.svg')
    shutil.copytree(P.parents[1]/'exports/spark_tile_overlays',ex/'spark_tile_overlays',dirs_exist_ok=True)
    sel=ex/'spark_tile_overlays/selected.svg'
    sel.write_text(sel.read_text().replace('M 9 9 H 28 L 9 28 Z','M 119 98 V 119 H 98 Z'),encoding='utf-8')
    shutil.copy2(OUT/'ui/tile_empty.png',ex/'spark_tile.png')
    for variant in ['primary','secondary']:shutil.copy2(OUT/f'ui/button_{variant}.png',ex/f'button_{variant}_normal.png')
    for name,value in [('P',P),('OUT',OUT),('RES',RES),('text',text),('image',image),('doc',doc),('button',button),('tile',tile),('materials',ui)]:setattr(old,name,value)
    main();old.narrow();old.states();old.support()
    for path in P.glob('pilot*.svg'):
        content=path.read_text().replace('glyph 24px','glyph 34px')
        content=content.replace('APPROVED REFERENCES / PILOT COMPATIBILITY','APPROVED REFERENCES / r002 CORRECTION')
        content=content.replace('No new environment','No new environment')
        path.write_text(content,encoding='utf-8')
    bake_text()
    renderer=(P.parents[1]/'render_review.cjs').read_text().replace("'../../output/art/rc-011'", "'../../../../output/art/rc-011/r002'")
    (P/'render_review.cjs').write_text(renderer)
    print('r002 editable compositions created, using acquired Noto Serif and reference-guided assets.')

if __name__=='__main__':build()
