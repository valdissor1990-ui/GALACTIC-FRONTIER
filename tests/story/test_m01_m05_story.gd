extends SceneTree
## Headless tests for StoryState + MissionCatalog M01–M05.
## godot --headless --path . --script res://tests/story/test_m01_m05_story.gd

var _failed: int = 0
var _passed: int = 0


func _initialize() -> void:
	print("=== GALACTIC FRONTIER — M01–M05 story tests ===")
	_test_m01_unlocks_m02()
	_test_m03_choices_exclusive_flags()
	_test_full_chain_to_act1_complete()
	_test_save_roundtrip()
	_test_dialogue_nodes_exist()
	print("")
	if _failed == 0:
		print("RESULT: PASS  (%d assertions)" % _passed)
		quit(0)
	else:
		print("RESULT: FAIL  (%d passed, %d failed)" % [_passed, _failed])
		quit(1)


func _assert_true(cond: bool, msg: String) -> void:
	if cond:
		_passed += 1
		print("  PASS  %s" % msg)
	else:
		_failed += 1
		print("  FAIL  %s" % msg)


func _test_m01_unlocks_m02() -> void:
	print("\n[m01 unlocks m02]")
	var state := StoryState.new()
	_assert_true(MissionCatalog.can_start("m01", state), "m01 available at start")
	_assert_true(not MissionCatalog.can_start("m02", state), "m02 locked before m01")
	MissionCatalog.apply_completion("m01", state)
	_assert_true(state.has_flag("m01_done"), "m01_done set")
	_assert_true(MissionCatalog.can_start("m02", state), "m02 available after m01")


func _test_m03_choices_exclusive_flags() -> void:
	print("\n[m03 choice flags]")
	for choice_id in ["share_helix", "share_union", "keep_private"]:
		var state := StoryState.new()
		MissionCatalog.apply_completion("m01", state)
		MissionCatalog.apply_completion("m02", state)
		MissionCatalog.apply_completion("m03", state, choice_id)
		_assert_true(state.is_mission_completed("m03"), "m03 completed for %s" % choice_id)
		match choice_id:
			"share_helix":
				_assert_true(state.has_flag("shared_helix"), "shared_helix")
				_assert_true(not state.has_flag("shared_union"), "no shared_union")
			"share_union":
				_assert_true(state.has_flag("shared_union"), "shared_union")
			"keep_private":
				_assert_true(state.has_flag("kept_private"), "kept_private")


func _test_full_chain_to_act1_complete() -> void:
	print("\n[full chain to act1_complete]")
	var state := StoryState.new()
	for mid in MissionCatalog.MISSION_ORDER:
		_assert_true(MissionCatalog.can_start(mid, state), "%s can start" % mid)
		var choice := "keep_private" if mid == "m03" else ""
		MissionCatalog.apply_completion(mid, state, choice)
	_assert_true(state.has_flag("act1_complete"), "act1_complete after m05")
	_assert_true(state.has_flag("vesper_access"), "vesper_access")
	_assert_true(state.has_flag("kestrel_access"), "kestrel_access")
	_assert_true(state.has_flag("relay_contact_1"), "relay_contact_1")


func _test_save_roundtrip() -> void:
	print("\n[save roundtrip]")
	var state := StoryState.new()
	MissionCatalog.apply_completion("m01", state)
	MissionCatalog.apply_completion("m02", state)
	var payload := state.to_save_dict()
	var restored := StoryState.new()
	restored.from_save_dict(payload)
	_assert_true(restored.has_flag("m01_done"), "flag restored")
	_assert_true(restored.is_mission_completed("m02"), "completed restored")
	_assert_true(restored.get_relationship("jex_morra") == state.get_relationship("jex_morra"), "relationship restored")


func _test_dialogue_nodes_exist() -> void:
	print("\n[dialogue nodes]")
	for node_id in ["m01_quinn_intro", "m02_jex_radio", "m03_nyra", "m04_vorn_brief", "m05_nyra_approach"]:
		var node: Dictionary = DialogueM01M05.get_node(node_id)
		_assert_true(not node.is_empty(), "node %s exists" % node_id)
		_assert_true(node.has("text"), "node %s has text" % node_id)
		var text: Dictionary = node["text"]
		_assert_true(str(text.get("ru", "")) != "", "%s ru" % node_id)
		_assert_true(str(text.get("en", "")) != "", "%s en" % node_id)
		for choice_variant in node.get("choices", []):
			var choice: Dictionary = choice_variant
			var next_node := str(choice.get("next", ""))
			_assert_true(choice.has("id"), "%s choice has stable id" % node_id)
			_assert_true(choice.has("text"), "%s choice has localized label" % node_id)
			_assert_true(next_node.is_empty() or not DialogueM01M05.get_node(next_node).is_empty(), "%s choice target resolves" % node_id)
