extends SceneTree
## Regression test: a 180 m/s projectile must not tunnel through a thin target.
## Run: godot --headless --path . --script res://tests/combat/test_projectile_sweep.gd

var _failed := false


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	print("SWEEP_TEST: create world")
	var world := Node3D.new()
	root.add_child(world)
	print("SWEEP_TEST: create target")
	var target := StaticBody3D.new()
	target.name = "ThinTarget"
	target.collision_layer = 1
	target.collision_mask = 0
	var target_shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1.0, 1.0, 0.10)
	target_shape.shape = box
	target.add_child(target_shape)
	target.position = Vector3(0.0, 0.0, -3.0)
	world.add_child(target)

	print("SWEEP_TEST: load projectile scene")
	var projectile_scene := load("res://scenes/combat/projectile.tscn") as PackedScene
	var projectile := projectile_scene.instantiate() as CombatProjectile
	world.add_child(projectile)
	print("SWEEP_TEST: projectile added world3d=", projectile.get_world_3d() != null)
	projectile.configure(Vector3.FORWARD, null, 180.0, 18.0)
	await physics_frame
	print("SWEEP_TEST: first physics frame")
	await physics_frame
	print("SWEEP_TEST: second physics frame")

	# One 60 Hz tick travels 3 metres, crossing the entire 10 cm target.
	print("SWEEP_TEST: before sweep")
	projectile._physics_process(1.0 / 60.0)
	print("SWEEP_TEST: after sweep")
	if not projectile.is_queued_for_deletion():
		_failed = true
		push_error("PROJECTILE_SWEEP_FAIL: fast projectile passed through thin target")
	else:
		print("PROJECTILE_SWEEP_PASS: collision detected across 3m physics step")

	world.queue_free()
	await process_frame
	quit(1 if _failed else 0)
