extends Node
## Applies a subtle translucent hostile-red overlay without replacing imported PBR materials.

@export var model_path: NodePath = NodePath("../RaiderInterceptorModel")


func _ready() -> void:
	call_deferred("_apply_hostile_overlay")


func _apply_hostile_overlay() -> void:
	var model := get_node_or_null(model_path)
	if model == null:
		push_warning("Enemy visual treatment: fighter model was not found.")
		return
	var overlay := StandardMaterial3D.new()
	overlay.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	overlay.albedo_color = Color(0.95, 0.045, 0.018, 0.24)
	overlay.emission_enabled = true
	overlay.emission = Color(0.48, 0.018, 0.006)
	overlay.emission_energy_multiplier = 0.38
	overlay.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	for item in model.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := item as MeshInstance3D
		if mesh_instance.mesh != null:
			mesh_instance.material_overlay = overlay
