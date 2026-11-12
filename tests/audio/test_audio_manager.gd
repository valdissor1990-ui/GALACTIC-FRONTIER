extends SceneTree
## Checks original procedural WAV streams are generated and configured correctly.

var _failed := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	await process_frame
	_check(AudioManager.engine_stream != null, "engine stream exists")
	_check(AudioManager.weapon_stream != null, "weapon stream exists")
	_check(AudioManager.impact_stream != null, "impact stream exists")
	if AudioManager.engine_stream != null:
		_check(AudioManager.engine_stream.data.size() == 44100, "engine loop contains two seconds of 16-bit PCM")
		_check(AudioManager.engine_stream.loop_mode == AudioStreamWAV.LOOP_FORWARD, "engine stream loops forward")
	if AudioManager.weapon_stream != null:
		_check(AudioManager.weapon_stream.data.size() > 4000, "weapon transient has PCM data")
		_check(AudioManager.weapon_stream.loop_mode == AudioStreamWAV.LOOP_DISABLED, "weapon transient does not loop")
	if AudioManager.impact_stream != null:
		_check(AudioManager.impact_stream.data.size() > 10000, "impact transient has PCM data")
		_check(AudioManager.impact_stream.loop_mode == AudioStreamWAV.LOOP_DISABLED, "impact transient does not loop")
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
