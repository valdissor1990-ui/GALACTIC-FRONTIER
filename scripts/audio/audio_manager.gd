extends Node
## Original procedural audio for engine ambience, energy fire and impacts.
## All waveforms are synthesized locally; no external or copyrighted audio assets.

const SAMPLE_RATE := 11025
const ENGINE_SECONDS := 2.0

var engine_stream: AudioStreamWAV
var weapon_stream: AudioStreamWAV
var impact_stream: AudioStreamWAV


func _ready() -> void:
	engine_stream = _build_engine_loop()
	weapon_stream = _build_weapon_fire()
	impact_stream = _build_impact()


func play_3d(stream: AudioStream, world_position: Vector3, volume_db: float = -10.0, unit_size: float = 24.0, max_distance: float = 500.0) -> void:
	if stream == null:
		return
	var player := AudioStreamPlayer3D.new()
	player.stream = stream
	player.volume_db = volume_db
	player.unit_size = unit_size
	player.max_distance = max_distance
	var host := get_tree().current_scene
	if host == null:
		host = get_tree().root
	host.add_child(player)
	player.global_position = world_position
	player.play()
	player.finished.connect(player.queue_free)


func _build_engine_loop() -> AudioStreamWAV:
	var count := int(SAMPLE_RATE * ENGINE_SECONDS)
	var data := PackedByteArray()
	data.resize(count * 2)
	for i in range(count):
		var t := float(i) / float(SAMPLE_RATE)
		var pulse := 0.78 + 0.22 * sin(TAU * 0.5 * t)
		var sample := (
			0.19 * sin(TAU * 55.0 * t)
			+ 0.085 * sin(TAU * 110.0 * t + 0.2)
			+ 0.035 * sin(TAU * 165.0 * t)
			+ 0.018 * sin(TAU * 220.0 * t)
		) * pulse
		_write_sample(data, i * 2, sample)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = count
	stream.data = data
	return stream


func _build_weapon_fire() -> AudioStreamWAV:
	var count := int(SAMPLE_RATE * 0.24)
	var data := PackedByteArray()
	data.resize(count * 2)
	for i in range(count):
		var t := float(i) / float(SAMPLE_RATE)
		var phase := t / 0.24
		var envelope := (1.0 - exp(-t * 900.0)) * exp(-t * 16.0)
		var frequency := 1100.0 - 780.0 * phase
		var tonal := sin(TAU * frequency * t) * 0.34
		var noise := sin(float(i) * 127.1) * sin(float(i) * 311.7) * 0.19 * exp(-t * 28.0)
		var sub := sin(TAU * (120.0 - 50.0 * phase) * t) * 0.14
		_write_sample(data, i * 2, (tonal + noise + sub) * envelope)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.loop_mode = AudioStreamWAV.LOOP_DISABLED
	stream.data = data
	return stream


func _build_impact() -> AudioStreamWAV:
	var count := int(SAMPLE_RATE * 0.52)
	var data := PackedByteArray()
	data.resize(count * 2)
	for i in range(count):
		var t := float(i) / float(SAMPLE_RATE)
		var envelope := exp(-t * 9.5)
		var crack := sin(float(i) * 173.3) * sin(float(i) * 271.9) * 0.42 * exp(-t * 35.0)
		var thump := 0.36 * sin(TAU * (72.0 - 25.0 * t) * t) * exp(-t * 8.0)
		var ring := 0.18 * sin(TAU * (640.0 - 210.0 * t) * t) * exp(-t * 7.0)
		_write_sample(data, i * 2, crack + thump + ring * envelope)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.loop_mode = AudioStreamWAV.LOOP_DISABLED
	stream.data = data
	return stream


func _write_sample(data: PackedByteArray, offset: int, value: float) -> void:
	var sample := int(clampi(roundi(clampf(value, -1.0, 1.0) * 32767.0), -32768, 32767))
	data[offset] = sample & 0xff
	data[offset + 1] = (sample >> 8) & 0xff
