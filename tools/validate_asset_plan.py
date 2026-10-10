"""Read-only RC-010 document/manifest checks; writes only its validation report.

Run with Python 3 from any directory. No Godot, network or Git access.
"""
import csv
import hashlib
import json
import re
from collections import Counter
from pathlib import Path
from urllib.parse import unquote

ROOT = Path(__file__).resolve().parents[1]
QA = ROOT / "output/qa/rc-010"
errors = []
counts = Counter()


def check(ok, message, family):
    counts[family] += 1
    if not ok:
        errors.append(message)


def read(path):
    return (ROOT / path).read_text(encoding="utf-8-sig")


def tokens(value):
    return [part.strip() for part in value.split(";") if part.strip()]


def csv_rows(path, key):
    with (ROOT / path).open(encoding="utf-8-sig", newline="") as stream:
        table = [row for row in csv.reader(stream, strict=True) if row]
    header = table[0]
    check(len(header) == len(set(header)), f"Duplicate CSV columns: {path}", "csv")
    for number, row in enumerate(table[1:], 2):
        check(len(row) == len(header), f"Wrong field count: {path}:{number}", "csv")
    rows = [dict(zip(header, row)) for row in table[1:]]
    ids = [row[key] for row in rows]
    check(len(ids) == len(set(ids)), f"Duplicate IDs: {path}", "csv")
    check(all(re.fullmatch(r"[a-z][a-z0-9_]*", value) for value in ids),
          f"Invalid stable ID syntax: {path}", "csv")
    return rows


def task_ids(value):
    found = set(re.findall(r"RC-\d{3}", value))
    for first, last in re.findall(r"RC-(\d{3})[–-](?:RC-)?(\d{3})", value):
        found.update(f"RC-{number:03}" for number in range(int(first), int(last) + 1))
    return found


def cycle_check(graph, name):
    visiting, done = [], set()

    def visit(node):
        if node in visiting:
            errors.append(f"{name} dependency cycle: {' -> '.join(visiting + [node])}")
            return
        if node in done:
            return
        visiting.append(node)
        for dependency in graph.get(node, set()):
            visit(dependency)
        visiting.pop()
        done.add(node)

    for node in graph:
        visit(node)
    counts["dependency_graphs"] += 1


def ancestors(node, graph, seen=None):
    seen = set() if seen is None else seen
    for parent in graph.get(node, set()):
        if parent not in seen:
            seen.add(parent)
            ancestors(parent, graph, seen)
    return seen


def slug(title):
    title = re.sub(r"\[([^]]+)\]\([^)]*\)", r"\1", title).lower()
    title = re.sub(r"[^\w\- ]", "", title)
    return title.replace(" ", "-")


def link_exists(reference, base):
    if re.match(r"[a-zA-Z][a-zA-Z0-9+.-]*:", reference):
        return True
    filename, _, anchor = unquote(reference).partition("#")
    target = (base.parent / filename).resolve() if filename else base
    if not target.exists():
        return False
    if anchor and target.suffix == ".md":
        content = target.read_text(encoding="utf-8-sig")
        anchors = {slug(line) for line in re.findall(r"^#{1,6}\s+(.+)$", content, re.M)}
        anchors.update(re.findall(r'<a\s+(?:id|name)="([^"]+)"', content))
        return anchor in anchors
    return True


manifest = csv_rows("docs/asset-inventory.csv", "id")
consumers = csv_rows("docs/asset-consumers.csv", "consumer_id")
assets = {row["id"]: row for row in manifest}
mapping = {row["consumer_id"]: row for row in consumers}
original = json.loads(read("output/qa/rc-010/original-asset-ids.json"))
check(set(original) <= assets.keys(), "Original asset IDs were removed", "preservation")

task_graph = {}
for line in read("docs/project-plan.md").splitlines():
    cells = line.split("|")
    if len(cells) >= 6 and re.search(r"\[[ xX]\].*\*\*RC-\d{3}\*\*", cells[1]):
        owner = re.search(r"RC-\d{3}", cells[1]).group()
        task_graph[owner] = task_ids(cells[3])
check(len(task_graph) == 60, "Could not read all 60 task definitions", "ownership")
cycle_check(task_graph, "Task")
asset_graph = {row["id"]: set(tokens(row["asset_dependencies"])) for row in manifest}
cycle_check(asset_graph, "Asset")
statuses = {"reference_only", "integrated_placeholder", "placeholder", "planned", "optional_planned",
            "source_ready", "runtime_ready", "integrated", "device_verified"}
required = ["id", "row_kind", "category", "description", "consumer_ids", "runtime_use",
            "source_master_path", "source_path_state", "runtime_destination", "runtime_path_state",
            "format", "spec_ref", "required_states_variants", "production_owner", "integration_owner",
            "readiness_status", "visual_direction_status", "provenance", "generation_reference", "licence_status"]
for row in manifest:
    ident = row["id"]
    check(all(row.get(field) for field in required), f"Required field empty: {ident}", "schema")
    check(row["readiness_status"] in statuses, f"Unknown status: {ident}", "readiness")
    check(row["source_path_state"] in {"existing", "planned"}, f"Bad source path state: {ident}", "paths")
    check(row["runtime_path_state"] in {"planned", "existing", "source_only", "external_delivery", "not_applicable"},
          f"Bad runtime path state: {ident}", "paths")
    for field in ("production_owner", "integration_owner", "task_dependencies"):
        check(task_ids(row[field]) <= task_graph.keys(), f"Unknown task in {ident}.{field}", "ownership")
    check(set(tokens(row["asset_dependencies"])) <= assets.keys(), f"Unknown asset dependency: {ident}", "ownership")
    for dependency in task_ids(row["task_dependencies"]):
        for owner in task_ids(row["production_owner"]):
            check(dependency in ancestors(owner, task_graph), f"Unplanned task prerequisite: {ident}/{dependency}", "ownership")
    for integrator in task_ids(row["integration_owner"]):
        for owner in task_ids(row["production_owner"]):
            if row["row_kind"] == "deliverable":
                check(owner == integrator or owner in ancestors(integrator, task_graph),
                      f"Integration precedes production: {ident}/{integrator}", "ownership")
    for field in ("current_paths", "evidence_paths"):
        for path in tokens(row[field]):
            check((ROOT / path).exists(), f"Missing existing {field}: {ident}/{path}", "paths")
    for path_field, state_field in (("source_master_path", "source_path_state"), ("runtime_destination", "runtime_path_state")):
        for path in tokens(row[path_field]):
            check(path == "none" or (not Path(path).is_absolute() and ".." not in Path(path).parts),
                  f"Noncanonical manifest path: {ident}/{path}", "paths")
            if row[state_field] == "existing":
                check((ROOT / path).exists(), f"Missing delivered path: {ident}/{path}", "paths")
    check(link_exists(row["spec_ref"], ROOT / "manifest-root.md"), f"Broken specification: {ident}", "links")
    if row["readiness_status"] in {"source_ready", "runtime_ready", "integrated", "device_verified"}:
        check(bool(row["evidence_paths"]), f"Readiness has no evidence: {ident}", "readiness")
    if row["readiness_status"] in {"runtime_ready", "integrated", "device_verified"}:
        check(row["runtime_path_state"] == "existing" and row["licence_status"] == "resolved",
              f"Runtime readiness without delivered/cleared export: {ident}", "readiness")
    if row["visual_direction_status"] == "approved_reference":
        check(row["row_kind"] == "reference" and bool(row["evidence_paths"]), f"Unsupported approval: {ident}", "readiness")
    check(row["licence_status"] in {"unresolved", "unverified_reference_only", "resolved"}, f"Unknown rights status: {ident}", "readiness")
    if row["licence_status"] == "resolved":
        check(bool(row["evidence_paths"]), f"Licence claim has no evidence: {ident}", "readiness")

for row in consumers:
    check(set(tokens(row["asset_ids"])) <= assets.keys(), f"Unknown consumer asset: {row['consumer_id']}", "coverage")
    check(bool(row["required_states"]), f"Consumer has no states: {row['consumer_id']}", "coverage")
    for field in ("behavior_owner", "presentation_integration_owner"):
        check(bool(row[field]) and task_ids(row[field]) <= task_graph.keys(), f"Invalid consumer owner: {row['consumer_id']}", "ownership")
roster_ids = set(re.findall(r"^\| `([a-z][a-z0-9_]+)`", read("docs/content-roster.md"), re.M))
check(roster_ids <= mapping.keys(), f"Unmapped roster IDs: {sorted(roster_ids - mapping.keys())}", "coverage")
for kind, expected in {"permanent": 12, "generated": 1, "actor": 5, "board": 4, "relic": 6, "upgrade": 8,
                       "event": 4, "service": 6, "room": 6, "currency": 1}.items():
    check(sum(row["kind"] == kind for row in consumers) == expected, f"Wrong scoped {kind} count", "coverage")
for screen in ("home", "combat", "map", "menu"):
    check(f"screen_{screen}" in mapping, f"Missing approved screen: {screen}", "coverage")
for row in manifest:
    if row["category"] == "character":
        check({"idle", "attack", "hit", "defeat"} <= set(tokens(row["required_states_variants"])),
              f"Missing character states: {row['id']}", "states")
    if row["id"] in {"button_frames", "ui_frames", "ui_state_overlays", "pilot_button"}:
        check({"normal", "pressed", "focused", "selected", "disabled", "invalid", "unavailable"}
              <= set(tokens(row["required_states_variants"])), f"Missing UI states: {row['id']}", "states")
destinations = {}
for row in manifest:
    if row["row_kind"] == "deliverable" and row["runtime_path_state"] == "planned":
        for path in tokens(row["runtime_destination"]):
            check(path not in destinations, f"Duplicate production destination: {row['id']} and {destinations.get(path)}", "reuse")
            destinations[path] = row["id"]

docs = ["README.md", "docs/art-direction.md", "docs/asset-manifest-guide.md", "docs/asset-production-spec.md",
        "docs/style-pilot-brief.md", "docs/project-plan.md", "docs/verification.md"]
for doc in docs:
    for reference in re.findall(r"\]\(([^)]+)\)", read(doc)):
        reference = reference.split(' "')[0].strip("<>")
        check(link_exists(reference, ROOT / doc), f"Broken local link: {doc} -> {reference}", "links")

changed = []
baseline = json.loads(read("output/qa/rc-010/preservation-baseline.json"))
for item in baseline:
    path = ROOT / item["path"]
    actual = hashlib.sha256(path.read_bytes()).hexdigest() if path.exists() else "missing"
    if actual != item["sha256"]:
        changed.append(item["path"])
check(not changed, f"Protected files changed: {changed}", "preservation")
historical = sorted((ROOT / "output/imagegen").glob("*.prompt.txt"))
check(len(historical) == 10 and all(path.with_name(path.name.replace(".prompt.txt", ".png")).exists() for path in historical),
      "Missing historical image/prompt pairs", "provenance")
comparisons = {}
for screen, stem in {"combat": "rune-cast-gameplay-reference-v5-navigation", "home": "rune-cast-home-reference-v1",
                     "map": "rune-cast-map-reference-v2-no-legend", "menu": "rune-cast-menu-reference-v2-blue-quit"}.items():
    approved = hashlib.sha256((ROOT / f"output/imagegen/approved/{screen}.png").read_bytes()).hexdigest()
    history = hashlib.sha256((ROOT / f"output/imagegen/{stem}.png").read_bytes()).hexdigest()
    comparisons[screen] = {"approved_sha256": approved, "historical_sha256": history, "identical": approved == history}

report = {"task": "RC-010", "planning_date": "2026-10-09", "result": "PASS" if not errors else "FAIL",
          "asset_records": len(manifest), "consumer_records": len(consumers), "original_ids_preserved": len(original),
          "category_counts": dict(sorted(Counter(row["category"] for row in manifest).items())),
          "readiness_counts": dict(sorted(Counter(row["readiness_status"] for row in manifest).items())),
          "consumer_kind_counts": dict(sorted(Counter(row["kind"] for row in consumers).items())),
          "roster_ids_mapped": len(roster_ids), "checks_by_family": dict(counts), "errors": errors,
          "protected_files": len(baseline), "protected_changes": changed, "historical_prompt_pairs": len(historical),
          "approved_history_comparisons": comparisons,
          "limits": "Document/manifest checks only; no new Godot, artwork, import, licensing or device acceptance."}
QA.mkdir(parents=True, exist_ok=True)
(QA / "validation-report.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
print(json.dumps(report, indent=2))
raise SystemExit(bool(errors))
