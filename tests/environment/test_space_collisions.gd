extends SceneTree
## Physics regression: planet/asteroid blockers and compound wing hitboxes.

const ENVIRONMENT_SCENE: PackedScene = preload("res://scenes/environment/space_environment.tscn")
const FLIGHT_SCENE: PackedScene = preload("res://scenes/flight/test_flight.tscn")
const ENEMY_SCENE: PackedScene = preload("res://scenes/combat/enemy_fighter.tscn")
const ROUTE_START := Vector3(0.0, 18.0, 0.0)
const ROUTE_END := Vector3(0.0, 18.0, -720.0)

var _failed := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var environment := ENVIRONMENT_SCENE.instantiate()
	root.add_child(environment)
	await physics_frame
	var obstacles := get_nodes_in_group("space_obstacles")
	_check(obstacles.size() >= 100, "planet and asteroid collision proxies must be registered")
	var asteroid_field := environment.get_node_or_null("AsteroidField") as MultiMeshInstance3D
	_check(asteroid_field != null, "the procedural asteroid belt must use one batched MultiMesh")
	if asteroid_field != null:
		var relay_sector_count := 0
		var outer_sector_count := 0
		var route_clear := true
		var asteroid_proxy_count := 0
		for obstacle in obstacles:
			if not str(obstacle.name).begins_with("AsteroidCollision_"):
				continue
			asteroid_proxy_count += 1
			var asteroid_position := (obstacle as Node3D).global_position
			var route_distance := float(environment.call("_distance_to_route", asteroid_position))
			if route_distance < 82.0 or route_distance > 760.0:
				route_clear = false
			if asteroid_position.z < -5000.0 and asteroid_position.z > -20000.0:
				relay_sector_count += 1
			elif asteroid_position.z <= -20000.0:
				outer_sector_count += 1
		_check(asteroid_proxy_count == asteroid_field.multimesh.instance_count, "each batched asteroid has one matching collision proxy")
		_check(relay_sector_count > 0, "asteroids populate the long outbound relay sector")
		_check(outer_sector_count > 0, "asteroids populate the distant wreck and return sectors")
		_check(route_clear, "every asteroid remains outside the marked flight corridor")
	_check(environment.has_node("NacreonGasGiant"), "a ringed gas giant landmark is generated")
	_check(environment.has_node("NacreonRings"), "the distant gas giant has a separate ring mesh")
	_check(environment.has_node("NacreonMoon"), "the distant planetary system includes a moon")
	_check(environment.has_node("DistantSpiralGalaxy"), "a procedural spiral galaxy is generated as a distant sky landmark")
	var ring_root := environment.get_node_or_null("NacreonRings") as MeshInstance3D
	_check(ring_root != null and ring_root.has_node("NacreonInnerRing") and ring_root.has_node("NacreonOuterRing") and ring_root.has_node("NacreonDustBand"), "planetary rings include separate inner, outer and diffuse dust bands")
	var dust_field := environment.get_node_or_null("InterplanetaryDust") as MultiMeshInstance3D
	_check(dust_field != null and dust_field.multimesh.instance_count >= 1000, "interplanetary dust is populated in one batched MultiMesh")
	var sky_camera := Camera3D.new()
	sky_camera.position = Vector3(120.0, 34.0, -240.0)
	sky_camera.current = true
	root.add_child(sky_camera)
	sky_camera.make_current()
	await process_frame
	await process_frame
	environment.call("_process", 0.0)
	var giant := environment.get_node("NacreonGasGiant") as MeshInstance3D
	var expected_giant_position := sky_camera.global_position + sky_camera.global_basis * Vector3(430.0, -92.0, -1320.0)
	_check(giant.global_position.distance_to(expected_giant_position) < 1.0, "gas giant remains visible as the player travels")
	var rings := environment.get_node("NacreonRings") as MeshInstance3D
	_check(is_equal_approx(rings.global_basis.x.length(), 100.0), "planetary rings retain their full visual scale while following the camera")
	sky_camera.queue_free()
	await process_frame
	var route_hit := _ray(ROUTE_START, ROUTE_END)
	_check(route_hit.is_empty(), "the relay approach corridor must remain clear of solid obstacles")
	var planet := environment.get_node_or_null("AureliaCollision") as StaticBody3D
	_check(planet != null, "Aurelia must have a static collision proxy")
	if planet != null:
		planet.global_position = ROUTE_START.lerp(ROUTE_END, 0.5)
		await physics_frame
		var blocked_hit := _ray(ROUTE_START, ROUTE_END)
		_check(not blocked_hit.is_empty() and blocked_hit.get("collider") == planet, "moving Aurelia onto the route must block the physics ray")
		planet.global_position = Vector3(-160.0, 26.0, -285.0)
		await physics_frame

	var flight := FLIGHT_SCENE.instantiate()
	root.add_child(flight)
	await physics_frame
	var player := flight.get_node("PlayerShip") as CharacterBody3D
	var wing_hit := _ray(Vector3(1.45, -0.05, 1.0), Vector3(1.45, -0.05, -1.0))
	_check(not wing_hit.is_empty() and wing_hit.get("collider") == player, "a ray through the outer wing must hit the player compound collider")

	var enemy := ENEMY_SCENE.instantiate() as CharacterBody3D
	enemy.position = Vector3(10.0, 0.0, 0.0)
	root.add_child(enemy)
	await physics_frame
	var enemy_wing_hit := _ray(Vector3(11.7, -0.05, 1.0), Vector3(11.7, -0.05, -1.0))
	_check(not enemy_wing_hit.is_empty() and enemy_wing_hit.get("collider") == enemy, "a ray through the enemy outer wing must hit its compound collider")
	if _failed == 0:
		print("SPACE_COLLISION_TEST_PASS: ", obstacles.size(), " obstacle proxies; route clear; player and enemy wing hitboxes active")
		quit(0)
	else:
		print("SPACE_COLLISION_TEST_FAIL: ", _failed, " assertions failed")
		quit(1)

func _ray(from: Vector3, to: Vector3) -> Dictionary:
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = 1
	query.collide_with_bodies = true
	return root.get_world_3d().direct_space_state.intersect_ray(query)

func _check(condition: bool, message: String) -> void:
	if condition:
		print("  PASS ", message)
	else:
		_failed += 1
		push_error("SPACE_COLLISION_TEST_FAIL: " + message)
