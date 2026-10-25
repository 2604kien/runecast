extends SceneTree
const Save = preload("res://scripts/core/local_save.gd")
var checks := 0
var failures := 0
var root_path := "res://output/qa/rc-028/store-tests-" + str(Time.get_ticks_usec())

func _init() -> void:
	call_deferred("_run")

func _check(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL: " + label)

func _validate(payload: Dictionary) -> Dictionary:
	return {"ok": payload.get("value") is int and payload.get("valid", true) == true, "error": "Invalid test model."}

func _run() -> void:
	var location := root_path.path_join("save.json")
	var store := Save.new(location, _validate)
	_check(store.load().status == "empty", "fresh store remains empty")
	var values := [0, 1, -1, 9007199254740993, -9007199254740993, 9223372036854775807, -9223372036854775807 - 1]
	var data := {"value": 9007199254740993, "integers": values, "nested": {"rng": -9223372036854775807 - 1}, "text": "rune", "flag": true, "null": null}
	var encoded := Save.encode_document(data, 9007199254740993)
	_check(encoded.ok, "int64 payload encodes")
	var decoded := Save.decode_document(encoded.text)
	_check(decoded.ok and decoded.payload == data and decoded.revision == 9007199254740993, "all signed int64 extremes round trip exactly")
	_check(not Save.encode_document({"object": RefCounted.new()}, 1).ok, "objects cannot be serialized")
	_check(not Save.encode_document({"callback": _validate}, 1).ok, "callbacks cannot be serialized")
	_check(not Save.encode_document({Save.INTEGER_TAG: "4"}, 1).ok, "integer marker cannot collide")
	_check(not Save.decode_document(encoded.text.left(20)).ok, "truncation rejected")
	_check(not Save.decode_document(encoded.text.replace(Save.SCHEMA, "future_v2")).ok, "unsupported version rejected")
	var envelope: Dictionary = JSON.parse_string(encoded.text)
	envelope.sha256 = "broken"
	_check(not Save.decode_document(JSON.stringify(envelope)).ok, "damaged checksum rejected")
	for value in ["9223372036854775808", "-9223372036854775809", "01", "+1", "1.0"]:
		var body := JSON.stringify({"value": {Save.INTEGER_TAG: value}})
		var malformed := JSON.stringify({"schema": Save.SCHEMA, "revision": "1", "body": body, "sha256": body.sha256_text()})
		_check(not Save.decode_document(malformed).ok, "invalid integer rejected " + value)
	_check(store.commit(data, 0).ok, "first commit")
	_check(Save.new(location, _validate).load().payload == data, "independent store reads exact payload")
	var original := FileAccess.get_file_as_string(store.path)
	for stage in ["write", "flush", "close", "backup", "replace"]:
		store.failure_point = stage
		var result := store.commit({"value": 2}, 1)
		_check(not result.ok, "injected " + stage + " fails")
		_check(FileAccess.get_file_as_string(store.path) == original, stage + " preserves committed current bytes")
		_check(Save.new(location, _validate).load().payload == data, stage + " preserves coherent old model")
	store.failure_point = ""
	_check(store.commit({"value": 2}, 1).ok, "retry commits once")
	_check(not store.commit({"value": 3}, 1).ok, "stale revision rejected")
	_check(not store.commit({"value": 3, "valid": false}, 2).ok, "invalid candidate cannot overwrite")
	var stale := Save.new(location, _validate)
	stale.load()
	_check(store.commit({"value": 3}, 2).ok, "newer writer commit")
	_check(not stale.commit({"value": 4}, 2).ok, "stale writer digest rejects overwrite")
	var lock_path := store.path + ".lock"
	DirAccess.make_dir_absolute(lock_path)
	var owner := FileAccess.open(lock_path.path_join("owner"), FileAccess.WRITE)
	owner.store_string(str(OS.get_process_id()))
	owner.close()
	_check(not store.commit({"value": 4}, 3).ok, "live process lock prevents competing writer")
	_check(Save.new(location, _validate).load().payload.value == 3, "competing writer preserves newest committed model")
	DirAccess.remove_absolute(lock_path.path_join("owner"))
	DirAccess.remove_absolute(lock_path)
	var nested: Array = []
	var holder: Array = []
	var guarded := Save.new(root_path.path_join("reentrant.json"), func(payload):
		nested.append(holder[0].commit({"value": 99}, 0))
		return _validate(payload))
	holder.append(guarded)
	guarded.load()
	_check(guarded.commit({"value": 1}, 0).ok, "outer commit succeeds with reentrant validator")
	_check(not nested.is_empty() and nested.all(func(result): return not result.ok), "every reentrant write rejects before mutation")
	holder.clear()
	var broken := FileAccess.open(store.path, FileAccess.WRITE)
	broken.store_string("{truncated")
	broken.close()
	var invalid := store.load()
	_check(not invalid.ok and invalid.recovery_available, "corrupt current exposes validated previous")
	_check(not store.commit({"value": 9}, 0).ok, "invalid current is never silently replaced")
	store.failure_point = "replace"
	_check(not store.recover_previous().ok and FileAccess.get_file_as_string(store.path) == "{truncated", "failed recovery preserves corrupt current")
	store.failure_point = ""
	var recovered := store.recover_previous()
	_check(recovered.ok and recovered.payload.value == 2, "explicit recovery restores validated previous")
	_check(FileAccess.get_file_as_string(recovered.preserved_path) == "{truncated", "unreadable original preserved for diagnosis")
	_check(store.commit({"value": 4}, recovered.revision).ok, "recovered save can commit")
	# A crash between renames leaves a validated previous but no current.
	DirAccess.rename_absolute(store.path, store.path + ".crash-original")
	var interrupted := store.load()
	_check(not interrupted.ok and interrupted.recovery_available, "missing current with previous requires explicit recovery")
	_check(store.recover_previous().ok, "interrupted replacement recovers previous")
	# Invalid backups never become a recovery option.
	for suffix in ["", ".previous"]:
		var invalid_file := FileAccess.open(store.path + suffix, FileAccess.WRITE)
		invalid_file.store_string("broken")
		invalid_file.close()
	var both_invalid := store.load()
	_check(not both_invalid.ok and not both_invalid.recovery_available, "invalid previous never offered")
	_check(not store.recover_previous().ok, "invalid previous cannot recover")
	# Recovery preserves arbitrary damaged bytes, including invalid UTF-8.
	var binary_path := root_path.path_join("binary.json")
	var binary_store := Save.new(binary_path, _validate)
	binary_store.load()
	binary_store.commit({"value": 1}, 0)
	binary_store.commit({"value": 2}, 1)
	var damaged := PackedByteArray([0, 255, 254, 128, 65])
	var damaged_file := FileAccess.open(binary_path, FileAccess.WRITE)
	damaged_file.store_buffer(damaged)
	damaged_file.close()
	var damaged_load := binary_store.load()
	_check(not damaged_load.ok and damaged_load.recovery_available, "invalid UTF-8 reports recoverable status without decoding")
	var binary_recovered := binary_store.recover_previous()
	_check(binary_recovered.ok and FileAccess.get_file_as_bytes(binary_recovered.preserved_path) == damaged, "recovery preserves damaged original bytes exactly")
	var race_path := ProjectSettings.globalize_path(root_path.path_join("recovery-race.json"))
	var armed := [false]
	var race_store := Save.new(race_path, func(payload):
		if armed[0]:
			armed[0] = false
			var tampered := FileAccess.open(race_path + ".previous", FileAccess.WRITE)
			tampered.store_string("changed after inspection")
			tampered.close()
		return _validate(payload))
	race_store.load()
	race_store.commit({"value": 1}, 0)
	race_store.commit({"value": 2}, 1)
	var race_broken := FileAccess.open(race_path, FileAccess.WRITE)
	race_broken.store_string("unreadable current")
	race_broken.close()
	race_store.load()
	armed[0] = true
	_check(not race_store.recover_previous().ok and FileAccess.get_file_as_string(race_path) == "unreadable current", "recovery revalidates changed previous under lock before promotion")
	print("RC-028 store checks: %d; failures: %d" % [checks, failures])
	quit(1 if failures else 0)
