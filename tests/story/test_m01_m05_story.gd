extends SceneTree
## Regression tests for mission progression, exclusive choices and save restoration.

var _failed := 0
var _passed := 0


func _initialize() -> void:
	_test_mission_unlock_chain()
	_test_choice_validation_and_exclusivity()
	_test_duplicate_completion_is_idempotent()
	_test_full_act_chain()
	_test_save_roundtrip_and_reset()
	_test_dialogue_catalog()
	print("RESULT: %s (%d passed, %d failed)" % ["PASS" if _failed == 0 else "FAIL", _passed, _failed])
	quit(0 if _failed == 0 else 1)


func _assert_true(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
	else:
		_failed += 1
		push_error("FAIL: " + message)


func _new_state_before_m03() -> StoryState:
	var state := StoryState.new()
	assert(MissionCatalog.apply_completion("m01", state))
	assert(MissionCatalog.apply_completion("m02", state))
	return state


func _test_mission_unlock_chain() -> void:
	var state := StoryState.new()
	_assert_true(MissionCatalog.can_start("m01", state), "M01 available at campaign start")
	_assert_true(not MissionCatalog.can_start("m02", state), "M02 locked before M01")
	_assert_true(MissionCatalog.apply_completion("m01", state), "M01 completes")
	_assert_true(MissionCatalog.can_start("m02", state), "M02 unlocked by M01")
	_assert_true(not MissionCatalog.can_start("missing", state), "unknown mission cannot start")


func _test_choice_validation_and_exclusivity() -> void:
	var state := _new_state_before_m03()
	_assert_true(not MissionCatalog.apply_completion("m03", state), "choice mission rejects missing choice")
	_assert_true(not MissionCatalog.apply_completion("m03", state, "not_a_choice"), "choice mission rejects unknown choice")
	_assert_true(MissionCatalog.apply_completion("m03", state, "share_helix"), "valid M03 choice completes")
	_assert_true(state.has_flag("shared_helix"), "selected Helix flag set")
	_assert_true(not state.has_flag("shared_union") and not state.has_flag("kept_private"), "other choice flags remain false")
	_assert_true(not MissionCatalog.apply_completion("m03", state, "share_union"), "completed M03 cannot accept a second choice")


func _test_duplicate_completion_is_idempotent() -> void:
	var state := StoryState.new()
	_assert_true(MissionCatalog.apply_completion("m01", state), "first completion succeeds")
	var relationship_after_first := state.get_relationship("sera_quinn")
	_assert_true(not MissionCatalog.apply_completion("m01", state), "duplicate completion rejected")
	_assert_true(state.get_relationship("sera_quinn") == relationship_after_first, "duplicate completion grants no repeated relationship")
	_assert_true(state.completed_missions.size() == 1, "completed mission is stored once")


func _test_full_act_chain() -> void:
	var state := StoryState.new()
	for mission_id in MissionCatalog.MISSION_ORDER:
		var choice := "keep_private" if mission_id == "m03" else ""
		_assert_true(MissionCatalog.can_start(mission_id, state), "%s unlocked in sequence" % mission_id)
		_assert_true(MissionCatalog.apply_completion(mission_id, state, choice), "%s completes" % mission_id)
	_assert_true(state.has_flag("act1_complete"), "Act I flag set after M05")
	_assert_true(state.has_flag("vesper_access") and state.has_flag("kestrel_access"), "region access flags set")


func _test_save_roundtrip_and_reset() -> void:
	var original := StoryState.new()
	original.adjust_relationship("nyra_sol", 34)
	original.set_flag("sample_flag")
	original.complete_mission("m01")
	original.complete_mission("m01")
	var restored := StoryState.new()
	restored.adjust_relationship("helix", 77)
	restored.from_save_dict(original.to_save_dict())
	_assert_true(restored.has_flag("sample_flag"), "flags restored")
	_assert_true(restored.completed_missions.size() == 1, "duplicate completion IDs removed")
	_assert_true(restored.get_relationship("nyra_sol") == 34, "saved relationship restored")
	_assert_true(restored.get_relationship("helix") == 0, "missing relationship resets to default")
	restored.from_save_dict({"mission_flags": {}, "completed_missions": [], "relationship": {}})
	_assert_true(restored.get_relationship("nyra_sol") == 0, "second load does not retain stale relationship")
	_assert_true(restored.active_mission_id.is_empty(), "missing active mission resets")


func _test_dialogue_catalog() -> void:
	for node_id in ["m01_quinn_intro", "m02_jex_radio", "m03_nyra", "m04_vorn_brief", "m05_nyra_approach"]:
		var dialogue := DialogueM01M05.get_node(node_id)
		_assert_true(not dialogue.is_empty(), "%s exists" % node_id)
		var lines: Dictionary = dialogue.get("text", {})
		_assert_true(not str(lines.get("ru", "")).is_empty(), "%s has Russian text" % node_id)
		_assert_true(not str(lines.get("en", "")).is_empty(), "%s has English text" % node_id)
