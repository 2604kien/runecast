"""Focused RC-014 source, texture, import and rendered evidence checks. No Git use.

This is a structural/technical audit. Artistic identity, painted alpha quality,
rights and device behavior require the separately recorded visual/release review.
"""
from __future__ import annotations

import argparse
import hashlib
from io import BytesIO
import json
from pathlib import Path
import re
import xml.etree.ElementTree as ET
import zipfile

from PIL import Image, ImageChops, ImageStat

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'source-assets/characters/shadeling'
PACK = ROOT / 'assets/enemies/shadeling'
QA = ROOT / 'output/qa/rc-014/framing-360'
ART = ROOT / 'output/art/rc-014/framing-360'
errors, checks = [], []


def check(ok, message, group):
    checks.append({'group': group, 'check': message, 'pass': bool(ok)})
    if not ok:
        errors.append(message)


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def relative(path):
    return path.relative_to(ROOT).as_posix()


def bounds(image, threshold=0):
    return image.getchannel('A').point(lambda a: 255 if a > threshold else 0).getbbox()


def inspect_ora(path):
    record = {'path': relative(path), 'sha256': sha(path), 'layers': []}
    with zipfile.ZipFile(path) as archive:
        check(archive.read('mimetype') == b'image/openraster', f'{path.name}: OpenRaster MIME', 'sources')
        stack = ET.fromstring(archive.read('stack.xml'))
        size = (int(stack.attrib['w']), int(stack.attrib['h']))
        check(size == (1024, 1024), f'{path.name}: 1024 square source canvas', 'sources')
        layers = list(stack.iter('layer'))
        check(len(layers) >= 5, f'{path.name}: at least five meaningful editable paint layers', 'sources')
        merged = Image.open(BytesIO(archive.read('mergedimage.png'))).convert('RGBA')
        composite = Image.new('RGBA', size)
        hashes, names = [], []
        for layer in reversed(layers):
            raw = archive.read(layer.attrib['src'])
            image = Image.open(BytesIO(raw))
            image.load()
            name = layer.attrib.get('name', '')
            names.append(name)
            check(image.mode == 'RGBA', f'{path.name}/{name}: RGBA layer', 'sources')
            check(image.size == size, f'{path.name}/{name}: common source canvas', 'sources')
            check(bounds(image) is not None, f'{path.name}/{name}: nonempty layer', 'sources')
            digest = hashlib.sha256(image.tobytes()).hexdigest()
            hashes.append(digest)
            check(digest != hashlib.sha256(merged.tobytes()).hexdigest(), f'{path.name}/{name}: not a duplicate flattened pose', 'sources')
            record['layers'].append({'name': name, 'source': layer.attrib['src'], 'sha256_rgba': digest,
                                     'alpha_bounds': bounds(image), 'opaque_pixels': image.getchannel('A').histogram()[255]})
            if layer.attrib.get('visibility', 'visible') == 'hidden':
                continue
            opacity = float(layer.attrib.get('opacity', '1'))
            if opacity != 1:
                image.putalpha(image.getchannel('A').point(lambda a: round(a*opacity)))
            composite.alpha_composite(image, (int(layer.attrib.get('x', '0')), int(layer.attrib.get('y', '0'))))
        check(len(set(names)) == len(names), f'{path.name}: unique semantic layer names', 'sources')
        check(len(set(hashes)) == len(hashes), f'{path.name}: unique layer pixel content', 'sources')
        delta = ImageChops.difference(composite, merged)
        maximum = max(channel[1] for channel in delta.getextrema())
        check(maximum <= 1, f'{path.name}: layer stack recomposes merged image (max channel error {maximum})', 'sources')
        record.update({'size': size, 'layer_count': len(layers), 'recomposition_max_channel_error': maximum,
                       'merged_alpha_bounds': bounds(merged)})
    return record


def inspect_texture(path):
    image = Image.open(path)
    image.load()
    check(image.mode == 'RGBA', f'{relative(path)}: straight RGBA image', 'textures')
    check(image.size == (512, 512), f'{relative(path)}: common 512 square canvas', 'textures')
    check(bool(image.info.get('icc_profile')), f'{relative(path)}: explicit colour profile', 'textures')
    image = image.convert('RGBA')
    box = bounds(image)
    box16 = bounds(image, 16)
    check(box is not None, f'{relative(path)}: visible alpha', 'textures')
    if box:
        check(box[0] >= 24 and box[1] >= 32 and box[2] <= 488 and box[3] <= 480,
              f'{relative(path)}: transparent outside envelope padding ({box})', 'textures')
    if box16:
        check(box16[0] >= 32 and box16[1] >= 32 and box16[2] <= 480 and box16[3] <= 480,
              f'{relative(path)}: strong alpha stays within32..480 ({box16})', 'textures')
    for corner in [(0,0),(511,0),(0,511),(511,511)]:
        check(image.getpixel(corner)[3] == 0, f'{path.name}: transparent corner {corner}', 'textures')
    recipe = path.with_name(path.name+'.import')
    check(recipe.is_file(), f'{relative(path)}: Godot import recipe exists', 'imports')
    if recipe.is_file():
        text = recipe.read_text(encoding='utf-8-sig')
        for setting in ['compress/mode=0','mipmaps/generate=false','process/fix_alpha_border=true']:
            check(setting in text, f'{relative(path)}: {setting}', 'imports')
    return {'path': relative(path), 'sha256': sha(path), 'size': image.size, 'alpha_bounds_nonzero': box,
            'alpha_bounds_gt16': box16, 'rgba8_decoded_bytes': image.width*image.height*4,
            'colour_profile_bytes': len(image.info.get('icc_profile', b''))}


def package_gifs(render):
    created = []
    for sequence in render.get('sequences', []):
        frames, durations = [], []
        for entry in sequence['frames']:
            path = ART / entry['file']
            if not path.is_file():
                check(False, f'Missing motion frame {entry["file"]}', 'renders')
                continue
            # Only package actual Godot renders; no artwork generation or retouch.
            frames.append(Image.open(path).convert('RGB'))
            durations.append(entry['duration_ms'])
        if not frames:
            continue
        durations[-1] += 650
        name = 'reduced-motion.gif' if sequence['reduced_motion'] else 'motion.gif'
        frames[0].save(ART/name, save_all=True, append_images=frames[1:], duration=durations, loop=0, disposal=2)
        created.append(name)
    return created


def main():
    global QA, ART
    parser = argparse.ArgumentParser()
    parser.add_argument('--report', default='output/qa/rc-014/framing-360/validation-report.json')
    parser.add_argument('--qa-dir', default='output/qa/rc-014/framing-360', help='Godot report and staged preview directory, relative to the project root')
    parser.add_argument('--art-dir', default='output/art/rc-014/framing-360', help='Rendered sheets and motion frames, relative to the project root')
    parser.add_argument('--package-gifs', action='store_true')
    args = parser.parse_args()
    QA = (ROOT/args.qa_dir).resolve()
    ART = (ROOT/args.art_dir).resolve()
    source_records = []
    oras = sorted(SOURCE.rglob('*.ora'))
    check(len(oras) >= 3, 'Neutral, attack and hit editable ORA masters exist', 'sources')
    for path in oras:
        try:
            source_records.append(inspect_ora(path))
        except Exception as exc:
            check(False, f'{relative(path)}: failed source inspection: {exc}', 'sources')
    textures = []
    for pose in ['neutral', 'attack', 'hit']:
        check((PACK/(pose+'.png')).is_file(), f'Required pose {pose}', 'textures')
    for path in sorted(PACK.rglob('*.png')):
        try:
            textures.append(inspect_texture(path))
        except Exception as exc:
            check(False, f'{relative(path)}: failed texture inspection: {exc}', 'textures')
    pose_paths = [PACK/(pose+'.png') for pose in ['neutral','attack','hit']]
    if all(p.is_file() for p in pose_paths):
        check(len({sha(path) for path in pose_paths}) == 3, 'Three distinct exported full poses', 'textures')
        bottoms = [bounds(Image.open(path).convert('RGBA'),16)[3] for path in pose_paths]
        check(max(bottoms)-min(bottoms) <= 4, f'Full poses have stable ground contact (bottom bounds {bottoms})', 'alignment')
    part_paths = list((PACK/'parts').glob('*.png'))
    check(len(part_paths) >= 7, 'Separately editable body/head/arm/lantern/light parts exported', 'alignment')
    metadata_path = SOURCE/'metadata.json'
    check(metadata_path.is_file(), 'Source/export alignment metadata exists', 'alignment')
    if metadata_path.is_file():
        metadata = json.loads(metadata_path.read_text(encoding='utf-8'))
        for record in metadata.get('reuse',[]):
            path = ROOT/record['path']
            check(path.is_file() and sha(path) == record['sha256'], 'Retained pilot dependency unchanged: '+record['path'], 'preservation')
        check(metadata.get('source_foot') == [512,896] and metadata.get('export_foot') == [256,448],
              'Common source/runtime foot anchors recorded', 'alignment')
        for pose in ['neutral','attack','hit']:
            master_path = SOURCE/metadata['poses'][pose]['master']
            with zipfile.ZipFile(master_path) as archive:
                merged = Image.open(BytesIO(archive.read('mergedimage.png'))).convert('RGBA')
                reference = merged.resize((512,512),Image.Resampling.LANCZOS)
            exported = Image.open(PACK/(pose+'.png')).convert('RGBA')
            error = ImageStat.Stat(ImageChops.difference(reference,exported)).mean
            # Transparent RGB can legitimately differ; premultiplied paint is the visible correspondence.
            def associated(image):
                rgba = image.copy()
                alpha = rgba.getchannel('A')
                return Image.merge('RGBA',(*[ImageChops.multiply(rgba.getchannel(channel),alpha) for channel in 'RGB'],alpha))
            visible_error = ImageStat.Stat(ImageChops.difference(associated(reference),associated(exported))).mean
            check(max(visible_error) < 1.0, f'{pose}: master/export visible correspondence (mean channel error {max(visible_error):.4f})', 'alignment')
        part_composite = Image.new('RGBA',(512,512))
        order = metadata.get('poses',{}).get('neutral',{}).get('draw_order',[])
        check(len(order) == len(part_paths), 'Neutral draw order covers all exported parts', 'alignment')
        for name in order:
            part_path = PACK/'parts'/(name+'.png')
            check(part_path.is_file(), 'Draw-order part exists: '+name, 'alignment')
            if part_path.is_file(): part_composite.alpha_composite(Image.open(part_path).convert('RGBA'))
        neutral = Image.open(PACK/'neutral.png').convert('RGBA')
        visible_error = ImageStat.Stat(ImageChops.difference(associated(part_composite),associated(neutral))).mean
        check(max(visible_error) < 1.0, f'Neutral parts reconstruct full pose (mean visible channel error {max(visible_error):.4f})','alignment')
    for path in list(PACK.glob('*.tscn'))+list(PACK.glob('*.tres'))+list(PACK.glob('*.gd')):
        content = path.read_text(encoding='utf-8-sig')
        for ref in re.findall(r'"res://([^"\n]+)"', content):
            if Path(ref).suffix:
                check((ROOT/ref).is_file(), f'{path.name}: resource exists {ref}', 'references')
        check('res://scripts/core/' not in content and 'res://scripts/ui/main' not in content,
              f'{path.name}: independent of combat runtime', 'boundaries')
    render_file = QA/'godot-render-results.json'
    check(render_file.is_file(), 'Actual Godot render report exists', 'renders')
    render = json.loads(render_file.read_text(encoding='utf-8')) if render_file.is_file() else {}
    check(render.get('result') == 'PASS' and not render.get('errors',[]), 'Godot imports/render/envelope checks pass', 'renders')
    check(render.get('behavior',{}).get('result') == 'PASS', 'Scene state/residency/endpoint behavior passes', 'renders')
    check(render.get('envelope',{}).get('sample_count',0) >= 136, 'Four states and reduced motion sampled across full envelope', 'renders')
    check(render.get('part_envelope',{}).get('sample_count',0) >= 17, 'Source-part stress samples remain inside canvas margin', 'renders')
    for entry in render.get('sheets', []):
        path = ART/entry['file']
        check(path.is_file(), 'Rendered evidence exists: '+entry['file'], 'renders')
        if path.is_file():
            with Image.open(path) as image:
                check(image.size == (entry['width'],entry['height']), 'Rendered dimensions: '+entry['file'], 'renders')
    for entry in textures:
        path = ROOT/entry['path']
        stage = QA/'preview-project'/entry['path']
        check(stage.is_file() and sha(stage) == sha(path), 'Rendered texture identical to delivery: '+entry['path'], 'staged_identity')
    imported = {x['path'].removeprefix('res://'):x for x in render.get('imported_resources',[])}
    for entry in textures:
        resource = imported.get(entry['path'],{})
        check((resource.get('width'),resource.get('height')) == (512,512), 'Imported texture dimensions: '+entry['path'], 'imports')
    gifs = package_gifs(render) if args.package_gifs else []
    memory = {'estimate_method':'RGBA8 width × height × 4, no mipmaps; excludes driver copies, framebuffers, font atlas and engine overhead; not measured device memory',
              'default_active_full_pose_bytes':512*512*4, 'warm_three_full_poses_bytes':3*512*512*4,
              'all_separate_parts_bytes':len(part_paths)*512*512*4,
              'full_poses_plus_all_parts_bytes':(3+len(part_paths))*512*512*4,
              'default_scene_loads_parts':False, 'part_count':len(part_paths)}
    report = {'task':'RC-014','result':'PASS' if not errors else 'FAIL','check_count':len(checks),'errors':errors,
              'evidence_directories':{'qa':relative(QA),'art':relative(ART)},
              'sources':source_records,'textures':textures,'memory':memory,'convenience_gifs':gifs,'checks':checks,
              'limitations':['Artistic alpha/identity review is recorded separately; this script does not certify aesthetics or rights.',
                             'Actual desktop Godot renders are not physical-device acceptance or measured memory.',
                             'Full gameplay integration and event-driven sequencing remain RC-016/RC-017.']}
    report_path = ROOT/args.report
    report_path.parent.mkdir(parents=True,exist_ok=True)
    report_path.write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
    print(json.dumps({key:report[key] for key in ['result','check_count','errors','memory','convenience_gifs']},indent=2))
    raise SystemExit(0 if not errors else 1)


if __name__ == '__main__':
    main()
