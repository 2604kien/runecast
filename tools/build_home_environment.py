"""Build the RC-015 Home source and export from retained clean generation.

Source paint is split into real complementary semantic regions, never screenshots.
The ORA supports regional repaint/recolour; relocating regions requires repainting.
Only this Home source directory and runtime Home directory are written.
"""
from pathlib import Path
from io import BytesIO
import hashlib
import json
import zipfile
import xml.etree.ElementTree as ET
import numpy as np
from PIL import Image, ImageDraw, ImageCms, ImageOps, ImageFont

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / 'source-assets/environments/home'
RUNTIME = ROOT / 'assets/environments/home'
SOURCE_SIZE = (1440, 3200)
EXPORT_SIZE = (720, 1600)
ICC = ImageCms.ImageCmsProfile(ImageCms.createProfile('sRGB')).tobytes()

def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def png_bytes(im):
    b = BytesIO()
    im.save(b, format='PNG', icc_profile=ICC)
    return b.getvalue()

def main():
    raw_path = SRC / 'raw/home-framed.png'
    raw = Image.open(raw_path).convert('RGBA')
    assert raw.size == (841, 1870)
    # Uniform center cover; the input is 0.06% narrower than exactly 9:20.
    # This trims 0.5556 raw pixels from top/bottom, without stretching.
    painting = ImageOps.fit(raw, SOURCE_SIZE, method=Image.Resampling.LANCZOS)
    labels = Image.new('L', raw.size)
    d = ImageDraw.Draw(labels)
    regions = [
        ('Indigo sky and cloud atmosphere', 'sky', []),
        ('Distant mountains bridges and mist', 'distance', [(0,442),(31,441),(47,534),(100,687),(152,588),(203,588),(234,548),(273,646),(307,630),(365,756),(445,756),(547,702),(603,654),(654,702),(696,661),(735,670),(771,607),(800,579),(817,641),(841,600),(841,1870),(0,1870)]),
        ('Tower architecture and rocky approach', 'tower', [(331,948),(336,898),(344,856),(350,821),(363,870),(369,912),(375,834),(385,790),(391,865),(397,628),(400,606),(405,599),(412,575),(418,536),(425,557),(433,578),(436,541),(440,516),(442,505),(452,461),(458,493),(467,522),(468,579),(480,605),(501,611),(514,619),(516,589),(532,548),(548,594),(549,619),(560,637),(566,659),(570,711),(581,721),(601,706),(605,659),(619,702),(620,723),(640,738),(652,748),(647,816),(630,824),(620,814),(620,884),(627,929),(640,968),(656,990),(659,1033),(641,1063),(657,1095),(674,1120),(670,1160),(695,1192),(700,1255),(713,1300),(699,1359),(704,1419),(697,1466),(650,1508),(577,1538),(494,1532),(466,1475),(493,1432),(509,1370),(493,1324),(510,1272),(509,1233),(478,1175),(466,1136),(453,1104),(464,1064),(491,1022),(509,1005),(505,985),(462,966),(441,972),(418,994),(396,1002),(358,1022),(323,1067),(295,1100),(305,1039),(315,990)]),
        ('Foreground stone control backing', 'paving', [(0,1238),(77,1327),(105,1468),(184,1543),(268,1515),(352,1529),(401,1494),(437,1488),(455,1533),(519,1540),(551,1520),(615,1511),(635,1484),(672,1534),(732,1487),(774,1339),(841,1283),(841,1870),(0,1870)]),
        ('Left edge brazier and rock dressing', 'left_brazier', [(0,1240),(44,1280),(74,1318),(105,1330),(128,1395),(131,1445),(108,1488),(84,1513),(40,1488),(0,1470)]),
        ('Right edge brazier and rock dressing', 'right_brazier', [(841,1290),(792,1307),(772,1387),(750,1396),(730,1420),(719,1466),(732,1511),(754,1546),(800,1537),(841,1539)]),
        ('Moon disk and blue light halo', 'moon', []),
    ]
    for i, (_, slug, polygon) in enumerate(regions[1:], 1):
        if slug == 'moon':
            d.ellipse((547,232,757,448), fill=i)
        else:
            d.polygon(polygon, fill=i)
    source_labels = np.asarray(ImageOps.fit(labels, SOURCE_SIZE, method=Image.Resampling.NEAREST))
    arr = np.asarray(painting)
    layers = []
    (SRC / 'layers').mkdir(parents=True, exist_ok=True)
    (SRC / 'masks').mkdir(parents=True, exist_ok=True)
    RUNTIME.mkdir(parents=True, exist_ok=True)
    for idx, (name, slug, _) in enumerate(regions):
        mask = source_labels == idx
        part = np.zeros_like(arr)
        part[mask] = arr[mask]
        layer = Image.fromarray(part)
        path = SRC / 'layers' / f'{idx:02d}-{slug}.png'
        mask_path = SRC / 'masks' / f'{idx:02d}-{slug}.png'
        layer.save(path, icc_profile=ICC)
        layer.getchannel('A').save(mask_path)
        assert layer.getbbox() is not None
        layers.append((name, path, layer, mask_path))
    # A separately editable tonal layer quiets the responsive live-control field.
    yy, xx = np.mgrid[0:3200, 0:1440]
    def smooth(a):
        a = np.clip(a, 0, 1)
        return a * a * (3 - 2 * a)
    amount = smooth((yy - 1860) / 300) * (1 - smooth((yy - 2890) / 230))
    amount *= smooth((xx - 40) / 180) * (1 - smooth((xx - 1220) / 180))
    veil = np.zeros((3200,1440,4), np.uint8)
    veil[:,:,:3] = (9,17,37)
    veil[:,:,3] = np.rint(amount * 48).astype(np.uint8)
    veil[veil[:,:,3] == 0] = 0
    veil_im = Image.fromarray(veil)
    veil_path = SRC / 'layers/07-control-backing-grade.png'
    veil_mask = SRC / 'masks/07-control-backing-grade.png'
    veil_im.save(veil_path, icc_profile=ICC)
    veil_im.getchannel('A').save(veil_mask)
    layers.append(('Adjustable quiet live-control backing grade', veil_path, veil_im, veil_mask))
    merged = Image.new('RGBA', SOURCE_SIZE)
    for _, _, layer, _ in layers:
        merged = Image.alpha_composite(merged, layer)
    assert merged.getchannel('A').getextrema() == (255,255)
    ungraded = Image.new('RGBA', SOURCE_SIZE)
    for _, _, layer, _ in layers[:-1]:
        ungraded = Image.alpha_composite(ungraded, layer)
    assert np.array_equal(np.asarray(ungraded), arr)
    runtime = merged.resize(EXPORT_SIZE, Image.Resampling.LANCZOS).convert('RGB')
    runtime_path = RUNTIME / 'home_tower.png'
    runtime.save(runtime_path, icc_profile=ICC)
    root = ET.Element('image', {'w':'1440','h':'3200','name':'Rune Cast RC-015 Home tower r001','version':'0.0.3'})
    stack = ET.SubElement(root, 'stack')
    with zipfile.ZipFile(SRC / 'home_tower.ora', 'w') as z:
        z.writestr('mimetype','image/openraster',compress_type=zipfile.ZIP_STORED)
        for idx, (name, path, layer, _) in reversed(list(enumerate(layers))):
            target=f'data/layer{idx:02d}.png'
            ET.SubElement(stack,'layer',{'name':name,'src':target,'x':'0','y':'0','opacity':'1.0','visibility':'visible','composite-op':'svg:src-over'})
            z.writestr(target,path.read_bytes(),compress_type=zipfile.ZIP_DEFLATED)
        z.writestr('stack.xml', ET.tostring(root, encoding='utf-8', xml_declaration=True))
        z.writestr('mergedimage.png',png_bytes(merged))
        thumb=merged.copy(); thumb.thumbnail((256,256))
        z.writestr('Thumbnails/thumbnail.png',png_bytes(thumb))
    svg = ['<svg xmlns="http://www.w3.org/2000/svg" width="841" height="1870" viewBox="0 0 841 1870">']
    for idx,(name,slug,polygon) in enumerate(regions):
        if polygon:
            points=' '.join(f'{x},{y}' for x,y in polygon)
            svg.append(f'<polygon id="{slug}" data-name="{name}" points="{points}" fill="none" stroke="#ffd36a" stroke-width="2"/>')
    svg.append('<ellipse id="moon" cx="652" cy="340" rx="105" ry="108" fill="none" stroke="#66cfff" stroke-width="2"/></svg>')
    (SRC/'separation-regions.svg').write_text('\n'.join(svg),encoding='utf-8')
    crop_rects={
        '9:16': [0,160,720,1280],
        '9:20': [0,0,720,1600],
        '9:21.5': [(720-1600*9/21.5)/2,0,1600*9/21.5,1600],
    }
    metadata={
        'asset_id':'home_tower','task':'RC-015','revision':'r001','date':'2026-10-13',
        'creator':'Codex using built-in image_gen and deterministic semantic layer/export authoring',
        'source_size':list(SOURCE_SIZE),'export_size':list(EXPORT_SIZE),'source':'home_tower.ora',
        'export':'assets/environments/home/home_tower.png','origin':[0,0],
        'color_space':'sRGB ICC','alpha':'RGB opaque runtime; straight-alpha RGBA source regions',
        'export_recipe':'Visible ORA stack src-over in bottom-to-top order; resize to720x1600 with Pillow LANCZOS; convert RGB; embed sRGB ICC.',
        'generation_input_size':[841,1870],
        'generation_to_master':{'mode':'uniform center cover','scale':1440/841,'raw_crop_rect':[0,5/9,841,841*20/9]},
        'source_to_export_scale':0.5,
        'layers':[{'name':name,'path':str(path.relative_to(SRC)).replace('\\','/'),'mask':str(mask.relative_to(SRC)).replace('\\','/'),'visible':True,'origin':[0,0],'bbox':layer.getbbox(),'sha256':digest(path),'ora_src':f'data/layer{idx:02d}.png'} for idx,(name,path,layer,mask) in enumerate(layers)],
        'semantic_recomposition_exact_before_grade':True,
        'editability':'Seven complementary semantic paint regions plus separate adjustable grading layer. Repaint, recolour and replace regions independently. Generated brushwork is flattened within each region; no brush history or hidden geometry is claimed. This is a static illustration, not a parallax or freely relocatable cutout rig.',
        'not_reference_screenshot_pixels':True,
        'crop_contract':{'mode':'center-cropped cover; uniform scaling only','runtime_source_rects':crop_rects,'formula':'k=max(viewport_width/720,viewport_height/1600); display=(runtime_point-(crop_x,crop_y))*k','max_loss_runtime':{'left':25.1162790698,'right':25.1162790698,'top':160,'bottom':160},'accepted_aspects':['9:16','9:20','9:21.5'],'declared_edge_allowance_runtime':{'left':36,'right':36,'top':160,'bottom':160},'revision_reason':'The older80px top/bottom allowance was insufficient for center-cover9:16, which removes160px each. Framing was revised before delivery to preserve moon and tower throughout.'},
        'focal_regions_runtime':{'horizontal_safe':[36,684],'intersection_of_all_crops':[36,160,648,1280],'moon_visible_disc':[485,214,146,150],'primary_tower':[285,394,278,459],'tower_approach':[248,801,364,490],'separate_logo_reservation':[36,70,648,330],'quiet_live_controls':[100,1010,520,440]},
        'preview_layout_guidance':'RC013 wordmark remains separate and uniformly scaled; live controls are responsive screen elements, never cropped as part of the illustration. Short-screen previews may position the wordmark higher relative to the cropped painting; protect the tower roof.',
        'runtime_import':{'lossless':True,'mipmaps':False,'premultiply_alpha':False,'filter':'linear','repeat':False,'size_limit':0},
        'memory':{'runtime_rgb_bytes':720*1600*3,'runtime_rgba8_conservative_bytes':720*1600*4,'runtime_rgba8_conservative_mib':720*1600*4/1048576,'master_layer_rgba8_mib':1440*3200*4/1048576,'all_source_layers_rgba8_mib':1440*3200*4*len(layers)/1048576,'scope':'Dimension estimates, not measured device/GPU memory. Source masters excluded from runtime.'},
        'provenance':'raw/generation-record.json','rights_status':'unresolved','approval_status':'reference_guided; no owner approval inferred',
        'runtime_sha256':digest(runtime_path),'source_sha256':digest(SRC/'home_tower.ora'),
        'scope':'Assets and isolated previews only. RC032 functional Home, RC042 full presentation integration, RC044 final supported responsive layouts. No physical-device acceptance.'
    }
    (SRC/'metadata.json').write_text(json.dumps(metadata,indent=2)+'\n',encoding='utf-8')
    # Compact artist-facing sheet, individual source regions shown honestly on gray.
    sheet=Image.new('RGB',(4*280,2*675),'#1b2336')
    font=ImageFont.truetype(str(ROOT/'assets/fonts/ui/NotoSerif-Variable.ttf'),15)
    draw=ImageDraw.Draw(sheet)
    for idx,(name,_,layer,_) in enumerate(layers):
        x=(idx%4)*280;y=(idx//4)*675
        sample=layer.copy();sample.thumbnail((270,600))
        bg=Image.new('RGBA',sample.size,'#455063');bg=Image.alpha_composite(bg,sample)
        sheet.paste(bg.convert('RGB'),(x+5,y+62))
        words=name.split();line='';line_y=y+5
        for word in words:
            if len(line+' '+word)>29:
                draw.text((x+6,line_y),line,font=font,fill='#ffe8b4');line=word;line_y+=19
            else:line=(line+' '+word).strip()
        draw.text((x+6,line_y),line,font=font,fill='#ffe8b4')
    sheet.save(SRC/'source-layer-sheet.png',icc_profile=ICC)
    print(json.dumps({'source_size':SOURCE_SIZE,'export_size':EXPORT_SIZE,'layers':len(layers),'opaque':True,'exact_region_recomposition':True,'runtime_rgba8_mib':metadata['memory']['runtime_rgba8_conservative_mib']}))

if __name__=='__main__':
    main()
