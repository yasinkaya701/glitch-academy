extends SceneTree

var failures := 0
var center: Control
var original_scenes: Dictionary = {}
var save_path := "/tmp/meridyen-story-flow-test.cfg"

func _initialize() -> void:
	call_deferred("run_test")

func run_test() -> void:
	var campaign = root.get_node("Campaign")
	campaign.save_path = save_path
	campaign.completed_ids.clear()
	campaign.story_flags.clear()
	DirAccess.remove_absolute(save_path)
	center = load("res://scenes/control_center.tscn").instantiate()
	root.add_child(center)
	await process_frame
	var intro = center.get_node_or_null("Intro")
	if intro: intro._finish()
	await process_frame
	check("default route is a story campaign", center.active_route == &"lgs")
	check("finale cannot open without repaired experiments", not center._route_ready_for_finale())
	center._start_finale()
	check("early finale does not create a mission", center.active_mission == null)
	var missions: Array = center._route_missions()
	check("campaign contains multiple experiments", missions.size() > 2)
	var dummy = load("res://scripts/mission.gd").new()
	var scene := PackedScene.new()
	scene.pack(dummy)
	dummy.free()
	for definition in center.CATALOG:
		original_scenes[definition.id] = definition.scene
		definition.scene = scene
	center._select_mission(1)
	center._start_mission()
	check("future experiment stays locked", center.active_mission == null)
	center._select_mission(0)
	center._start_mission()
	check("first experiment begins with MERIDYEN briefing", center.story_dialogue.visible and center.active_mission == null)
	center.story_dialogue._continue()
	check("briefing launches experiment", is_instance_valid(center.active_mission))
	check("opening experiment does not count as repair", center._route_completed_count() == 0)
	center._retry_current()
	check("retry does not count as repair", center._route_completed_count() == 0)
	center.active_mission.completed.emit()
	await process_frame
	await process_frame
	check("completion signal persists one repair", center._route_completed_count() == 1)
	check("interstitial follows repair", center.story_dialogue.visible)
	check("next experiment unlocks after repair", center._is_unlocked(missions[1].id))
	center.story_dialogue._return()
	check("return dismisses dialogue and keeps progress", not center.story_dialogue.visible and center._route_completed_count() == 1)
	for index in range(1, missions.size()):
		center._select_mission(index)
		center._start_mission()
		if center.story_dialogue.visible: center.story_dialogue._continue()
		check("ordered experiment launches: %s" % missions[index].id, is_instance_valid(center.active_mission))
		center.active_mission.completed.emit()
		await process_frame
		await process_frame
		check("repair count is exact", center._route_completed_count() == index + 1)
		center.story_dialogue._return()
	check("all route repairs unlock final measurement", center._route_ready_for_finale())
	check("repairs alone never declare victory", not campaign.has_story_flag(center._story_key("won")))
	center._start_finale()
	check("earned finale uses playable Three Suns", center.active_mission.has_method("_run_baseline"))
	center._return_to_hub()
	check("leaving finale never declares victory", not campaign.has_story_flag(center._story_key("won")))
	center._start_finale()
	center.active_mission._run_baseline()
	center.active_mission._run_changed()
	center.active_mission._compare()
	center.active_mission._release_control()
	await process_frame
	await process_frame
	check("verified final measurement earns win", campaign.has_story_flag(center._story_key("won")))
	check("win has closing transmission", center.story_dialogue.visible and center.story_dialogue.heading.text == "Dünya yeniden dengede")
	center.story_dialogue._continue()
	campaign.completed_ids.clear()
	campaign.story_flags.clear()
	campaign._load()
	check("win and repairs survive reload", campaign.has_story_flag(center._story_key("won")) and center._route_ready_for_finale())
	center._select_route(&"tyt")
	check("LGS stamps do not complete another route", center._route_completed_count() == 0 and not center._route_ready_for_finale())
	center._select_route(&"class")
	check("free exploration keeps all experiments unlocked", center._is_unlocked(&"heart"))
	for definition in center.CATALOG: definition.scene = original_scenes[definition.id]
	center.queue_free()
	await process_frame
	DirAccess.remove_absolute(save_path)
	print("STORY FLOW FAILURES: ", failures)
	quit(failures)

func check(label: String, passed: bool) -> void:
	print("OK " if passed else "FAIL ", label)
	if not passed: failures += 1
