"""RC-011 editable review composition. No game imports, gameplay or Git access."""
from pathlib import Path
from PIL import Image, ImageFont, ImageDraw
from html import escape
import json, math, re, importlib.util, xml.etree.ElementTree as ET, io, base64

P=Path(__file__).resolve().parent
OUT=P.parents[1]/'output/art/rc-011'
RES=P/'review_resources'
RES.mkdir(exist_ok=True)
OUT.mkdir(parents=True,exist_ok=True)
CREAM='#f4e7c6'; MUTED='#b7c3d0'; GOLD='#c8a160'; TEAL='#5ce0d1'; AMBER='#ffc15c'; NAVY='#0c1525'
resources={}
spec=importlib.util.spec_from_file_location('pilot_materials',P/'button/build_materials.py')
materials=importlib.util.module_from_spec(spec); spec.loader.exec_module(materials)

def nine(src,size,margins,dest):
    im=Image.open(P/'exports'/src).convert('RGBA'); w,h=im.size
    l,t,r,b=margins; dl,dt,dr,db=dest; W,H=size
    canvas=Image.new('RGBA',size)
    xs=[0,l,w-r,w]; ys=[0,t,h-b,h]; xx=[0,dl,W-dr,W]; yy=[0,dt,H-db,H]
    for i in range(3):
      for j in range(3):
        piece=im.crop((xs[i],ys[j],xs[i+1],ys[j+1]))
        canvas.paste(piece.resize((xx[i+1]-xx[i],yy[j+1]-yy[j]),Image.Resampling.LANCZOS),(xx[i],yy[j]))
    name=f'{Path(src).stem}_{W}x{H}.png'; canvas.save(RES/name)
    resources[name]={'source':'exports/'+src,'size':size,'source_slices':margins,'destination_slices':dest}
    return 'review_resources/'+name

def text(x,y,s,size=20,color=CREAM,anchor='start',weight=400):
    return f'<text x="{x}" y="{y}" font-family="Open Sans SemiBold, sans-serif" font-size="{size}" font-weight="{weight}" fill="{color}" text-anchor="{anchor}">{escape(str(s))}</text>'
def rect(x,y,w,h,fill,stroke='none',sw=1,rx=0):
    return f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{rx}" fill="{fill}" stroke="{stroke}" stroke-width="{sw}"/>'
def line(x1,y1,x2,y2,c,w=2,dash=''):
    return f'<path d="M{x1} {y1} L{x2} {y2}" fill="none" stroke="{c}" stroke-width="{w}"'+(f' stroke-dasharray="{dash}"' if dash else '')+'/>'
def image(href,x,y,w,h):
    return f'<image xlink:href="{href}" x="{x}" y="{y}" width="{w}" height="{h}"/>'
def poly(pts,fill,stroke='none',sw=1):
    return f'<polygon points="{pts}" fill="{fill}" stroke="{stroke}" stroke-width="{sw}"/>'
def group(s,ident='',transform=''):
    return '<g'+(f' id="{ident}"' if ident else '')+(f' transform="{transform}"' if transform else '')+'>'+s+'</g>'
def doc(w,h,content,title):
    return f'<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="{w}" height="{h}" viewBox="0 0 {w} {h}"><title>{escape(title)}</title><metadata>RC-011 r001; unintegrated review composition; all text, ports and values remain editable. Environment and non-Spark symbols are identified vector placeholders. See delivery.md.</metadata>'+content+'</svg>'

def button(x,y,w,h,label,primary=False,state='normal',size=20,sub=None):
    src='button_primary_normal.png' if primary else 'button_secondary_normal.png'
    art=image(nine(src,(w,h),(24,20,24,20),(12,10,12,10)),x,y,w,h)
    for st in sorted(state.split('+'),key=lambda q:q=='focused'):
      if st!='normal':
        overlay=materials.responsive_overlay_svg((w,h),st)
        overlay=re.sub(r'^<svg[^>]*>','',overlay).removesuffix('</svg>')
        art+=group(overlay,transform=f'translate({x} {y})')
    shift=2 if state=='pressed' else 0
    art+=group(text(x+w/2,y+h/2+(0 if sub else size*.34)+shift,label,size,CREAM if state!='disabled' else '#c4c8cb','middle',600)+(text(x+w/2,y+h-11,sub,17,MUTED,'middle') if sub else ''),'')
    return art

def tile(x,y,n,kind='empty',rotation=0,powered=False,state='',temp=False,value=6):
    s=image(nine('spark_tile.png',(n,n),(16,16,16,16),(8,8,8,8)),x,y,n,n)
    center=n/2; small=n<100; glyph=24 if small else 48
    color=AMBER if powered else '#8595ae'
    geo=''
    if kind=='spark':
      geo=line(0,64,128,64,color,5 if not small else 128*3/n)
      geo+=poly('128,64 116,58 116,70',color)
    if kind=='begin':
      geo=line(64,64,128,64,color,5)+poly('128,64 116,58 116,70',color)
    if kind=='end': geo=line(0,64,64,64,color,5)
    if geo:
      # End witness has W input already expressed; other effects rotate the W-E graph.
      rotate=rotation*90 if kind!='end' else 0
      s+=group(geo,transform=f'translate({x} {y}) scale({n/128}) rotate({rotate} 64 64)')
      s+=f'<circle cx="{x+center}" cy="{y+center}" r="{glyph*.58}" fill="#13263a"/>'
    if kind=='spark': s+=image('exports/spark.svg',x+(n-glyph)/2,y+(n-glyph)/2,glyph,glyph)
    if powered and kind!='empty': s+=image('exports/spark_tile_overlays/powered.svg',x,y,n,n)
    if kind=='begin': s+=group(poly(f'{x+center-9},{y+center-12} {x+center+11},{y+center} {x+center-9},{y+center+12}',TEAL,'#081522',2),transform=f'rotate({rotation*90} {x+center} {y+center})')
    if kind=='end': s+=f'<circle cx="{x+center}" cy="{y+center}" r="{12 if small else 19}" fill="none" stroke="{TEAL}" stroke-width="4"/>'
    if state:
      # Independent shape/state geometry leaves the central glyph and bottom numeric zones free.
      if 'selected' in state:s+=rect(x+2,y+2,n-4,n-4,'none',GOLD,3)+poly(f'{x+5},{y+5} {x+15},{y+5} {x+5},{y+15}',GOLD)
      if 'focused' in state:s+=rect(x+6,y+6,n-12,n-12,'none',CREAM,2).replace('/>',' stroke-dasharray="5 3"/>')
      if state in ['invalid','protected']:
        s+=rect(x+3,y+3,n-6,n-6,'none','#d39a90',2)+text(x+9,y+n-9,'x',18,'#edb09c',weight=700)
      if state=='invalid':
        s+=poly(f'{x+n-24},{y+n-25} {x+n-9},{y+n-9} {x+n-24},{y+n-9}','#edb09c')
      if state=='unavailable':
        for k in range(3):s+=line(x+n-28+k*6,y+n-9,x+n-9+k*3,y+n-28,'#a4adbb',2)
        s+=f'<circle cx="{x+n-19}" cy="{y+n-38}" r="7" fill="#182535" stroke="#a4adbb" stroke-width="2"/>'+text(x+n-19,y+n-34,'i',12,CREAM,'middle')
      if state=='eligible':s+=rect(x+3,y+3,n-6,n-6,'none',TEAL,2)+text(x+9,y+n-9,'+',18,TEAL,weight=700)
    if kind!='empty':
      name=('SPK' if small else 'SPARK') if kind=='spark' else kind.upper()
      vertical=kind=='spark' and rotation%2==1
      s+=text(x+9 if kind=='spark' else x+center,y+(17 if small else 23),name,12 if small else 14,CREAM,'start' if kind=='spark' else 'middle',600)
      if kind in ['spark','end']:s+=text(x+18 if vertical else x+center,y+n-10,value,18 if small else 22,AMBER if kind=='spark' else TEAL,'middle',600)
      if kind=='spark':
        cx=x+n-12 if small else x+n-19; cy=y+n-17 if small else y+23
        s+=f'<circle cx="{cx}" cy="{cy}" r="{9 if small else 12}" fill="#175377"/>'+text(cx,cy+4,0 if temp else 2,12 if small else 16,'#ffffff','middle')
    if temp:
      tx=x+n-20 if small else x+20;ty=y+17 if small else y+n-21
      marker=20 if small else 30
      s+=image('exports/temporary-marker.svg',tx-marker/2,ty-marker/2,marker,marker)
    return s

def board(x,y,n,built=True):
    s=''
    for i in range(16):
      kind='begin' if i==0 else 'end' if i==2 else 'spark' if built and i==1 else 'empty'
      s+=group(tile(x+(i%4)*(n+6),y+(i//4)*(n+6),n,kind,0 if built else 2,built,value=6 if built else 0),f'cell_{i}')
    return s

def main():
    s=rect(0,0,720,1600,NAVY)
    s+=group(text(24,42,'RUNE CAST',28,GOLD,weight=700)+text(695,40,'TRAINING CRYPT',19,CREAM,'end'),'live_header')
    s+=line(18,56,702,56,GOLD)
    env=rect(18,64,684,310,'#142238')
    for x in [27,100,177,542,617,679]:
      env+=poly(f'{x},84 {x+20},84 {x+20},290 {x-5},290','#20334b')+line(x+4,94,x-2,282,'#34445d',2)
    for y in [301,318,336,356]:env+=line(18,y,702,y,'#2b3b50',2)
    env+=text(30,363,'Environment placeholder',10,MUTED)
    s+=group(env,'placeholder_environment')
    # Arena base680x300 maps to684x310; sprite uses0.46 design/export px.
    sx=684/680; sy=310/300; anchorx=18+340*sx; anchory=64+233*sy
    s+=group(image('exports/shadeling.png',anchorx-256*.46*sx,anchory-448*.46*sy,512*.46*sx,512*.46*sy),'shadeling_art')
    s+=group(text(360,111,'ATTACK 8',24,'#f2b395','middle',600)+text(360,337,'SHADELING',19,CREAM,'middle',600)+rect(259,346,202,20,'#4f2637')+rect(260,347,200,18,'#b75060')+text(360,362,'32 / 32',15,'#ffffff','middle'),'live_enemy_ui')
    s+=group(text(130,402,'HEALTH 30 / 30',20,CREAM,'middle')+text(370,402,'ENERGY 3 / 3',20,CREAM,'middle')+text(607,402,'TURN 1',20,CREAM,'middle')+text(360,439,'CIRCUIT COMPLETE',24,TEAL,'middle',700),'live_combat_ui')
    s+=group(board(77,450,137),'built_witness_board')
    for i,(a,b) in enumerate([('Straight','4 / 4'),('Corner','2 / 2'),('Split','2 / 2'),('Join','2 / 2')]):s+=button(18+i*173,1023,167,58,a,size=15,sub=b)
    for i,(a,b) in enumerate([('Rotate','disabled'),('Flip','disabled'),('Undo','normal'),('Erase','normal')]):s+=button(18+i*173,1087,167,58,a,state=b,size=18)
    for x,w,a in [(18,224,'Inspect'),(248,224,'Cancel selection'),(478,224,'Details / Pass')]:s+=button(x,1151,w,50,a,size=19)
    s+=text(360,1227,'RUNES / tap to use · hold to inspect · drag to scroll',18,CREAM,'middle')
    for i,a in enumerate(['Spark','Focus']):
      x=18+i*150
      s+=image(nine('spark_tile.png',(142,92),(16,16,16,16),(8,8,8,8)),x,1238,142,92)+text(x+71,1261,a,18,AMBER if i==0 else '#c4a8e9','middle',600)
      if i==0:s+=image('exports/spark.svg',x+55,1266,32,32)
      else:s+=text(x+71,1293,'?',26,'#c4a8e9','middle')
      s+=text(x+71,1321,6 if i==0 else 2,20,AMBER if i==0 else '#c4a8e9','middle',600)
    s+=text(340,1290,'Focus symbol placeholder',12,MUTED)
    s+=text(360,1360,'Complete route. Open Details / Pass for forecast.',18,CREAM,'middle')+text(360,1385,'Kit: Extra Branches. Hand 2 / draw 5 / discard 0.',17,MUTED,'middle')
    s+=button(18,1404,684,64,'CAST   2 energy',True,size=28)+text(360,1491,'Cast ends turn',18,CREAM,'middle')
    for i,a in enumerate(['Menu','Map','Guide','Sound: On']):s+=button(18+i*173,1504,167,50,a,size=20)
    s+=text(360,1575,'RC-011 REVIEW · board_training seed294 · BUILT EXAMPLE',13,GOLD,'middle')+text(360,1593,'Not a prefill or guaranteed opening hand · isolated art composition',12,MUTED,'middle')
    (P/'pilot_review.svg').write_text(doc(720,1600,s,'RC-011 matching pilot — Training built witness'),encoding='utf-8')

def narrow():
    s=rect(0,0,360,640,NAVY)+text(18,27,'FIRST CIRCUIT',19,GOLD,weight=700)+text(342,25,'RC-011 study',11,MUTED,'end')
    s+=text(18,54,'360 × 640 · native 72px cells',14,CREAM)+text(18,76,'Page scrolled below compact arena',12,MUTED)
    s+=line(18,84,337,84,GOLD,1,'4 3')+board(24,94,72)
    s+=rect(347,94,4,510,'#1b2b40',rx=2)+rect(347,243,4,175,GOLD,rx=2)
    for i,(a,b) in enumerate([('Straight','4 / 4'),('Corner','2 / 2'),('Split','2 / 2'),('Join','2 / 2')]):s+=button(18+i*81,410,77,50,a,size=12,sub=b)
    for i,a in enumerate(['Rotate','Flip','Undo','Erase']):s+=button(18+i*81,466,77,58,a,state='disabled' if i<2 else 'normal',size=14)
    for i,a in enumerate(['Inspect','Cancel','Details / Pass']):s+=button(18+i*109,530,103,50,a,size=13)
    s+=text(18,605,'Hand, Cast and navigation continue below',13,CREAM)+line(18,616,337,616,GOLD,1,'4 3')+text(18,635,'Scroll study · lower-controls companion supplied',11,MUTED)
    (P/'pilot_narrow.svg').write_text(doc(360,640,s,'Native narrow layout, board scroll position'),encoding='utf-8')
    s=rect(0,0,360,640,NAVY)+text(18,28,'LOWER CONTROLS',19,GOLD,weight=700)+text(18,53,'360 × 640 · next scroll position',13,MUTED)
    for i,a in enumerate(['Inspect','Cancel','Details / Pass']):s+=button(18+i*109,74,103,50,a,size=13)
    s+=text(18,151,'RUNES / hold to inspect',16,CREAM)
    for i,a in enumerate(['Spark','Focus']):
      x=18+i*150;s+=image(nine('spark_tile.png',(142,92),(16,16,16,16),(8,8,8,8)),x,168,142,92)+text(x+71,193,a,18,CREAM,'middle')+text(x+71,251,6 if i==0 else 2,20,CREAM,'middle')
      s+=image('exports/spark.svg',x+55,199,32,32) if i==0 else text(x+71,230,'?',26,'#c4a8e9','middle')
    s+=line(18,273,310,273,GOLD,2)+text(18,303,'Complete route. Cost 2; damage 6.',18,CREAM)+text(18,330,'Hand 2 / draw 5 / discard 0.',16,MUTED)
    s+=button(18,359,324,64,'CAST  2 energy',True,size=24)+text(180,450,'Cast ends turn',18,CREAM,'middle')
    for i,a in enumerate(['Menu','Map','Guide','Sound']):s+=button(18+i*81,478,77,50,a,size=14)
    s+=text(18,567,'Built Training witness · no fixed footer',13,MUTED)+text(18,589,'Page and hand keep separate scroll axes.',13,MUTED)
    (P/'pilot_narrow_controls.svg').write_text(doc(360,640,s,'Native narrow lower controls'),encoding='utf-8')
    s=rect(0,0,360,640,NAVY)+rect(14,77,332,487,'#182b3b',GOLD,2,12)+text(180,122,'Spark',28,CREAM,'middle',600)
    for y,t in [(180,'Damage: 6.'),(216,'Energy: 2, paid when'),(252,'Cast is accepted.'),(310,'Ports: west to east.'),(346,'Powered from Begin.'),(404,'Permanent rune; after'),(440,'Cast / Pass it discards.')]:s+=text(32,y,t,23,CREAM)
    s+=rect(320,148,7,320,'#0c1c2b',rx=3)+rect(320,153,7,173,'#8092a0',rx=3)+button(32,482,296,64,'Close',size=22)
    s+=text(18,605,'Inspector body scrolls; Close stays fixed.',13,MUTED)+text(18,627,'No card activation in this panel.',13,MUTED)
    (P/'pilot_inspector.svg').write_text(doc(360,640,s,'Narrow inspector companion with fixed Close'),encoding='utf-8')

def states():
    s=rect(0,0,1440,2280,NAVY)+text(32,44,'RC-011 / SHARED STATES & EXACT GEOMETRY',30,GOLD,weight=700)+text(32,75,'Review candidates. Labels, costs, ports and markers are live-style editable geometry.',18,MUTED)
    # Parallel buttons demonstrate the same state recipe on both materials.
    states=['normal','pressed','focused','selected','disabled','invalid','unavailable','focused+selected','focused+unavailable']
    for j,st in enumerate(states):
      col=j%3;row=j//3;x=32+col*470;y=108+row*153
      s+=text(x,y,st.upper(),14,GOLD,weight=600)+button(x,y+12,212,58,'Cast',True,st,22)+button(x+222,y+12,212,58,'Options',False,st,20)
      label='Still inspectable · stock 0 / 6' if 'unavailable' in st else 'Warning + explanation' if st=='invalid' else 'No available action' if st=='disabled' else 'Same bounds; separate live text'
      s+=text(x,y+94,label,14,MUTED)
    s+=text(32,594,'SPARK / clockwise rotations; upright labels and values',22,CREAM)
    for i in range(4):
      x=32+i*170;s+=tile(x,612,137,'spark',i,True)+text(x+68.5,775,['0 · W to E','1 · N to S','2 · E to W','3 · S to N'][i],16,CREAM,'middle')
    s+=text(770,594,'Native 72px cells · glyph 24px',20,CREAM)
    for i in range(4):s+=tile(770+i*90,625,72,'spark',i,True)+text(806+i*90,722,str(i),14,MUTED,'middle')
    s+=tile(1160,612,137,'spark',0,True,state='selected+focused',temp=True)+text(1228,775,'Free Spark · TEMP',16,CREAM,'middle')
    for j,st in enumerate(['unpowered','powered','selected','focused','invalid','unavailable','eligible','protected']):
      x=32+j*173;s+=text(x,826,st,16,CREAM)+tile(x,846,137,'spark',0,st!='unpowered',st)
    s+=text(32,1025,'Actual glyph sizes',20,CREAM)
    for j,n in enumerate([24,32,48]):
      x=32+j*85;s+=image('exports/spark.svg',x,1045,n,n)+text(x,1120,f'{n}px',14,MUTED)
      mono='exports/spark-monochrome.svg';s+=rect(x-4,1146,n+8,n+8,CREAM)+image(mono,x,1150,n,n)+text(x,1217,'mono',14,MUTED)
    s+=text(350,1025,'Minimum & scaled buttons · fixed slice corners',20,CREAM)
    s+=button(350,1044,66,50,'OK',size=16)+button(432,1044,145,58,'Rotate',size=20)+button(595,1044,330,64,'Details / Pass',size=23)
    s+=button(350,1130,570,84,'Continue',True,size=28)+text(350,1238,'66×50 / 145×58 / 330×64 / 570×84',16,MUTED)
    s+=text(990,1025,'Exhausted stock remains inspectable',18,CREAM)+button(990,1044,385,64,'Straight   0 / 6',state='focused+unavailable',size=23)
    s+=text(990,1137,'No stock available.',20,CREAM)+text(990,1167,'Erase or replace an installed one first.',17,MUTED)+text(990,1197,'The i cue opens an explanation.',17,MUTED)
    s+=text(32,1282,'Endpoints-only / sampled opening · Training seed294',22,CREAM)
    for i in range(4):s+=tile(32+i*90,1300,72,'begin' if i==0 else 'end' if i==2 else 'empty',2,False,value=0)
    s+=text(32,1398,'Begin0 r2 (west); End2 r3 (west input).',16,MUTED)+text(32,1424,'14 empty cells; opening hand Spark / Spark / Focus.',16,MUTED)
    s+=text(770,1282,'Small cells: cost moved to bottom-right',20,CREAM)+tile(770,1300,72,'spark',0,True,temp=True)+text(860,1330,'TEMP, damage and cost stay separate.',18,CREAM)+text(860,1360,'SPK 12px; inspector gives the full name.',17,MUTED)
    s+=text(32,1490,'Palette / monochrome distinction',22,CREAM)
    for i,c in enumerate([NAVY,'#273a53','#53435c',GOLD,TEAL,AMBER,CREAM]):s+=rect(32+i*90,1509,74,45,c,'#6a7b8b')
    s+=text(32,1590,'Focus = dashed outer ring · selected = notch + inset · invalid = warning · unavailable = information cue',19,CREAM)
    s+=text(32,1620,'Alpha and scale tests: pilot-shadeling-alpha.png and pilot-shadeling-scale.png.',18,MUTED)
    s+=text(32,1668,'State sheet illustrates appearance only. Godot bindings and physical-device acceptance remain future work.',17,MUTED)
    s+=text(32,1728,'Alpha backdrops / actual exported neutral',22,CREAM)
    for i,bg in enumerate(['#e8e9ec',NAVY,'#4bafb2','checker']):
      x=32+i*342;y=1750
      if bg=='checker':
        for a in range(16):
          for b in range(14):s+=rect(x+a*20,y+b*20,20,20,'#ddd' if (a+b)%2 else '#bbb')
      else:s+=rect(x,y,320,280,bg)
      s+=image('exports/shadeling.png',x+32,y-15,256,256)+text(x,y+304,['Light','Dark navy','Turquoise','Checkerboard'][i],16,CREAM)
    s+=text(32,2110,'Grayscale / state silhouettes survive without hue',22,CREAM)
    for i,st in enumerate(['normal','selected','focused','disabled','invalid','unavailable']):
      im=materials.render_button((212,58),'secondary',() if st=='normal' else (st,)).convert('LA').convert('RGBA')
      name=f'grayscale_{st}.png';im.save(RES/name)
      s+=image('review_resources/'+name,32+i*234,2132,212,58)+text(32+i*234,2220,st,16,CREAM)
    (P/'pilot_states.svg').write_text(doc(1440,2280,s,'Pilot shared states, sizes and port geometry'),encoding='utf-8')

def support():
    s=rect(0,0,720,950,NAVY)+text(28,43,'ENDPOINTS-ONLY / ROTATED BEGIN',27,GOLD,weight=600)+text(28,76,'Training seed294 opening: Begin0 r2, End2 r3',20,CREAM)
    s+=group(board(77,112,137,False),'opening_board')
    s+=rect(79,114,133,133,'none',GOLD,3)
    for i,a in enumerate(['Rotate','Flip','Undo','Erase']):s+=button(18+i*173,703,167,58,a,state='disabled' if i in [1,2] else 'normal',size=18)
    s+=button(18,779,224,50,'Inspect',size=20)+button(248,779,224,50,'Cancel selection',size=19)+button(478,779,224,50,'Details / Pass',size=19)
    s+=text(28,863,'Begin selected. Rotate is available; Flip is unavailable.',20,CREAM)+text(28,895,'Opening hand: Spark UID0, Spark UID3, Focus UID5.',18,MUTED)+text(28,925,'All other cells empty. A deliberately chosen witness, not a guaranteed draw.',16,MUTED)
    (P/'pilot_endpoints.svg').write_text(doc(720,950,s,'Endpoints-only selected Begin with rotated output'),encoding='utf-8')
    s=rect(0,0,1600,1020,NAVY)+text(28,42,'APPROVED REFERENCES / PILOT COMPATIBILITY',29,GOLD,weight=600)+text(28,74,'Unedited approved screens above; new pilot swatches below. References are not game textures.',19,MUTED)
    for i,name in enumerate(['home','combat','map','menu']):
      x=28+i*394;s+=text(x,114,name.upper(),20,CREAM)
      s+=image('../../output/imagegen/approved/'+name+'.png',x,131,350,778)
      s+=button(x,934,165,58,'Primary',True,size=18)+button(x+175,934,165,58,'Secondary',size=18)
    (P/'pilot_reference_comparison.svg').write_text(doc(1600,1020,s,'Approved screen compatibility comparison'),encoding='utf-8')

def bake_preview_text():
    # Keep canonical SVG text editable; render a transient copy with the exact engine font bytes.
    # Pillow/FreeType and Godot differ in rasterization; actual Godot metric evidence is pilot-type.png.
    candidates=list((P/'typography').glob('engine-fallback-preview-only.*'))
    fontpath=next(p for p in candidates if p.suffix in ['.woff2','.ttf'])
    ns='{http://www.w3.org/2000/svg}'
    ET.register_namespace('',ns[1:-1]);ET.register_namespace('xlink','http://www.w3.org/1999/xlink')
    dest=P/'review_resources/render';dest.mkdir(exist_ok=True)
    for path in P.glob('pilot*.svg'):
      root=ET.fromstring(path.read_text(encoding='utf-8'))
      for parent in root.iter():
        for child in list(parent):
          if child.tag!=ns+'text':continue
          a=child.attrib;value=''.join(child.itertext());size=int(float(a.get('font-size','20')))
          font=ImageFont.truetype(str(fontpath),size)
          bbox=font.getbbox(value,anchor='ls');width=font.getlength(value)
          tileim=Image.new('RGBA',(max(1,bbox[2]-bbox[0]+4),max(1,bbox[3]-bbox[1]+4)))
          ImageDraw.Draw(tileim).text((2-bbox[0],2-bbox[1]),value,font=font,fill=a.get('fill',CREAM),anchor='ls')
          data=io.BytesIO();tileim.save(data,format='PNG')
          x=float(a.get('x',0));y=float(a.get('y',0));anchor=a.get('text-anchor','start')
          x-=width/2 if anchor=='middle' else width if anchor=='end' else 0
          node=ET.Element(ns+'image',{'x':str(x+bbox[0]-2),'y':str(y+bbox[1]-2),'width':str(tileim.width),'height':str(tileim.height),'{http://www.w3.org/1999/xlink}href':'data:image/png;base64,'+base64.b64encode(data.getvalue()).decode()})
          parent.insert(list(parent).index(child),node);parent.remove(child)
      (dest/path.name).write_text(ET.tostring(root,encoding='unicode'),encoding='utf-8')

if __name__=='__main__':
    main();narrow();states();support()
    (P/'review_resources/resources.json').write_text(json.dumps(resources,indent=2)+'\n')
    bake_preview_text()
    print('Editable compositions and sliced linked resources built; exact engine fallback raster copy generated.')
