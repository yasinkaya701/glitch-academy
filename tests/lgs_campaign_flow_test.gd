extends SceneTree
## LGS rotasını ilk mevsim gözleminden finale kadar oynatır.
## Kullanım: godot --headless --path . --script tests/lgs_campaign_flow_test.gd

const ANSWERS := {
	"bridge": [0, 1, 1],
	"turkish": [0, 1, 0],
	"history": [0, 1, 1],
	"english": [0, 1, 0],
	"religion": [0, 0, 0],
}

var failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _check(label: String, condition: bool) -> void:
	print("%s  %s" % ["ok" if condition else "HATA", label])
	if not condition:
		failures += 1


func _run() -> void:
	var center: Control = load("res://scenes/control_center.tscn").instantiate()
	root.add_child(center)
	await process_frame
	await process_frame
	center.progress_path = OS.get_user_data_dir().path_join("lgs_campaign_flow_test.cfg")
	center.completed_ids.clear()
	center._refresh_list()
	var intro: Node = center.get_child(center.get_child_count() - 1)
	if intro.has_method("_finish"):
		intro.call("_finish")
	await process_frame
	_check("ilk rota LGS ve altı ders görünür", center.active_route == &"lgs" and center.visible_missions.size() == 6)
	_check("ilk seçili görev Mevsim Gözlemevi", center.selected_mission.id == &"seasons")

	center._start_mission()
	await process_frame
	var seasons: Control = center.active_mission
	seasons._show_experiment()
	seasons._observe(false)
	seasons._observe(true)
	seasons._show_application()
	seasons._store_setting(1, true)
	seasons._store_setting(2, false)
	seasons._apply_settings()
	_check("yanlış sera ayarı onarım vermiyor", not center.completed_ids.has(&"seasons"))
	seasons._store_setting(2, true)
	seasons._store_setting(1, false)
	seasons._apply_settings()
	await process_frame
	_check("iki tarih gözlemi ve doğru yarımküre ayarı serayı onarıyor", center.completed_ids.has(&"seasons"))
	_check("mevsim onarımı ilk hikâye geçişini açıyor", center.get_node("StoryBeat").visible)
	center._continue_story()
	await process_frame
	_check("mevsim sonrası Köprü açılıyor", center.selected_mission.id == &"bridge")
	_check("Türkçe köprü onarılmadan açılmıyor", not center._is_unlocked(&"turkish"))

	for mission_id in [&"bridge", &"turkish", &"history", &"english", &"religion"]:
		_check("%s seçili" % mission_id, center.selected_mission.id == mission_id)
		center._start_mission()
		await process_frame
		var mission: Control = center.active_mission
		var answers: Array = ANSWERS[String(mission_id)]
		var incorrect := (int(answers[0]) + 1) % 3
		mission.action_buttons.get_child(incorrect).pressed.emit()
		await process_frame
		_check("%s yanlış seçimde ilerlemiyor" % mission_id, mission.stage == 0 and not mission.locked)
		_check("%s ölçüm geri bildirimi veriyor" % mission_id, mission.feedback.text.begins_with("Ölçüm uyuşmadı."))
		for answer_index in answers.size():
			mission.action_buttons.get_child(int(answers[answer_index])).pressed.emit()
			await process_frame
			var next_button: Button = mission.action_buttons.get_child(mission.action_buttons.get_child_count() - 1)
			next_button.pressed.emit()
			await process_frame
		_check("%s üç etkileşimde onarıldı" % mission_id, center.completed_ids.has(mission_id))
		_check("%s hikâye geçişi gösteriliyor" % mission_id, center.get_node("StoryBeat").visible)
		center._continue_story()
		await process_frame

	_check("tarih veya İngilizce sinyali dayanışma arşivini açıyor", center._is_unlocked(&"religion"))
	_check("altı ders final protokolünü açıyor", center.get_node("Finale").visible and center._lgs_complete())
	center.completed_ids.erase(&"history")
	_check("İngilizce sinyali tek başına alternatif final dalını açık tutuyor", center._is_unlocked(&"religion"))
	center.completed_ids[&"history"] = true

	var saved := ConfigFile.new()
	var save_path: String = center.progress_path
	var saved_ok := saved.load(save_path) == OK
	var all_saved := saved_ok
	for mission_id in center.LGS_IDS:
		all_saved = all_saved and saved.get_value("campaign", String(mission_id), false)
	_check("altı onarım yerel ilerlemeye kaydediliyor", all_saved)
	DirAccess.remove_absolute(save_path)
	print("BAŞARISIZ: %d" % failures if failures > 0 else "HEPSİ GEÇTİ")
	quit(failures)
