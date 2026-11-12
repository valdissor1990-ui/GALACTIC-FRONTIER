extends SceneTree
## Checks original procedural WAV streams are generated and configured correctly.

var _failed := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var manager := root.get_node_or_null("AudioManager")
	if manager == null:
		manager = AUDIO_MANAGER_SCRIPT.new()
		manager.name = "AudioManager"
		root.add_child(manager)
	await process_frame
	var engine := manager.get("engine_stream") as AudioStreamWAV
	var weapon := manager.get("weapon_stream") as AudioStreamWAV
	var impact := manager.get("impact_stream") as AudioStreamWAV
	_check(engine != null, "engine stream exists")
	_check(weapon != null, "weapon stream exists")
	_check(impact != null, "impact stream exists")
	if engine != null:
		_check(engine.data.size() == 44100, "engine loop contains two seconds of 16-bit PCM")
		_check(engine.loop_mode == AudioStreamWAV.LOOP_FORWARD, "engine stream loops forward")
	if weapon != null:
		_check(weapon.data.size() > 4000, "weapon transient has PCM data")
		_check(weapon.loop_mode == AudioStreamWAV.LOOP_DISABLED, "weapon transient does not loop")
	if impact != null:
		_check(impact.data.size() > 10000, "impact transient has PCM data")
		_check(impact.loop_mode == AudioStreamWAV.LOOP_DISABLED, "impact transient does not loop")
	if _failed == 0:
		print("PROCEDURAL_AUDIO_TEST_PASS: engine, weapon and impact streams generated")
		quit(0)
	else:
		print("PROCEDURAL_AUDIO_TEST_FAIL assertions=", _failed)
		quit(1)

func _check(condition: bool, message: String) -> void:
	if condition:
		print("  PASS ", message)
	else:
		_failed += 1
		push_error("PROCEDURAL_AUDIO_TEST_FAIL: " + message)
