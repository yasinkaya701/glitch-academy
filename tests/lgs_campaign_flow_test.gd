extends SceneTree
## Verifies the LGS route catalog, sequential locks, route-scoped progress and save data.
## Run with: godot --headless --path . --script tests/lgs_campaign_flow_test.gd

const LGS_IDS: Array[StringName] = [
	&"seasons", &"bridge", &"pulley", &"turkish", &"history", &"english", &"religion",
]

var failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _check(label: String, condition: bool) -> void:
	print("%s  %s" % ["ok" if condition else "HATA", label])
	if not condition:
		failures += 1


func _run() -> void:
	var campaign: Node = root.get_node("Campaign")
	var original_save_path: String = campaign.save_path
	var test_save_path := "user://lgs_campaign_flow_test.cfg"
	campaign.save_path = test_save_path
	campaign.completed_ids.clear()
	campaign.story_flags.clear()
	campaign.selected_route = &"tyt"
	campaign._save()

	var center: Control = load("res://scenes/control_center.tscn").instantiate()
	root.add_child(center)
	current_scene = center
	await process_frame
	await process_frame
	var intro := center.get_node_or_null("Intro")
	if intro != null and intro.has_method("_finish"):
		intro.call("_finish")
	await process_frame
	center._select_route(&"lgs")
	await process_frame

	_check("LGS rotası seçili", center.active_mode == &"lgs" and center.active_route == &"lgs")
	_check("yedi LGS görevi doğru sırada görünür", _visible_ids(center) == LGS_IDS)
	_check("yalnız Mevsimler başlangıçta oynanabilir", _only_available(center, 0))
	_check("LGS kaydı diğer rota ilerlemesini tamamlamaz", not campaign.is_completed(&"seasons", &"class"))
	center._select_route(&"tyt")
	_check("YKS'ye geçiş LGS rotasını bozmaz", center.active_mode == &"yks")
	center._select_route(&"lgs")
	_check("YKS'den LGS'ye dönünce yedi görev geri gelir", _visible_ids(center) == LGS_IDS)

	for index in range(LGS_IDS.size()):
		var mission_id: StringName = LGS_IDS[index]
		var definition = center._mission_by_id(mission_id)
		var expected_available := index == 0
		if index > 0:
			expected_available = campaign.is_completed(LGS_IDS[index - 1], &"lgs")
		_check("%s kaydının sahnesi bağlı" % mission_id, definition != null and definition.scene != null)
		_check("%s tasarım kartı var" % mission_id, FileAccess.file_exists("res://stations/%s/DESIGN_CARD.md" % mission_id))
		_check("%s yalnız önceki onarımdan sonra açılır" % mission_id, center._mission_available(definition) == expected_available)
		if index < LGS_IDS.size() - 1:
			campaign.mark_completed(mission_id, &"lgs")
			await process_frame
			_check("%s onarımı sıradaki görevi açar" % mission_id, _available_through(center, index + 1))

	var completed_before_final: Array[StringName] = []
	for index in range(LGS_IDS.size() - 1):
		completed_before_final.append(LGS_IDS[index])
	_check("LGS ilerlemesi yalnız LGS anahtarına kaydedilir", _save_has_all(campaign.save_path, completed_before_final))
	campaign.mark_completed(&"religion", &"lgs")
	center._check_story_after_mission(&"religion")
	_check("son görev kampanya bitişini bir kez kaydeder", campaign.has_story_flag(&"lgs_campaign_complete"))
	_check("son görev LGS dışında tamamlanmış sayılmaz", not campaign.is_completed(&"religion", &"class"))

	center.queue_free()
	campaign.completed_ids.clear()
	campaign.story_flags.clear()
	campaign.save_path = original_save_path
	DirAccess.remove_absolute(ProjectSettings.globalize_path(test_save_path))
	print("BAŞARISIZ: %d" % failures if failures > 0 else "HEPSİ GEÇTİ")
	quit(failures)


func _visible_ids(center: Control) -> Array[StringName]:
	var ids: Array[StringName] = []
	for mission in center.visible_missions:
		ids.append(mission.id)
	return ids


func _only_available(center: Control, expected_index: int) -> bool:
	return _available_through(center, expected_index)


func _available_through(center: Control, expected_index: int) -> bool:
	for index in range(center.visible_missions.size()):
		if center._mission_available(center.visible_missions[index]) != (index <= expected_index):
			return false
	return true


func _save_has_all(path: String, mission_ids: Array) -> bool:
	var config := ConfigFile.new()
	if config.load(path) != OK:
		return false
	var saved: PackedStringArray = config.get_value("progress", "completed", PackedStringArray())
	for mission_id in mission_ids:
		if not saved.has("lgs::%s" % mission_id):
			return false
	return true
