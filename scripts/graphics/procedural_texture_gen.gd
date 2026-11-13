extends RefCounted
class_name ProceduralTextureGen
## Runtime procedural textures for materials that need Image/NoiseTexture2D.
## Planets prefer pure shader noise (planet_*.gdshader); use this for
## StandardMaterial3D slots, decals, or baking previews.

static func make_noise(
	seed: int = 0,
	freq: float = 0.04,
	fractal_octaves: int = 4,
	type: FastNoiseLite.NoiseType = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
) -> FastNoiseLite:
	var n := FastNoiseLite.new()
	n.seed = seed
	n.noise_type = type
	n.frequency = freq
	n.fractal_octaves = fractal_octaves
	n.fractal_type = FastNoiseLite.FRACTAL_FBM
	return n


static func noise_texture2d(
	seed: int = 0,
	size: int = 256,
	freq: float = 0.04,
	seamless: bool = true
) -> NoiseTexture2D:
	var tex := NoiseTexture2D.new()
	tex.width = size
	tex.height = size
	tex.seamless = seamless
	tex.noise = make_noise(seed, freq)
	# Force generation in editor/runtime
	tex.generate_mipmaps = true
	return tex


static func albedo_from_noise(
	base: Color,
	mid: Color,
	high: Color,
	seed: int = 1,
	size: int = 256
) -> ImageTexture:
	var noise := make_noise(seed, 0.035, 5)
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	for y in size:
		for x in size:
			var t := (noise.get_noise_2d(x, y) + 1.0) * 0.5
			var c: Color
			if t < 0.45:
				c = base.lerp(mid, t / 0.45)
			else:
				c = mid.lerp(high, (t - 0.45) / 0.55)
			img.set_pixel(x, y, c)
	return ImageTexture.create_from_image(img)


static func orm_from_noise(
	seed: int = 2,
	size: int = 256,
	roughness_min: float = 0.7,
	roughness_max: float = 0.98
) -> ImageTexture:
	## R=AO, G=Roughness, B=Metallic (Godot ORM convention)
	var noise := make_noise(seed, 0.05, 4)
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	for y in size:
		for x in size:
			var t := (noise.get_noise_2d(x, y) + 1.0) * 0.5
			var ao := clampf(0.55 + t * 0.45, 0.0, 1.0)
			var rough := lerpf(roughness_min, roughness_max, t)
			var metal := 0.04 + t * 0.06
			img.set_pixel(x, y, Color(ao, rough, metal, 1.0))
	return ImageTexture.create_from_image(img)


static func apply_noise_to_standard(
	mat: StandardMaterial3D,
	base: Color,
	mid: Color,
	high: Color,
	seed: int = 3,
	size: int = 256
) -> void:
	if mat == null:
		return
	mat.albedo_texture = albedo_from_noise(base, mid, high, seed, size)
	mat.albedo_color = Color.WHITE
	var orm := orm_from_noise(seed + 17, size)
	mat.ao_enabled = true
	mat.ao_texture = orm
	mat.ao_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_RED
	mat.roughness_texture = orm
	mat.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_GREEN
	mat.metallic_texture = orm
	mat.metallic_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_BLUE
	mat.metallic = 1.0
	mat.roughness = 1.0
