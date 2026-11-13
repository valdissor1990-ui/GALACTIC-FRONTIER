extends SceneTree
## Regression coverage for campaign progression, branch choices and save recovery.

var _failed := 0
var _passed := 0


func _initialize() -> void:
	_test_unlock_chain()
	_test_choice_validation_and_exclusivity()
	_test_duplicate_completion_is_idempotent()
	_test_full_act_chain()
	_test_save_restore_resets_defaults()
	_test_dialogue_graph()
	print("")
	print("RESULT: %s (%d passed, %d failed)" % ["PASS" if _failed == 0 else "FAIL", _passed, _failed])
	quit(0 if _failed == 0 else 1)


func _assert_true(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  PASS  " + message)
	else:
		_failed += 1
		push_error("  FAIL  " + message)


func _state_before_m03() -> StoryState:
	var state := StoryState.new()
	MissionCatalog.apply_completion("m01", state)
	MissionCatalog.apply_completion("m02", state)
	return state


func _test_unlock_chain() -> void:
	var state := StoryState.new()
	_assert_true(MissionCatalog.can_start("m01", state), "M01 available at campaign start")
	_assert_true(not MissionCatalog.can_start("m02", state), "M02 locked before M01")
	_assert_true(MissionCatalog.apply_completion("m01", state), "M01 completion succeeds")
	_assert_true(MissionCatalog.can_start("m02", state), "M02 unlocked after M01")
	_assert_true(not MissionCatalog.can_start("unknown", state), "unknown mission is rejected")


func _test_choice_validation_and_exclusivity() -> void:
	for choice_id in ["share_helix", "share_union", "keep_private"]:
		var state := _state_before_m03()
		_assert_true(not MissionCatalog.apply_completion("m03", state), "M03 rejects missing choice")
		_assert_true(not MissionCatalog.apply_completion("m03", state, "invalid"), "M03 rejects invalid choice")
		_assert_true(MissionCatalog.apply_completion("m03", state, choice_id), "M03 accepts " + choice_id)
		var helix := state.has_flag("shared_helix")
		var union := state.has_flag("shared_union")
		var private_choice := state.has_flag("kept_private")
		_assert_true(int(helix) + int(union) + int(private_choice) == 1, "exactly one M03 choice flag is active")
		_assert_true(state.has_flag({"share_helix":"shared_helix","share_union":"shared_union","keep_private":"kept_private"}[choice_id]), "selected choice flag is set")
		_assert_true(not MissionCatalog.apply_completion("m03", state, "share_union"), "completed M03 cannot be selected twice")


func _test_duplicate_completion_is_idempotent() -> void:
	var state := StoryState.new()
	_assert_true(MissionCatalog.apply_completion("m01", state), "first M01 completion succeeds")
	var relationship := state.get_relationship("sera_quinn")
	_assert_true(not MissionCatalog.apply_completion("m01", state), "duplicate M01 completion rejected")
	_assert_true(state.get_relationship("sera_quinn") == relationship, "duplicate completion does not repeat relationship reward")
	_assert_true(state.completed_missions.size() == 1, "mission ID is stored once")


func _test_full_act_chain() -> void:
	var state := StoryState.new()
	for mission_id in MissionCatalog.MISSION_ORDER:
		var choice := "keep_private" if mission_id == "m03" else ""
		_assert_true(MissionCatalog.can_start(mission_id, state), mission_id + " unlocks in order")
		_assert_true(MissionCatalog.apply_completion(mission_id, state, choice), mission_id + " completes")
	_assert_true(state.has_flag("act1_complete"), "Act I completion flag is set")
	_assert_true(state.has_flag("vesper_access") and state.has_flag("kestrel_access"), "region unlock flags are set")


func _test_save_restore_resets_defaults() -> void:
	var original := StoryState.new()
	original.adjust_relationship("nyra_sol", 34)
	original.set_flag("sample_flag")
	original.complete_mission("m01")
	original.complete_mission("m01")
	var restored := StoryState.new()
	restored.adjust_relationship("helix", 77)
	restored.from_save_dict(original.to_save_dict())
	_assert_true(restored.has_flag("sample_flag"), "story flags restored")
	_assert_true(restored.completed_missions.size() == 1, "duplicate completed IDs removed")
	_assert_true(restored.get_relationship("nyra_sol") == 34, "saved relationship restored")
	_assert_true(restored.get_relationship("helix") == 0, "missing relationship returns to default")
	restored.from_save_dict({"mission_flags": {}, "completed_missions": [], "relationship": {}})
	_assert_true(restored.get_relationship("nyra_sol") == 0, "subsequent load does not retain stale relationship")
	_assert_true(restored.active_mission_id.is_empty(), "missing active mission resets")


func _test_dialogue_graph() -> void:
	for node_id in DialogueM01M05.catalog().keys():
		var node: Dictionary = DialogueM01M05.get_node(str(node_id))
		var line: Dictionary = node.get("text", {})
		_assert_true(not str(line.get("ru", "")).is_empty(), str(node_id) + " has Russian text")
		_assert_true(not str(line.get("en", "")).is_empty(), str(node_id) + " has English text")
		for choice_variant in node.get("choices", []):
			var choice: Dictionary = choice_variant
			var next_node := str(choice.get("next", ""))
			_assert_true(choice.has("id") and choice.has("text"), str(node_id) + " choice has stable ID and label")
			_assert_true(next_node.is_empty() or not DialogueM01M05.get_node(next_node).is_empty(), str(node_id) + " next node resolves")
