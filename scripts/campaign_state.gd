extends Node
## Route-independent campaign progress shared by the control center and story hooks.

signal state_changed

const SAVE_PATH := "user://yks_campaign.cfg"

var completed_ids: Dictionary[StringName, bool] = {}
var story_flags: Dictionary[StringName, bool] = {}
var save_path := SAVE_PATH
var selected_route: StringName = &"tyt"
var selected_field: StringName = &"all"


func _ready() -> void:
	_load()


func mark_completed(mission_id: StringName) -> void:
	completed_ids[mission_id] = true
	_save()
	state_changed.emit()


func is_completed(mission_id: StringName) -> bool:
	return completed_ids.has(mission_id)


func has_story_flag(flag: StringName) -> bool:
	return story_flags.has(flag)


func set_story_flag(flag: StringName) -> void:
	if story_flags.has(flag):
		return
	story_flags[flag] = true
	_save()
	state_changed.emit()


func set_route(route: StringName) -> void:
	if route not in [&"tyt", &"ayt", &"ydt"] or selected_route == route:
		return
	selected_route = route
	_save()


func set_field(field: StringName) -> void:
	if field not in [&"all", &"sayisal", &"ea", &"sozel"] or selected_field == field:
		return
	selected_field = field
	_save()


func completed_subject_count(catalog: Array, include_y_d_t := true) -> int:
	var subjects: Dictionary[String, bool] = {}
	for mission in catalog:
		var routes: PackedStringArray = mission.get("routes")
		if not (routes.has("tyt") or routes.has("ayt") or routes.has("ydt")):
			continue
		if not include_y_d_t and routes.has("ydt") and not routes.has("tyt") and not routes.has("ayt"):
			continue
		if is_completed(mission.get("id")):
			subjects[str(mission.get("subject"))] = true
	return subjects.size()


func _load() -> void:
	var config := ConfigFile.new()
	if config.load(save_path) != OK:
		return
	var needs_migration := false
	for mission_id in config.get_value("progress", "completed", PackedStringArray()):
		completed_ids[StringName(mission_id)] = true
	for flag in config.get_value("story", "flags", PackedStringArray()):
		story_flags[StringName(flag)] = true
	if story_flags.has(&"life_repaired") and not story_flags.has(&"life_repair_verified"):
		story_flags.erase(&"life_repaired")
		needs_migration = true
	if story_flags.has(&"life_repair_verified") and not story_flags.has(&"life_repaired"):
		story_flags[&"life_repaired"] = true
		needs_migration = true
	if not story_flags.has(&"life_repair_verified") and story_flags.has(&"three_suns_ready"):
		story_flags.erase(&"three_suns_ready")
		needs_migration = true
	var loaded_route := StringName(config.get_value("progress", "route", "tyt"))
	var loaded_field := StringName(config.get_value("progress", "field", "all"))
	if loaded_route in [&"tyt", &"ayt", &"ydt"]:
		selected_route = loaded_route
	if loaded_field in [&"all", &"sayisal", &"ea", &"sozel"]:
		selected_field = loaded_field
	if needs_migration:
		_save()


func _save() -> void:
	var config := ConfigFile.new()
	config.load(save_path)
	var completed := PackedStringArray()
	for mission_id in completed_ids:
		completed.append(String(mission_id))
	var flags := PackedStringArray()
	for flag in story_flags:
		flags.append(String(flag))
	config.set_value("progress", "completed", completed)
	config.set_value("progress", "route", String(selected_route))
	config.set_value("progress", "field", String(selected_field))
	config.set_value("story", "flags", flags)
	config.save(save_path)
