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
	_test_runtime_glb_import()
	print("")
	if _failed == 0:
		print("RESULT: PASS (%d assertions)" % _passed)
		quit(0)
	else:
		print("RESULT: FAIL (%d passed, %d failed)" % [_passed, _failed])
		quit(1)


func _test_runtime_glb_import() -> void:
	print("\\n[runtime GLB import]")
	var visual := ShipVisualFallback.new()
	visual.imported_model_name = &"RuntimeGLB"
	visual.imported_model_path = "res://assets/models/ships/player_fighter.glb"
	visual.imported_model_scale = Vector3.ONE * 0.3
	visual.fallback_mesh_names = [&"Hull"]
	var hull := MeshInstance3D.new()
	hull.name = "Hull"
	hull.mesh = BoxMesh.new()
	visual.add_child(hull)
	root.add_child(visual)
	var imported := visual.get_node_or_null("RuntimeGLB")
	_assert_true(imported != null and _contains_mesh(imported), "GLB is loaded through Godot's runtime glTF importer")
	_assert_true(not hull.visible, "runtime GLB import hides primitive fallback geometry")
	visual.queue_free()


func _contains_mesh(node: Node) -> bool:
	if node is MeshInstance3D and (node as MeshInstance3D).mesh != null:
		return true
	for child in node.get_children():
		if _contains_mesh(child):
			return true
	return false


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
	var engine_nozzle_found := false
	for child in visual.get_children():
		if String(child.name).begins_with("Fallback_EngineNozzle_"):
			engine_nozzle_found = true
	_assert_true(engine_nozzle_found, "engine nozzles are generated")
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
