extends Node
## Optional helper: attach to any always-on node, or call from HUD.
## Prefer using GraphicsQuality.cycle_preset() from pause menu later.

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("cycle_graphics_quality"):
		var gq := get_node_or_null("/root/GraphicsQuality")
		if gq and gq.has_method("cycle_preset"):
			gq.cycle_preset()
			print("Graphics quality: ", gq.get_preset_name())
			get_viewport().set_input_as_handled()
