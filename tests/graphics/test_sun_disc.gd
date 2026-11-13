extends SceneTree
## Headless regression checks for the world-space sun object and quality gating.
## Run with: godot --headless --path . --script res://tests/graphics/test_sun_disc.gd

var _failed := 0
var _passed := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var backdrop_script := load("res://scripts/environment/open_space_backdrop.gd") as Script
	var script_ready := backdrop_script != null and backdrop_script.can_instantiate()
	_check(script_ready, "open-space backdrop script parses and can instantiate")
	if not script_ready:
		_finish()
		return
	var backdrop := backdrop_script.new() as Node3D
	root.add_child(backdrop)

	var sun_root := backdrop.get_node_or_null("SunDiscRoot")
	_check(sun_root != null, "world-space sun root is created")
	_check(sun_root != null and sun_root.get_node_or_null("SunDisc") is MeshInstance3D, "bright sun disc mesh is present")
	_check(sun_root != null and sun_root.get_node_or_null("SunFlare") is MeshInstance3D, "soft flare mesh is present")
	var disc := sun_root.get_node_or_null("SunDisc") as MeshInstance3D if sun_root else null
	var flare := sun_root.get_node_or_null("SunFlare") as MeshInstance3D if sun_root else null
	_check(disc != null and disc.material_override is ShaderMaterial, "sun disc uses its dedicated HDR shader")
	_check(flare != null and flare.material_override is ShaderMaterial, "flare uses a lightweight additive shader")
	var world_environment := backdrop.get_node_or_null("WorldEnvironment") as WorldEnvironment
	_check(world_environment != null and world_environment.environment != null, "world environment is initialized")
	if world_environment != null and world_environment.environment != null:
		_check(is_equal_approx(world_environment.environment.get_glow_level(3), 1.0), "Godot 4 glow levels are configured through the Environment API")

	var quality := root.get_node_or_null("GraphicsQuality")
	if quality != null and backdrop.has_method("apply_quality"):
		quality.set("current", 0)
		backdrop.apply_quality(quality)
		_check(flare != null and not flare.visible, "Low preset disables the flare")
		quality.set("current", 1)
		backdrop.apply_quality(quality)
		_check(flare != null and flare.visible, "Medium preset enables a restrained flare")
		quality.set("current", 2)
		backdrop.apply_quality(quality)
		_check(flare != null and flare.visible, "High preset keeps the flare enabled")
	else:
		_check(false, "GraphicsQuality autoload is available for preset checks")

	backdrop.queue_free()
	_finish()


func _check(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  PASS  %s" % message)
	else:
		_failed += 1
		push_error("  FAIL  %s" % message)


func _finish() -> void:
	print("SUN DISC RESULT: %d passed, %d failed" % [_passed, _failed])
	quit(0 if _failed == 0 else 1)
