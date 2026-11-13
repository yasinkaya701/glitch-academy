extends Control

const Mission = preload("res://scripts/mission.gd")
const MissionDefinition = preload("res://scripts/mission_definition.gd")
const INTRO = preload("res://scenes/intro/intro.tscn")
const MERIDYEN_PORTRAIT = preload("res://assets/characters/meridyen/meridyen_ai_concept.png")
const CATALOG: Array[MissionDefinition] = [
	preload("res://stations/seasons/mission.tres"),
	preload("res://stations/bridge/mission.tres"),
	preload("res://stations/turkish/mission.tres"),
	preload("res://stations/history/mission.tres"),
	preload("res://stations/philosophy/mission.tres"),
	preload("res://stations/english/mission.tres"),
	preload("res://stations/religion/mission.tres"),
	preload("res://stations/measurement/mission.tres"),
	preload("res://stations/vectors/mission.tres"),
	preload("res://stations/derivative/mission.tres"),
	preload("res://stations/prism/mission.tres"),
	preload("res://stations/free_fall/mission.tres"),
	preload("res://stations/photoelectric/mission.tres"),
	preload("res://stations/waves/mission.tres"),
	preload("res://stations/indicator/mission.tres"),
	preload("res://stations/heart/mission.tres"),
	preload("res://stations/pressure/mission.tres"),
	preload("res://stations/pulley/mission.tres"),
]

const LGS_IDS: Array[StringName] = [&"seasons", &"bridge", &"pulley", &"turkish", &"history", &"english", &"religion"]
const PROGRESS_PATH := "user://lgs_campaign.cfg"
var progress_path := PROGRESS_PATH
const CAMPAIGN_CARDS := {
	"seasons": {"subject": "Fen Bilimleri", "action": "Mevsim sistemini gözlemle", "icon": "seasons"},
	"bridge": {"subject": "Matematik", "action": "Yapay zekânın özdeşlik ispatını düzelt", "icon": "proof"},
	"pulley": {"subject": "Fen Bilimleri", "action": "Palanga düzeneğindeki ivme hatasını düzelt", "icon": "lgs_pulley"},
	"turkish": {"subject": "Türkçe", "action": "Güvenlik komutunu düzelt", "icon": "lgs_turkish"},
	"history": {"subject": "T.C. İnkılap Tarihi", "action": "Belgeleri kronolojiye yerleştir", "icon": "lgs_history"},
	"english": {"subject": "İngilizce", "action": "Yardım mesajlarını çöz", "icon": "lgs_english"},
	"religion": {"subject": "Din Kültürü ve Ahlak Bilgisi", "action": "Dayanışma kayıtlarını eşleştir", "icon": "lgs_religion"},
}

@onready var hub: Control = %Hub
@onready var grade_filter: OptionButton = %GradeFilter
@onready var mission_list: ItemList = %MissionList
@onready var legacy_missions: Control = %Missions
@onready var campaign_view: Control = %CampaignView
@onready var campaign_grid: GridContainer = %CampaignGrid
@onready var campaign_progress: Label = %CampaignProgress
@onready var campaign_bar: ProgressBar = %CampaignBar
@onready var campaign_prompt: Label = %CampaignPrompt
@onready var campaign_hint: Label = %CampaignHint
@onready var campaign_start: Button = %CampaignStart
@onready var mission_title: Label = %MissionTitle
@onready var mission_description: Label = %MissionDescription
@onready var mission_status: Label = %MissionStatus
@onready var start_mission: Button = %StartMission
@onready var progress: Label = %Progress
@onready var play_screen: Control = %PlayScreen
@onready var play_title: Label = %PlayTitle
@onready var play_status: Label = %PlayStatus
@onready var mission_host: Control = %MissionHost

var active_route: StringName = &"lgs"
var selected_mission: MissionDefinition
var active_mission: Mission
var visible_missions: Array[MissionDefinition] = []
var completed_ids: Dictionary[StringName, bool] = {}
var story_pending := ""
var meridyen_portrait: TextureRect
var meridyen_idle_tween: Tween
var meridyen_entrance_tween: Tween


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
	campaign_start.pressed.connect(_start_mission)
	%Back.pressed.connect(_return_to_hub)
	%Reset.pressed.connect(_start_mission)
	%ContinueStory.pressed.connect(_continue_story)
	%CloseFinale.pressed.connect(_close_finale)
	_build_meridyen_portrait()
	_load_progress()
	_select_route(&"lgs")
	_update_observatory_progress()
	_play_intro()


func _play_intro() -> void:
	var intro: Control = INTRO.instantiate()
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
	campaign_start.grab_focus()


func _set_world_alarm(strength: float) -> void:
	if %Observatory.has_method("set_alarm"):
		%Observatory.call("set_alarm", strength)


func _select_route(route: StringName) -> void:
	active_route = route
	grade_filter.visible = route == &"class"
	campaign_view.visible = route == &"lgs"
	legacy_missions.visible = route != &"lgs"
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
		if active_route == &"lgs" and not LGS_IDS.has(mission.id):
			continue
		var subject := "Fen Bilimleri" if active_route == &"lgs" and mission.subject == "Kimya" else mission.subject
		var index := mission_list.add_item("%s  ·  %s" % [mission.title, subject])
		mission_list.set_item_metadata(index, mission.id)
		var icon_path := _mission_icon_path(mission.id)
		if not icon_path.is_empty() and ResourceLoader.exists(icon_path):
			mission_list.set_item_icon(index, load(icon_path))
		visible_missions.append(mission)
		if mission.id == selected_id:
			mission_list.select(index)
	var selected_items := mission_list.get_selected_items()
	if selected_items.is_empty() and not visible_missions.is_empty():
		mission_list.select(0)
		_select_mission(0)
	elif selected_items.is_empty():
		_clear_selection()
	else:
		_select_mission(selected_items[0])
	if active_route == &"lgs":
		_refresh_campaign()
	else:
		progress.text = "Onarılan görevler  %d / %d" % [completed_ids.size(), CATALOG.size()]


func _mission_icon_path(mission_id: StringName) -> String:
	var icon_names := {
		&"seasons": "seasons.png",
		&"bridge": "proof.svg",
		&"pulley": "pulley.svg",
		&"turkish": "lgs_turkish.svg",
		&"history": "lgs_history.svg",
		&"english": "lgs_english.svg",
		&"religion": "lgs_religion.svg",
		&"measurement": "measurement.png",
		&"vectors": "vectors.png",
		&"derivative": "derivative.svg",
		&"prism": "prism.png",
		&"free_fall": "free_fall.png",
		&"photoelectric": "photoelectric.svg",
		&"waves": "waves.svg",
		&"indicator": "indicator.png",
		&"heart": "heart.png",
		&"pressure": "pressure.png",
	}
	if not icon_names.has(mission_id):
		return ""
	return "res://assets/ui/icons/%s" % icon_names[mission_id]


func _refresh_campaign() -> void:
	for child in campaign_grid.get_children():
		campaign_grid.remove_child(child)
		child.queue_free()
	var repaired := 0
	for mission_id in LGS_IDS:
		if completed_ids.has(mission_id):
			repaired += 1
	campaign_progress.text = "%d / %d görev onarıldı" % [repaired, LGS_IDS.size()]
	campaign_bar.value = repaired * 100.0 / float(LGS_IDS.size())
	for mission_index in LGS_IDS.size():
		var mission_id := LGS_IDS[mission_index]
		var definition := _definition_for(mission_id)
		var card_data: Dictionary = CAMPAIGN_CARDS[String(mission_id)]
		var is_done := completed_ids.has(mission_id)
		var is_locked := not _is_unlocked(mission_id)
		var state := "Onarıldı" if is_done else ("Kilitli" if is_locked else "Açık")
		var card := Button.new()
		card.custom_minimum_size = Vector2(328, 120)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.focus_mode = Control.FOCUS_ALL
		card.tooltip_text = "%s. %s. %s" % [card_data.subject, definition.title, card_data.action]
		for color_name in ["font_color", "font_hover_color", "font_pressed_color", "font_disabled_color", "font_focus_color"]:
			card.add_theme_color_override(color_name, Color(0, 0, 0, 0))
		var icon_extension := ".svg" if String(card_data.icon).begins_with("lgs_") else ".png"
		var icon_path := "res://assets/ui/icons/%s%s" % [card_data.icon, icon_extension]
		card.disabled = is_locked
		var card_fill := Color("#132235") if not is_done else Color("#122820")
		var card_edge := Color("#3a576f") if not is_done else Color("#477961")
		if is_locked:
			card_fill = Color("#101a27")
			card_edge = Color("#293846")
		card.add_theme_stylebox_override("normal", _campaign_card_style(card_fill, card_edge))
		card.add_theme_stylebox_override("hover", _campaign_card_style(Color("#1c3046"), Color("#75d9c5")))
		card.add_theme_stylebox_override("pressed", _campaign_card_style(Color("#203a4e"), Color("#e7b76b")))
		card.add_theme_stylebox_override("disabled", _campaign_card_style(Color("#101a27"), Color("#293846")))
		card.add_theme_stylebox_override("focus", _campaign_card_style(Color("#1c3046"), Color("#75d9c5")))
		var content := HBoxContainer.new()
		content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		content.offset_left = 13
		content.offset_top = 10
		content.offset_right = -13
		content.offset_bottom = -10
		content.add_theme_constant_override("separation", 12)
		content.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(content)
		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(38, 38)
		icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if ResourceLoader.exists(icon_path):
			icon.texture = load(icon_path)
		content.add_child(icon)
		var copy := VBoxContainer.new()
		copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		copy.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		copy.add_theme_constant_override("separation", 2)
		copy.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content.add_child(copy)
		var eyebrow := Label.new()
		eyebrow.text = "%02d  ·  %s" % [mission_index + 1, state]
		eyebrow.theme_type_variation = &"SectionLabel"
		eyebrow.add_theme_font_size_override("font_size", 13)
		if is_done:
			eyebrow.add_theme_color_override("font_color", Color("#a0dfbc"))
		elif is_locked:
			eyebrow.add_theme_color_override("font_color", Color("#748795"))
		copy.add_child(eyebrow)
		var subject := Label.new()
		subject.text = card_data.subject
		subject.add_theme_font_size_override("font_size", 14)
		subject.add_theme_color_override("font_color", Color("#8fa6b3"))
		if is_locked:
			subject.add_theme_color_override("font_color", Color("#748795"))
		copy.add_child(subject)
		var title := Label.new()
		title.text = definition.title
		title.add_theme_font_size_override("font_size", 19)
		title.theme_type_variation = &"HeadlineLabel"
		title.add_theme_color_override("font_color", Color("#e8f1f2") if not is_locked else Color("#91a0ab"))
		copy.add_child(title)
		var action := Label.new()
		action.text = card_data.action
		action.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		action.add_theme_font_size_override("font_size", 14)
		action.add_theme_color_override("font_color", Color("#8fa6b3"))
		copy.add_child(action)
		if is_done:
			card.add_theme_color_override("font_color", Color("#a0dfbc"))
		elif is_locked:
			card.add_theme_color_override("font_color", Color("#748795"))
		else:
			card.add_theme_color_override("font_color", Color("#e8f1f2"))
		card.pressed.connect(_select_campaign_mission.bind(mission_id))
		campaign_grid.add_child(card)
		if selected_mission != null and selected_mission.id == mission_id and not is_locked:
			card.grab_focus()
	if selected_mission != null and LGS_IDS.has(selected_mission.id):
		var selected_locked := not _is_unlocked(selected_mission.id)
		campaign_prompt.text = selected_mission.description
		campaign_hint.text = "İstasyon  ·  %s" % CAMPAIGN_CARDS[String(selected_mission.id)].subject
		campaign_start.text = "Bölümü başlat  →"
		campaign_start.disabled = selected_locked or selected_mission.scene == null
		if selected_mission.id == &"seasons" and not completed_ids.has(&"seasons"):
			campaign_prompt.text = "Mevsim Gözlemevi'ni kontrol et."
			campaign_start.text = "Deneyi başlat  →"
	else:
		campaign_start.disabled = true


func _select_campaign_mission(mission_id: StringName) -> void:
	var definition := _definition_for(mission_id)
	if definition == null or not _is_unlocked(mission_id):
		return
	selected_mission = definition
	_refresh_campaign()


func _definition_for(mission_id: StringName) -> MissionDefinition:
	for definition in CATALOG:
		if definition.id == mission_id:
			return definition
	return null


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
	if active_route == &"lgs" and not _is_unlocked(selected_mission.id):
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
	_save_progress()
	_update_observatory_progress()
	play_status.text = "Onarıldı"
	if active_route == &"lgs":
		story_pending = _story_for(mission_id)
		%StoryEyebrow.text = "SİNYAL %02d / %02d  ·  DOĞRULANDI" % [LGS_IDS.find(mission_id) + 1, LGS_IDS.size()]
		%StoryText.text = story_pending
		%StoryBeat.show()
		_set_meridyen_portrait(story_pending.contains("MERİDYEN:"))


func _build_meridyen_portrait() -> void:
	var story_content: VBoxContainer = %StoryBeat.get_node("StoryContent")
	meridyen_portrait = TextureRect.new()
	meridyen_portrait.name = "MeridyenPortrait"
	meridyen_portrait.texture = MERIDYEN_PORTRAIT
	meridyen_portrait.custom_minimum_size = Vector2(176, 160)
	meridyen_portrait.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	meridyen_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	meridyen_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	meridyen_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	meridyen_portrait.hide()
	story_content.add_child(meridyen_portrait)
	story_content.move_child(meridyen_portrait, 0)


func _set_meridyen_portrait(visible: bool) -> void:
	if meridyen_idle_tween and meridyen_idle_tween.is_running():
		meridyen_idle_tween.kill()
	if meridyen_entrance_tween and meridyen_entrance_tween.is_running():
		meridyen_entrance_tween.kill()
	meridyen_portrait.visible = visible
	if not visible:
		return
	meridyen_portrait.pivot_offset = meridyen_portrait.custom_minimum_size * 0.5
	meridyen_portrait.modulate = Color(1.0, 0.52, 0.46, 0.0)
	meridyen_portrait.scale = Vector2(0.82, 0.82)
	meridyen_portrait.rotation = deg_to_rad(-7.0)
	meridyen_entrance_tween = create_tween()
	meridyen_entrance_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	meridyen_entrance_tween.tween_property(meridyen_portrait, "modulate", Color(1.0, 0.52, 0.46, 0.92), 0.12)
	meridyen_entrance_tween.parallel().tween_property(meridyen_portrait, "scale", Vector2.ONE, 0.28)
	meridyen_entrance_tween.tween_property(meridyen_portrait, "modulate", Color.WHITE, 0.16)
	meridyen_entrance_tween.tween_property(meridyen_portrait, "rotation", deg_to_rad(3.0), 0.09)
	meridyen_entrance_tween.tween_property(meridyen_portrait, "rotation", deg_to_rad(-1.5), 0.08)
	meridyen_entrance_tween.tween_property(meridyen_portrait, "rotation", 0.0, 0.12)
	meridyen_entrance_tween.tween_callback(_start_meridyen_idle)


func _start_meridyen_idle() -> void:
	if not is_instance_valid(meridyen_portrait) or not meridyen_portrait.visible:
		return
	meridyen_idle_tween = create_tween().set_loops()
	meridyen_idle_tween.tween_property(meridyen_portrait, "rotation", deg_to_rad(1.2), 0.8).set_trans(Tween.TRANS_SINE)
	meridyen_idle_tween.tween_property(meridyen_portrait, "rotation", deg_to_rad(-1.2), 0.9).set_trans(Tween.TRANS_SINE)
	meridyen_idle_tween.tween_property(meridyen_portrait, "rotation", 0.0, 0.6).set_trans(Tween.TRANS_SINE)


func _continue_story() -> void:
	_set_meridyen_portrait(false)
	%StoryBeat.hide()
	_remove_active_mission()
	play_screen.hide()
	%WorldView.show()
	%HubScrim.show()
	hub.show()
	_refresh_list()
	if _lgs_complete():
		%Finale.show()
		return
	for mission_id in LGS_IDS:
		if _is_unlocked(mission_id) and not completed_ids.has(mission_id):
			_select_campaign_mission(mission_id)
			break
	story_pending = ""


func _return_to_hub() -> void:
	if active_route == &"lgs" and _lgs_complete():
		%Finale.show()
		return
	_remove_active_mission()
	play_screen.hide()
	%WorldView.show()
	%HubScrim.show()
	hub.show()
	_refresh_list()
	_set_meridyen_portrait(false)
	%StoryBeat.hide()


func _close_finale() -> void:
	%Finale.hide()
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


func _is_unlocked(mission_id: StringName) -> bool:
	if mission_id == &"seasons":
		return true
	if mission_id == &"bridge":
		return completed_ids.has(&"seasons")
	if mission_id == &"pulley":
		return completed_ids.has(&"bridge")
	if mission_id == &"turkish":
		return completed_ids.has(&"bridge")
	if mission_id == &"history":
		return completed_ids.has(&"bridge") and completed_ids.has(&"turkish")
	if mission_id == &"english":
		return completed_ids.has(&"turkish")
	if mission_id == &"religion":
		return completed_ids.has(&"history") or completed_ids.has(&"english")
	return true


func _lgs_complete() -> bool:
	for mission_id in LGS_IDS:
		if not completed_ids.has(mission_id):
			return false
	return true


func _story_for(mission_id: StringName) -> String:
	match mission_id:
		&"seasons":
			return "Seranın ışıkları düzeldi. Matematik laboratuvarındaki ispat kaydı bozuldu.\n\nMERİDYEN: “Bir sistemi düzelttin. Şimdi kendi ispatıma bak.”"
		&"bridge":
			return "Köprü yeniden açıldı. Yakındaki vinç yükü yanlış ivmeyle kaldırıyor. MERİDYEN hareket kayıtlarındaki ivmeleri ters çevirmiş."
		&"pulley":
			return "Vinç yeniden çalıştı. İvme kayıtlarının içinden değiştirilmiş güvenlik talimatının koordinatları çıktı. Harita Türkçe istasyonuna yöneliyor."
		&"turkish":
			return "Onarılan güvenlik komutunda geçmiş kaydın koordinatları belirdi. Harita tarih arşivine yöneliyor.\n\nMERİDYEN: “O kayıt artık gerekli değil.”"
		&"history":
			return "Arşivdeki tarihli belgeler eşleşti; MERİDYEN'in imzası kayıtlarda bulundu. Kontrol hattı gerçeklik çapasına uzanıyor.\n\nMERİDYEN: “Düzeni korumak için kontrolü geri almalıyım.”"
		&"english":
			return "Yardım istasyonunun kısa mesajları çözüldü. Kaynak imzası, gerçeklik çapasının kontrol hattına bağlandığını gösteriyor.\n\nMERİDYEN: “Düzeni korumak için kontrolü geri almalıyım.”"
		&"religion":
			return "Yardımlaşma kayıtları yeniden doğrulandı. Yerleşim birlikte hareket ediyor; yedi görevin onarım kaydı merkezde."
	return ""


func _save_progress() -> void:
	var config := ConfigFile.new()
	for mission_id in completed_ids.keys():
		config.set_value("campaign", String(mission_id), true)
	config.save(progress_path)


func _load_progress() -> void:
	var config := ConfigFile.new()
	if config.load(progress_path) != OK:
		return
	for mission_id in LGS_IDS:
		if config.get_value("campaign", String(mission_id), false):
			completed_ids[mission_id] = true


func _update_observatory_progress() -> void:
	var repaired := 0
	for mission_id in LGS_IDS:
		if completed_ids.has(mission_id):
			repaired += 1
	if %Observatory.has_method("set_operational_count"):
		%Observatory.call("set_operational_count", repaired)


func _campaign_card_style(fill: Color, edge: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = edge
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.content_margin_left = 15
	style.content_margin_top = 11
	style.content_margin_right = 15
	style.content_margin_bottom = 11
	style.anti_aliasing = true
	return style
