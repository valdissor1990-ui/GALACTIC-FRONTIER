extends SceneTree
## Regression test: a 180 m/s projectile must not tunnel through a thin target.
## Target at -1.5 m: the discrete end-of-tick position (-3 m) is past it,
## so this test can pass only when the swept collision query detects the crossing.
## Run: godot --headless --path . --script res://tests/combat/test_projectile_sweep.gd

var _failed := false


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var world := Node3D.new()
	root.add_child(world)
	current_scene = world
	var target := StaticBody3D.new()
	target.name = "ThinTarget"
	target.collision_layer = 1
	target.collision_mask = 0
	var target_shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1.0, 1.0, 0.10)
	target_shape.shape = box
	target.add_child(target_shape)
	target.position = Vector3(0.0, 0.0, -1.5)
	world.add_child(target)

	var projectile_scene := load("res://scenes/combat/projectile.tscn") as PackedScene
	var projectile := projectile_scene.instantiate() as CombatProjectile
	world.add_child(projectile)
	var source := Node3D.new()
	source.name = "FreedProjectileOwner"
	world.add_child(source)
	projectile.configure(Vector3.FORWARD, source, 180.0, 18.0)
	# The firing ship can be destroyed while its projectile is still in flight.
	source.queue_free()
	await process_frame
	await physics_frame
	await process_frame

	# One real 60 Hz physics tick travels 3 metres, crossing the 10 cm target.
	if is_instance_valid(projectile):
		_failed = true
		push_error("PROJECTILE_SWEEP_FAIL: fast projectile passed through thin target")
	else:
		print("PROJECTILE_SWEEP_PASS: collision detected across 3m physics step")

	world.queue_free()
	await process_frame
	quit(1 if _failed else 0)
