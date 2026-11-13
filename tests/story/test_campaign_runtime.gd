extends SceneTree
## Headless integration tests for the runtime campaign bridge.
## godot --headless --path . --script res://tests/story/test_campaign_runtime.gd -- --test-mode

var _passed := 0
var _failed := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var manager := CampaignManager.new()
	manager.persistence_enabled = false
	root.add_child(manager)
	_test_start_and_validate_objectives(manager)
	_test_optional_objective(manager)
	_test_choice_gate_and_campaign_chain(manager)
	root.remove_child(manager)
	manager.free()
	print("CAMPAIGN RUNTIME RESULT: %s (%d passed, %d failed)" % ["PASS" if _failed == 0 else "FAIL", _passed, _failed])
	quit(0 if _failed == 0 else 1)


func _assert_true(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  PASS  " + message)
	else:
		_failed += 1
		push_error("  FAIL  " + message)


func _test_start_and_validate_objectives(manager: CampaignManager) -> void:
	print("\n[start and objective validation]")
	var started := manager.start_mission("m01")
	_assert_true(started.get("ok", false), "M01 starts at new game")
	_assert_true(manager.get_objectives().size() == 5, "M01 exposes all five objectives")
	_assert_true(not manager.complete_objective("not_a_real_objective").get("ok", false), "unknown objective is rejected")
	_assert_true(not manager.start_mission("m02").get("ok", false), "cannot switch missions while M01 is active")
	_assert_true(not manager.complete_objective("talk_quinn").get("mission_completed", false), "first objective does not finish mission")
	for objective_id in ["talk_quinn", "undock", "goto_buoy", "scan_buoy", "return_dock"]:
		manager.complete_objective(objective_id)
	_assert_true(manager.story_state.is_mission_completed("m01"), "M01 completes after required objectives")
	_assert_true(manager.story_state.has_flag("m01_done"), "M01 completion flag is applied")
	_assert_true(manager.story_state.active_mission_id.is_empty(), "active mission clears on completion")


func _test_optional_objective(manager: CampaignManager) -> void:
	print("\n[optional objective]")
	_assert_true(manager.start_mission("m02").get("ok", false), "M02 unlocks after M01")
	manager.complete_objective("goto_vb01")
	var first_scan := manager.complete_objective("scan_debris")
	_assert_true(not first_scan.get("objective_completed", true), "counted scan objective requires three scans")
	manager.complete_objective("scan_debris")
	var third_scan := manager.complete_objective("scan_debris")
	_assert_true(third_scan.get("objective_completed", false), "third scan completes counted objective")
	manager.complete_objective("deliver_jex")
	_assert_true(manager.story_state.is_mission_completed("m02"), "M02 completes without optional combat objective")


func _test_choice_gate_and_campaign_chain(manager: CampaignManager) -> void:
	print("\n[choice gate and campaign chain]")
	_assert_true(manager.start_mission("m03").get("ok", false), "M03 unlocks after M02")
	manager.complete_objective("talk_quinn_tag")
	manager.complete_objective("talk_nyra")
	_assert_true(not manager.complete_objective("choose_share").get("ok", false), "choice objective rejects missing choice")
	_assert_true(not manager.complete_objective("choose_share", "invalid_choice").get("ok", false), "choice objective rejects unknown choice")
	var chosen := manager.complete_objective("choose_share", "keep_private")
	_assert_true(chosen.get("mission_completed", false), "valid M03 choice completes mission")
	_assert_true(manager.story_state.has_flag("kept_private"), "choice flag is applied to story state")
	_assert_true(manager.start_mission("m05").get("ok", false) == false, "M05 remains locked before M04")
	_assert_true(manager.start_mission("m04").get("ok", false), "M04 unlocks after M03")
