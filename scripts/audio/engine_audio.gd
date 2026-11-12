extends AudioStreamPlayer3D
## Speed-responsive engine bed attached to the player ship.

func _ready() -> void:
	stream = AudioManager.engine_stream
	volume_db = -22.0
	unit_size = 34.0
	max_distance = 1200.0
	if stream != null:
		play()


func _process(delta: float) -> void:
	var ship := get_parent() as CharacterBody3D
	if ship == null:
		return
	var target_pitch := clampf(0.82 + ship.velocity.length() / 260.0, 0.82, 1.42)
	pitch_scale = lerpf(pitch_scale, target_pitch, clampf(delta * 2.5, 0.0, 1.0))
