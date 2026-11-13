extends SceneTree
## Regression tests for runtime GLB loading and visible fallback geometry.

var _passed := 0
var _failed := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var loader_script: Script = load("res://scripts/visual/runtime_gltf_model.gd")

	var valid_parent := Node3D.new()
	var valid_fallback := _make_hidden_fallback("PlayerFallback")
	var valid_loader := Node3D.new()
	valid_loader.set_script(loader_script)
	valid_loader.set("source_path", "res://assets/models/ships/player_fighter.glb")
	valid_loader.set("model_scale", Vector3.ONE * 0.3)
	valid_parent.add_child(valid_fallback)
	valid_parent.add_child(valid_loader)
	root.add_child(valid_parent)
	await process_frame
	await process_frame
	var model := valid_loader.get_node_or_null("Model")
	_check(model != null, "valid GLB creates a runtime Model node")
	_check(_count_meshes(model) >= 1, "runtime GLB contains renderable mesh nodes")
	_check(not valid_fallback.visible, "fallback stays hidden when the real model loads")

	var fallback_parent := Node3D.new()
	var fallback_mesh := _make_hidden_fallback("EnemyFallback")
	var failed_loader := Node3D.new()
	failed_loader.set_script(loader_script)
	fallback_parent.add_child(fallback_mesh)
	fallback_parent.add_child(failed_loader)
	failed_loader.call("_show_fallback_visuals")
	_check(fallback_mesh.visible, "fallback mesh becomes visible after a runtime load failure")

	if _failed == 0:
		print("SHIP_VISUAL_FALLBACK_TEST_PASS: %d assertions" % _passed)
		quit(0)
	else:
		push_error("SHIP_VISUAL_FALLBACK_TEST_FAIL: %d passed, %d failed" % [_passed, _failed])
		quit(1)

func _make_hidden_fallback(node_name: String) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	mesh.name = node_name
	mesh.mesh = BoxMesh.new()
	mesh.visible = false
	return mesh

func _count_meshes(node: Node) -> int:
	if node == null:
		return 0
	var count := 1 if node is MeshInstance3D and (node as MeshInstance3D).mesh != null else 0
	for child in node.get_children():
		count += _count_meshes(child)
	return count

func _check(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  PASS  " + message)
	else:
		_failed += 1
		push_error("  FAIL  " + message)
