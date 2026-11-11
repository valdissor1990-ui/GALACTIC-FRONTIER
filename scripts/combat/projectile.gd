extends Area3D
class_name CombatProjectile
## Straight-line projectile used by the first combat prototype.

@export_range(1.0, 2000.0, 1.0) var speed: float = 180.0
@export_range(0.1, 1000.0, 0.1) var damage: float = 18.0
@export_range(0.1, 20.0, 0.1) var lifetime: float = 5.0

var _direction: Vector3 = Vector3.FORWARD
var _source: Node3D
var _remaining_lifetime: float = 5.0


func configure(direction: Vector3, source: Node3D, projectile_speed: float, projectile_damage: float) -> void:
	_direction = direction.normalized()
	_source = source
	speed = projectile_speed
	damage = projectile_damage
	_remaining_lifetime = lifetime


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	global_position += _direction * speed * delta
	_remaining_lifetime -= delta
	if _remaining_lifetime <= 0.0:
		queue_free()


func _on_body_entered(body: Node3D) -> void:
	if body == null or _is_source_or_child(body):
		return

	var damageable := _find_damageable(body)
	if damageable != null:
		damageable.call("take_damage", damage)
	queue_free()


func _is_source_or_child(node: Node) -> bool:
	if _source == null:
		return false
	var current: Node = node
	while current != null:
		if current == _source:
			return true
		current = current.get_parent()
	return false


func _find_damageable(node: Node) -> Node:
	var current: Node = node
	while current != null:
		if current.has_method("take_damage"):
			return current
		var component := current.get_node_or_null("Damageable")
		if component != null and component.has_method("take_damage"):
			return component
		current = current.get_parent()
	return null
