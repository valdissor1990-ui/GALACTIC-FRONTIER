extends Node
class_name HitFlashFx
## Pushes hit_flash into ShaderMaterials under a Visual root when Damageable takes hits.

@export var damageable_path: NodePath
@export var visual_root_path: NodePath = NodePath("../Visual")
@export var flash_decay: float = 4.5
@export var flash_on_hit: float = 1.0

var _damageable: Damageable
var _materials: Array[ShaderMaterial] = []
var _flash: float = 0.0


func _ready() -> void:
	if damageable_path != NodePath(""):
		_damageable = get_node_or_null(damageable_path) as Damageable
	if _damageable == null:
		_damageable = get_parent().get_node_or_null("Damageable") as Damageable
	var visual := get_node_or_null(visual_root_path)
	if visual:
		_collect_materials(visual)
	if _damageable:
		_damageable.hull_changed.connect(_on_hull_changed)
		_damageable.shield_changed.connect(_on_shield_changed)
		_damageable.destroyed.connect(_on_destroyed)


func _collect_materials(node: Node) -> void:
	if node is MeshInstance3D:
		var mi := node as MeshInstance3D
		var mat := mi.get_active_material(0)
		if mat is ShaderMaterial:
			# Duplicate so enemies do not share flash state
			var local_mat := (mat as ShaderMaterial).duplicate() as ShaderMaterial
			mi.set_surface_override_material(0, local_mat)
			_materials.append(local_mat)
	for child in node.get_children():
		_collect_materials(child)


func _process(delta: float) -> void:
	if _flash <= 0.0:
		return
	_flash = maxf(0.0, _flash - delta * flash_decay)
	_apply()


func _apply() -> void:
	for m in _materials:
		m.set_shader_parameter("hit_flash", _flash)


func _on_hull_changed(_current: float, _maximum: float) -> void:
	_flash = maxf(_flash, flash_on_hit)
	_apply()


func _on_shield_changed(_current: float, _maximum: float) -> void:
	# Lighter flash when only shields absorb
	_flash = maxf(_flash, flash_on_hit * 0.55)
	_apply()


func _on_destroyed() -> void:
	_flash = 1.0
	_apply()
