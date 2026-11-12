extends SceneTree
## Physics regression: planet/asteroid blockers and compound wing hitboxes.

const ENVIRONMENT_SCENE: PackedScene = preload("res://scenes/environment/space_environment.tscn")
const FLIGHT_SCENE: PackedScene = preload("res://scenes/flight/test_flight.tscn")
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
	if _failed == 0:
		print("SPACE_COLLISION_TEST_PASS: ", obstacles.size(), " obstacle proxies; route clear; wing hitbox active")
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
