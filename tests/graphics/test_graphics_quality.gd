extends SceneTree
## Deterministic checks for the global graphics quality table.

var _passed := 0
var _failed := 0


func _initialize() -> void:
	var script := load("res://scripts/graphics/graphics_quality.gd") as Script
	_assert_true(script != null, "graphics quality script loads")
	if script == null:
		quit(1)
		return
	var quality: Node = script.new()
	quality.set("current", 0)
	_assert_true(is_equal_approx(quality.base_scale_3d(), 0.59), "Low uses reduced 3D scale")
	_assert_true(quality.asteroid_count() == 80, "Low reduces asteroid count")
	_assert_true(not quality.screen_post_enabled(), "Low disables screen post")
	_assert_true(quality.msaa_3d_level() == Viewport.MSAA_DISABLED, "Low disables 3D MSAA")
	_assert_true(quality.anisotropic_filtering_level() == Viewport.ANISOTROPY_4X, "Low uses 4x anisotropic filtering")
	quality.set("current", 1)
	_assert_true(is_equal_approx(quality.base_scale_3d(), 0.77), "Medium uses balanced 3D scale")
	_assert_true(quality.asteroid_count() == 160, "Medium uses baseline asteroid count")
	_assert_true(quality.screen_post_enabled(), "Medium enables screen post")
	_assert_true(quality.msaa_3d_level() == Viewport.MSAA_2X, "Medium uses 2x 3D MSAA")
	_assert_true(quality.anisotropic_filtering_level() == Viewport.ANISOTROPY_8X, "Medium uses 8x anisotropic filtering")
	quality.set("current", 2)
	_assert_true(is_equal_approx(quality.base_scale_3d(), 1.0), "High uses native 3D scale")
	_assert_true(quality.asteroid_count() == 240, "High increases asteroid count")
	_assert_true(quality.ssao_enabled(), "High enables SSAO")
	_assert_true(quality.msaa_3d_level() == Viewport.MSAA_4X, "High uses 4x 3D MSAA")
	_assert_true(quality.anisotropic_filtering_level() == Viewport.ANISOTROPY_16X, "High uses 16x anisotropic filtering")
	quality.set_dynamic_scale_mul(0.5)
	_assert_true(is_equal_approx(quality.dynamic_scale_mul, 0.5), "dynamic scale lower bound is clamped")
	quality.set_dynamic_scale_mul(1.15)
	_assert_true(is_equal_approx(quality.dynamic_scale_mul, 1.15), "dynamic scale upper bound is clamped")
	quality.free()
	print("GRAPHICS QUALITY RESULT: %s (%d passed, %d failed)" % ["PASS" if _failed == 0 else "FAIL", _passed, _failed])
	quit(0 if _failed == 0 else 1)


func _assert_true(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  PASS  " + message)
	else:
		_failed += 1
		push_error("  FAIL  " + message)
