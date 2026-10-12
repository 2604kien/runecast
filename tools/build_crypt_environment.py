"""RC-015 mechanical layer assembly/export; never paints or alters retained inputs.

The retained clean environment plate supplies visible architecture/platform.
Imagegen supplies the actual newly painted hidden substrate. ORA is the editable
production master; rerunning this recipe restores the recorded initial delivery.
"""
from pathlib import Path
from io import BytesIO
import hashlib, json, zipfile
import xml.etree.ElementTree as ET
import numpy as np
from PIL import Image, ImageCms

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / 'source-assets/environments/crypt'
OUT = ROOT / 'assets/environments/crypt'
ICC = ImageCms.ImageCmsProfile(ImageCms.createProfile('sRGB')).tobytes()
SIZE = (841, 570)
MASTER = (1682, 1140)

def sha(p):
    return hashlib.sha256(p.read_bytes()).hexdigest()

def png(im):
    buf = BytesIO()
    im.save(buf, format='PNG', icc_profile=ICC)
    return buf.getvalue()

def build():
    SRC.mkdir(parents=True, exist_ok=True)
    (SRC/'layers').mkdir(exist_ok=True)
    OUT.mkdir(parents=True, exist_ok=True)
    retained = ROOT/'source-assets/pilot/revisions/r006/exports/crypt-background.png'
    plate = Image.open(retained).convert('RGBA').crop((0,0,*SIZE))
    # Uniform cover accommodates the generator's near-identical aspect without stretching.
    raw = Image.open(SRC/'raw/underpaint.png').convert('RGBA')
    factor = max(SIZE[0]/raw.width, SIZE[1]/raw.height)
    resized = raw.resize((round(raw.width*factor), round(raw.height*factor)), Image.Resampling.LANCZOS)
    ox, oy = (resized.width-SIZE[0])//2, (resized.height-SIZE[1])//2
    underpaint = resized.crop((ox,oy,ox+SIZE[0],oy+SIZE[1]))
    # The original paint spans the entire partially transparent floor boundary.
    # New paint begins only below the opaque floor, preserving visible composition.
    blend = np.clip((np.arange(SIZE[1])-396)/36,0,1)
    blend = Image.fromarray(np.repeat((blend*255).astype('uint8')[:,None],SIZE[0],axis=1))
    background = Image.composite(underpaint, plate, blend)
    horizon = np.interp(np.arange(SIZE[0]), [0,124,243,339,486,616,695,797,840], [348,379,364,381,370,374,352,372,340])
    alpha = np.clip((np.arange(SIZE[1])[:,None] - (horizon[None,:]-24))/24,0,1)
    floor = plate.copy()
    floor.putalpha(Image.fromarray(np.round(alpha*255).astype('uint8')))
    layers = []
    for name, stem, im in [('Rear architecture and painted hidden chamber','background',background),('Cobblestone platform, steps and near rocks','floor',floor)]:
        master = im.resize(MASTER, Image.Resampling.LANCZOS)
        path = SRC/'layers'/f'{stem}.png'
        path.write_bytes(png(master))
        runtime = master.resize(SIZE, Image.Resampling.LANCZOS)
        (OUT/f'{stem}.png').write_bytes(png(runtime.convert('RGB') if stem=='background' else runtime))
        layers.append((name, stem, master))
    merged = Image.new('RGBA',MASTER)
    for _,_,im in layers:
        merged = Image.alpha_composite(merged,im)
    (SRC/'merged.png').write_bytes(png(merged))
    root = ET.Element('image', {'w':str(MASTER[0]),'h':str(MASTER[1]),'name':'RC-015 shared crypt','version':'0.0.3'})
    stack = ET.SubElement(root,'stack')
    with zipfile.ZipFile(SRC/'crypt.ora','w') as z:
        z.writestr('mimetype','image/openraster',compress_type=zipfile.ZIP_STORED)
        for name,stem,im in reversed(layers):
            dest=f'data/{stem}.png'
            ET.SubElement(stack,'layer',{'name':name,'src':dest,'x':'0','y':'0','opacity':'1.0','visibility':'visible','composite-op':'svg:src-over'})
            z.writestr(dest,png(im),compress_type=zipfile.ZIP_DEFLATED)
        z.writestr('stack.xml',ET.tostring(root,encoding='utf-8',xml_declaration=True))
        z.writestr('mergedimage.png',png(merged))
        thumb=merged.copy();thumb.thumbnail((256,256));z.writestr('Thumbnails/thumbnail.png',png(thumb))
    meta = {
        'asset_id':'crypt','revision':'r001','date':'2026-10-13',
        'source_dimensions':list(MASTER),'export_dimensions':list(SIZE),
        'source_to_export_scale':0.5,'origin':[0,0],
        'coordinate_basis':'Retained r006 full composition, 841x1870; only y0..570 environment arena retained. Source coordinates are 2x this basis.',
        'resolution_note':'2x editing canvas is resampled from retained native 841-wide paint, not a claim of newly synthesized detail.',
        'layers':[{'name':name,'path':f'layers/{stem}.png','runtime':f'assets/environments/crypt/{stem}.png','sha256':sha(SRC/'layers'/f'{stem}.png')} for name,stem,_ in layers],
        'floor_contact':[446,428],'floor_contact_source':[892,856],
        'floor_overlap':{'horizon_points':[[0,348],[124,379],[243,364],[339,381],[486,370],[616,374],[695,352],[797,372],[840,340]],'alpha_ramp_above_horizon':24,'background_opaque_everywhere':True,'background_new_underpaint_blend_y':[396,432],'minimum_hidden_original_paint_below_horizon':15,'new_hidden_paint_continues_to_bottom':570,'full_opaque_under_floor_overlap':True},
        'review_crop':[0,60,841,450],
        'mapping':'runtime = source * 0.5; preview = (runtime - (0,60)) * W/841; character root=(446,368)*W/841, texture scale=0.75*W/841',
        'preview_sizes':[[720,385],[450,241],[360,193]],
        'overscan':{'left':0,'right':0,'top':60,'bottom':60,'art_only_450_high_crop_origin_y':[0,120],'accepted_actor_and_ui_crop':[0,60,841,450],'restriction':'Only default crop is accepted with current actor/live UI. Other art-only stress crops prove opaque coverage, not alternate layout approval. RC-016 owns responsive integration.'},
        'transform_contract':'Common top-left, common canvas, uniform positive scale and one translation for all layers. No independent transform, rotation or parallax. Rounded viewport height does not change scale.',
        'actor':{'texture_dimensions':[512,512],'foot_texture':[256,448],'texture_scale_in_composition':0.75,'foot_composition':[446,428],'declared_motion_envelope_composition':[272,116,620,452],'measured_rc014_motion_union_composition':[275.75,155,611,434]},
        'overlay_reservations_composition':{'intent':[390,76,500,144],'role_name_health':[285,436,600,508]},
        'foreground':{'delivered':False,'reason':'Existing edge stone/candles already frame the actor. A front layer adds occlusion and texture cost without a composition benefit.'},
        'color_space':'sRGB embedded ICC','alpha':'background RGB opaque; floor RGBA straight alpha','import':'lossless; linear; no mipmaps; repeat disabled; alpha border fix',
        'reuse':[{'path':str(retained.relative_to(ROOT)).replace('\\','/'),'sha256':sha(retained)},{'path':'source-assets/pilot/revisions/r004/crypt/crypt.ora','sha256':sha(ROOT/'source-assets/pilot/revisions/r004/crypt/crypt.ora')}],
        'generation':{'tool':'image_gen.imagegen','mode':'built-in edit','model':None,'seed':None,'unknown_note':'Tool did not expose model version or seed','prompt':'raw/underpaint.prompt.txt','raw':'raw/underpaint.png','raw_sha256':sha(SRC/'raw/underpaint.png'),'edit_target':'raw/retained-arena.png','original_tool_output':'C:/Users/nguye/.codex/generated_images/01a13059-c8ac-7e43-ba59-ee48e1c6c3e9/exec-a12a3d87-bedb-4219-b527-f619c629debe.png'},
        'editability':'Two overlapping full-canvas semantic paint layers. The rear chamber remains fully painted when floor is hidden; newly generated hidden substrate replaces the old raised platform below y432. Visible architecture/floor reuse the clean generated pilot, never the approved screenshot. Brush history unavailable.',
        'memory':{'rgba8_layer_bytes':841*570*4,'two_layers_bytes':841*570*4*2,'two_layers_mib':841*570*8/1048576,'mipmaps':False,'measurement':'dimension estimate, excludes engine, fonts and render buffers'},
        'readiness_status':'source_ready','visual_direction_status':'reference_guided','licence_status':'unresolved','rights_note':'Inherited reference/generated-art rights remain unresolved; no approval or release clearance inferred.'
    }
    (SRC/'metadata.json').write_text(json.dumps(meta,indent=2)+'\n',encoding='utf-8')
    print(json.dumps({'source':MASTER,'runtime':SIZE,'layers':len(layers),'memory_MiB':meta['memory']['two_layers_mib']}))

if __name__=='__main__':
    build()
