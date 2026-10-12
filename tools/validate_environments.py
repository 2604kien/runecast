"""Focused RC-015 source/export, geometry, import and preservation verification.

Does not repaint images, access Git, run gameplay tests or overwrite older QA.
Use --snapshot before delivery edits, then run normally after the isolated render.
Art direction/readability require the separately recorded visual review.
"""
from __future__ import annotations

import argparse
from collections import Counter
import hashlib
from io import BytesIO
import json
from pathlib import Path
import re
import sys
import xml.etree.ElementTree as ET
import zipfile

import numpy as np
from PIL import Image, ImageChops

ROOT = Path(__file__).resolve().parents[1]
QA = ROOT / "output/qa/rc-015"
ART = ROOT / "output/art/rc-015"
checks: list[dict] = []
errors: list[str] = []


def rel(path: Path) -> str:
    return path.relative_to(ROOT).as_posix()


def sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def check(ok, message: str, group: str) -> None:
    checks.append({"group": group, "check": message, "pass": bool(ok)})
    if not ok:
        errors.append(message)


def read_json(path: Path):
    return json.loads(path.read_text(encoding="utf-8-sig"))


def protected_paths():
    roots = ["assets", "source-assets", "scripts", "scenes", "data",
             "output/imagegen/approved", "output/art/rc-014/framing-360"]
    excluded = ("assets/environments/", "source-assets/environments/")
    paths = set()
    for folder in roots:
        for path in (ROOT / folder).rglob("*"):
            if path.is_file() and not rel(path).startswith(excluded):
                paths.add(path)
    for filename in ["project.godot", "export_presets.cfg"]:
        paths.add(ROOT / filename)
    return sorted(paths)


def snapshot() -> None:
    destination = QA / "preservation-baseline.json"
    if destination.exists():
        raise SystemExit("Refusing to overwrite the existing preservation baseline")
    files = [{"path": rel(path), "sha256": sha(path), "bytes": path.stat().st_size}
             for path in protected_paths()]
    destination.parent.mkdir(parents=True, exist_ok=True)
    destination.write_text(json.dumps({"task": "RC-015", "scope":
        "Existing assets and sources excluding new environment folders; scripts, scenes, data, project/export settings, approved references and current RC-014 previews. No Git operation.",
        "files": files}, indent=2) + "\n", encoding="utf-8")
    print(f"RC015 preservation snapshot: {len(files)} files -> {rel(destination)}")


def validate_preservation():
    path = QA / "preservation-baseline.json"
    check(path.is_file(), "Pre-delivery preservation baseline exists", "preservation")
    if not path.is_file():
        return {}
    records = read_json(path)["files"]
    for record in records:
        actual = ROOT / record["path"]
        check(actual.is_file() and sha(actual) == record["sha256"],
              f"Unchanged: {record['path']}", "preservation")
    expected = {row["path"] for row in records}
    unexpected = [rel(p) for p in protected_paths() if rel(p) not in expected]
    check(not unexpected, "No new files in protected existing asset/source/gameplay scope", "preservation")
    return {"files": len(records), "unexpected_files": unexpected, "baseline": rel(path)}


def open_image(path: Path) -> Image.Image:
    image = Image.open(path)
    image.load()
    return image


def max_delta(a: Image.Image, b: Image.Image) -> int:
    if a.size != b.size:
        return 256
    return max(hi for lo, hi in ImageChops.difference(a.convert("RGBA"), b.convert("RGBA")).getextrema())


def inspect_ora(path: Path, expected: tuple[int, int], minimum_layers: int):
    check(path.is_file(), f"Required editable master: {rel(path)}", "sources")
    if not path.is_file():
        return {}, None, []
    record = {"path": rel(path), "sha256": sha(path), "layers": []}
    with zipfile.ZipFile(path) as archive:
        check(archive.testzip() is None, f"{path.name}: ZIP integrity", "sources")
        check(archive.read("mimetype") == b"image/openraster", f"{path.name}: OpenRaster MIME", "sources")
        stack = ET.fromstring(archive.read("stack.xml"))
        size = (int(stack.attrib["w"]), int(stack.attrib["h"]))
        check(size == expected, f"{path.name}: source dimensions {expected}", "sources")
        layers = list(stack.iter("layer"))
        check(len(layers) >= minimum_layers, f"{path.name}: at least {minimum_layers} editable layers", "sources")
        merged = Image.open(BytesIO(archive.read("mergedimage.png"))).convert("RGBA")
        check(merged.size == expected, f"{path.name}: merged canvas alignment", "sources")
        composite = Image.new("RGBA", size)
        pixels, names, decoded = [], [], []
        for layer in reversed(layers):
            image = Image.open(BytesIO(archive.read(layer.attrib["src"])))
            image.load()
            name = layer.attrib.get("name", "")
            check(bool(name.strip()), f"{path.name}: named semantic layer", "sources")
            check(image.size == size and image.mode == "RGBA", f"{path.name}/{name}: aligned full-canvas RGBA", "sources")
            check(layer.attrib.get("x", "0") == "0" and layer.attrib.get("y", "0") == "0",
                  f"{path.name}/{name}: common origin", "sources")
            check(layer.attrib.get("composite-op", "svg:src-over") == "svg:src-over",
                  f"{path.name}/{name}: reproducible normal blend mode", "sources")
            image = image.convert("RGBA")
            bounds = image.getchannel("A").getbbox()
            check(bounds is not None, f"{path.name}/{name}: nonempty paint", "sources")
            pixel_hash = hashlib.sha256(image.tobytes()).hexdigest()
            check(pixel_hash != hashlib.sha256(merged.tobytes()).hexdigest(),
                  f"{path.name}/{name}: not duplicate flattened composite", "sources")
            names.append(name)
            pixels.append(pixel_hash)
            decoded.append((name, image.copy(), layer.attrib))
            record["layers"].append({"name": name, "source": layer.attrib["src"], "alpha_bounds": bounds,
                "alpha_extrema": image.getchannel("A").getextrema(), "rgba_sha256": pixel_hash})
            if layer.attrib.get("visibility", "visible") != "hidden":
                opacity = float(layer.attrib.get("opacity", "1"))
                if opacity != 1:
                    image.putalpha(image.getchannel("A").point(lambda a: round(a * opacity)))
                composite.alpha_composite(image)
        check(len(set(names)) == len(names), f"{path.name}: unique layer names", "sources")
        check(len(set(pixels)) == len(pixels), f"{path.name}: distinct layer pixels", "sources")
        difference = max_delta(composite, merged)
        check(difference <= 1, f"{path.name}: visible layers reproduce merged image (max error {difference})", "sources")
        record.update({"source_size": size, "layer_count": len(layers), "recomposition_max_error": difference})
        return record, merged, decoded


def inspect_png(path: Path, size: tuple[int, int], opaque: bool | None):
    check(path.is_file(), f"Required export: {rel(path)}", "textures")
    if not path.is_file():
        return {}, None
    image = open_image(path)
    check(image.size == size, f"{path.name}: export dimensions {size}", "textures")
    check(image.mode in ("RGB", "RGBA"), f"{path.name}: RGB/RGBA8 PNG", "textures")
    check(bool(image.info.get("icc_profile")), f"{path.name}: embedded sRGB profile", "textures")
    check(max(size) <= 2048, f"{path.name}: <=2048 runtime axis budget", "memory")
    rgba = image.convert("RGBA")
    alpha = rgba.getchannel("A")
    if opaque is True:
        check(alpha.getextrema() == (255, 255), f"{path.name}: fully opaque", "textures")
    elif opaque is False:
        check(alpha.getextrema() == (0, 255), f"{path.name}: meaningful transparent/opaque coverage", "textures")
    return {"path": rel(path), "sha256": sha(path), "size": size, "mode": image.mode,
            "alpha_extrema": alpha.getextrema(), "alpha_bounds": alpha.getbbox(),
            "rgba8_bytes": size[0]*size[1]*4, "rgba8_mib": size[0]*size[1]*4/1048576}, rgba


def inspect_crypt():
    folder = ROOT / "source-assets/environments/crypt"
    metadata_path = folder / "metadata.json"
    metadata = read_json(metadata_path) if metadata_path.is_file() else {}
    source, merged, layers = inspect_ora(folder / "crypt.ora", (1682, 1140), 2)
    bg_record, bg = inspect_png(ROOT / "assets/environments/crypt/background.png", (841, 570), True)
    floor_record, floor = inspect_png(ROOT / "assets/environments/crypt/floor.png", (841, 570), False)
    if bg is not None and floor is not None:
        for filename, output in [("background", bg), ("floor", floor)]:
            source_names = [entry.get("name") for entry in metadata.get("layers", [])
                            if entry.get("runtime", "").endswith("/"+filename+".png")]
            matches = [(name, image) for name, image, attrs in layers
                       if name in source_names]
            if len(matches) == 1:
                difference = max_delta(matches[0][1].resize((841,570), Image.Resampling.LANCZOS), output)
                check(difference <= 1, f"Crypt {filename}: exact source layer -> Lanczos export (max error {difference})", "correspondence")
            else:
                check(False, f"Crypt {filename}: unambiguous named ORA layer mapping", "correspondence")
        arr_bg, arr_floor = np.array(bg), np.array(floor)
        overlap = int(np.count_nonzero((arr_bg[:,:,3] == 255) & (arr_floor[:,:,3] > 0)))
        check(overlap > 841 * 24, "Crypt: painted background under more than 24 full-width rows of visible floor", "overlap")
        check(bool(np.all(arr_bg[:,:,3] == 255)), "Crypt: hidden background remains painted through all floor coverage", "overlap")
        check(np.count_nonzero((arr_floor[:,:,3] > 0) & (arr_floor[:,:,3] < 255)) > 841,
              "Crypt: filtered/feathered floor overlap has intermediate alpha", "overlap")
        recomposed = Image.alpha_composite(bg, floor)
        check(recomposed.getchannel("A").getextrema() == (255,255), "Crypt: full composition has no empty corners", "overlap")
        for x,y in [(0,0),(840,0),(0,569),(840,569)]:
            check(recomposed.getpixel((x,y))[3] == 255, f"Crypt corner {x,y}: opaque", "overlap")
        source["runtime_overlap_pixels"] = overlap
        source["runtime_floor_transition_bounds"] = Image.fromarray(((arr_floor[:,:,3]>0)&(arr_floor[:,:,3]<255)).astype(np.uint8)*255).getbbox()
        # Every allowed vertical art crop must remain opaque under the common transform.
        for top in (0,60,120):
            for width in (720,450,360):
                image = recomposed.crop((0,top,841,top+450)).resize((width,round(450*width/841)),Image.Resampling.LANCZOS)
                check(image.getchannel("A").getextrema()==(255,255),
                      f"Crypt crop y{top}, width{width}: scaled composite has no alpha seam/corner", "overlap")
    for entry in metadata.get("layers", []):
        path = folder / entry["path"]
        check(path.is_file(), f"Crypt external editable layer: {entry['path']}", "correspondence")
        if path.is_file():
            matched = [im for name,im,attrs in layers if name == entry["name"]]
            check(len(matched)==1 and max_delta(open_image(path),matched[0])==0,
                  f"Crypt {entry['name']}: external layer equals ORA paint", "correspondence")
            check(sha(path)==entry.get("sha256"), f"Crypt {entry['name']}: recorded source hash", "metadata")
    for key,expected in [("source_dimensions",[1682,1140]),("export_dimensions",[841,570]),
                         ("origin",[0,0]),("review_crop",[0,60,841,450]),("floor_contact",[446,428])]:
        check(metadata.get(key)==expected, f"Crypt {key}: exact delivered contract", "metadata")
    for record in metadata.get("reuse",[]):
        path = ROOT / record["path"]
        check(path.is_file() and sha(path)==record["sha256"], f"Crypt retained input unchanged: {record['path']}", "preservation")
    check((folder/"metadata.json").is_file(), "Crypt geometry metadata exists", "metadata")
    check((folder/"delivery.md").is_file(), "Crypt delivery guide exists", "metadata")
    check((folder/"lighting.json").is_file(), "Editable lighting settings exist", "lighting")
    lighting_path = folder / "lighting.json"
    if lighting_path.is_file():
        lighting = read_json(lighting_path)
        presets = lighting.get("presets", {})
        names = list(presets) if isinstance(presets, dict) else [p.get("id",p.get("name")) for p in presets]
        check(set(names) == {"base_cool", "warm_candle", "dark"}, "Exactly base_cool, warm_candle, dark lighting presets", "lighting")
        resource_path = ROOT / "assets/environments/crypt/lighting.tres"
        if isinstance(presets,dict) and resource_path.is_file():
            resource_text = resource_path.read_text(encoding="utf-8-sig")
            for name,preset in presets.items():
                match = re.search(r"^"+re.escape(name)+r"\s*=\s*Vector3\(([^)]+)\)", resource_text, re.M)
                values = [float(v.strip()) for v in match.group(1).split(",")] if match else None
                check(values==preset.get("tone"), f"Lighting {name}: editable JSON equals runtime Resource", "lighting")
    for filename in ["lighting.tres"]:
        check((ROOT/"assets/environments/crypt"/filename).is_file(), f"Reusable runtime {filename}", "lighting")
    check(not (ROOT/"assets/environments/crypt/foreground.png").exists(), "Optional foreground omitted as recorded; no actor/UI obstruction layer", "textures")
    return {"source": source, "textures": [bg_record, floor_record]}


def inspect_home():
    folder = ROOT / "source-assets/environments/home"
    source, merged, layers = inspect_ora(folder / "home_tower.ora", (1440,3200), 2)
    runtime, output = inspect_png(ROOT / "assets/environments/home/home_tower.png", (720,1600), True)
    if merged is not None and output is not None:
        expected = merged.resize((720,1600), Image.Resampling.LANCZOS).convert("RGB")
        difference = max_delta(expected, output)
        check(difference <= 1, f"Home: visible master -> Lanczos RGB export (max error {difference})", "correspondence")
    for filename in ["metadata.json", "delivery.md"]:
        check((folder/filename).is_file(), f"Home {filename} exists", "metadata")
    metadata_path = folder / "metadata.json"
    if metadata_path.is_file():
        metadata = read_json(metadata_path)
        check(metadata.get("source_size",metadata.get("source_dimensions"))==[1440,3200],
              "Home metadata records source canvas", "metadata")
        check(metadata.get("export_size",metadata.get("export_dimensions"))==[720,1600],
              "Home metadata records runtime canvas", "metadata")
        for entry in metadata.get("layers",[]):
            path = folder / entry["path"]
            check(path.is_file(), f"Home external editable layer: {entry['path']}", "correspondence")
            if path.is_file():
                matched = [im for name,im,attrs in layers if name==entry["name"]]
                check(len(matched)==1 and max_delta(open_image(path),matched[0])==0,
                      f"Home {entry['name']}: external layer equals ORA paint", "correspondence")
                if "sha256" in entry:
                    check(sha(path)==entry["sha256"], f"Home {entry['name']}: recorded source hash", "metadata")
                if entry.get("mask"):
                    mask_path = folder / entry["mask"]
                    check(mask_path.is_file(), f"Home {entry['name']}: editable mask exists", "correspondence")
                    if mask_path.is_file():
                        mask = open_image(mask_path).convert("L")
                        alpha = open_image(path).convert("RGBA").getchannel("A")
                        check(mask.size==alpha.size and ImageChops.difference(mask,alpha).getbbox() is None,
                              f"Home {entry['name']}: mask equals layer alpha", "correspondence")
        for key,filename in [("runtime_sha256",ROOT/"assets/environments/home/home_tower.png"),
                             ("source_sha256",folder/"home_tower.ora")]:
            check(filename.is_file() and sha(filename)==metadata.get(key),f"Home {key}: recorded delivery hash","metadata")
        crops = metadata.get("crop_contract",{}).get("runtime_source_rects",{})
        check(set(crops)=={"9:16","9:20","9:21.5"}, "Home: exactly requested aspect crop records", "geometry")
        for aspect,crop in crops.items():
            for focal in ["moon_visible_disc","primary_tower","tower_approach"]:
                rect = metadata.get("focal_regions_runtime",{}).get(focal)
                check(rect is not None and rect[0]>=crop[0] and rect[1]>=crop[1]
                      and rect[0]+rect[2]<=crop[0]+crop[2] and rect[1]+rect[3]<=crop[1]+crop[3],
                      f"Home {aspect}: complete {focal} inside cover crop", "geometry")
        for aspect,expected in {"9:16":[0,160,720,1280],"9:20":[0,0,720,1600],
                                "9:21.5":[25.116279069767415,0,669.7674418604652,1600]}.items():
            actual = crops.get(aspect,[])
            check(len(actual)==4 and max(abs(a-b) for a,b in zip(actual,expected))<1e-6,
                  f"Home {aspect}: exact uniform cover mapping", "geometry")
    return {"source": source, "textures": [runtime]}


def geometry():
    mappings = []
    crop = [0,60,841,450]
    envelope = [272,56,620,392]
    measured = [275.75,95,611,374]
    # The 841x570 export has 60 top/bottom overscan and no horizontal overscan.
    for width,height in [(720,385),(450,241),(360,193)]:
        k = width/841
        entry = {"output": [width,height], "uniform_scale": k, "texture_scale": .75*k,
                 "foot": [446*k,368*k], "declared_actor_envelope": [v*k for v in envelope],
                 "sampled_actor_union": [v*k for v in measured]}
        check(0 <= envelope[0]*k < envelope[2]*k <= width and 0 <= envelope[1]*k < envelope[3]*k <= height,
              f"Crypt {width}: complete declared actor/lantern/motion envelope fits", "geometry")
        check(abs(height-450*k) < .5, f"Crypt {width}: proportional viewport rounding only", "geometry")
        mappings.append(entry)
    home_crops = []
    for ratio in [(9,16),(9,20),(9,21.5)]:
        aspect = ratio[0]/ratio[1]
        width = min(720,1600*aspect)
        height = min(1600,720/aspect)
        rect = [(720-width)/2,(1600-height)/2,width,height]
        check(rect[0] >= 0 and rect[1] >= 0 and rect[0]+width <= 720.000001 and rect[1]+height <= 1600.000001,
              f"Home {ratio[0]}:{ratio[1]}: center cover crop stays inside source", "geometry")
        home_crops.append({"aspect":list(ratio),"source_crop":rect})
    return {"crypt_export": [841,570], "crypt_crop":crop, "vertical_overscan":[60,60],
            "horizontal_overscan":[0,0], "crypt_comparisons":mappings,"home_cover_crops":home_crops}


def imports_and_renders(source_only: bool):
    if source_only:
        return {"result":"NOT_RUN", "reason":"--source-only excludes actual engine/import evidence"}
    stage = QA / "preview-project"
    check(stage.is_dir(), "Recreated isolated Godot preview project exists", "staging")
    staged_count = 0
    for folder in ["assets/environments", "assets/enemies/shadeling", "assets/ui", "assets/icons", "assets/fonts", "scenes/ui/theme"]:
        for path in (ROOT/folder).rglob("*"):
            if not path.is_file() or path.suffix in (".import", ".uid") or path.name == ".gdignore":
                continue
            staged = stage / rel(path)
            # Optional unused parts/files need not be staged, but every delivered environment must be.
            required = folder == "assets/environments"
            if required or staged.is_file():
                check(staged.is_file() and sha(path) == sha(staged), f"Exact staged input: {rel(path)}", "staging")
                staged_count += 1
    for filename in ["crypt/background.png", "crypt/floor.png", "home/home_tower.png"]:
        actual = ROOT/"assets/environments"/filename
        recipe = actual.with_name(actual.name+".import")
        check(recipe.is_file(), f"{filename}: real Godot import recipe exists", "imports")
        if recipe.is_file():
            content = recipe.read_text(encoding="utf-8-sig")
            for setting in ["compress/mode=0", "mipmaps/generate=false"]:
                check(setting in content, f"{filename}: {setting}", "imports")
    report_path = QA / "godot-render-results.json"
    check(report_path.is_file(), "Actual Godot rendering report exists", "renders")
    if not report_path.is_file():
        return {"result":"MISSING", "staged_files":staged_count}
    report = read_json(report_path)
    check(report.get("result") == "PASS" and not report.get("errors"), "Godot import/render/state/layout checks pass", "renders")
    required_sheets = {"crypt-layer-background.png", "crypt-layer-floor.png", "crypt-recomposed.png",
                       "crypt-overlap-crop-guides.png"}
    required_sheets.update(f"crypt-art-overscan-y{top}.png" for top in (0,60,120))
    for width in (720,450,360):
        required_sheets.update(f"crypt-{preset}-{width}.png" for preset in ("base_cool","warm_candle","dark"))
        required_sheets.add(f"crypt-motion-guides-{width}.png")
        required_sheets.update(f"crypt-motion-{width}-{sample}.png" for sample in
                              ("idle-060","attack-046","hit-018","defeat-068","defeat-125"))
    required_sheets.update(f"home-{height}-{kind}.png" for height in (1280,1600,1720) for kind in ("clean","composed"))
    recorded_sheets = {sheet["file"] for sheet in report.get("sheets",[])}
    check(required_sheets.issubset(recorded_sheets), "Godot report covers required layers, overscan, three lighting presets, all states/widths and three Home crops", "renders")
    check(all(item.get("pass") is True for item in report.get("checks",[])), "Every recorded engine assertion passes", "renders")
    for sheet in report.get("sheets", []):
        path = ART / sheet["file"]
        check(path.is_file(), f"Rendered preview exists: {sheet['file']}", "renders")
        if path.is_file():
            image = open_image(path)
            expected = (sheet.get("width", image.width), sheet.get("height", image.height))
            check(image.size == expected, f"Preview dimensions: {sheet['file']}", "renders")
    for log in ["godot-import.log", "godot-render.log"]:
        path = QA / log
        check(path.is_file(), f"Engine log exists: {log}", "renders")
        if path.is_file():
            content = path.read_text(encoding="utf-8-sig",errors="replace")
            check(not re.search(r"SCRIPT ERROR|Parse Error|Failed to load", content), f"No engine script/resource errors: {log}", "renders")
    return {"report":rel(report_path), "result":report.get("result"), "staged_files":staged_count, "sheets":len(report.get("sheets",[]))}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--snapshot", action="store_true")
    parser.add_argument("--source-only", action="store_true")
    parser.add_argument("--report", default="output/qa/rc-015/validation-report.json")
    args = parser.parse_args()
    if args.snapshot:
        snapshot()
        return
    preservation = validate_preservation()
    deliveries = {}
    for name, function in [("crypt",inspect_crypt),("home",inspect_home)]:
        try:
            deliveries[name] = function()
        except Exception as exc:
            check(False, f"{name}: validation could not finish: {type(exc).__name__}: {exc}", "sources")
    mapping = geometry()
    engine = imports_and_renders(args.source_only)
    textures = [t for d in deliveries.values() for t in d.get("textures",[]) if t]
    crypt_bytes = sum(t["rgba8_bytes"] for t in deliveries.get("crypt",{}).get("textures",[]) if t)
    home_bytes = sum(t["rgba8_bytes"] for t in deliveries.get("home",{}).get("textures",[]) if t)
    check(crypt_bytes <= 11.9*1048576 and crypt_bytes > 0, "Crypt decoded textures stay within provisional 11.9 MiB budget", "memory")
    combat = crypt_bytes /1048576 + 3 + 4.75 + 6 + 2
    transition = combat + home_bytes/1048576 + 720*1440*4/1048576
    check(combat <= 32, "Conservative Combat subtotal stays within provisional 32 MiB", "memory")
    check(transition <= 48, "Conservative transition art subtotal stays within provisional 48 MiB", "memory")
    result = {"task":"RC-015", "result":"PASS" if not errors else "FAIL", "check_count":len(checks),
              "groups":dict(Counter(c["group"] for c in checks)), "errors":errors, "checks":checks,
              "preservation":preservation,"deliveries":deliveries,"mapping":mapping,"engine":engine,
              "memory":{"textures":textures,"crypt_mib":crypt_bytes/1048576,"home_mib":home_bytes/1048576,
                "combat_estimate_mib":combat,"transition_estimate_mib":transition,
                "assumptions":"RGBA8 no mipmaps. Combat includes 3MiB warmed actor,4.75MiB full RC013 set (including wordmark),6MiB full RC012 glyph set,2MiB VFX allowance. Transition adds Home and 720x1440 Map allowance. Excludes font atlas, renderer buffers and driver overhead; no device measurement."},
              "limits":["Technical checks do not establish visual reference match, rights clearance, human approval or device acceptance.",
                        "Preview is an isolated composition; RC016 owns responsive gameplay integration."]}
    path = (ROOT / args.report).resolve()
    if not path.is_relative_to(ROOT) or path.suffix != ".json":
        parser.error("Report must be a JSON file within the workspace")
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(result,indent=2)+"\n",encoding="utf-8")
    print(f"RC015 {result['result']}: {len(checks)} checks, {len(errors)} errors; {rel(path)}")
    for error in errors[:25]:
        print("FAIL:",error)
    sys.exit(0 if not errors else 1)


if __name__ == "__main__":
    main()
