extends SceneTree
## Headless behaviour tests for quality-aware gravitational lensing.

var _passed := 0
var _failed := 0


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	var camera := Camera3D.new()
	camera.name = "LensTestCamera"
	root.add_child(camera)
	camera.current = true

	var mass := Node3D.new()
	mass.name = "TestGravityMass"
	mass.set_script(load("res://scripts/environment/gravity_lens_mass.gd"))
	mass.set("show_debug_core", false)
	mass.set("lens_strength", 1.2)
	mass.position = Vector3(0.0, 0.0, -500.0)
	root.add_child(mass)

	var fx := Node.new()
	fx.name = "GravitationalLensFx"
	fx.set_script(load("res://scripts/vfx/gravitational_lens_fx.gd"))
	fx.set("auto_find_masses", true)
	root.add_child(fx)
	await process_frame
	await process_frame

	_assert_true(mass.is_in_group("gravity_lens_mass"), "lens source registers itself")
	_assert_true(fx.get("_masses").size() == 1, "screen effect discovers lens source")
	var layer := fx.get("_layer") as CanvasLayer
	_assert_true(layer != null and layer.layer == 2, "lens effect renders above post FX and below HUD")

	var quality := root.get_node_or_null("GraphicsQuality")
	if quality != null:
		quality.set("current", 0)
		fx.call("apply_quality", quality)
		_assert_true(not layer.visible, "Low preset disables lens effect")
		quality.set("current", 2)
		fx.call("apply_quality", quality)
		fx.call("_process", 0.016)
		_assert_true(layer.visible, "High preset enables lens effect when a mass is visible")

	fx.queue_free()
	mass.queue_free()
	camera.queue_free()
	print("GRAVITATIONAL LENS RESULT: %s (%d passed, %d failed)" % ["PASS" if _failed == 0 else "FAIL", _passed, _failed])
	quit(0 if _failed == 0 else 1)


func _assert_true(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  PASS  " + message)
	else:
		_failed += 1
		push_error("  FAIL  " + message)
