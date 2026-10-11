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
CLEANUP_LEDGER = "output/art/rc-011/cleanup/deletion-manifest.json"
BASELINE_SHA256 = "a9433d2eb4fa3a0a56b693574e5287ec5ce2b3517dbd04fa0a3004a6c1228a81"
errors = []
counts = Counter()


def check(ok, message, family):
    counts[family] += 1
    if not ok:
        errors.append(message)


def read(path):
    return (ROOT / path).read_text(encoding="utf-8-sig")


def cleanup_path_allowed(value, removal=False):
    """Only canonical workspace art paths can receive cleanup exceptions."""
    if not isinstance(value, str) or not value or "\\" in value or ":" in value:
        return False
    parts = value.split("/")
    if any(part in ("", ".", "..") for part in parts):
        return False
    try:
        (ROOT / value).resolve().relative_to(ROOT.resolve())
    except ValueError:
        return False
    art = value.startswith(("source-assets/pilot/", "output/art/rc-011/"))
    study = removal and len(parts) == 3 and parts[:2] == ["output", "imagegen"]
    # Approved references, runtime and QA paths are outside these exact scopes.
    return art or bool(study and parts[2] != "approved")


def load_cleanup():
    """Missing ledger means the original strict preservation contract applies."""
    result = {"path": CLEANUP_LEDGER, "present": False, "completed": False,
              "removed": {}, "updated": {}, "errors": []}
    ledger_path = ROOT / CLEANUP_LEDGER
    if not ledger_path.exists():
        return result
    result["present"] = True
    try:
        ledger = json.loads(ledger_path.read_text(encoding="utf-8-sig"))
    except (OSError, ValueError) as exc:
        result["errors"].append("Unreadable cleanup ledger: " + str(exc))
        return result
    if not isinstance(ledger, dict):
        result["errors"].append("Cleanup ledger must be an object")
        return result
    if ledger.get("status") != "completed" or not isinstance(ledger.get("authorization"), str) or not ledger["authorization"].strip():
        result["errors"].append("Cleanup requires completed status and recorded user authorization")
    seen = set()
    for kind in ("removed", "updated"):
        rows = ledger.get(kind)
        if not isinstance(rows, list):
            result["errors"].append("Cleanup " + kind + " must be a list")
            continue
        for row in rows:
            if not isinstance(row, dict):
                result["errors"].append("Invalid cleanup " + kind + " record")
                continue
            value = row.get("path")
            hash_fields = ("sha256",) if kind == "removed" else ("before_sha256", "after_sha256")
            valid = cleanup_path_allowed(value, removal=kind == "removed")
            valid = valid and value.casefold() not in seen
            valid = valid and isinstance(row.get("reason"), str) and bool(row["reason"].strip())
            valid = valid and all(isinstance(row.get(field), str) and re.fullmatch(r"[0-9a-f]{64}", row[field]) for field in hash_fields)
            if kind == "removed":
                valid = valid and type(row.get("bytes")) is int and row["bytes"] >= 0
            if not valid:
                result["errors"].append("Invalid or duplicate cleanup " + kind + " path/hash/reason: " + str(value))
                continue
            seen.add(value.casefold())
            path = ROOT / value
            if kind == "removed":
                actual_ok = not path.exists()
            else:
                actual_ok = path.is_file() and hashlib.sha256(path.read_bytes()).hexdigest() == row["after_sha256"]
            if not actual_ok:
                result["errors"].append("Completed cleanup " + kind + " state does not match: " + value)
                continue
            result[kind][value] = row
    result["completed"] = not result["errors"]
    if not result["completed"]:
        # A partial or invalid record cannot weaken any preservation check.
        result["removed"].clear()
        result["updated"].clear()
    return result


def preservation_partition(rows, cleanup, allow_updates=False):
    result = {"total": len(rows), "preserved": [], "retired": [], "updated": [], "unexpected": []}
    for row in rows:
        value, expected = row["path"], row["sha256"]
        path = ROOT / value
        actual = hashlib.sha256(path.read_bytes()).hexdigest() if path.is_file() else None
        removed = cleanup["removed"].get(value, {})
        updated = cleanup["updated"].get(value, {})
        if actual == expected:
            state = "preserved"
        elif not path.exists() and removed.get("sha256") == expected:
            state = "retired"
        elif allow_updates and actual and updated.get("before_sha256") == expected and updated.get("after_sha256") == actual:
            state = "updated"
        else:
            state = "unexpected"
        result[state].append(value)
    result["counts"] = {key: len(result[key]) for key in ("preserved", "retired", "updated", "unexpected")}
    return result


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
        "docs/style-pilot-brief.md", "docs/project-plan.md", "docs/verification.md",
        "docs/visual-reference.md", "docs/gameplay-visual-contract.md"]
for doc in docs:
    for reference in re.findall(r"\]\(([^)]+)\)", read(doc)):
        reference = reference.split(' "')[0].strip("<>")
        check(link_exists(reference, ROOT / doc), f"Broken local link: {doc} -> {reference}", "links")

cleanup = load_cleanup()
check(not cleanup["errors"], f"Invalid cleanup ledger: {cleanup['errors']}", "cleanup")
baseline_path = ROOT / "output/qa/rc-010/preservation-baseline.json"
check(hashlib.sha256(baseline_path.read_bytes()).hexdigest() == BASELINE_SHA256,
      "Original preservation baseline bytes changed", "preservation")
baseline = json.loads(read("output/qa/rc-010/preservation-baseline.json"))
preservation = preservation_partition(baseline, cleanup)
changed = preservation["unexpected"]
check(not changed, f"Unexpected protected-file changes: {changed}", "preservation")
historical = sorted((ROOT / "output/imagegen").glob("*.prompt.txt"))
# Completed cleanup may retire studies, but every retained pair must be intact.
# Original study removals still require the original baseline hash above.
check((cleanup["completed"] or len(historical) >= 10)
      and all(path.with_name(path.name.replace(".prompt.txt", ".png")).is_file() for path in historical)
      and all(path.with_name(path.stem + ".prompt.txt").is_file() for path in (ROOT / "output/imagegen").glob("*.png")),
      "Missing retained historical image/prompt pairs", "provenance")
comparisons = {}
for screen, stem in {"combat": "rune-cast-gameplay-reference-v5-navigation", "home": "rune-cast-home-reference-v1",
                     "map": "rune-cast-map-reference-v2-no-legend", "menu": "rune-cast-menu-reference-v2-blue-quit"}.items():
    approved = hashlib.sha256((ROOT / f"output/imagegen/approved/{screen}.png").read_bytes()).hexdigest()
    history_name = f"output/imagegen/{stem}.png"
    history_path = ROOT / history_name
    history = hashlib.sha256(history_path.read_bytes()).hexdigest() if history_path.is_file() else cleanup["removed"].get(history_name, {}).get("sha256")
    check(bool(history), f"Historical comparison has neither retained bytes nor a recorded retirement: {history_name}", "provenance")
    comparisons[screen] = {"approved_sha256": approved, "historical_sha256": history,
                           "historical_state": "retained" if history_path.is_file() else "retired" if history else "missing",
                           "identical": approved == history if history else None}

report = {"task": "RC-010", "planning_date": "2026-10-09", "result": "PASS" if not errors else "FAIL",
          "asset_records": len(manifest), "consumer_records": len(consumers), "original_ids_preserved": len(original),
          "category_counts": dict(sorted(Counter(row["category"] for row in manifest).items())),
          "readiness_counts": dict(sorted(Counter(row["readiness_status"] for row in manifest).items())),
          "consumer_kind_counts": dict(sorted(Counter(row["kind"] for row in consumers).items())),
          "roster_ids_mapped": len(roster_ids), "checks_by_family": dict(counts), "errors": errors,
          "protected_files": len(baseline), "protected_changes": changed, "preservation": preservation,
          "cleanup": {"path": CLEANUP_LEDGER, "present": cleanup["present"], "completed": cleanup["completed"],
                      "removed_files": len(cleanup["removed"]), "updated_files": len(cleanup["updated"])},
          "historical_prompt_pairs": len(historical),
          "approved_history_comparisons": comparisons,
          "limits": "Document/manifest checks only; no new Godot, artwork, import, licensing or device acceptance."}
QA.mkdir(parents=True, exist_ok=True)
(QA / "validation-report.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
print(json.dumps(report, indent=2))
raise SystemExit(bool(errors))
