"""Build RC-012 SVG masters/exports from retained r006 vectors and authored additions.

No runtime gameplay files, retained pilot files, or repository metadata are touched.
Python standard library only. Run from any directory with Python 3.
"""
from __future__ import annotations

import ast
import hashlib
import json
from pathlib import Path
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "source-assets/icons"
RUNTIME = ROOT / "assets/icons"
EVIDENCE = ROOT / "output/qa/rc-012"
PILOT = ROOT / "source-assets/pilot/revisions/r006"
NS = "http://www.w3.org/2000/svg"
ET.register_namespace("", NS)


def tag(name):
    return "{" + NS + "}" + name


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def path(d, fill="none", stroke="none", sw=1, extra=""):
    return f'<path d="{d}" fill="{fill}" stroke="{stroke}" stroke-width="{sw}" stroke-linejoin="round" stroke-linecap="round" {extra}/>'


def poly(points, fill, stroke="none", sw=1):
    if not isinstance(points, str):
        points = " ".join(f"{x},{y}" for x, y in points)
    return f'<polygon points="{points}" fill="{fill}" stroke="{stroke}" stroke-width="{sw}" stroke-linejoin="round"/>'


def rect(x, y, w, h, fill, stroke="none", sw=1, rx=0):
    return f'<rect x="{x}" y="{y}" width="{w}" height="{h}" fill="{fill}" stroke="{stroke}" stroke-width="{sw}" rx="{rx}"/>'


def circle(x, y, r, fill, stroke="none", sw=1):
    return f'<circle cx="{x}" cy="{y}" r="{r}" fill="{fill}" stroke="{stroke}" stroke-width="{sw}"/>'


def group(s, id=None, transform=None):
    attrs = (f' id="{id}"' if id else "") + (f' transform="{transform}"' if transform else "")
    return f"<g{attrs}>{s}</g>"


def retained_icon_function():
    # Read only the pure shape-authoring function. Never execute the old builder.
    parsed = ast.parse((PILOT / "build_review.py").read_text(encoding="utf-8"))
    node = next(n for n in parsed.body if isinstance(n, ast.FunctionDef) and n.name == "icon")
    scope = dict(path=path, poly=poly, rect=rect, circle=circle, group=group, CREAM="#fff0bd")
    exec(compile(ast.Module(body=[node], type_ignores=[]), "retained_r006_icon", "exec"), scope)
    return scope["icon"]


def named_layers(body):
    """Keep editable primary silhouette, facets and remaining detail groups."""
    wrapper = ET.fromstring(f'<g xmlns="{NS}">{body}</g>')
    if len(wrapper) == 1 and wrapper[0].tag == tag("g"):
        outer = wrapper[0]
    else:
        outer = wrapper
    children = list(outer)
    for child in children:
        outer.remove(child)
    for layer_name, members in [("outline", children[:1]), ("fill", children[1:2]), ("detail", children[2:])]:
        layer = ET.SubElement(outer, tag("g"), {"id": layer_name})
        layer.extend(members)
    return ET.tostring(outer, encoding="unicode")


def svg(name, body, metadata):
    root = ET.Element(tag("svg"), {"width": "128", "height": "128", "viewBox": "0 0 128 128"})
    ET.SubElement(root, tag("title")).text = f"Rune Cast — {name} — RC-012"
    ET.SubElement(root, tag("metadata")).text = metadata
    root.append(ET.fromstring(named_layers(body)))
    ET.indent(root)
    return ET.tostring(root, encoding="unicode", xml_declaration=False) + "\n"


def build():
    retained = retained_icon_function()
    records = []
    dependencies = [PILOT / "build_review.py", PILOT / "ui/spark.svg", PILOT / "ui/split.svg", PILOT / "ui/join.svg"]
    before = {str(p.relative_to(ROOT)).replace("\\", "/"): sha(p) for p in dependencies}

    def add(rel, asset_id, label, body, origin, usage, ports=None, **extra):
        source, runtime = SOURCE / rel, RUNTIME / rel
        source.parent.mkdir(parents=True, exist_ok=True)
        runtime.parent.mkdir(parents=True, exist_ok=True)
        payload = svg(label, body, "RC-012 original vector adaptation. No embedded raster, external resources, live labels or gameplay logic. " + origin)
        source.write_text(payload, encoding="utf-8", newline="\n")
        runtime.write_bytes(source.read_bytes())
        records.append(dict(id=rel.removesuffix(".svg").replace("/", "_"), asset_id=asset_id, label=label,
            source=source.relative_to(ROOT).as_posix(), runtime=runtime.relative_to(ROOT).as_posix(),
            sha256=sha(source), provenance=origin, usage=usage, decorative_ports=[],
            logical_ports=ports, **extra))

    # Board endpoints: retain r006's check for Begin and diamond for End.
    rings = circle(64, 64, 43, "#07595c", "#31dce1", 6) + circle(64, 64, 33, "#03434b", "#258b94", 3)
    check = group(poly([(-15,-6),(-4,6),(17,-14),(21,-9),(-4,15),(-20,0)], "#73fff1"), transform="translate(64 64) scale(1.35)")
    add("circuit/begin.svg", "circuit_geometry", "Begin", rings + check,
        "r006 begin_mark polygon and endpoint rings; centered on SVG128.", "Board endpoint; BEGIN is a separate live label.", ["E"],
        port_status="existing endpoint orientation retained as undirected art recipe; evaluator migration owns behavior")
    end = path("M40.55 100.05 A43 43 0 1 1 87.45 100.05", "none", "#31dce1", 6)
    end += circle(64, 64, 33, "#03434b", "#258b94", 3) + poly("64,45 83,64 64,83 45,64", "#80fff0", "#24bac1", 2)
    add("circuit/end.svg", "circuit_geometry", "End", end,
        "r006 open endpoint ring and central diamond; centered on SVG128.", "Board endpoint; END is a separate live label.", ["N"],
        port_status="existing endpoint orientation retained as undirected art recipe; evaluator migration owns behavior")
    for name, d, ports in [("straight", "M0 64H128", ["W","E"]), ("corner", "M0 64H64V128", ["W","S"])]:
        wire = path(d, "none", "#ffc84f", 8, 'data-role="connection"') + path(d, "none", "#fff0a1", 2)
        add(f"circuit/{name}.svg", "circuit_geometry", name.title(), wire,
            "RC-012 exact edge geometry; undirected replacement for historical directed wire art.", "Full-cell connection geometry; inset whole image for toolbar icon.", ports,
            kind="connection", connection_path=d, art_safe_bounds_exception="connection stroke intentionally reaches exact cell edges")
    for name, transform in [("split", "translate(15.6 9) scale(1.1)"), ("join", "translate(12.5 11.7275) scale(1.03)")]:
        original = ET.parse(PILOT / f"ui/{name}.svg").getroot()
        inner = next(n for n in original if n.tag == tag("g"))
        body = group("".join(ET.tostring(c, encoding="unicode") for c in inner), transform=transform)
        add(f"circuit/{name}.svg", "circuit_geometry", name.title(), body,
            f"Exact retained r006 ui/{name}.svg path/polygon geometry; uniform normalization {transform}; removed unused filters.",
            "Decorative board/tool silhouette. Terminals are not connection ports.", None,
            kind="decoration", port_status="UNRESOLVED: integration/evaluator follow-up must confirm undirected graph; do not infer port count from fork/trident", normalized_transform=transform)

    spark = ET.parse(PILOT / "ui/spark.svg").getroot()
    spark_body = "".join(ET.tostring(n, encoding="unicode") for n in spark if n.tag == tag("g"))
    add("runes/core/spark.svg", "rune_symbols", "Spark", spark_body,
        "Exact retained r006/r002 Spark rays, center and highlight; original SVG128 coordinates.",
        "Spark and Free Spark share this board symbol. Free Spark identity/temporary marker stays on hand/detail surfaces.", ["W","E"],
        port_status="separate undirected effect connection recipe; no connection strokes baked into glyph")

    mappings = [
        ("runes/core/shield.svg","rune_symbols","Shield","shield","Board effect or detailed card; straight connections separate."),
        ("runes/core/focus.svg","rune_symbols","Focus","book","Technique card/detail only; no board ports."),
        ("navigation/menu.svg","navigation_icons","Menu","menu","Bottom Menu navigation and identified menu buttons."),
        ("navigation/map.svg","navigation_icons","Map","map","Bottom Map navigation and route entry."),
        ("navigation/guide.svg","navigation_icons","Guide","guide","Bottom Guide navigation; question mark is vector geometry."),
        ("navigation/sound_on.svg","navigation_icons","Sound on","sound","Bottom Sound toggle; sound waves show enabled state."),
        ("editing/remove.svg","editing_icons","Remove","remove","Remove action only; eraser retains dark tip."),
        ("editing/rotate.svg","editing_icons","Rotate","rotate","Rotate editing action; curved arrow allowed, never circuit direction."),
        ("resources/health.svg","resource_icons","Health","heart","Player/enemy health and recovery values remain live."),
        ("resources/energy.svg","resource_icons","Energy","crystal","Energy and cost crystal; live values outside glyph."),
        ("resources/attack.svg","resource_icons","Attack","sword","Initial attack intent and incoming-damage forecast; live number."),
        ("resources/draw_pile.svg","resource_icons","Draw pile","deck","Draw pile emblem; separate frame, DRAW label and count."),
        ("resources/discard_pile.svg","resource_icons","Discard pile","skull","Discard pile emblem; separate frame, DISCARD label and count."),
        ("resources/pause.svg","resource_icons","Pause","pause","Top pause control explicitly retained by current visual contract."),
    ]
    for rel, asset, label, old, usage in mappings:
        body = retained(old, 19, 19, 90)
        ports = ["W","E"] if old == "shield" else []
        add(rel, asset, label, body,
            f"Retained r006 build_review.py icon('{old}') geometry and palette; normalized with translate(19 19) scale(0.9).", usage, ports,
            port_status="separate effect connection recipe" if ports else "not a board connection symbol")

    sound_off = poly("9,38 30,38 50,19 50,81 30,64 9,64", "#fff0bd", "#101522", 4)
    sound_off += path("M63 32L89 68 M89 32L63 68", "none", "#fff0bd", 8)
    add("navigation/sound_off.svg", "navigation_icons", "Sound off", group(sound_off, transform="translate(19 19) scale(0.9)"),
        "r006 Sound speaker with original RC-012 cross replacing waves; shared shape and palette.", "Bottom Sound toggle; crossed speaker distinguishes mute without color.", [])
    # Conjure is a technique. A cupped hand and small Spark express creation;
    # it is not another installed effect or an additional Spark artwork.
    conjure = path("M22 84L37 70Q44 66 50 72L57 79L73 77Q85 68 97 59L105 63Q102 72 86 88L69 103L39 105Z", "#ad76e4", "#101522", 4)
    conjure += path("M39 91L66 91L84 79 M28 84L39 101", "none", "#e7c9ff", 4)
    conjure += poly("65,19 70,34 85,39 70,44 65,60 60,44 45,39 60,34", "#ffd66a", "#9b632b", 2)
    conjure += path("M32 32L36 26 M94 30L99 24", "none", "#ecd3ff", 4)
    add("runes/core/conjure.svg", "rune_symbols", "Conjure", conjure,
        "Original RC-012 precise vector cupped-hand/creation-star motif; r006 violet/gold palette, no external icon set.",
        "Conjure Spark technique card/detail only; no board ports. Live effect text identifies creation.", [])
    hourglass = path("M39 22H89 M39 106H89 M43 24V39L62 63L43 87V104 M85 24V39L66 63L85 87V104", "none", "#101522", 10)
    hourglass += path("M39 22H89 M39 106H89 M43 24V39L62 63L43 87V104 M85 24V39L66 63L85 87V104", "none", "#e5c47d", 6)
    hourglass += poly("49,34 79,34 64,54", "#ffe8a7") + poly("64,74 80,98 48,98", "#ffe8a7")
    add("temporary_marker.svg", "temporary_marker", "Temporary hourglass", hourglass,
        "Original RC-012 vector hourglass, using retained pilot gold/dark palette.",
        "Free Spark detailed hand card/detail/Guide lifetime cue plus live wording; prohibited on clean board.", [])

    assert len(records) == 24
    assert all(sha(ROOT / p) == expected for p, expected in before.items())
    # The editable shader master is tracked beside the SVG masters.
    (RUNTIME / "symbol_tint.gdshader").write_bytes((SOURCE / "symbol_tint.gdshader").read_bytes())
    metadata = dict(schema_version=1, task="RC-012", revision="r001", date="2026-10-11", symbol_count=len(records),
        source_status="delivered SVG source; Godot import/visual evidence recorded separately by integration preview",
        coordinate_system=dict(viewbox=[0,0,128,128], origin="top_left", pivot=[64,64], decorative_safe_bounds=[16,16,112,112],
            port_coordinates=dict(N=[64,0], E=[128,64], S=[64,128], W=[0,64]), quarter_turn="clockwise about (64,64)",
            rotation_map="N->E->S->W->N; text and card/detail badges stay upright", wire_width_normalized=8,
            wire_width_at_137=8.5625, wire_width_at_72=4.5,
            wire_runtime_recipe="SVG8 normalized main width: 1.5/2/3 logical pixels at 24/32/48; 4.5/8.5625 at 72/137. Drawn matching segments use 8*cell_side/128; no arrowheads.",
            channel_half_width=10, grid_gap="6 design px is renderer-owned; do not move cell-edge port coordinates"),
        connections=dict(begin="E to center; render separately from Begin decoration", end="N to center; render separately from End decoration",
            spark="W/E; symbol and connections separate", shield="W/E; symbol and connections separate", focus="technique; none", conjure="technique; none",
            split=None, join=None, unresolved="Split/Join glyph tips are decorative. Undirected graph/branch aggregation/cycle/repeated-trigger policy belongs to gameplay migration, not RC-012."),
        import_recipe=dict(svg_scale=2.0, texture_size=[256,256], compression="lossless", mipmaps=False,
            filtering="linear; preview at integer-aligned positions; nearest is inappropriate for these antialiased outlines", decoded_rgba8_mib=len(records)*256*256*4/1048576,
            notes="6 MiB conservative all-24 decoded estimate at scale2; engine font atlases, buffers and transient copies excluded. Source SVGs excluded by source-assets/.gdignore."),
        appearance=dict(shader="assets/icons/symbol_tint.gdshader", modes={"0":"original color", "1":"luminance monochrome; retains outline/facet readability", "2":"one-color alpha silhouette; diagnostic/accessibility supplemental preview"},
            selected="outline plus corner check", focused="dashed outer outline", disabled="reduced opacity plus disabled treatment and live label", unavailable="struck slot/slash plus unavailable live label",
            invalid="cross plus live explanation", note="Interaction overlays are theme/consumer geometry, never copied glyph files. Monochrome mode1 is the preferred working monochrome; alpha-only mode2 loses interior detail.",
            monochrome_on_dark="mode1 with light ink and default black monochrome_paper",
            monochrome_on_parchment="mode1 with dark ink (#111b29) and light monochrome_paper (#e8d5aa); direct dark multiplication loses internal detail"),
        provenance=dict(creator="OpenAI Codex precise vector authoring/adaptation in local workspace", reference="output/imagegen/approved/combat-final-v2-clean-board.png",
            sources=before, source_art_method="Retained r006 explicit vector primitives reused; original additions hand-authored by Codex. No image generation, tracing raster embeds, third-party icon set or external font dependency.",
            rights="Original project vector construction; no third-party icon licence added. Reference provenance/owner approval does not establish separate shipping-rights clearance; RC-050 audits final shipped assets.",
            owner_approval="Supplied reference only; adapted assets are not separately owner-approved or pixel-identical."), symbols=records)
    (SOURCE / "core_symbols.json").write_text(json.dumps(metadata, indent=2) + "\n", encoding="utf-8")
    EVIDENCE.mkdir(parents=True, exist_ok=True)
    # Focused format and source-preservation checks; these are not render claims.
    failures=[]
    allowed={tag(n) for n in ["svg","title","metadata","g","path","polygon","circle","rect"]}
    for rec in records:
        p=ROOT / rec["runtime"]
        root=ET.parse(p).getroot()
        if root.attrib.get("viewBox") != "0 0 128 128": failures.append(rec["id"]+": viewBox")
        if sha(p) != sha(ROOT / rec["source"]): failures.append(rec["id"]+": source/export mismatch")
        for node in root.iter():
            if node.tag not in allowed: failures.append(rec["id"]+": unexpected element "+node.tag)
            if any("href" in k for k in node.attrib): failures.append(rec["id"]+": linked dependency")
        if not {"outline","fill","detail"}.issubset({n.attrib.get("id") for n in root.iter()}): failures.append(rec["id"]+": editable layer IDs")
    report=dict(task="RC-012", status="pass" if not failures else "fail", failures=failures, svg_count=len(records),
        checks=["XML parse and allowed plain-vector elements", "SVG128 source/export byte equality", "No image/text/filter/external reference elements", "Editable outline/fill/detail groups", "Retained r006 dependencies byte-unchanged"],
        retained_source_hashes=before, note="Format/source checks only. Actual Godot imported/rendered evidence is produced by the isolated RC-012 preview.")
    (EVIDENCE / "symbol_source_validation.json").write_text(json.dumps(report, indent=2)+"\n", encoding="utf-8")
    print(json.dumps({"status":report["status"],"symbols":len(records),"metadata":"source-assets/icons/core_symbols.json","failures":failures},indent=2))
    if failures: raise SystemExit(1)


if __name__ == "__main__":
    build()
