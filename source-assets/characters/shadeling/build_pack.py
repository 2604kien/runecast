"""RC-014 technical assembly of retained/generated painting into editable sources.

No painting is synthesized by this script. Imagegen supplies all new brushwork;
this script records cut masks, normalization, underlap placement, ORA and exports.
Pilot inputs are read-only. Run using Python with Pillow and NumPy.
"""
from pathlib import Path
from io import BytesIO
import hashlib, json, zipfile, xml.etree.ElementTree as ET
from PIL import Image, ImageChops, ImageCms, ImageDraw
import numpy as np

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
PILOT = ROOT/'source-assets/pilot/revisions/r002'
RUNTIME = ROOT/'assets/enemies/shadeling'
OUT = ROOT/'output/art/rc-014'
ICC = ImageCms.ImageCmsProfile(ImageCms.createProfile('sRGB')).tobytes()
SIZE = (1024,1024)
LZ = Image.Resampling.LANCZOS

def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def clear_hidden_rgb(im):
    a=np.array(im);a[a[:,:,3]==0]=0;return Image.fromarray(a)
def save(im,p):
    p.parent.mkdir(parents=True,exist_ok=True)
    clear_hidden_rgb(im).save(p,icc_profile=ICC)
def mask(points):
    im=Image.new('L',SIZE); ImageDraw.Draw(im).polygon(points,fill=255); return im
def cut(im,m):
    o=im.copy(); o.putalpha(ImageChops.multiply(im.getchannel('A'),m)); return clear_hidden_rgb(o)
def compose(layers):
    o=Image.new('RGBA',SIZE)
    for p in layers.values(): o.alpha_composite(p)
    return o
def normalize(name,scale,tx,ty):
    im=Image.open(HERE/'raw'/f'{name}.png').convert('RGBA')
    a=np.array(im); removed=int(((a[:,:,3]>0)&(a[:,:,3]<=3)).sum()); a[a[:,:,3]<=3]=0
    im=Image.fromarray(a)
    out=im.transform(SIZE,Image.Transform.AFFINE,(1/scale,0,-tx/scale,0,1/scale,-ty/scale),Image.Resampling.BICUBIC)
    return out,{'raw_size':list(im.size),'scale':scale,'translate':[tx,ty],'removed_alpha_lte':3,'residue_pixels':removed}
def ora(path,layers,title):
    merged=compose(layers)
    doc=ET.Element('image',{'version':'0.0.3','w':'1024','h':'1024','name':title})
    stack=ET.SubElement(doc,'stack',{'name':'Editable painted parts — bottom to top in build record'})
    with zipfile.ZipFile(path,'w',zipfile.ZIP_DEFLATED) as z:
        z.writestr('mimetype','image/openraster',compress_type=zipfile.ZIP_STORED)
        for name,im in reversed(list(layers.items())):
            src=f'data/{name}.png'
            ET.SubElement(stack,'layer',{'name':name,'src':src,'opacity':'1.0','visibility':'visible','composite-op':'svg:src-over','x':'0','y':'0'})
            b=BytesIO(); im.save(b,format='PNG',icc_profile=ICC); z.writestr(src,b.getvalue())
        z.writestr('stack.xml',ET.tostring(doc,encoding='utf-8',xml_declaration=True))
        for name,im in [('mergedimage.png',merged),('Thumbnails/thumbnail.png',merged.resize((256,256),LZ))]:
            b=BytesIO(); im.save(b,format='PNG',icc_profile=ICC);z.writestr(name,b.getvalue())
    return merged
def layer_record(layers):
    return {k:{'alpha_gt16_pixels':int((np.asarray(p)[:,:,3]>16).sum()),'rgba_sha256':hashlib.sha256(p.tobytes()).hexdigest(),'bounds_gt16':p.getchannel('A').point(lambda a:255 if a>16 else 0).getbbox()} for k,p in layers.items()}

# Keep neutral pose's full composition. Only hidden underlaps and part assignment change.
old={p.stem:Image.open(p).convert('RGBA') for p in (PILOT/'layers').glob('*.png')}
neutral=Image.open(PILOT/'neutral-reference.png').convert('RGBA')
under_scale=720/884
under,under_map=normalize('underlap',under_scale,469-568*under_scale,896-1099*under_scale)
save(under,HERE/'refinements/underlap-normalized.png')
hood_points=[(460,160),(554,192),(555,219),(527,246),(579,297),(579,345),(550,391),(484,439),(418,420),(365,352),(371,296),(401,213)]
hood_mask=mask(hood_points)
body=old['body_cloak'].copy()
# Tiny isolated gold chain residue in the old body region belongs with the lantern.
fleck_mask=mask([(118,438),(152,438),(152,506),(118,506)])
fleck=cut(body,fleck_mask)
body.putalpha(ImageChops.subtract(body.getchannel('A'),fleck.getchannel('A')))
head=cut(body,hood_mask)
body.putalpha(ImageChops.subtract(body.getchannel('A'),head.getchannel('A')))
# New painted shoulder: only the missing inner shoulder/cloth seam; no duplicate arm.
shoulder_points=[(309,326),(407,317),(443,374),(432,426),(399,498),(353,552),(318,561),(289,510),(290,450),(301,396)]
shoulder=cut(under,mask(shoulder_points))
# Painted cloth sampled from repair plate, remapped behind hood base. This is a
# real generated robe patch, not a named duplicate of the flattened character.
neck_patch=under.crop((432,514,568,654)).resize((244,200),Image.Resampling.BICUBIC)
neck_canvas=Image.new('RGBA',SIZE);neck_canvas.alpha_composite(neck_patch,(365,278))
neck_points=[(400,319),(516,315),(552,286),(584,291),(597,338),(566,402),(514,448),(470,465),(413,434),(379,387)]
neck=cut(neck_canvas,ImageChops.multiply(mask(neck_points),neutral.getchannel('A')))
# Underlaps are behind intact extracted surfaces. Neutral silhouette stays broad;
# overlapping hidden paint is required when the shoulder/head move slightly.
layers={
 'shoulder_underlap':shoulder,
 'neck_underlap':neck,
 'body_cloak':body,
 'head_hood':head,
 'lantern_arm':old['lantern_arm'],
 'lantern_glass_backing':old['lantern_glass_backing'],
 'lantern_shell':old['lantern_shell'],
 'lantern_glass_light':old['lantern_glass_light'],
 'flame':old['flame'],
}
layers['lantern_shell']=layers['lantern_shell'].copy();layers['lantern_shell'].alpha_composite(fleck)
layers={k:clear_hidden_rgb(im) for k,im in layers.items()}

records={}; maps={}; poses={}
poses['neutral']=ora(HERE/'shadeling.ora',layers,'RC-014 Shadeling r001 — neutral with painted underlaps')
for k,im in layers.items():
    save(im,HERE/'layers'/f'{k}.png');save(im.resize((512,512),LZ),RUNTIME/'parts'/f'{k}.png')
records['neutral']={'master':'shadeling.ora','layers':layer_record(layers),'draw_order':list(layers)}

# Coordinates of separation polygons below are in immutable generated1254px space.
# The character is normalized uniformly against one fixed ground, never tight-cropped.
raw_polys={
 'attack':{
  'head_hood':[(625,181),(731,222),(717,269),(738,315),(776,377),(729,442),(684,477),(642,507),(582,482),(520,407),(478,363),(508,300),(529,265)],
  'lantern_arm':[(175,209),(252,198),(307,252),(352,305),(413,330),(461,380),(487,441),(523,529),(536,652),(496,661),(433,591),(400,494),(345,435),(304,379),(278,332),(227,325),(164,296)],
  'lantern':[(58,280),(163,271),(166,295),(207,306),(240,279),(266,293),(269,328),(245,368),(278,424),(248,522),(236,588),(201,627),(113,611),(55,568),(48,500),(79,427),(89,408),(59,417)],
  'window':[(120,411),(253,437),(209,549),(88,525)],
 },
 'hit':{
  'head_hood':[(812,202),(924,258),(905,305),(917,369),(920,412),(873,449),(818,480),(767,498),(727,478),(690,424),(679,364),(663,333),(710,285),(740,256)],
  'lantern_arm':[(326,540),(394,529),(417,502),(492,477),(526,493),(509,548),(453,576),(426,602),(389,627),(341,621),(320,584)],
  'lantern':[(269,616),(321,602),(342,624),(375,619),(399,598),(421,610),(401,650),(413,682),(438,722),(412,797),(405,861),(378,904),(298,896),(254,855),(255,810),(276,736),(266,730),(263,702)],
  'window':[(310,723),(411,745),(380,838),(280,822)],
  'free_arm':[(644,398),(687,391),(728,435),(735,480),(783,531),(828,553),(817,598),(773,584),(732,539),(700,507),(664,484),(642,457),(627,423)]
 }
}
normalization={
 'attack':(720/929,64-55*(720/929),896-1118*(720/929)),
 'hit':(720/887,512-671*(720/887),896-1095*(720/887)),
}
for pose,(s,tx,ty) in normalization.items():
    full,maps[pose]=normalize(pose,s,tx,ty)
    polys={k:[(round(x*s+tx),round(y*s+ty)) for x,y in v] for k,v in raw_polys[pose].items()}
    lm=mask(polys['lantern']); am=ImageChops.subtract(mask(polys['lantern_arm']),lm); hm=mask(polys['head_hood'])
    parts={}
    taken=ImageChops.lighter(lm,ImageChops.lighter(am,hm))
    if 'free_arm' in polys:
        fm=ImageChops.subtract(mask(polys['free_arm']),taken);taken=ImageChops.lighter(taken,fm)
    parts['body_cloak']=cut(full,ImageChops.invert(taken))
    parts['head_hood']=cut(full,hm)
    parts['lantern_arm']=cut(full,am)
    if 'free_arm' in polys: parts['free_arm']=cut(full,fm)
    window=ImageChops.multiply(lm,mask(polys['window']))
    a=np.asarray(full)
    bright=((a[:,:,0]>190)&(a[:,:,1]>100)&(a[:,:,0].astype(float)>a[:,:,2]*1.5))
    flame=ImageChops.multiply(window,Image.fromarray((bright*255).astype('uint8')))
    parts['lantern_shell']=cut(full,ImageChops.subtract(lm,window))
    parts['lantern_glass_light']=cut(full,ImageChops.subtract(window,flame))
    parts['flame']=cut(full,flame)
    target=HERE/'poses'/f'{pose}.ora'
    poses[pose]=ora(target,parts,f'RC-014 Shadeling r001 — painted {pose}')
    for k,im in parts.items(): save(im,HERE/'poses'/pose/f'{k}.png')
    records[pose]={'master':f'poses/{pose}.ora','layers':layer_record(parts),'draw_order':list(parts),'source_masks':polys,
       'part_motion':'Editable paint regions, not a separate runtime rig. Full-pose switching/transforms avoid revealed hidden anatomy.'}

for name,im in poses.items():
    save(im,HERE/f'{name}-reference.png')
    run=im.resize((512,512),LZ)
    save(run,RUNTIME/f'{name}.png')
    records[name]['source_size']=[1024,1024];records[name]['runtime_size']=[512,512]
    records[name]['alpha_bounds_all']=run.getchannel('A').getbbox()
    records[name]['alpha_bounds_gt16']=run.getchannel('A').point(lambda a:255 if a>16 else 0).getbbox()
    records[name]['alpha_bounds_opaque']=run.getchannel('A').point(lambda a:255 if a==255 else 0).getbbox()
    records[name]['runtime_sha256']=sha(RUNTIME/f'{name}.png')

generation=[]
outputs={'attack':'exec-4f9ff55e-c0a4-40e9-b9a0-d89f0aa2f5dc.png','hit':'exec-76047cb4-7dc2-4550-967a-704c13b0207e.png','underlap':'exec-400f73d4-5e26-4ea7-96fd-91f813375fee.png'}
for name,out in outputs.items():
    generation.append({'name':name,'tool':'image_gen.imagegen','mode':'built-in edit','model_version':None,'seed':None,'model_seed_status':'not exposed by tool','date':'2026-10-12','prompt':f'raw/{name}.prompt.txt','raw':f'raw/{name}.png','sha256':sha(HERE/'raw'/f'{name}.png'),'original_tool_output':f'C:/Users/nguye/.codex/generated_images/01a12b4e-e815-7710-afd5-0cd606deb26f/{out}','edit_target':'source-assets/pilot/revisions/r002/neutral-reference.png','edit_target_sha256':sha(PILOT/'neutral-reference.png'),'transparent_background':True})
attachment_raw={
 'attack':{'head':(609,360),'body_center':(664,735),'attack_origin':(225,269),'lantern_pivot':(243,310)},
 'hit':{'head':(786,351),'body_center':(724,678),'attack_origin':(382,578),'lantern_pivot':(397,606)}
}
old_meta=json.loads((PILOT/'metadata.json').read_text())
attachments={'neutral':{k:old_meta['export_pivots'][v] for k,v in [('head','head'),('body_center','body_center'),('attack_origin','attack_origin'),('lantern_pivot','held_item')]}}
for pose,points in attachment_raw.items():
    s,tx,ty=normalization[pose];attachments[pose]={k:[round((x*s+tx)/2,3),round((y*s+ty)/2,3)] for k,(x,y) in points.items()}
metadata={'asset_id':'shadeling','revision':'r001','task':'RC-014','date':'2026-10-12','source_size':[1024,1024],'export_size':[512,512],'source_foot':[512,896],'export_foot':[256,448],
 'roster_role':'designated_map_encounter_boss',
 'role_context':'Boss for one designated map encounter, not introductory normal enemy or automatically final guardian. Preserve shadeling and training_shadeling IDs and existing development fixtures. RC-025/RC-034 own encounter placement and behavior.',
 'pose_feedback':{'date':'2026-10-12','owner_decision':'Keep the pose; document future dodging','hit_reading':'Owner observed a dodge-like lean. Retain the delivered hit pose and four-state interface without repainting or renaming.','possible_mechanic':'Dodging is a candidate for RC-034 boss design, not an implemented or committed mechanic. No chance, timing, balance, new state or phase is specified.','downstream':'If adopted, RC-017 must distinguish resolved damage, dodge and zero-damage feedback without inferring outcomes from the pose. RC-016 owns live labels and illustration integration.','decision_record':'docs/decisions.md#october-12-2026--preserve-shadeling-pose-and-consider-dodging'},
 'colour':{'space':'sRGB','alpha':'straight/unassociated','profile':'embedded standard sRGB ICC; no pixel recolour'},
 'poses':records,'normalization':maps,'underlap_normalization':under_map,
 'neutral_masks':{'head_hood':hood_points,'shoulder_underlap':shoulder_points,'neck_underlap':neck_points},
 'neutral_part_pivots':{'foot':[256,448],'head_hood':[237,208],'lantern_arm':old_meta['export_pivots']['lantern_arm'],'held_item':old_meta['export_pivots']['held_item'],'flame':old_meta['export_pivots']['flame']},
 'part_envelope_degrees':{'head_hood':[-2,2],'lantern_arm':[-4,4],'held_item_relative_to_arm':[-3,3]},
 'attachments':attachments,
 'presentation':{'reference_composition':[841,1870],'sprite_top_left':[254,92],'sprite_display':[384,384],'texture_scale':0.75,'foot_composition':[446,428],'arena_crop':[0,60,841,450],'foot_crop':[446,368],'design_width':720,'design_scale':.75*720/841,'desktop_width':450,'desktop_scale':.75*450/841,'native_width':360,'native_texture_scale':.75*360/841,'native_foot':[446*360/841,368*360/841],'native_viewport':[360,193],'native_mapping':'Proportional arena-only preview: same Rect(0,60,841,450) crop and W/841 transform as 720/450; rounded viewport height does not alter uniform art scale. Not full native-phone acceptance.','historical_r006_native':{'sprite_top_left':[90,60],'sprite_display':[180,180],'texture_scale':180/512,'foot':[180,217.5],'isolated_preview_viewport':[360,280],'status':'Preserved historical separate r006 native layout; superseded for RC-014 proportional arena previews by owner framing correction on 2026-10-12.'},'allowed_alpha_envelope':[24,32,488,480],'padding_revision':'RC-014 wide painted attack keeps significant-alpha X32..474 and filtered alpha X29..476. Explicit24px horizontal safety border replaces32 for this pack; no canvas, origin or actor downscaling.'},
 'generation':generation,'reuse':[{'path':str(p.relative_to(ROOT)).replace('\\','/'),'sha256':sha(p)} for p in [PILOT/'shadeling.ora',PILOT/'neutral-reference.png',PILOT/'raw/shadeling.png',PILOT/'raw/shadeling.prompt.txt',PILOT/'metadata.json']+sorted((PILOT/'layers').glob('*.png'))],
 'source_method':'Neutral retained paint, separate extracted hood, generated shoulder/neck underlaps. Attack/hit are newly generated paintings with disjoint semantic masks. No flattened duplicate layers. Brush stroke history unavailable; ORA is authoritative editable pixel-layer interchange.',
 'memory':{'rgba8_single_pose_bytes':1048576,'rgba8_three_poses_bytes':3145728,'rgba8_neutral_parts_bytes':len(layers)*1048576,'rgba8_all_poses_and_parts_bytes':(3+len(layers))*1048576,'default_active':'One full pose, no part textures; transient old/new overlap may reach 2MiB while swapping. Optional warm cache retains3MiB. Nine part textures are9MiB only in part stress/optional alternate rig.','excludes':'import compression, mipmaps (off), font atlases, environment, UI, renderer buffers, allocator/cache overhead; estimates not measured device memory'},
 'readiness_status':'source_ready','technical_status':'pending final Godot and source checks','visual_direction_status':'reference_guided','licence_status':'unresolved','rights_note':'Inherited generated-art/reference rights remain unresolved. No owner acceptance or release clearance inferred from reference approval.'}
(HERE/'metadata.json').write_text(json.dumps(metadata,indent=2)+'\n',encoding='utf-8')
(HERE/'raw/generation-record.json').write_text(json.dumps(generation,indent=2)+'\n',encoding='utf-8')
# Explicit human-editable mask outlines, linked to full source reference.
for name,regions in [('neutral',metadata['neutral_masks'])]+[(p,r['source_masks']) for p,r in records.items() if 'source_masks' in r]:
    lines=['<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1024" viewBox="0 0 1024 1024">',f'<image href="{name}-reference.png" width="1024" height="1024"/>']
    for key,pts in regions.items(): lines.append(f'<polygon id="{key}" points="'+ ' '.join(f'{x},{y}' for x,y in pts)+'" fill="none" stroke="#29e6d0" stroke-width="2"/>')
    lines+=['<path d="M496 896H528M512 880V912" stroke="#ffc760"/>','</svg>']
    (HERE/f'{name}-masks.svg').write_text('\n'.join(lines),encoding='utf-8')
print(json.dumps({'poses':{p:r['alpha_bounds_gt16'] for p,r in records.items()},'attachments':attachments,'parts':list(layers)},indent=2))
