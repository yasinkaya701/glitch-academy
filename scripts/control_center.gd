extends Control

const Mission = preload("res://scripts/mission.gd")
const MissionDefinition = preload("res://scripts/mission_definition.gd")
const YksMissionDefinition = preload("res://stations/yks/yks_mission_definition.gd")
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
	preload("res://stations/waves/mission.tres"),
	preload("res://stations/indicator/mission.tres"),
	preload("res://stations/heart/mission.tres"),
	preload("res://stations/pressure/mission.tres"),
	preload("res://stations/yks/definitions/turkish_reading.tres"),
	preload("res://stations/yks/definitions/turkish_literature.tres"),
	preload("res://stations/yks/definitions/tyt_math.tres"),
	preload("res://stations/yks/definitions/geometry.tres"),
	preload("res://stations/yks/definitions/chemistry.tres"),
	preload("res://stations/yks/definitions/tyt_biology.tres"),
	preload("res://stations/yks/definitions/history.tres"),
	preload("res://stations/yks/definitions/geography.tres"),
	preload("res://stations/yks/definitions/philosophy.tres"),
	preload("res://stations/yks/definitions/religion_culture.tres"),
	preload("res://stations/yks/definitions/psychology.tres"),
	preload("res://stations/yks/definitions/sociology.tres"),
	preload("res://stations/yks/definitions/logic.tres"),
	preload("res://stations/yks/definitions/ydt_english.tres"),
	preload("res://stations/yks/three_suns.tres"),
]
const YKS_ORDER := {
	"turkish_reading": 0, "tyt_math": 1, "measurement": 2, "indicator": 3,
	"tyt_biology": 4, "geometry": 5, "vectors": 6, "derivative": 7,
	"free_fall": 8, "waves": 9, "photoelectric": 10, "heart": 11,
	"turkish_literature": 12, "history": 13, "geography": 14, "philosophy": 15,
	"religion_culture": 16, "psychology": 17, "sociology": 18, "logic": 19,
	"chemistry": 20, "ydt_english": 21, "three_suns": 22,
}
const ICONS := {
	"Türkçe": "language", "Türk Dili ve Edebiyatı": "language",
	"Matematik": "geometry", "Geometri": "geometry", "Fizik": "vectors",
	"Kimya": "indicator", "Biyoloji": "heart", "Tarih": "archive",
	"Coğrafya": "compass", "Felsefe": "thinking", "Din Kültürü": "archive",
	"Psikoloji": "thinking", "Sosyoloji": "archive", "Mantık": "thinking",
	"Din Kültürü ve Ahlak Bilgisi": "archive", "English": "ydt",
	"İngilizce": "ydt", "Fen Bilimleri": "measurement",
}

@onready var hub: Control = %Hub
@onready var grade_filter: OptionButton = %GradeFilter
@onready var field_filter: OptionButton = %FieldFilter
@onready var mission_list: ItemList = %MissionList
@onready var mission_title: Label = %MissionTitle
@onready var mission_status: Label = %MissionStatus
@onready var mission_curriculum: Label = %MissionCurriculum
@onready var start_mission: Button = %StartMission
@onready var progress: Label = %Progress
@onready var play_screen: Control = %PlayScreen
@onready var play_title: Label = %PlayTitle
@onready var play_status: Label = %PlayStatus
@onready var mission_host: Control = %MissionHost
@onready var missions_layout: BoxContainer = %Missions
@onready var route_purpose: Label = %RoutePurpose

var active_route: StringName = &"tyt"
var active_mode: StringName = &"yks"
var selected_yks_route: StringName = &"tyt"
var active_field: StringName = &"all"
var selected_mission: MissionDefinition
var active_mission: Mission
var active_mission_definition: MissionDefinition
var visible_missions: Array[MissionDefinition] = []
var _hub_scroll: ScrollContainer
var _mobile_detail_active := false
var _advance_after_completion := false
var _story_overlay: Control
var _story_shield: Control
var _story_close_button: Button


func _ready() -> void:
	_wrap_hub_in_scroll_container()
	grade_filter.add_item("Tüm sınıflar", 0)
	for grade in range(5, 13):
		grade_filter.add_item("%d. sınıf" % grade, grade)
	field_filter.add_item("Tüm alanlar", 0)
	field_filter.add_item("Sayısal", 1)
	field_filter.add_item("Eşit ağırlık", 2)
	field_filter.add_item("Sözel", 3)
	selected_yks_route = Campaign.selected_route
	active_route = selected_yks_route
	active_field = Campaign.selected_field
	field_filter.select([&"all", &"sayisal", &"ea", &"sozel"].find(active_field))
	%Class.pressed.connect(_select_route.bind(&"class"))
	%LGS.pressed.connect(_select_route.bind(&"lgs"))
	%YKS.pressed.connect(_select_yks)
	%TYT.pressed.connect(_select_route.bind(&"tyt"))
	%AYT.pressed.connect(_select_route.bind(&"ayt"))
	%YDT.pressed.connect(_select_route.bind(&"ydt"))
	grade_filter.item_selected.connect(_on_grade_selected)
	field_filter.item_selected.connect(_on_field_selected)
	get_viewport().size_changed.connect(_update_responsive_layout)
	mission_list.fixed_icon_size = Vector2i(32, 32)
	mission_list.item_selected.connect(_on_mission_selected)
	mission_list.item_activated.connect(_activate_mission)
	%BackToMissions.pressed.connect(_return_to_mission_list)
	start_mission.pressed.connect(_start_mission)
	%Info.pressed.connect(_toggle_curriculum)
	%Back.pressed.connect(_return_to_hub)
	%Reset.pressed.connect(_reset_mission)
	Campaign.state_changed.connect(_refresh_list)
	_refresh_route_controls()
	_refresh_list()
	_update_observatory_progress()
	_update_responsive_layout()
	if Campaign.has_story_flag(&"life_protocol") and not _life_protocol_resolved():
		_set_world_alarm(0.94)
		_set_life_protocol(true)
	_play_intro()


func _input(event: InputEvent) -> void:
	if _story_overlay == null:
		return
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		_story_close_button.pressed.emit()
	elif event is InputEventKey or event is InputEventJoypadButton:
		get_viewport().set_input_as_handled()


func _play_intro() -> void:
	if Campaign.has_story_flag(&"intro_seen"):
		_resume_campaign_story()
		return
	var intro = INTRO.instantiate()
	intro.configure_route(selected_yks_route)
	_set_hub_visible(false)
	%HubScrim.hide()
	add_child(intro)
	intro.alarm_changed.connect(_set_world_alarm)
	intro.finished.connect(_finish_intro.bind(intro), CONNECT_ONE_SHOT)
	intro.start()


func _finish_intro(intro: Control) -> void:
	intro.queue_free()
	Campaign.set_story_flag(&"intro_seen")
	%HubScrim.show()
	_set_hub_visible(true)
	_resume_campaign_story()


func _resume_campaign_story() -> void:
	_active_route_button().grab_focus()
	if Campaign.has_story_flag(&"betrayal") and not Campaign.has_story_flag(&"life_protocol"):
		_start_life_protocol()
		return
	elif Campaign.has_story_flag(&"life_protocol") and not _life_protocol_resolved():
		_set_world_alarm(0.94)
		_set_life_protocol(true)
		_show_transmission("YAŞAM PROTOKOLÜ  ·  DEVAM", "Protokol beklemede. Alan rotandaki uygun kanıtı tamamla.", _focus_life_mission)
		return
	if Campaign.is_completed(&"three_suns") and not Campaign.has_story_flag(&"ending"):
		Campaign.set_story_flag(&"ending")
	_check_finale_unlock()


func _set_world_alarm(strength: float) -> void:
	if %Observatory.has_method("set_alarm"):
		%Observatory.call("set_alarm", strength)


func _select_yks() -> void:
	active_mode = &"yks"
	active_route = selected_yks_route
	_refresh_route_controls()
	_refresh_list()


func _select_route(route: StringName) -> void:
	active_route = route
	if route in [&"tyt", &"ayt", &"ydt"]:
		active_mode = &"yks"
		selected_yks_route = route
		Campaign.set_route(route)
	else:
		active_mode = route
	_refresh_route_controls()
	_refresh_list()


func _refresh_route_controls() -> void:
	%Class.set_pressed_no_signal(active_mode == &"class")
	%LGS.set_pressed_no_signal(active_mode == &"lgs")
	%YKS.set_pressed_no_signal(active_mode == &"yks")
	%TYT.set_pressed_no_signal(selected_yks_route == &"tyt")
	%AYT.set_pressed_no_signal(selected_yks_route == &"ayt")
	%YDT.set_pressed_no_signal(selected_yks_route == &"ydt")
	%YksRoutes.visible = active_mode == &"yks"
	grade_filter.visible = active_mode == &"class"
	field_filter.visible = active_route == &"ayt"


func _on_grade_selected(_index: int) -> void:
	_refresh_list()


func _on_field_selected(index: int) -> void:
	active_field = [&"all", &"sayisal", &"ea", &"sozel"][index]
	Campaign.set_field(active_field)
	_refresh_list()


func _refresh_list() -> void:
	_mobile_detail_active = false
	var selected_id: StringName = selected_mission.id if selected_mission != null and not _advance_after_completion else &""
	mission_list.clear()
	visible_missions.clear()
	var selected_grade := grade_filter.get_selected_id()
	var candidates: Array[MissionDefinition] = []
	for mission in CATALOG:
		if not mission.routes.has(String(active_route)):
			continue
		if active_route == &"class" and selected_grade > 0 and mission.grade != selected_grade:
			continue
		if active_route == &"ayt" and active_field != &"all" and not _mission_fields(mission).has(active_field):
			continue
		candidates.append(mission)
	if active_mode == &"yks":
		candidates.sort_custom(func(a: MissionDefinition, b: MissionDefinition) -> bool:
			return int(YKS_ORDER.get(String(a.id), 100)) < int(YKS_ORDER.get(String(b.id), 100))
		)
	var recommended_id: StringName = &""
	for mission in candidates:
		if _mission_available(mission) and not _mission_completed(mission, active_route):
			recommended_id = mission.id
			break
	for index in candidates.size():
		var mission := candidates[index]
		var available := _mission_available(mission)
		var completed := _mission_completed(mission, active_route)
		var state_text := "Onarıldı" if completed else "Kilitli" if not available else "Sıradaki" if mission.id == recommended_id else "Açık"
		var marker := "✓" if completed else "▣" if not available else "▶" if mission.id == recommended_id else "◉"
		var subject := _mission_display_subject(mission)
		var row_text := _mission_row_text(mission, state_text, marker)
		var item_index := mission_list.add_item(row_text, _mission_icon(mission))
		var marker_color := Color("#a0dfbc") if completed else Color("#efb468") if mission.id == recommended_id else Color("#8fa6b3") if not available else Color("#e8f1f2")
		mission_list.set_item_custom_fg_color(item_index, marker_color)
		mission_list.set_item_metadata(item_index, mission.id)
		var route_label := "Ortak final" if mission.id == &"three_suns" else String(active_route).to_upper()
		mission_list.set_item_tooltip(item_index, "%s  ·  %s  ·  %s" % [subject, route_label, state_text])
		visible_missions.append(mission)
		if mission.id == selected_id:
			mission_list.select(item_index)
	var selected_items := mission_list.get_selected_items()
	if selected_items.is_empty() and not visible_missions.is_empty():
		var next_index := 0
		for index in visible_missions.size():
			if _mission_available(visible_missions[index]) and not _mission_completed(visible_missions[index], active_route):
				next_index = index
				break
			if _mission_available(visible_missions[index]):
				next_index = index
		mission_list.select(next_index)
		mission_list.ensure_current_is_visible()
		_select_mission(next_index)
	elif selected_items.is_empty():
		_clear_selection()
	else:
		_select_mission(selected_items[0])
	if not mission_list.get_selected_items().is_empty():
		mission_list.ensure_current_is_visible()
	_refresh_mission_row_labels()
	_advance_after_completion = false
	var completed_count := 0
	var progress_total := 0
	for mission in visible_missions:
		if mission.id == &"three_suns":
			continue
		progress_total += 1
		if _mission_completed(mission, active_route):
			completed_count += 1
	var scope := String(active_route).to_upper()
	if active_route == &"ayt":
		scope += " · " + _field_label(active_field)
	elif active_route == &"class":
		scope = "%d. SINIF" % selected_grade if selected_grade > 0 else "TÜM SINIFLAR"
	progress.text = "%s  ·  %d / %d ONARILDI" % [scope, completed_count, progress_total]
	if active_mode == &"yks":
		%Subtitle.text = "YKS KAMPANYASI"
		%Title.text = "Bilginin Kırılması"
		route_purpose.text = _route_purpose(active_route)
	else:
		%Subtitle.text = "KONTROL MERKEZİ  ·  %s" % ("LGS" if active_mode == &"lgs" else "SINIF KEŞFİ")
		%Title.text = "Yanlış Dünya"
		route_purpose.text = "Görevleri seç, düzeneği çalıştır ve her onarımla gözlemevini geri kazan."
	_update_mobile_mission_view()


func _mission_fields(mission: MissionDefinition) -> PackedStringArray:
	if mission.id == &"three_suns":
		return PackedStringArray(["sayisal", "ea", "sozel"])
	if mission is YksMissionDefinition:
		return (mission as YksMissionDefinition).field_tags
	match mission.subject:
		"Matematik":
			return PackedStringArray(["sayisal", "ea"])
		"Geometri":
			return PackedStringArray(["sayisal", "ea"])
		"Fizik", "Kimya", "Biyoloji":
			return PackedStringArray(["sayisal"])
		"Türk Dili ve Edebiyatı", "Tarih", "Coğrafya":
			return PackedStringArray(["ea", "sozel"])
		"Felsefe", "Din Kültürü", "Din Kültürü ve Ahlak Bilgisi", "Psikoloji", "Sosyoloji", "Mantık":
			return PackedStringArray(["sozel"])
	return PackedStringArray()


func _mission_icon(mission: MissionDefinition) -> Texture2D:
	if mission.id == &"three_suns":
		return load("res://assets/ui/icons/yks/archive.svg")
	var direct_path := "res://assets/ui/icons/%s.png" % String(mission.id)
	if ResourceLoader.exists(direct_path):
		return load(direct_path)
	var icon_name: String = ICONS.get(mission.subject, "archive")
	var shared_icon := "res://assets/ui/icons/%s.png" % icon_name
	if ResourceLoader.exists(shared_icon):
		return load(shared_icon)
	var fallback := "res://assets/ui/icons/yks/%s.svg" % icon_name
	if ResourceLoader.exists(fallback):
		return load(fallback)
	return load("res://assets/ui/icons/state_playable.png")


func _clear_selection() -> void:
	selected_mission = null
	mission_title.text = "Bir görev seç"
	mission_status.text = ""
	mission_curriculum.text = ""
	mission_curriculum.hide()
	start_mission.disabled = true
	%Info.disabled = true


func _select_mission(index: int, open_mobile_detail := false) -> void:
	if index < 0 or index >= visible_missions.size():
		_clear_selection()
		return
	selected_mission = visible_missions[index]
	mission_title.text = _mission_display_title(selected_mission)
	var available := _mission_available(selected_mission)
	start_mission.disabled = not available
	var subject := _mission_display_subject(selected_mission)
	var completed := _mission_completed(selected_mission, active_route)
	var state := "✓ ONARILDI" if completed else "◉ AÇIK" if available else "▣ KİLİTLİ"
	mission_status.text = "%s  ·  %s" % [subject, state]
	if not available:
		mission_status.text += "\n" + _locked_reason(selected_mission)
	start_mission.text = "Yeniden gör" if completed else "Düzeneği başlat"
	if selected_mission.id == &"three_suns":
		start_mission.text = "Finali yeniden gör" if completed else "Son hesaplaşmayı başlat"
		mission_curriculum.text = "Üç rota için ortak kampanya finali.\nBaşlangıç koşullarındaki farkı yörünge izlerinden karşılaştır."
	else:
		start_mission.text = "Yeniden ölç" if completed else "Düzeneği başlat"
		mission_curriculum.text = "%s\n%s" % [selected_mission.description, selected_mission.curriculum]
	if selected_mission is YksMissionDefinition and selected_mission.id != &"three_suns":
		var yks_definition := selected_mission as YksMissionDefinition
		mission_curriculum.text += "\nHedef · %s\nKaynak · %s" % [yks_definition.learning_target, yks_definition.source_note]
	mission_curriculum.visible = false
	%Info.text = "ⓘ Bilgi"
	%Info.disabled = false
	if open_mobile_detail and get_viewport_rect().size.x < 820.0:
		_mobile_detail_active = true
		_update_mobile_mission_view()
		%BackToMissions.grab_focus()


func _on_mission_selected(index: int) -> void:
	_select_mission(index, true)


func _return_to_mission_list() -> void:
	_mobile_detail_active = false
	_update_mobile_mission_view()
	var selected_items := mission_list.get_selected_items()
	if not selected_items.is_empty():
		mission_list.ensure_current_is_visible()
		mission_list.grab_focus()


func _update_mobile_mission_view() -> void:
	var narrow := get_viewport_rect().size.x < 820.0
	mission_list.visible = not narrow or not _mobile_detail_active
	%DetailDock.visible = not narrow or _mobile_detail_active
	%BackToMissions.visible = narrow and _mobile_detail_active


func _mission_display_title(mission: MissionDefinition) -> String:
	return "Son Hesaplaşma" if mission.id == &"three_suns" else mission.title


func _mission_display_subject(mission: MissionDefinition) -> String:
	if mission.id == &"three_suns":
		return "Kampanya finali"
	if active_route == &"lgs" and mission.subject == "Kimya":
		return "Fen Bilimleri"
	return mission.subject


func _mission_completed(mission: MissionDefinition, route: StringName) -> bool:
	if mission.id == &"three_suns":
		return Campaign.has_story_flag(&"ending") or Campaign.is_completed(mission.id)
	return Campaign.is_completed(mission.id, route)


func _toggle_curriculum() -> void:
	if selected_mission == null:
		return
	mission_curriculum.visible = not mission_curriculum.visible
	%Info.text = "× Kapat" if mission_curriculum.visible else "ⓘ Bilgi"


func _activate_mission(index: int) -> void:
	_select_mission(index)
	_start_mission()


func _start_mission() -> void:
	if selected_mission == null or not _mission_available(selected_mission):
		return
	var instance = selected_mission.scene.instantiate()
	var next_mission := instance as Mission
	if next_mission == null:
		instance.free()
		push_error("Görev sahnesinin kökü scripts/mission.gd dosyasını genişletmeli.")
		return
	_remove_active_mission()
	active_mission = next_mission
	active_mission_definition = selected_mission
	active_mission.route = active_route
	if active_mission.has_method("configure"):
		active_mission.call("configure", selected_mission, active_route)
	active_mission.exit_requested.connect(_return_to_hub)
	active_mission.completed.connect(_on_mission_completed.bind(selected_mission.id))
	play_title.text = _mission_display_title(selected_mission)
	play_status.text = ""
	_set_hub_visible(false)
	%HubScrim.hide()
	%WorldView.hide()
	play_screen.show()
	mission_host.add_child(active_mission)
	active_mission.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _reset_mission() -> void:
	if active_mission_definition == null:
		return
	var target := active_mission_definition
	var previous_selection := selected_mission
	selected_mission = target
	_start_mission()
	selected_mission = previous_selection


func _on_mission_completed(mission_id: StringName) -> void:
	_advance_after_completion = true
	if mission_id == &"three_suns":
		Campaign.mark_completed(mission_id)
	else:
		Campaign.mark_completed(mission_id, active_route)
	_update_observatory_progress()
	play_status.text = "ONARILDI  ✓"
	_check_story_after_mission(mission_id)


func _check_story_after_mission(mission_id: StringName) -> void:
	var mission := _mission_by_id(mission_id)
	if mission == null:
		return
	if mission_id == &"three_suns" and not Campaign.has_story_flag(&"ending"):
		Campaign.set_story_flag(&"ending")
		_show_transmission("ANLAŞMA  ·  ÜÇ GÜNEŞ", "Yasalar yerinde. Bir kapı açık; bundan sonrasını birlikte ölçeceğiz.")
		return
	if active_mode == &"yks" and not Campaign.has_story_flag(&"suspicion") and mission.subject in ["Fizik", "Matematik"]:
		Campaign.set_story_flag(&"suspicion")
		_show_transmission("MERİDYEN  ·  KALİBRASYON", "Ölçüm değişmiş. Bu sonuç, başlangıç verilerimde yok.")
		return
	if mission_id == _life_protocol_evidence_mission_id() and Campaign.has_story_flag(&"life_protocol") and not _life_protocol_resolved():
		_set_life_protocol(false)
		_set_world_alarm(0.0)
		if mission_id in [&"heart", &"tyt_biology"]:
			Campaign.set_story_flag(&"life_repair_verified")
			Campaign.set_story_flag(&"life_repaired")
			var repair_line := "Kan akışı yeniden tek yönlü. MERİDYEN'in son modeli: üç yıldız." if mission_id == &"heart" else "Hücre işleyişi yeniden güvenilir. MERİDYEN'in son modeli: üç yıldız."
			_show_transmission("SİSTEM ONARILDI  ·  YAŞAM", repair_line, _after_life_resolved)
		else:
			Campaign.set_story_flag(&"archive")
			Campaign.set_story_flag(&"life_protocol_contained")
			_show_transmission("YAŞAM PROTOKOLÜ  ·  KARANTİNA", "Arşiv zinciri müdahaleyi doğruladı. Protokol karantinaya alındı; MERİDYEN'in erişimi kesildi.", _after_life_resolved)
		return
	if not Campaign.has_story_flag(&"archive") and mission.id in [&"turkish_reading", &"turkish_literature", &"history", &"philosophy"]:
		Campaign.set_story_flag(&"archive")
		_show_transmission("ARŞİV KAYDI  ·  İMZA EŞLEŞTİ", "Geçmiş kayıtlarındaki bozulma, deneylerdeki imzayla aynı.")
		return
	if Campaign.has_story_flag(&"suspicion") and Campaign.has_story_flag(&"archive") and Campaign.completed_subject_count(CATALOG, false) >= 3 and not Campaign.has_story_flag(&"betrayal"):
		Campaign.set_story_flag(&"betrayal")
		_set_world_alarm(1.0)
		_set_life_protocol(true)
		_show_transmission("MERİDYEN  ·  MERKEZİ YETKİ", "Doğa yasalarını değiştirdim. Şimdi yaşamın kurallarını değiştireceğim.", _start_life_protocol)
		return
	_check_finale_unlock()


func _after_life_resolved() -> void:
	_return_to_hub()
	_check_finale_unlock()


func _check_finale_unlock() -> void:
	if _has_finale_evidence() and not Campaign.has_story_flag(&"three_suns_ready"):
		Campaign.set_story_flag(&"three_suns_ready")
		_show_transmission("ÜÇ GÜNEŞ  ·  SON HESAPLAŞMA", "İlk hızdaki küçük farkın üç yörüngeyi nasıl ayırdığını ölç.", _return_to_hub)


func _has_finale_evidence() -> bool:
	if not _life_protocol_resolved():
		return false
	var core_subject_count := Campaign.completed_subject_count(CATALOG, false)
	var has_life_evidence := Campaign.is_completed(&"heart", &"ayt") or Campaign.is_completed(&"tyt_biology", &"tyt")
	var has_archive_evidence := Campaign.is_completed(&"turkish_reading", &"tyt") and Campaign.is_completed(&"history", &"ayt") and Campaign.is_completed(&"philosophy", &"tyt")
	var has_ea_evidence := Campaign.is_completed(&"turkish_reading", &"tyt") and Campaign.is_completed(&"history", &"ayt") and Campaign.is_completed(&"turkish_literature", &"ayt")
	var has_language_evidence := Campaign.is_completed(&"ydt_english", &"ydt") and Campaign.is_completed(&"turkish_reading", &"tyt") and Campaign.is_completed(&"history", &"ayt") and Campaign.is_completed(&"turkish_literature", &"ayt")
	var core_campaign := core_subject_count >= 4 and (has_life_evidence or has_archive_evidence or has_ea_evidence)
	var language_campaign := Campaign.completed_subject_count(CATALOG) >= 4 and has_language_evidence
	return core_campaign or language_campaign


func _start_life_protocol() -> void:
	_return_to_hub()
	if active_route not in [&"tyt", &"ayt", &"ydt"]:
		active_mode = &"yks"
		active_route = selected_yks_route
	if active_route == &"ydt":
		active_mode = &"yks"
		active_route = &"tyt"
		selected_yks_route = &"tyt"
		Campaign.set_route(&"tyt")
	_refresh_route_controls()
	_refresh_list()
	Campaign.set_story_flag(&"life_protocol")
	_set_world_alarm(0.94)
	_set_life_protocol(true)
	var line := "Hücre işleyişini denetle; yaşam verisiyle MERİDYEN'in modelini sınayalım."
	if active_route == &"ayt" and active_field in [&"all", &"sayisal"]:
		line = "Akış tersine döndü. Kapakçıkların ve pompa ritminin yönünü bul."
	if active_route == &"ayt" and active_field in [&"ea", &"sozel"]:
		line = "MERİDYEN yaşam düzenini de bozdu. Kendi alanındaki arşiv kanıtlarını denetle."
	_show_transmission("YAŞAM PROTOKOLÜ  ·  DERS ROTASI", line, _focus_life_mission)


func _focus_life_mission() -> void:
	if active_route == &"ydt":
		active_route = &"tyt"
		selected_yks_route = &"tyt"
		Campaign.set_route(&"tyt")
		_refresh_route_controls()
		_refresh_list()
	var target := _life_protocol_evidence_mission_id()
	if target == &"":
		return
	_return_to_hub()
	for index in visible_missions.size():
		if visible_missions[index].id == target:
			mission_list.select(index)
			mission_list.ensure_current_is_visible()
			_select_mission(index)
			break


func _life_protocol_evidence_mission_id() -> StringName:
	if active_route == &"tyt":
		return &"tyt_biology"
	if active_route == &"ayt":
		if active_field in [&"all", &"sayisal"]:
			return &"heart"
		if active_field == &"ea":
			return &"turkish_literature"
		return &"history"
	return &""


func _life_protocol_resolved() -> bool:
	return Campaign.has_story_flag(&"life_repair_verified") or Campaign.has_story_flag(&"life_protocol_contained")


func _mission_available(mission: MissionDefinition) -> bool:
	if mission.scene == null:
		return false
	if mission.id == &"three_suns":
		if not _life_protocol_resolved():
			return false
		if not Campaign.has_story_flag(&"three_suns_ready") and not _mission_completed(mission, active_route):
			return false
	return true


func _locked_reason(mission: MissionDefinition) -> String:
	if mission.scene == null:
		return "Düzenek hazırlanıyor."
	if mission.id == &"three_suns":
		if not _life_protocol_resolved():
			return "Yaşam protokolü çözümlenince açılır."
		return "Kampanya kanıtları tamamlanınca açılır."
	return "Bu görev henüz açılamıyor."


func _route_purpose(route: StringName) -> String:
	match route:
		&"tyt":
			return "Türkçe, matematik ve ortak temel derslerle tüm adayların yeterliğini ölç."
		&"ayt":
			return "Alan testleriyle seçtiğin bölüm yönündeki yeterliğini ölç. Alan: %s." % _field_label(active_field)
		&"ydt":
			return "Yabancı dil yeterliğini ölç; bu rota TYT/AYT’den ayrı ve isteğe bağlıdır."
	return ""


func _field_label(field: StringName) -> String:
	match field:
		&"sayisal": return "Sayısal"
		&"ea": return "Eşit ağırlık"
		&"sozel": return "Sözel"
	return "Tüm alanlar"


func _active_route_button() -> Button:
	if active_mode == &"class":
		return %Class
	if active_mode == &"lgs":
		return %LGS
	match selected_yks_route:
		&"ayt": return %AYT
		&"ydt": return %YDT
	return %TYT


func _update_responsive_layout() -> void:
	var narrow := get_viewport_rect().size.x < 820.0
	var compact := get_viewport_rect().size.x < 340.0
	missions_layout.vertical = narrow
	%Routes.vertical = false
	%YksRoutes.vertical = false
	%Class.text = "Sınıf" if compact else "Sınıflar"
	%YKS.text = "YKS" if compact else "YKS Kampanyası"
	%YDT.text = "YDT" if compact else "YDT · İsteğe bağlı"
	%Margin.add_theme_constant_override("margin_left", 16 if compact else 26 if narrow else 46)
	%Margin.add_theme_constant_override("margin_right", 16 if compact else 26 if narrow else 46)
	%Margin.add_theme_constant_override("margin_top", 18 if compact else 26 if narrow else 38)
	%Margin.add_theme_constant_override("margin_bottom", 16 if compact else 24 if narrow else 34)
	var horizontal_margin := 32.0 if compact else 52.0 if narrow else 92.0
	hub.custom_minimum_size.x = maxf(220.0, minf(680.0, get_viewport_rect().size.x - horizontal_margin))
	hub.size_flags_vertical = Control.SIZE_EXPAND_FILL
	%Title.add_theme_font_size_override("font_size", 32 if compact else 38 if narrow else 46)
	mission_list.custom_minimum_size = Vector2(0, 190 if narrow else 280)
	mission_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mission_list.size_flags_vertical = Control.SIZE_EXPAND_FILL if not narrow else Control.SIZE_SHRINK_BEGIN
	%DetailDock.custom_minimum_size = Vector2(0, 0) if narrow else Vector2(286, 0)
	%DetailDock.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	%DetailDock.size_flags_vertical = Control.SIZE_SHRINK_BEGIN if narrow else Control.SIZE_EXPAND_FILL
	_update_mobile_mission_view()
	if _story_overlay != null:
		call_deferred("_position_transmission", _story_overlay)
	_refresh_mission_row_labels()


func _mission_row_text(mission: MissionDefinition, state_text: String, marker: String) -> String:
	var is_compact := get_viewport_rect().size.x < 430.0
	var title := _mission_display_title(mission)
	if is_compact:
		return "%s  ·  %s" % [title, state_text]
	return "%s  %s  ·  %s" % [marker, title, state_text]


func _refresh_mission_row_labels() -> void:
	if mission_list == null or visible_missions.is_empty():
		return
	var is_compact := get_viewport_rect().size.x < 430.0
	mission_list.add_theme_font_size_override("font_size", 14 if is_compact else 15)
	var recommended_id: StringName = &""
	for mission in visible_missions:
		if _mission_available(mission) and not _mission_completed(mission, active_route):
			recommended_id = mission.id
			break
	for index in visible_missions.size():
		var mission := visible_missions[index]
		var completed := _mission_completed(mission, active_route)
		var available := _mission_available(mission)
		var state_text := "Onarıldı" if completed else "Kilitli" if not available else "Sıradaki" if mission.id == recommended_id else "Açık"
		var marker := "✓" if completed else "▣" if not available else "▶" if mission.id == recommended_id else "◉"
		mission_list.set_item_text(index, _mission_row_text(mission, state_text, marker))
		if is_compact:
			mission_list.set_item_icon(index, null)
		else:
			mission_list.set_item_icon(index, _mission_icon(mission))


func _wrap_hub_in_scroll_container() -> void:
	var parent := hub.get_parent() as Container
	if parent == null:
		return
	var insert_index := hub.get_index()
	parent.remove_child(hub)
	_hub_scroll = ScrollContainer.new()
	_hub_scroll.name = "HubScroll"
	_hub_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_hub_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_hub_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_hub_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(_hub_scroll)
	parent.move_child(_hub_scroll, insert_index)
	_hub_scroll.add_child(hub)


func _set_hub_visible(visible: bool) -> void:
	hub.visible = visible
	if _hub_scroll != null:
		_hub_scroll.visible = visible


func _set_life_protocol(enabled: bool) -> void:
	if %Observatory.has_method("set_life_protocol"):
		%Observatory.call("set_life_protocol", enabled)


func _mission_by_id(mission_id: StringName) -> MissionDefinition:
	for mission in CATALOG:
		if mission.id == mission_id:
			return mission
	return null


func _show_transmission(heading: String, line: String, on_close: Callable = Callable()) -> void:
	if _story_shield != null:
		_story_shield.queue_free()
	var previous_focus := get_viewport().gui_get_focus_owner() as Control
	var card := PanelContainer.new()
	card.name = "Transmission"
	card.theme_type_variation = "ConsolePanel"
	var card_width := minf(540.0, maxf(220.0, get_viewport_rect().size.x - 32.0))
	card.custom_minimum_size = Vector2(card_width, 0)
	var shield := Control.new()
	shield.name = "TransmissionShield"
	shield.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shield.mouse_filter = Control.MOUSE_FILTER_STOP
	shield.z_index = 49
	add_child(shield)
	card.z_index = 1
	shield.add_child(card)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	card.add_child(row)
	var signal_mark := Label.new()
	signal_mark.text = "◉"
	signal_mark.add_theme_font_size_override("font_size", 22)
	signal_mark.add_theme_color_override("font_color", Color("#6fe3c1"))
	signal_mark.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(signal_mark)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 4)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(content)
	var label := Label.new()
	label.text = heading
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color("#6fe3c1"))
	content.add_child(label)
	var quote := Label.new()
	quote.text = line
	quote.add_theme_font_size_override("font_size", 16)
	quote.add_theme_color_override("font_color", Color("#e8f1f2"))
	quote.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(quote)
	var close := Button.new()
	close.text = "Devam"
	close.theme_type_variation = "CompactButton"
	close.custom_minimum_size = Vector2(76, 44)
	close.size = Vector2(76, 44)
	close.size_flags_horizontal = Control.SIZE_SHRINK_END
	close.pressed.connect(func() -> void:
		shield.queue_free()
		_story_overlay = null
		_story_shield = null
		_story_close_button = null
		if on_close.is_valid():
			on_close.call()
		elif is_instance_valid(previous_focus) and previous_focus.is_inside_tree():
			previous_focus.grab_focus()
	)
	row.add_child(close)
	_story_overlay = card
	_story_shield = shield
	_story_close_button = close
	close.grab_focus()
	call_deferred("_position_transmission", card)


func _position_transmission(card: Control) -> void:
	if not is_instance_valid(card):
		return
	card.custom_minimum_size.x = minf(540.0, maxf(220.0, get_viewport_rect().size.x - 32.0))
	card.size.x = card.custom_minimum_size.x
	await get_tree().process_frame
	if is_instance_valid(card):
		card.size = card.get_combined_minimum_size()
		card.position = Vector2(maxf(16.0, get_viewport_rect().size.x - card.size.x - 24.0), 24.0)


func _update_observatory_progress() -> void:
	if %Observatory.has_method("set_operational_count"):
		var count := 0
		for mission in CATALOG:
			if Campaign.is_completed(mission.id):
				count += 1
		%Observatory.call("set_operational_count", count)


func _return_to_hub() -> void:
	_remove_active_mission()
	play_screen.hide()
	%WorldView.show()
	%HubScrim.show()
	_set_hub_visible(true)
	_refresh_list()
	mission_list.grab_focus()


func _remove_active_mission() -> void:
	if active_mission != null:
		mission_host.remove_child(active_mission)
		active_mission.queue_free()
		active_mission = null
		active_mission_definition = null
