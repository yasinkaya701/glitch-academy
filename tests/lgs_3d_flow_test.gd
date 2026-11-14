extends SceneTree
var failures := 0
func _initialize() -> void:
	call_deferred("_run")
func check(label: String, ok: bool) -> void:
	print("%s %s" % ["OK" if ok else "FAIL", label])
	if not ok: failures += 1
func _run() -> void:
	root.size = Vector2i(1280,720)
	for kind in ["seasons", "bridge", "pressure", "indicator"]:
		var mission = load("res://stations/%s/mission.tscn" % kind).instantiate()
		mission.route = &"lgs"
		var emissions := [0]
		mission.completed.connect(func(): emissions[0] += 1)
		root.add_child(mission)
		await process_frame
		await process_frame
		var stage = mission.diagram if kind == "seasons" else mission.stage
		check(kind + " isolated 3D world", stage.viewport != null and stage.viewport.find_children("*", "MeshInstance3D", true, false).size() > 3)
		if kind == "seasons":
			mission._show_experiment()
			mission._observe(false)
			mission._observe(true)
			mission._change_tilt(true)
			check("tilt setting drives model", is_zero_approx(stage.tilt))
			mission._show_recovery()
			mission.north_setting = mission.Season.SUMMER
			mission.south_setting = mission.Season.WINTER
			mission._apply_settings()
			check("wrong season stays in application", mission.phase == mission.Phase.RECOVERY)
			mission.north_setting = mission.Season.WINTER
			mission.south_setting = mission.Season.SUMMER
			mission._apply_settings()
			check("season repair", stage.repaired)
			mission._complete_mission()
		elif kind == "bridge":
			mission._skip_intro()
			mission.answer_input.text = "8"
			mission._on_submit_pressed()
			check("wrong beam stays in calculation", mission.phase == &"calc")
			mission.answer_input.text = "10"
			mission._on_submit_pressed()
			mission._on_close_bridge_pressed()
			await create_timer(1.1).timeout
			check("bridge repair", stage.hypotenuse_installed and stage.bridge_closed)
			stage._sync_model(1.0)
			check("3D beam visible", stage._diagonal.visible and not stage._missing.visible)
		elif kind == "pressure":
			mission._skip_intro()
			mission.answer_input.text = "12"
			mission._on_submit_pressed()
			check("wrong pressure stays in calculation", mission.phase == &"calc")
			mission.answer_input.text = "20"
			mission._on_submit_pressed()
			mission.depth_slider.value = 20
			stage._sync_model(0.1)
			check("pressure model 2000 Pa", is_equal_approx(stage.get_pressure_pa(),2000.0))
			check("manometer responds", stage._right_column.scale.y > stage._left_column.scale.y)
			mission._on_unlock_pressed()
			check("pressure valve repaired", stage.valve_unlocked)
		else:
			mission._skip_intro()
			mission._on_dip_pressed()
			await create_timer(0.7).timeout
			mission._on_choice_selected("baz")
			check("wrong chemistry stays in identification", mission.phase == &"identify")
			mission._on_choice_selected("asit")
			mission._on_neutralize_pressed()
			await create_timer(2.0).timeout
			check("neutralization", stage.is_neutralized and is_equal_approx(stage.current_ph,7.0))
		check(kind + " completion signal", emissions[0] == 1)
		mission.queue_free()
		await process_frame
		var retry = load("res://stations/%s/mission.tscn" % kind).instantiate()
		root.add_child(retry)
		await process_frame
		check(kind + " retry resets", not (retry.diagram.repaired if kind == "seasons" else retry.stage.bridge_closed if kind == "bridge" else retry.stage.valve_unlocked if kind == "pressure" else retry.stage.is_neutralized))
		retry.queue_free()
		await process_frame
	var center = load("res://scenes/control_center.tscn").instantiate()
	root.add_child(center)
	await process_frame
	center._select_route(&"lgs")
	for kind in [&"seasons", &"bridge", &"pressure", &"indicator"]:
		var definition = null
		for candidate in center.visible_missions:
			if candidate.id == kind: definition = candidate
		check(String(kind) + " in LGS menu", definition != null)
		if definition == null: continue
		center.selected_mission = definition
		center._start_mission()
		await process_frame
		check(String(kind) + " launched from hub", center.active_mission != null and center.active_mission.route == &"lgs")
		center._return_to_hub()
		await process_frame
		check(String(kind) + " returned to hub", center.active_mission == null and center.hub.visible)
	center.queue_free()
	await process_frame
	print("FAILURES: %d" % failures)
	quit(failures)
