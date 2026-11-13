extends Node
## Verifies a release archive before handing off replacement to Windows PowerShell.
## Save data remains in user:// and is never touched by game updates.

signal status_changed(message: String)
signal update_available(version: String, notes: String)
signal update_failed(reason: String)

const RELEASE_API := "https://api.github.com/repos/valdissor1990-ui/GALACTIC-FRONTIER/releases/latest"
const ARCHIVE_NAME := "GALACTIC-FRONTIER-windows-update.zip"
const MANIFEST_NAME := "update-manifest.json"
const HELPER_SOURCE := "res://tools/install_update.ps1"

var _http: HTTPRequest
var _manifest: Dictionary = {}
var _busy := false


func _ready() -> void:
	_http = HTTPRequest.new()
	_http.timeout = 120.0
	add_child(_http)


func current_version() -> String:
	return str(ProjectSettings.get_setting("application/config/version", "0.1.0"))


func check_for_updates() -> void:
	if _busy:
		return
	if not OS.has_feature("windows"):
		status_changed.emit("Автообновление доступно в Windows-версии.")
		return
	_busy = true
	status_changed.emit("Проверяем наличие обновлений…")
	var release_result: Dictionary = await _request_json(RELEASE_API)
	if not release_result.ok:
		var reason := str(release_result.error)
		if reason.contains("HTTP 404"):
			_busy = false
			status_changed.emit("Пока нет опубликованных обновлений.")
			return
		_fail(reason)
		return
	var release: Dictionary = release_result.data
	if bool(release.get("draft", false)) or bool(release.get("prerelease", false)):
		_fail("Последний релиз не является стабильной версией.")
		return
	var manifest_url := ""
	var archive_url := ""
	for asset in release.get("assets", []):
		if not asset is Dictionary:
			continue
		var name := str(asset.get("name", ""))
		if name == MANIFEST_NAME:
			manifest_url = str(asset.get("browser_download_url", ""))
		elif name == ARCHIVE_NAME:
			archive_url = str(asset.get("browser_download_url", ""))
	if manifest_url.is_empty() or archive_url.is_empty():
		_fail("В релизе нет манифеста или архива обновления.")
		return
	var manifest_result: Dictionary = await _request_json(manifest_url)
	if not manifest_result.ok:
		_fail(str(manifest_result.error))
		return
	_manifest = manifest_result.data
	var version := str(_manifest.get("version", "")).trim_prefix("v")
	var tag := str(release.get("tag_name", "")).trim_prefix("v")
	if version.is_empty() or version != tag or str(_manifest.get("sha256", "")).length() != 64:
		_fail("Манифест релиза некорректен или не совпадает с тегом.")
		return
	if not _is_newer(version, current_version()):
		_busy = false
		status_changed.emit("Установлена последняя версия " + current_version() + ".")
		return
	_manifest["archive_url"] = archive_url
	_busy = false
	status_changed.emit("Доступно обновление " + version + ".")
	update_available.emit(version, str(release.get("body", "")))


func download_and_install_update() -> void:
	if _busy or _manifest.is_empty():
		return
	if not OS.has_feature("windows"):
		_fail("Установка поддерживается только в Windows.")
		return
	_busy = true
	status_changed.emit("Скачиваем обновление…")
	var folder := "user://updates"
	var folder_error := DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	if folder_error != OK and folder_error != ERR_ALREADY_EXISTS:
		_fail("Не удалось создать временную папку.")
		return
	var archive_path := folder.path_join("pending-update.zip")
	if FileAccess.file_exists(archive_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(archive_path))
	_http.download_file = ProjectSettings.globalize_path(archive_path)
	var request_error := _http.request(str(_manifest.get("archive_url", "")))
	if request_error != OK:
		_http.download_file = ""
		_fail("Не удалось начать загрузку: %s" % request_error)
		return
	var response: Array = await _http.request_completed
	_http.download_file = ""
	if int(response[0]) != HTTPRequest.RESULT_SUCCESS or int(response[1]) != 200:
		_fail("Загрузка завершилась с HTTP %s." % response[1])
		return
	var file := FileAccess.open(archive_path, FileAccess.READ)
	if file == null:
		_fail("Не удалось открыть скачанный архив.")
		return
	var bytes := file.get_buffer(file.get_length())
	file.close()
	var hash_context := HashingContext.new()
	if hash_context.start(HashingContext.HASH_SHA256) != OK:
		_fail("Не удалось запустить SHA-256.")
		return
	hash_context.update(bytes)
	var actual_hash := hash_context.finish().hex_encode().to_lower()
	if actual_hash != str(_manifest.get("sha256", "")).to_lower():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(archive_path))
		_fail("Контрольная сумма не совпала. Архив удалён.")
		return
	var helper_text := FileAccess.get_file_as_string(HELPER_SOURCE)
	if helper_text.is_empty():
		_fail("Установщик обновлений отсутствует в сборке.")
		return
	var helper_path := folder.path_join("install_update.ps1")
	var helper := FileAccess.open(helper_path, FileAccess.WRITE)
	if helper == null:
		_fail("Не удалось подготовить установщик.")
		return
	helper.store_string(helper_text)
	helper.close()
	var executable := OS.get_executable_path()
	var args := PackedStringArray([
		"-NoProfile", "-NonInteractive", "-ExecutionPolicy", "Bypass",
		"-File", ProjectSettings.globalize_path(helper_path),
		"-ProcessId", str(OS.get_process_id()),
		"-InstallDir", executable.get_base_dir(),
		"-Archive", ProjectSettings.globalize_path(archive_path),
		"-ExecutableName", executable.get_file()
	])
	var child_pid := OS.create_process("powershell.exe", args, false)
	if child_pid <= 0:
		_fail("Не удалось запустить установщик Windows.")
		return
	_busy = false
	status_changed.emit("Обновление подготовлено. Игра закроется и запустится снова.")
	get_tree().quit()


func has_rollback_backup() -> bool:
	if not OS.has_feature("windows"):
		return false
	var rollback_dir := OS.get_environment("LOCALAPPDATA").path_join("GALACTIC-FRONTIER").path_join("rollback")
	return FileAccess.file_exists(rollback_dir.path_join(OS.get_executable_path().get_file())) and FileAccess.file_exists(rollback_dir.path_join("GALACTIC-FRONTIER.pck"))


func rollback_last_update() -> void:
	if _busy or not has_rollback_backup():
		return
	var folder := "user://updates"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	var helper_text := FileAccess.get_file_as_string(HELPER_SOURCE)
	if helper_text.is_empty():
		_fail("Установщик обновлений отсутствует.")
		return
	var helper_path := folder.path_join("install_update.ps1")
	var helper := FileAccess.open(helper_path, FileAccess.WRITE)
	if helper == null:
		_fail("Не удалось подготовить откат.")
		return
	helper.store_string(helper_text)
	helper.close()
	var executable := OS.get_executable_path()
	var args := PackedStringArray([
		"-NoProfile", "-NonInteractive", "-ExecutionPolicy", "Bypass",
		"-File", ProjectSettings.globalize_path(helper_path),
		"-ProcessId", str(OS.get_process_id()),
		"-InstallDir", executable.get_base_dir(),
		"-ExecutableName", executable.get_file(),
		"-Rollback"
	])
	var child_pid := OS.create_process("powershell.exe", args, false)
	if child_pid <= 0:
		_fail("Не удалось запустить откат.")
		return
	status_changed.emit("Возвращаем предыдущую версию игры…")
	get_tree().quit()


func _request_json(url: String) -> Dictionary:
	_http.download_file = ""
	var headers := PackedStringArray(["User-Agent: GALACTIC-FRONTIER-Updater", "Accept: application/vnd.github+json"])
	var error := _http.request(url, headers)
	if error != OK:
		return {"ok": false, "error": "Ошибка запроса: %s" % error}
	var response: Array = await _http.request_completed
	if int(response[0]) != HTTPRequest.RESULT_SUCCESS or int(response[1]) != 200:
		return {"ok": false, "error": "GitHub вернул HTTP %s." % response[1]}
	var parsed: Variant = JSON.parse_string((response[3] as PackedByteArray).get_string_from_utf8())
	if not parsed is Dictionary:
		return {"ok": false, "error": "GitHub вернул некорректный JSON."}
	return {"ok": true, "data": parsed}


func _is_newer(candidate: String, installed: String) -> bool:
	var a := candidate.split(".")
	var b := installed.trim_prefix("v").split(".")
	if a.size() != 3 or b.size() != 3:
		return candidate != installed
	for index in range(3):
		if int(a[index]) != int(b[index]):
			return int(a[index]) > int(b[index])
	return false


func _fail(reason: String) -> void:
	_busy = false
	status_changed.emit("Ошибка обновления: " + reason)
	update_failed.emit(reason)
