from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
from html import escape
import json, math

HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[4]
OUT=ROOT/'output/art/rc-011/r002/type-geometry'
FONT=HERE/'fonts/NotoSerif-Variable.ttf'
im=Image.new('RGB',(1100,1230),'#122137');d=ImageDraw.Draw(im)
elements=['<rect width="1100" height="1230" fill="#122137"/>']
measure=[]

def text(x,y,value,size=20,weight=600,fill='#fff0ca',stroke=1.5):
    font=ImageFont.truetype(str(FONT),size);font.set_variation_by_axes([weight,100])
    d.text((x,y),value,font=font,fill=fill,stroke_width=round(stroke),stroke_fill='#08121e',anchor='lt')
    elements.append(f'<text x="{x}" y="{y+size*.83}" font-family="Noto Serif" font-size="{size}" font-weight="{weight}" fill="{fill}" stroke="#08121e" stroke-width="{stroke*2}" paint-order="stroke fill">{escape(value)}</text>')
    measure.append({'string':value,'font_px':size,'weight':weight,'width_px':font.getlength(value)})

def line(y):
    d.line((32,y,1068,y),fill='#88734c',width=1);elements.append(f'<path d="M32 {y} H1068" stroke="#88734c"/>')
text(32,24,'RUNE CAST / COMBAT TYPE REVISION',32,600,'#e9b55c',2)
text(32,79,'Actual Noto Serif · weight600 / width100 · official font and OFL obtained',16,400,stroke=0)
text(32,108,'Cream lettering, dark outside stroke, large action hierarchy; no system substitute.',16,400,stroke=0)
line(143)
text(32,164,'RUNE CAST',36,600,'#edb152',2)
text(355,174,'Floor 3 · Ashen Crypt',21,400,stroke=1)
text(32,239,'CIRCUIT COMPLETE',29,600,'#61e5bc',2)
text(32,312,'CAST',48,600,stroke=3)
text(300,334,'2',38,600,stroke=2)
text(420,324,'Resume',38,600,stroke=2)
text(760,324,'Continue',38,600,stroke=2)
text(32,394,'Spark',20,600,stroke=1)
text(207,394,'Free Spark',20,600,stroke=1)
text(410,394,'Conjure Spark',20,600,stroke=1)
text(697,383,'6    0    8    1',32,600,stroke=2)
text(32,449,'SPARK',17,600,stroke=1)
text(205,439,'0 / 6',24,600,stroke=1)
text(410,439,'32 / 32',24,600,stroke=1)
text(695,447,'Menu    Map    Guide',21,600,stroke=1)
text(32,502,'Cancel selection     Details / Pass',20,600,stroke=1)
text(530,502,'Confirm Pass / enemy acts',20,600,stroke=1)
line(548)
text(32,574,'SPARK / LONG AMBER RAYS + YELLOW CENTER',24,600,'#edb152',1)
text(32,618,'Exact editable SVG · no baked ports, labels, cost or effect value',17,400,stroke=0)
for i,n in enumerate([24,32,48,62,80,128]):
    x=40+i*174
    text(x,664,f'{n}px canvas',15,400,stroke=0)
    icon=Image.open(HERE/f'spark-{n}.png').convert('RGBA')
    im.paste(icon,(x,710),icon)
    elements.append(f'<image href="spark.svg" x="{x}" y="710" width="{n}" height="{n}"/>')
text(32,865,'Gameplay recommendation: 80px canvas gives a 60px visible sun in a 137px cell.',18,400,stroke=0)
text(32,897,'62px canvas gives a 46px sun. The earlier 48px canvas made the symbol too small.',17,400,stroke=0)
line(933)
text(32,956,'137px CELL / TWO SCALE OPTIONS',22,600,'#edb152',1)
for i,n in enumerate([62,80]):
    x=40+i*220;y=1010
    d.rectangle((x,y,x+137,y+137),fill='#372719',outline='#bb8a41',width=3)
    elements.append(f'<rect x="{x}" y="{y}" width="137" height="137" fill="#372719" stroke="#bb8a41" stroke-width="3"/>')
    text(x+9,y+10,'SPARK',17,600,stroke=1)
    icon=Image.open(HERE/f'spark-{n}.png').convert('RGBA')
    im.paste(icon,(x+(137-n)//2,y+29),icon)
    elements.append(f'<image href="spark.svg" x="{x+(137-n)//2}" y="{y+29}" width="{n}" height="{n}"/>')
    text(x+58,y+108,'6',24,600,stroke=1)
    text(x,y+152,f'{n}px sun canvas',15,400,stroke=0)
text(515,1017,'Reference direction',21,600,stroke=1)
text(515,1056,'Brighter center; long visible amber rays.',18,400,stroke=0)
text(515,1088,'Thin warm edge preserves sun silhouette.',18,400,stroke=0)
text(515,1120,'Ports stay separate atN/E/S/W edge centers.',18,400,stroke=0)
text(515,1152,'No owner approval or integration inferred.',18,400,stroke=0)
im.save(OUT/'type-spark-specimen.png')
(HERE/'type-spark-specimen.svg').write_text('<svg xmlns="http://www.w3.org/2000/svg" width="1100" height="1230" viewBox="0 0 1100 1230"><title>r002 actual Noto Serif and Spark review; editable text</title>'+''.join(elements)+'</svg>',encoding='utf8')
(HERE/'font-measurements.json').write_text(json.dumps(measure,indent=2)+'\n',encoding='utf8')
print(OUT/'type-spark-specimen.png')
