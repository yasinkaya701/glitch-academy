extends SceneTree
## All LGS resources must be reachable and contain an isolated, functional 3D world.
const EXPECTED := [&"seasons", &"bridge", &"pressure", &"indicator", &"history", &"pulley", &"turkish", &"english", &"religion", &"genetics"]
var failures := 0
func _initialize() -> void:
	call_deferred("_run")
func check(label: String, ok: bool) -> void:
	print("%s %s" % ["OK" if ok else "FAIL", label])
	if not ok: failures += 1
func _run() -> void:
	root.size = Vector2i(1280,720)
	var center = load("res://scenes/control_center.tscn").instantiate()
	root.add_child(center)
	await process_frame
	center._select_route(&"lgs")
	var actual: Array = []
	for definition in center.visible_missions: actual.append(definition.id)
	check("all ten LGS missions registered", actual.size() == EXPECTED.size())
	for directory in DirAccess.get_directories_at("res://stations"):
		var path := "res://stations/%s/mission.tres" % directory
		if not ResourceLoader.exists(path): continue
		var definition = load(path)
		if definition.routes.has("lgs"):
			check("route resource reachable: " + directory, actual.has(definition.id))
	for id in EXPECTED:
		var definition = null
		for candidate in center.visible_missions:
			if candidate.id == id: definition = candidate
		if definition == null:
			check("missing " + String(id), false)
			continue
		center.selected_mission = definition
		center._launch_selected_mission()
		await process_frame
		await process_frame
		var mission = center.active_mission
		var emissions := [0]
		mission.completed.connect(func(): emissions[0] += 1)
		check(String(id) + " route injected", mission.route == &"lgs")
		var worlds: Array = mission.find_children("*", "SubViewport", true, false)
		var found_world := false
		for viewport in worlds:
			if viewport.own_world_3d and viewport.find_children("*", "MeshInstance3D", true, false).size() > 3:
				found_world = true
		check(String(id) + " actual isolated 3D geometry", found_world)
		if id == &"genetics":
			var sim = load("res://stations/genetics/genetics_model.gd")
			check("genetics AA x aa", sim.cross("AA", "aa") == PackedStringArray(["Aa", "Aa", "Aa", "Aa"]))
			check("genetics recessive ratios", is_equal_approx(sim.recessive_probability("Aa","Aa"), 0.25) and is_equal_approx(sim.recessive_probability("Aa","aa"),0.5))
			check("genetics recessive parents", sim.cross("aa","aa").count("aa") == 4)
			check("genetics dominant parents", is_zero_approx(sim.recessive_probability("AA","AA")))
			check("genetics invalid parent rejected", sim.cross("abc","aa").is_empty())
			m_genetics_guard(mission)
			mission._select_example(0)
			mission._select_example(1)
			check("genetics observations reveal a recessive seed", mission._offspring.count("aa") == 1 and mission._seeds.size() == 4)
			mission._enter_prediction()
			check("genetics new result hidden before prediction", mission._phase == 1 and not mission._revealed)
			mission._prediction.text = "50abc"
			mission._submit_prediction()
			check("genetics malformed percentage rejected", mission._phase == 1)
			mission._predict(25)
			check("genetics wrong prediction stays hidden", mission._phase == 1 and not mission._revealed)
			mission._prediction.text = "50%"
			mission._submit_prediction()
			mission._predict(50)
			check("genetics correct prediction reveals two recessive outcomes", mission._offspring.count("aa") == 2 and mission._revealed)
			check("genetics completion exactly once", emissions[0] == 1)
		elif id in [&"turkish", &"english", &"religion"]:
			mission._begin_test()
			mission._advance_phase()
			var data: Dictionary = mission.PACK[String(id)]
			var answer := int(data.steps[0].answer)
			mission._choose_evidence((answer+1)%3,0)
			check(String(id) + " incorrect evidence rejected", mission.stage == 0 and mission.phase == 2)
			mission._choose_evidence(answer,0)
			mission._choose_evidence(int(data.steps[1].answer),1)
			check(String(id) + " evidence opens repair", mission.phase == 3)
			mission._choose_repair((int(data.steps[2].answer)+1)%3)
			check(String(id) + " wrong repair stays broken", mission.phase == 3 and mission.fault_visible)
			mission._choose_repair(int(data.steps[2].answer))
			await create_timer(0.9).timeout
			check(String(id) + " repair moves physical scene", mission.diorama._opening > 0.9 if id == &"turkish" else mission.diorama._delivery_progress > 0.9)
			mission._choose_rescue((int(data.rescue.answer)+1)%3)
			check(String(id) + " new-situation error consumes attempt", mission.attempts == 1 and mission.phase == 4)
			mission._choose_rescue(int(data.rescue.answer))
			mission._finish()
			mission._finish()
			check(String(id) + " completion exactly once", emissions[0] == 1)
		elif id == &"history":
			check("history flat backdrop replaced", not mission.stage.actor.visible and mission.stage.room != null)
			var first_page: String = mission.stage._line_label.text
			mission.stage._next_page()
			check("history full text accessible through pages", mission.stage._line_label.text != first_page and " ".join(mission.stage._pages) == mission.stage.voice.get_line_text(&"ataturk", &"stage_0").strip_edges())
			var choices: Array = mission.stage.voice.get_choices(&"ataturk")
			for card in choices:
				if not bool(card.get("correct",false)):
					mission._on_card_selected(card)
					break
			check("history incorrect claim does not advance", mission._stage_level == 0 and mission.stage.room.alarm > 0.0)
			for level in range(4):
				for card in choices:
					if bool(card.get("correct",false)) and int(card.get("stage",-1)) == level:
						mission._on_card_selected(card)
						break
				await process_frame
			check("history four records restored", mission._stage_level == 4 and mission.stage.room.restored_count == 4)
			check("history completion signal", emissions[0] == 1)
			mission._on_action_pressed()
			check("history retry clears 3D archive", mission.stage.room.restored_count == 0)
		elif id == &"pulley":
			mission._advance()
			mission._pull_buttons[0].pressed.emit()
			mission._pull_buttons[0].pressed.emit()
			mission._advance()
			mission._select_mode(1)
			mission._pull_buttons[0].pressed.emit()
			mission._pull_buttons[0].pressed.emit()
			mission._advance()
			check("pulley actual rope motion recorded", mission._phase == mission.Phase.DIAGNOSE)
			mission._select_evidence(1)
			mission._advance()
			mission._toggle_support_count()
			mission._advance()
			mission._effort_slider.value = 20
			mission._pull_rope(Vector2(0,300))
			mission._advance()
			check("pulley new load rescued", mission._phase == mission.Phase.SEAL)
			mission._advance()
			check("pulley completion", emissions[0] == 1)
		center._return_to_hub()
		await process_frame
		check(String(id) + " return releases scene", center.active_mission == null and center.hub.visible)
		center._launch_selected_mission()
		await process_frame
		check(String(id) + " fresh retry", center.active_mission != null and center.active_mission.route == &"lgs")
		if id in [&"turkish", &"english", &"religion"]:
			var fresh = center.active_mission
			var pack: Dictionary = fresh.PACK[String(id)]
			fresh._begin_test()
			fresh._advance_phase()
			fresh._choose_evidence(int(pack.steps[0].answer),0)
			fresh._choose_evidence(int(pack.steps[1].answer),1)
			fresh._choose_repair(int(pack.steps[2].answer))
			for attempt in range(3): fresh._choose_rescue((int(pack.rescue.answer)+1)%3)
			check(String(id) + " three failed attempts stop progression", fresh.locked and fresh.attempts == 3 and fresh.phase == 4)
			fresh._restart_after_failure()
			fresh.diorama._sync_model(1.0)
			check(String(id) + " rewind restores crisis", fresh.phase == 0 and fresh.attempts == 0 and fresh.fault_visible and not fresh.diorama.solved)
		if id == &"pulley":
			center.active_mission._request_exit()
			check("station exit signal returns to hub", center.active_mission == null)
		else:
			center._return_to_hub()
		await process_frame
	center.queue_free()
	await process_frame
	print("FAILURES: %d" % failures)
	quit(failures)

func m_genetics_guard(mission) -> void:
	mission._enter_prediction()
	check("genetics requires both observations", mission._phase == 0 and mission._advance.disabled)
