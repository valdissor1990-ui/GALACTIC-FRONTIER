extends Node
## Applies a restrained hostile red treatment while preserving the fighter's material detail.

@export var model_path: NodePath = NodePath("../Visual/EnemyFighterModel")


func _ready() -> void:
	call_deferred("_apply_hostile_materials")


func _apply_hostile_materials() -> void:
	var model := get_node_or_null(model_path)
	if model == null:
		push_warning("Enemy visual treatment: fighter model was not found.")
		return
	for item in model.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := item as MeshInstance3D
		if mesh_instance.mesh == null:
			continue
		for surface in range(mesh_instance.mesh.get_surface_count()):
			var source := mesh_instance.get_active_material(surface)
			if not (source is StandardMaterial3D):
				continue
			var material := (source as StandardMaterial3D).duplicate() as StandardMaterial3D
			if material.name.to_lower().contains("glass"):
				continue
			var original := material.albedo_color
			material.albedo_color = Color(
				clampf(original.r * 1.25 + 0.12, 0.0, 1.0),
				original.g * 0.30,
				original.b * 0.24,
				original.a
			)
			if material.emission_enabled:
				material.emission = Color(0.62, 0.035, 0.012)
				material.emission_energy_multiplier = maxf(material.emission_energy_multiplier, 1.25)
			mesh_instance.set_surface_override_material(surface, material)
