extends SceneTree
## Headless tests for procedural ship visuals when imported GLBs are absent.
## Run:
##   godot --headless --path . --script res://tests/visual/test_ship_visual_fallback.gd

var _passed: int = 0
var _failed: int = 0


func _initialize() -> void:
	print("=== GALACTIC FRONTIER — Ship visual fallback tests ===")
	call_deferred("_run_tests")


func _run_tests() -> void:
	_test_procedural_fallback_is_visible()
	_test_imported_model_hides_fallback()
	print("")
	if _failed == 0:
		print("RESULT: PASS (%d assertions)" % _passed)
		quit(0)
	else:
		print("RESULT: FAIL (%d passed, %d failed)" % [_passed, _failed])
		quit(1)


func _assert_true(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  PASS  %s" % message)
	else:
		_failed += 1
		print("  FAIL  %s" % message)


func _test_procedural_fallback_is_visible() -> void:
	print("\n[missing imported model]")
	var visual := ShipVisualFallback.new()
	visual.imported_model_name = &"OptionalGLB"
	visual.fallback_mesh_names = [&"Hull"]
	var hull := MeshInstance3D.new()
	hull.name = "Hull"
	hull.mesh = BoxMesh.new()
	visual.add_child(hull)
	root.add_child(visual)
	_assert_true(hull.visible, "primitive hull remains visible when imported model is absent")
	_assert_true(visual.get_node_or_null("Fallback_Canopy") != null, "procedural cockpit canopy is generated")
	_assert_true(visual.get_node_or_null("Fallback_EngineNozzle_-1") != null, "left engine nozzle is generated")
	visual.queue_free()


func _test_imported_model_hides_fallback() -> void:
	print("\n[valid imported model]")
	var visual := ShipVisualFallback.new()
	visual.imported_model_name = &"OptionalGLB"
	visual.fallback_mesh_names = [&"Hull"]
	var hull := MeshInstance3D.new()
	hull.name = "Hull"
	hull.mesh = BoxMesh.new()
	visual.add_child(hull)
	var imported := Node3D.new()
	imported.name = "OptionalGLB"
	var imported_mesh := MeshInstance3D.new()
	imported_mesh.mesh = BoxMesh.new()
	imported.add_child(imported_mesh)
	visual.add_child(imported)
	root.add_child(visual)
	_assert_true(not hull.visible, "fallback hull hides when imported model has render geometry")
	visual.queue_free()
