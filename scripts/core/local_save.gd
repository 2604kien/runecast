extends RefCounted
## RC-028 local save envelope. Only primitive data crosses this boundary.
## The caller validates models, commits a detached candidate, then publishes it.
const SCHEMA := "rc028_local_v1"
const INTEGER_TAG := "__rc_i64__"
const MAX_BYTES := 4194304
const MAX_DEPTH := 64
static var _writing_paths: Dictionary = {}
var path: String
var failure_point := "" # Explicit test injection; never read from save data.
var _validator: Callable
var _revision := 0
var _observed := ""
var _loaded := false
var _blocked := false

func _init(location: String = "user://runecast-save.json", validator: Callable = Callable()) -> void:
	path = ProjectSettings.globalize_path(location)
	_validator = validator

func load() -> Dictionary:
	var before := _fingerprint(path)
	var current := _read(path)
	var previous := _read(path + ".previous")
	_loaded = true
	_observed = _fingerprint(path)
	if before != _observed:
		_blocked = true
		return {"ok": false, "status": "invalid", "revision": 0, "error": "Saved progress changed while loading. Retry loading.", "recovery_available": false}
	_revision = int(current.get("revision", 0))
	_blocked = not current.ok
	if current.get("missing", false) and previous.get("missing", false):
		_blocked = false
		return {"ok": true, "status": "empty", "payload": {}, "revision": 0, "error": "", "recovery_available": false}
	if current.get("missing", false) and previous.ok:
		_blocked = true
		current.error = "The current save is missing after an interrupted replacement. A validated previous copy is available."
	current.status = "valid" if current.ok else "invalid"
	current.erase("_text")
	current.recovery_available = previous.ok
	if not current.ok and previous.ok: current.error += " You can recover the validated previous copy."
	return current

func commit(payload: Dictionary, expected_revision: int) -> Dictionary:
	if _writing_paths.has(path): return _failure("Another save transaction is in progress. Retry when it finishes.")
	if not _loaded: return _failure("Load the saved state before committing a transaction.")
	if _blocked: return _failure("The existing save needs explicit recovery. It has been preserved.")
	if expected_revision != _revision or _observed != _fingerprint(path): return _failure("Saved progress changed. Reload it before retrying; no newer save was overwritten.")
	if _revision == 9223372036854775807: return _failure("The save revision limit was reached.")
	_writing_paths[path] = true
	var result := _prepare_commit(payload, expected_revision)
	_writing_paths.erase(path)
	return result

func _prepare_commit(payload: Dictionary, expected_revision: int) -> Dictionary:
	var checked := _validate(payload)
	if not checked.ok: return checked
	var encoded := encode_document(payload, _revision + 1)
	if not encoded.ok: return encoded
	return _commit_text(str(encoded.text), expected_revision)

func _commit_text(contents: String, expected_revision: int) -> Dictionary:
	var directory_error := DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	if directory_error != OK: return _failure("Cannot create the save directory (%s)." % error_string(directory_error))
	var lock := _acquire_lock()
	if not lock.ok: return lock
	var result := _commit_locked(contents, expected_revision)
	_release_lock()
	return result

func _commit_locked(contents: String, expected_revision: int) -> Dictionary:
	if _revision != expected_revision or _observed != _fingerprint(path): return _failure("Saved progress changed before the write. Reload before retrying.")
	var temporary := path + ".temporary"
	var written := _write_checked(temporary, contents)
	if not written.ok: return written
	var candidate := _read(temporary)
	if not candidate.ok: return _failure("The temporary save failed validation: " + str(candidate.error))
	if _observed != _fingerprint(path): return _failure("Saved progress changed during the write. The newer save was preserved.")
	if FileAccess.file_exists(path):
		if failure_point == "backup": return _failure("Injected previous-copy write failure. Retry; progress has not changed.")
		var backup_write := _write_checked(path + ".previous.next", FileAccess.get_file_as_string(path), false)
		if not backup_write.ok: return backup_write
		if not _read(path + ".previous.next").ok: return _failure("The previous copy failed validation; the current save is unchanged.")
		var backed_up := _replace(path + ".previous.next", path + ".previous", false)
		if not backed_up.ok: return backed_up
	var replaced := _replace(temporary, path, true)
	if not replaced.ok: return replaced
	_revision = int(candidate.revision)
	_observed = _fingerprint(path)
	return {"ok": true, "revision": _revision, "error": ""}

func _write_checked(destination: String, contents: String, inject: bool = true) -> Dictionary:
	var file := FileAccess.open(destination, FileAccess.WRITE)
	if file == null: return _failure("Cannot open the temporary save (%s). Retry after checking storage." % error_string(FileAccess.get_open_error()))
	if inject and failure_point == "write":
		file.store_string(contents.left(contents.length() / 2))
		file.close()
		return _failure("Injected save write failure. The last committed progress is unchanged.")
	file.store_string(contents)
	var write_error := file.get_error()
	file.flush()
	var flush_error := file.get_error()
	file.close() # Godot close has no result; readback verifies the closed file.
	if write_error != OK or flush_error != OK or (inject and failure_point in ["flush", "close"]):
		return _failure("The save could not be flushed or closed successfully. Retry; progress has not changed.")
	if FileAccess.get_file_as_string(destination) != contents:
		return _failure("The closed save did not match the written data. Retry; progress has not changed.")
	return {"ok": true, "error": ""}

func _replace(source: String, destination: String, inject: bool) -> Dictionary:
	# Retain the old target until promotion succeeds. The validated .previous
	# also survives a process termination in the two-rename interval.
	var displaced := destination + ".replacing"
	if FileAccess.file_exists(displaced):
		var removal := DirAccess.remove_absolute(displaced)
		if removal != OK: return _failure("Cannot clear an older replacement staging file (%s)." % error_string(removal))
	var had_target := FileAccess.file_exists(destination)
	if had_target:
		var moved := DirAccess.rename_absolute(destination, displaced)
		if moved != OK: return _failure("Cannot stage the save replacement (%s)." % error_string(moved))
	var replacement := ERR_CANT_CREATE if inject and failure_point == "replace" else DirAccess.rename_absolute(source, destination)
	if replacement != OK:
		var rollback := DirAccess.rename_absolute(displaced, destination) if had_target else OK
		if rollback != OK:
			_blocked = true
			return _failure("Save replacement and rollback failed. The previous copy is preserved; reload and recover it.")
		return _failure("Save replacement failed (%s). The last committed progress is unchanged; Retry." % error_string(replacement))
	if had_target: DirAccess.remove_absolute(displaced) # Cleanup only; new+previous are already complete.
	return {"ok": true, "error": ""}

func recover_previous() -> Dictionary:
	if _writing_paths.has(path): return _failure("Another save transaction is in progress.")
	if not _loaded or not _blocked: return _failure("Recovery requires a previously inspected invalid save.")
	if _observed != _fingerprint(path): return _failure("The save changed. Inspect it again before recovery.")
	_writing_paths[path] = true
	var previous := _read(path + ".previous")
	if not previous.ok:
		_writing_paths.erase(path)
		return _failure("No validated previous copy is available. The unreadable save has been preserved.")
	var lock := _acquire_lock()
	if not lock.ok:
		_writing_paths.erase(path)
		return lock
	var result := _recover_locked()
	_release_lock()
	_writing_paths.erase(path)
	return result

func _recover_locked() -> Dictionary:
	if _observed != _fingerprint(path): return _failure("The save changed before recovery. Inspect it again.")
	# Validate again under the writer lock and retain those exact bytes. Never
	# promote a reread which might differ from the approved previous model.
	var previous := _read(path + ".previous")
	if not previous.ok: return _failure("The previous copy changed or failed validation. The current save is preserved.")
	var preserved_path := ""
	if FileAccess.file_exists(path):
		preserved_path = path + ".unreadable-" + Crypto.new().generate_random_bytes(12).hex_encode()
		var preserved := DirAccess.copy_absolute(path, preserved_path)
		if preserved != OK or _fingerprint(preserved_path) != _observed: return _failure("Could not preserve the unreadable original byte for byte. Recovery was cancelled.")
	var written := _write_checked(path + ".temporary", str(previous._text))
	if not written.ok: return written
	var candidate := _read(path + ".temporary")
	if not candidate.ok or candidate.payload != previous.payload or candidate.revision != previous.revision:
		return _failure("The recovery candidate failed validation. The current save is preserved.")
	if _observed != _fingerprint(path): return _failure("The current save changed during recovery. Inspect it again.")
	var replaced := _replace(path + ".temporary", path, true)
	if not replaced.ok: return replaced
	_blocked = false
	_loaded = true
	_revision = int(previous.revision)
	_observed = _fingerprint(path)
	return {"ok": true, "status": "valid", "payload": previous.payload, "revision": _revision,
		"error": "", "recovery_available": true, "preserved_path": preserved_path}

func _acquire_lock() -> Dictionary:
	var lock_path := path + ".lock"
	var made := DirAccess.make_dir_absolute(lock_path)
	if made != OK:
		var owner_path := lock_path.path_join("owner")
		var owner := FileAccess.get_file_as_string(owner_path) if FileAccess.file_exists(owner_path) else ""
		if owner.is_valid_int() and not OS.is_process_running(int(owner)):
			DirAccess.remove_absolute(owner_path)
			DirAccess.remove_absolute(lock_path)
			made = DirAccess.make_dir_absolute(lock_path)
		if made != OK: return _failure("Another process owns the save lock. Close it, then Retry. An ownerless lock needs manual inspection.")
	var owner_file := FileAccess.open(lock_path.path_join("owner"), FileAccess.WRITE)
	if owner_file == null:
		DirAccess.remove_absolute(lock_path)
		return _failure("Cannot record the save lock owner.")
	owner_file.store_string(str(OS.get_process_id()))
	owner_file.flush()
	var owner_error := owner_file.get_error()
	owner_file.close()
	if owner_error != OK:
		_release_lock()
		return _failure("Cannot flush the save lock owner.")
	return {"ok": true, "error": ""}

func _release_lock() -> void:
	DirAccess.remove_absolute(path + ".lock/owner")
	DirAccess.remove_absolute(path + ".lock")

func _read(source: String) -> Dictionary:
	if not FileAccess.file_exists(source):
		return {"ok": false, "missing": true, "error": "No saved run is available.", "revision": 0}
	var file := FileAccess.open(source, FileAccess.READ)
	if file == null: return _failure("Cannot read the saved progress (%s)." % error_string(FileAccess.get_open_error()))
	if file.get_length() > MAX_BYTES:
		file.close()
		return _failure("The save exceeds the supported size limit.")
	var bytes := file.get_buffer(file.get_length())
	var read_error := file.get_error()
	file.close()
	if read_error != OK: return _failure("The saved progress could not be read completely (%s)." % error_string(read_error))
	if not _valid_utf8(bytes): return _failure("The save contains damaged UTF-8 bytes. The original file is preserved.")
	var contents := bytes.get_string_from_utf8()
	var decoded := decode_document(contents)
	if not decoded.ok: return decoded
	var checked := _validate(decoded.payload)
	if not checked.ok: return checked
	decoded._text = contents
	return decoded

func _validate(payload: Dictionary) -> Dictionary:
	if not _validator.is_valid(): return _failure("No registered save validator is configured.")
	var checked: Variant = _validator.call(payload.duplicate(true))
	if not checked is Dictionary or checked.get("ok") != true:
		return _failure(str(checked.get("error", "The saved models are incompatible.")) if checked is Dictionary else "The save validator returned an invalid result.")
	return {"ok": true, "error": ""}

static func encode_document(payload: Dictionary, revision: int) -> Dictionary:
	if revision <= 0: return _failure("The save revision must be positive.")
	var encoded := _encode(payload, 0)
	if not encoded.ok: return encoded
	var body := JSON.stringify(encoded.value, "", true, true)
	var envelope := JSON.stringify({"schema": SCHEMA, "revision": str(revision), "sha256": body.sha256_text(), "body": body})
	if envelope.to_utf8_buffer().size() > MAX_BYTES: return _failure("The save exceeds the supported size limit.")
	return {"ok": true, "error": "", "text": envelope}

static func decode_document(contents: String) -> Dictionary:
	if contents.to_utf8_buffer().size() > MAX_BYTES: return _failure("The save exceeds the supported size limit.")
	var parser := JSON.new()
	if parser.parse(contents) != OK or not parser.data is Dictionary: return _failure("The save is truncated or is not a valid JSON envelope.")
	var envelope: Dictionary = parser.data
	if envelope.get("schema") != SCHEMA: return _failure("Unsupported save schema. This version supports only " + SCHEMA + ".")
	if envelope.size() != 4 or not envelope.get("body") is String or not envelope.get("sha256") is String or not _canonical_integer(envelope.get("revision")) or int(envelope.revision) <= 0:
		return _failure("The save envelope or revision is malformed.")
	if envelope.body.sha256_text() != envelope.sha256: return _failure("The save checksum does not match; the file may be damaged.")
	if parser.parse(envelope.body) != OK: return _failure("The save body is not valid JSON.")
	var decoded := _decode(parser.data, 0)
	if not decoded.ok: return decoded
	if not decoded.value is Dictionary: return _failure("The save body must contain model records.")
	return {"ok": true, "error": "", "payload": decoded.value, "revision": int(envelope.revision)}

static func _encode(value: Variant, depth: int) -> Dictionary:
	if depth > MAX_DEPTH: return _failure("Save data is nested too deeply.")
	if value is int: return {"ok": true, "value": {INTEGER_TAG: str(value)}}
	if value is Dictionary:
		var result := {}
		for key in value:
			if not (key is String or key is StringName) or str(key) == INTEGER_TAG: return _failure("Save dictionary key '%s' has unsupported type %s." % [str(key), type_string(typeof(key))])
			var item := _encode(value[key], depth + 1)
			if not item.ok: return item
			result[str(key)] = item.value
		return {"ok": true, "value": result}
	if value is Array:
		var result: Array = []
		for item in value:
			var encoded := _encode(item, depth + 1)
			if not encoded.ok: return encoded
			result.append(encoded.value)
		return {"ok": true, "value": result}
	if value == null or value is String or value is bool: return {"ok": true, "value": value}
	if value is StringName: return {"ok": true, "value": str(value)}
	if value is float and is_finite(value): return {"ok": true, "value": value}
	return _failure("Save data contains an unsupported value; objects, callbacks and resources cannot be serialized.")

static func _decode(value: Variant, depth: int) -> Dictionary:
	if depth > MAX_DEPTH: return _failure("Save data is nested too deeply.")
	if value is Dictionary:
		if value.has(INTEGER_TAG):
			if value.size() != 1 or not _canonical_integer(value[INTEGER_TAG]): return _failure("A saved integer is malformed or outside the signed 64-bit range.")
			return {"ok": true, "value": int(value[INTEGER_TAG])}
		var result := {}
		for key in value:
			var item := _decode(value[key], depth + 1)
			if not item.ok: return item
			result[key] = item.value
		return {"ok": true, "value": result}
	if value is Array:
		var result: Array = []
		for item in value:
			var decoded := _decode(item, depth + 1)
			if not decoded.ok: return decoded
			result.append(decoded.value)
		return {"ok": true, "value": result}
	if value == null or value is String or value is bool or (value is float and is_finite(value)): return {"ok": true, "value": value}
	return _failure("The save contains an unsupported primitive.")

static func _canonical_integer(value: Variant) -> bool:
	return value is String and value.is_valid_int() and str(int(value)) == value

static func _valid_utf8(bytes: PackedByteArray) -> bool:
	# Check before Godot's decoder so corrupt files produce a recoverable
	# status instead of engine Unicode errors or replacement characters.
	var index := 0
	while index < bytes.size():
		var first := int(bytes[index])
		index += 1
		if first < 128: continue
		var continuation := 0
		var low := 128
		var high := 191
		if first >= 194 and first <= 223: continuation = 1
		elif first >= 224 and first <= 239:
			continuation = 2
			if first == 224: low = 160
			if first == 237: high = 159
		elif first >= 240 and first <= 244:
			continuation = 3
			if first == 240: low = 144
			if first == 244: high = 143
		else: return false
		if index + continuation > bytes.size() or bytes[index] < low or bytes[index] > high: return false
		index += 1
		for offset in range(continuation - 1):
			if bytes[index] < 128 or bytes[index] > 191: return false
			index += 1
	return true

static func _fingerprint(source: String) -> String:
	return FileAccess.get_sha256(source) if FileAccess.file_exists(source) else ""

static func _failure(message: String) -> Dictionary:
	return {"ok": false, "error": message, "revision": 0}
