extends Control

const Mission = preload("res://scripts/mission.gd")
const MissionDefinition = preload("res://scripts/mission_definition.gd")
const INTRO = preload("res://scenes/intro/intro.tscn")
const CATALOG: Array[MissionDefinition] = [
	preload("res://stations/seasons/mission.tres"),
	preload("res://stations/measurement/mission.tres"),
	preload("res://stations/vectors/mission.tres"),
	preload("res://stations/derivative/mission.tres"),
	preload("res://stations/bridge/mission.tres"),
	preload("res://stations/prism/mission.tres"),
	preload("res://stations/free_fall/mission.tres"),
	preload("res://stations/photoelectric/mission.tres"),
	preload("res://stations/indicator/mission.tres"),
	preload("res://stations/heart/mission.tres"),
	preload("res://stations/pressure/mission.tres"),
]

@onready var hub: Control = %Hub
@onready var grade_filter: OptionButton = %GradeFilter
@onready var mission_list: ItemList = %MissionList
@onready var mission_title: Label = %MissionTitle
@onready var mission_description: Label = %MissionDescription
@onready var mission_status: Label = %MissionStatus
@onready var start_mission: Button = %StartMission
@onready var progress: Label = %Progress
@onready var play_screen: Control = %PlayScreen
@onready var play_title: Label = %PlayTitle
@onready var play_status: Label = %PlayStatus
@onready var mission_host: Control = %MissionHost

var active_route: StringName = &"class"
var selected_mission: MissionDefinition
var active_mission: Mission
var visible_missions: Array[MissionDefinition] = []
var completed_ids: Dictionary[StringName, bool] = {}


func _ready() -> void:
	grade_filter.add_item("Tüm sınıflar", 0)
	for grade in range(5, 13):
		grade_filter.add_item("%d. sınıf" % grade, grade)
	%Class.pressed.connect(_select_route.bind(&"class"))
	%LGS.pressed.connect(_select_route.bind(&"lgs"))
	%TYT.pressed.connect(_select_route.bind(&"tyt"))
	%AYT.pressed.connect(_select_route.bind(&"ayt"))
	grade_filter.item_selected.connect(_on_grade_selected)
	mission_list.item_selected.connect(_select_mission)
	mission_list.item_activated.connect(_activate_mission)
	start_mission.pressed.connect(_start_mission)
	%Back.pressed.connect(_return_to_hub)
	%Reset.pressed.connect(_start_mission)
	_refresh_list()
	_play_intro()


func _play_intro() -> void:
	var intro = INTRO.instantiate()
	hub.hide()
	%HubScrim.hide()
	add_child(intro)
	intro.alarm_changed.connect(_set_world_alarm)
	intro.finished.connect(_finish_intro.bind(intro), CONNECT_ONE_SHOT)
	intro.start()


func _finish_intro(intro: Control) -> void:
	intro.queue_free()
	%HubScrim.show()
	hub.show()
	%Class.grab_focus()


func _set_world_alarm(strength: float) -> void:
	if %Observatory.has_method("set_alarm"):
		%Observatory.call("set_alarm", strength)


func _select_route(route: StringName) -> void:
	active_route = route
	grade_filter.visible = route == &"class"
	%Class.set_pressed_no_signal(route == &"class")
	%LGS.set_pressed_no_signal(route == &"lgs")
	%TYT.set_pressed_no_signal(route == &"tyt")
	%AYT.set_pressed_no_signal(route == &"ayt")
	_refresh_list()


func _on_grade_selected(_index: int) -> void:
	_refresh_list()


func _refresh_list() -> void:
	var selected_id: StringName = selected_mission.id if selected_mission != null else &""
	mission_list.clear()
	visible_missions.clear()
	var selected_grade := grade_filter.get_selected_id()
	for mission in CATALOG:
		if not mission.routes.has(String(active_route)):
			continue
		if active_route == &"class" and selected_grade > 0 and mission.grade != selected_grade:
			continue
		var subject := "Fen Bilimleri" if active_route == &"lgs" and mission.subject == "Kimya" else mission.subject
		var index := mission_list.add_item("%s  ·  %s" % [mission.title, subject])
		mission_list.set_item_metadata(index, mission.id)
		visible_missions.append(mission)
		if mission.id == selected_id:
			mission_list.select(index)
	var selected_items := mission_list.get_selected_items()
	if selected_items.is_empty():
		_clear_selection()
	else:
		_select_mission(selected_items[0])
	progress.text = "Onarılan görevler  %d / %d" % [completed_ids.size(), CATALOG.size()]


func _clear_selection() -> void:
	selected_mission = null
	mission_title.text = "Görev seç"
	mission_description.text = "Bir istasyon seçtiğinde deneyin amacı burada görünür."
	if visible_missions.is_empty():
		mission_description.text = "Bu seçim için henüz görev bulunmuyor."
	mission_status.text = ""
	start_mission.disabled = true


func _select_mission(index: int) -> void:
	selected_mission = visible_missions[index]
	mission_title.text = selected_mission.title
	mission_description.text = selected_mission.description
	start_mission.disabled = selected_mission.scene == null
	if completed_ids.has(selected_mission.id):
		mission_status.text = "Onarıldı"
	elif selected_mission.scene == null:
		mission_status.text = "Hazırlanıyor"
	else:
		mission_status.text = "Oynanabilir"


func _activate_mission(index: int) -> void:
	_select_mission(index)
	_start_mission()


func _start_mission() -> void:
	if selected_mission == null or selected_mission.scene == null:
		return
	var instance := selected_mission.scene.instantiate()
	var next_mission := instance as Mission
	if next_mission == null:
		instance.free()
		push_error("Görev sahnesinin kökü scripts/mission.gd dosyasını genişletmeli.")
		return
	_remove_active_mission()
	active_mission = next_mission
	active_mission.route = active_route
	active_mission.exit_requested.connect(_return_to_hub)
	active_mission.completed.connect(_on_mission_completed.bind(selected_mission.id))
	play_title.text = selected_mission.title
	play_status.text = ""
	hub.hide()
	%HubScrim.hide()
	%WorldView.hide()
	play_screen.show()
	mission_host.add_child(active_mission)
	active_mission.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _on_mission_completed(mission_id: StringName) -> void:
	completed_ids[mission_id] = true
	if %Observatory.has_method("set_operational_count"):
		var repaired_signals := roundi(6.0 * completed_ids.size() / CATALOG.size())
		%Observatory.call("set_operational_count", repaired_signals)
	play_status.text = "Onarıldı"


func _return_to_hub() -> void:
	_remove_active_mission()
	play_screen.hide()
	%WorldView.show()
	%HubScrim.show()
	hub.show()
	_refresh_list()


func _remove_active_mission() -> void:
	if active_mission != null:
		mission_host.remove_child(active_mission)
		active_mission.queue_free()
		active_mission = null
