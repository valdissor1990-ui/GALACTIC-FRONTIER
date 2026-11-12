extends Node
class_name SaveManager
## Versioned, local-only save slots with atomic replacement and backup recovery.
## Add this node as an autoload named SaveManager when the game session is ready.

signal save_completed(slot_id: String)
signal save_failed(slot_id: String, reason: String)

const CURRENT_SCHEMA_VERSION: int = 1
const MAX_SAVE_BYTES: int = 2 * 1024 * 1024
const MAX_SLOT_ID_LENGTH: int = 24

@export_dir var save_directory: String = "user://saves"


func save_slot(slot_id: String, payload: Dictionary) -> Dictionary:
	if not _is_valid_slot_id(slot_id):
		return _failure("Invalid slot id.")
	if payload.is_empty():
		return _failure("Save payload is empty.")
	if not _is_json_value(payload):
		return _failure("Save payload contains unsupported or non-finite values.")

	var payload_json := JSON.stringify(payload)
	var envelope := {
		"schema_version": CURRENT_SCHEMA_VERSION,
		"saved_at_unix": int(Time.get_unix_time_from_system()),
		"payload_hash": _payload_checksum(payload),
		"payload": payload
	}
	var serialized := JSON.stringify(envelope, "  ")
	if serialized.to_utf8_buffer().size() > MAX_SAVE_BYTES:
		return _failure("Save exceeds the %d byte limit." % MAX_SAVE_BYTES)

	var directory_error := _ensure_save_directory()
	if directory_error != OK:
		return _failure("Cannot create save directory (error %d)." % directory_error)

	var target := _slot_path(slot_id)
	var temporary := target + ".tmp"
	var backup := target + ".bak"
	var write_error := _write_file(temporary, serialized)
	if write_error != OK:
		return _failure("Cannot write temporary save (error %d)." % write_error)

	var target_absolute := ProjectSettings.globalize_path(target)
	var temporary_absolute := ProjectSettings.globalize_path(temporary)
	var backup_absolute := ProjectSettings.globalize_path(backup)

	if FileAccess.file_exists(backup):
		DirAccess.remove_absolute(backup_absolute)
	if FileAccess.file_exists(target):
		var backup_error := DirAccess.rename_absolute(target_absolute, backup_absolute)
		if backup_error != OK:
			DirAccess.remove_absolute(temporary_absolute)
			return _failure("Cannot preserve previous save (error %d)." % backup_error)

	var commit_error := DirAccess.rename_absolute(temporary_absolute, target_absolute)
	if commit_error != OK:
		if FileAccess.file_exists(backup):
			DirAccess.rename_absolute(backup_absolute, target_absolute)
		DirAccess.remove_absolute(temporary_absolute)
		return _failure("Cannot commit save file (error %d)." % commit_error)

	save_completed.emit(slot_id)
	return {"ok": true, "slot_id": slot_id, "saved_at_unix": envelope.saved_at_unix}


func load_slot(slot_id: String) -> Dictionary:
	if not _is_valid_slot_id(slot_id):
		return _failure("Invalid slot id.")

	var primary := _read_and_validate(_slot_path(slot_id))
	if primary.ok:
		primary["recovered_from_backup"] = false
		return primary

	var backup_path := _slot_path(slot_id) + ".bak"
	var backup := _read_and_validate(backup_path)
	if backup.ok:
		backup["recovered_from_backup"] = true
		return backup

	return _failure("Save and backup are unavailable or invalid. Primary: %s Backup: %s" % [str(primary.get("error", "unknown")), str(backup.get("error", "unknown"))])


func delete_slot(slot_id: String) -> Dictionary:
	if not _is_valid_slot_id(slot_id):
		return _failure("Invalid slot id.")
	var target := _slot_path(slot_id)
	var backup := target + ".bak"
	var temporary := target + ".tmp"
	for path in [target, backup, temporary]:
		if FileAccess.file_exists(path):
			var error := DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
			if error != OK:
				return _failure("Cannot delete %s (error %d)." % [path.get_file(), error])
	return {"ok": true, "slot_id": slot_id}


func list_slots() -> Array[Dictionary]:
	var slots: Array[Dictionary] = []
	var directory := DirAccess.open(save_directory)
	if directory == null:
		return slots
	directory.list_dir_begin()
	var filename := directory.get_next()
	while not filename.is_empty():
		if not directory.current_is_dir() and filename.ends_with(".json"):
			var slot_id := filename.trim_suffix(".json")
			if _is_valid_slot_id(slot_id):
				var result := _read_and_validate(_slot_path(slot_id))
				if result.ok:
					slots.append({
						"slot_id": slot_id,
						"saved_at_unix": result.saved_at_unix,
						"schema_version": result.schema_version
					})
		filename = directory.get_next()
	directory.list_dir_end()
	slots.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.saved_at_unix) > int(b.saved_at_unix)
	)
	return slots


func _read_and_validate(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return _failure("File does not exist.")
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return _failure("Cannot open save file.")
	if file.get_length() > MAX_SAVE_BYTES:
		file.close()
		return _failure("Save file exceeds size limit.")
	var serialized := file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(serialized)
	if not parsed is Dictionary:
		return _failure("Save file is not a JSON object.")
	var envelope: Dictionary = parsed
	var version := int(envelope.get("schema_version", -1))
	if version != CURRENT_SCHEMA_VERSION:
		return _failure("Unsupported save schema version: %d." % version)
	var payload: Variant = envelope.get("payload")
	if not payload is Dictionary or payload.is_empty():
		return _failure("Save payload is missing.")
	if not _is_json_value(payload):
		return _failure("Save payload contains invalid values.")
	var expected_hash := str(envelope.get("payload_hash", ""))
	if _payload_checksum(payload) != expected_hash:
		return _failure("Save checksum mismatch.")
	return {
		"ok": true,
		"payload": payload,
		"saved_at_unix": int(envelope.get("saved_at_unix", 0)),
		"schema_version": version
	}


func _payload_checksum(payload: Dictionary) -> String:
	var normalized: Variant = JSON.parse_string(JSON.stringify(payload))
	return str(hash(JSON.stringify(_canonicalize_json(normalized))))


func _canonicalize_json(value: Variant) -> Variant:
	if value is Dictionary:
		var keys: Array = value.keys()
		keys.sort()
		var canonical: Dictionary = {}
		for key in keys:
			canonical[key] = _canonicalize_json(value[key])
		return canonical
	if value is Array:
		var canonical_array: Array = []
		for item in value:
			canonical_array.append(_canonicalize_json(item))
		return canonical_array
	return value


func _write_file(path: String, contents: String) -> Error:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(contents)
	file.flush()
	var error := file.get_error()
	file.close()
	return error


func _ensure_save_directory() -> Error:
	return DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(save_directory))


func _slot_path(slot_id: String) -> String:
	return save_directory.path_join(slot_id + ".json")


func _is_valid_slot_id(slot_id: String) -> bool:
	if slot_id.is_empty() or slot_id.length() > MAX_SLOT_ID_LENGTH:
		return false
	for character in slot_id:
		var code := character.unicode_at(0)
		var valid := (code >= 48 and code <= 57) or (code >= 65 and code <= 90) or (code >= 97 and code <= 122) or code == 45 or code == 95
		if not valid:
			return false
	return true


func _is_json_value(value: Variant, depth: int = 0) -> bool:
	if depth > 16:
		return false
	match typeof(value):
		TYPE_NIL, TYPE_BOOL, TYPE_STRING, TYPE_INT:
			return true
		TYPE_FLOAT:
			return is_finite(value)
		TYPE_ARRAY:
			for item in value:
				if not _is_json_value(item, depth + 1):
					return false
			return true
		TYPE_DICTIONARY:
			for key in value:
				if not key is String or not _is_json_value(value[key], depth + 1):
					return false
			return true
		_:
			return false


func _failure(reason: String) -> Dictionary:
	return {"ok": false, "error": reason}
