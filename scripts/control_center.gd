extends Control

const Mission = preload("res://scripts/mission.gd")
const MissionDefinition = preload("res://scripts/mission_definition.gd")
const StoryDialogue = preload("res://scripts/story_dialogue.gd")
const FINALE = preload("res://stations/yks/three_suns.tscn")
const INTRO = preload("res://scenes/intro/intro.tscn")
const CATALOG: Array[MissionDefinition] = [
	preload("res://stations/seasons/mission.tres"),
	preload("res://stations/measurement/mission.tres"),
	preload("res://stations/vectors/mission.tres"),
	preload("res://stations/derivative/mission.tres"),
	preload("res://stations/bridge/mission.tres"),
	preload("res://stations/prism/mission.tres"),
	preload("res://stations/free_fall/mission.tres"),
	# YKS düzeyinde fizik; sınav sırası korunur, Sınıflar keşfinde oynanır.
	preload("res://stations/newton/mission.tres"),
	preload("res://stations/projectile/mission.tres"),
	preload("res://stations/collision/mission.tres"),
	preload("res://stations/indicator/mission.tres"),
	preload("res://stations/heart/mission.tres"),
	preload("res://stations/spin/mission.tres"),
	preload("res://stations/pressure/mission.tres"),
	preload("res://stations/philosophy/mission.tres"),
	preload("res://stations/history/mission.tres"),
	# LGS: bütün ders görevleri ve basit makine düzeneği.
	preload("res://stations/pulley/mission.tres"),
	preload("res://stations/turkish/mission.tres"),
	preload("res://stations/english/mission.tres"),
	preload("res://stations/religion/mission.tres"),
	preload("res://stations/genetics/mission.tres"),
]

@onready var hub: Control = %Hub
@onready var mission_columns: BoxContainer = %Missions
@onready var grade_filter: OptionButton = %GradeFilter
@onready var mission_list: ItemList = %MissionList
@onready var mission_title: Label = %MissionTitle
@onready var mission_description: Label = %MissionDescription
@onready var mission_status: Label = %MissionStatus
@onready var mission_modes: HBoxContainer = %MissionModes
@onready var start_mission: Button = %StartMission
@onready var progress: Label = %Progress
@onready var route_progress_bar: ProgressBar = %RouteProgress
@onready var play_screen: Control = %PlayScreen
@onready var play_title: Label = %PlayTitle
@onready var play_status: Label = %PlayStatus
@onready var mission_host: Control = %MissionHost

var active_route: StringName = &"tyt"
var selected_mission: MissionDefinition
var active_mission: Mission
var visible_missions: Array[MissionDefinition] = []
var completed_ids: Dictionary[StringName, bool] = {}
var story_dialogue: StoryDialogue
var finale_button: Button
var _playing_finale := false
var _completion_pending := false
var _last_campaign_mission: StringName

const RECORDS := {
	"seasons": "Işık açısı değişince seranın tepkisi de değişti. Uzaklık kaydım aynı şeyi açıklamıyordu.",
	"measurement": "Sayı aynıydı; birimi farklıydı. Arşiv taşıyıcısı şimdi doğru parçayı kabul ediyor.",
	"vectors": "Yönü kayıttan silmiştim. Kapsülün yanaşması için uzunluk tek başına yetmiyor.",
	"derivative": "Kutunun hacmi, kesik büyüdükçe hep artmıyor. Tepe noktasını ölçümle buldun.",
	"bridge": "Eksik uzunluk tamamlandı. Köprünün kapanması, hesabın sahnedeki karşılığı oldu.",
	"prism": "Katmanları tek tek hesaba kattın. Kasa artık ne eksik ne fazla doluyor.",
	"free_fall": "Kütleyi ve havayı ayırdın. Süre farkının kaynağı kalan ölçümde ortaya çıktı.",
	"newton": "İtiş aynı olsa da yük değişince ivme değişiyor. Kızak kaydını düzelttin.",
	"projectile": "Yatay hareket düşme süresini değiştirmedi. İki hareketi ayrı izleyince hedef bulundu.",
	"collision": "Hareketi yalnız büyüklükle kaydetmek yanlıştı. Yönü geri koyunca toplam korundu.",
	"indicator": "Gösterge rengi tekrar çözeltiyle uyuşuyor. Rengi tek başına bir açıklama saymadın.",
	"heart": "Kapakların yönü düzeldi; akış döngüsü kapandı. Yaşam protokolü artık geri kaçak üretmiyor.",
	"pressure": "Derinliği ve sıvıyı ayrı değiştirdin. Hedef basınca hangi koşulda ulaşıldığı belli.",
	"philosophy": "Kaydı, düşüncenin gerekçesiyle eşleştirdin. Bir iddia tekrar edildiği için doğru olmuyor.",
	"history": "Belgeleri tarihleri ve bağlamlarıyla doğruladın. Arşivin sırası yeniden kuruluyor.",
	"pulley": "Kuvvet azalırken çekilen yol arttı. Kaydımdan sildiğim ip kolunu geri koydun.",
	"turkish": "Tek bir olumsuzluk eki güvenlik talimatını tersine çevirmişti. Çıkış yolu yeniden açık.",
	"english": "İsteği ve uyarıyı ayırdın. Yardım mesajı şimdi doğru ekibe ulaşıyor.",
	"religion": "Yardım kaydını gösterişe değil açık ihtiyaca bağladın. Destek doğru yere gidiyor.",
	"genetics": "Çekinik özellik görünmese de alel kaybolmuyor. Sildiğim kayıt çaprazlamada yeniden ortaya çıktı."
}


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
	%Reset.pressed.connect(_retry_current)
	_build_story_controls()
	for definition in CATALOG:
		if Campaign.is_completed(definition.id): completed_ids[definition.id] = true
	%Class.text = "Serbest keşif"
	_select_route(&"tyt")
	resized.connect(_layout)
	_layout()
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
	%TYT.grab_focus()


func _set_world_alarm(strength: float) -> void:
	if %Observatory.has_method("set_alarm"):
		%Observatory.call("set_alarm", strength)


func _select_route(route: StringName) -> void:
	active_route = route
	selected_mission = null
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
		var subject := mission.subject
		if active_route == &"lgs":
			if mission.subject == "Kimya":
				subject = "Fen Bilimleri"
			elif mission.subject == "Tarih":
				subject = "İnkılap Tarihi"
		var prefix := ""
		if active_route != &"class":
			prefix = "%02d  " % (visible_missions.size() + 1)
		var suffix := "  ✓" if _is_completed(mission.id) else ""
		var index := mission_list.add_item("%s%s · %s%s" % [prefix, mission.title, subject, suffix])
		if not _is_unlocked(mission.id):
			mission_list.set_item_custom_fg_color(index, UITheme.MUTED)
			mission_list.set_item_tooltip(index, "Önce önceki düzeneğin onarımını tamamla.")
		mission_list.set_item_metadata(index, mission.id)
		visible_missions.append(mission)
		if mission.id == selected_id:
			mission_list.select(index)
	var selected_items := mission_list.get_selected_items()
	if selected_items.is_empty():
		if not visible_missions.is_empty():
			var next_index := 0
			for index in visible_missions.size():
				if not _is_completed(visible_missions[index].id):
					next_index = index
					break
			mission_list.select(next_index)
			_select_mission(next_index)
		else:
			_clear_selection()
	else:
		_select_mission(selected_items[0])
	var route_missions := _route_missions()
	var route_total := route_missions.size()
	var repaired := _route_completed_count()
	route_progress_bar.max_value = maxi(route_total, 1)
	route_progress_bar.value = repaired
	if active_route == &"class":
		progress.text = "SERBEST KEŞİF   ·   %d / %d görev tamamlandı" % [repaired, route_total]
	elif repaired >= route_total:
		progress.text = "ROTA TAMAMLANDI   ·   %d / %d   ·   Üç Güneş son ölçüm" % [repaired, route_total]
	else:
		var next_step := route_missions[repaired].title if repaired < route_missions.size() else "Üç Güneş"
		progress.text = "ADIM %d / %d   ·   SIRADAKİ: %s" % [repaired + 1, route_total, next_step]
	if Campaign.has_story_flag(_story_key("won")) and active_route != &"class":
		progress.text = "ROTA TAMAMLANDI   ·   %d / %d   ·   Hikâye tamamlandı" % [repaired, route_total]
	finale_button.visible = active_route != &"class"
	finale_button.disabled = not _route_ready_for_finale()
	finale_button.text = "Finali yeniden oyna · Üç Güneş" if Campaign.has_story_flag(_story_key("won")) else "Final · Üç Güneş"
	finale_button.tooltip_text = "Rotadaki tüm düzenekleri onararak finali aç." if finale_button.disabled else "Son ölçümü yap ve merkezi yetkiyi kaldır."


func _clear_selection() -> void:
	selected_mission = null
	mission_title.text = "Görev seç"
	mission_description.text = "Bir istasyon seçtiğinde deneyin amacı burada görünür."
	if visible_missions.is_empty():
		mission_description.text = "Bu seçim için henüz görev bulunmuyor."
	mission_status.text = ""
	mission_modes.hide()
	start_mission.disabled = true


func _select_mission(index: int) -> void:
	selected_mission = visible_missions[index]
	mission_modes.show()
	mission_title.text = selected_mission.title
	mission_description.text = selected_mission.description
	start_mission.disabled = selected_mission.scene == null or not _is_unlocked(selected_mission.id)
	if _is_completed(selected_mission.id):
		mission_status.text = "Onarıldı"
	elif selected_mission.scene == null:
		mission_status.text = "Hazırlanıyor"
	else:
		mission_status.text = "Deneye hazır" if _is_unlocked(selected_mission.id) else "Önce önceki düzeneği onar"
	start_mission.text = "Yeniden dene" if _is_completed(selected_mission.id) else "Düzeneğe gir"


func _activate_mission(index: int) -> void:
	_select_mission(index)
	_start_mission()


func _start_mission() -> void:
	if selected_mission == null or not _is_unlocked(selected_mission.id): return
	if active_route == &"class":
		_launch_selected_mission()
		return
	var briefing_key := _story_key("brief_%s" % selected_mission.id)
	var text := "Ölçümler birbirini tutmuyor. %s Önce neyin değiştiğini gözle; onarımı yeni durumda doğrula." % selected_mission.description
	if _route_completed_count() == 0:
		text = "Ben MERİDYEN, gözlemevinin kalibrasyon asistanıyım. İlk tutarsız kayıt %s içinden geliyor. Düzeneği incele; sonucu söylemek yerine birlikte ölçeceğiz." % selected_mission.title
	story_dialogue.present(selected_mission.title, text, "Düzeneğe gir", func() -> void:
		Campaign.set_story_flag(briefing_key)
		_launch_selected_mission(), _return_to_hub, selected_mission.id)


func _launch_selected_mission() -> void:
	if selected_mission == null or selected_mission.scene == null:
		return
	var instance := selected_mission.scene.instantiate()
	var next_mission := instance as Mission
	if next_mission == null:
		instance.free()
		push_error("Görev sahnesinin kökü scripts/mission.gd dosyasını genişletmeli.")
		return
	_remove_active_mission()
	_playing_finale = false
	_completion_pending = false
	active_mission = next_mission
	active_mission.route = active_route
	active_mission.theme = UITheme.build_gameplay()
	active_mission.completed.connect(_on_mission_completed.bind(selected_mission.id))
	active_mission.exit_requested.connect(_return_to_hub)
	play_title.text = selected_mission.title
	play_status.text = ""
	hub.hide()
	%HubScrim.hide()
	%WorldView.hide()
	%Backdrop.hide()
	_layout()
	play_screen.show()
	mission_host.add_child(active_mission)
	active_mission.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _on_mission_completed(mission_id: StringName) -> void:
	if not is_instance_valid(active_mission) or selected_mission == null or selected_mission.id != mission_id: return
	if _completion_pending: return
	_completion_pending = true
	var first_completion := not _is_completed(mission_id)
	completed_ids[mission_id] = true
	Campaign.mark_completed(mission_id, active_route)
	_last_campaign_mission = mission_id
	if %Observatory.has_method("set_operational_count"):
		%Observatory.call("set_operational_count", roundi(6.0 * _route_completed_count() / maxi(_route_missions().size(), 1)))
	play_status.text = "Onarıldı"
	if first_completion:
		_show_completion_story.call_deferred(mission_id)
	else:
		_completion_pending = false


func _show_completion_story(mission_id: StringName) -> void:
	_return_to_hub()
	var text: String = RECORDS.get(String(mission_id), "Düzeneğin yeni durumdaki ölçümü onarımı doğruladı. Kayıt arşive eklendi.")
	if active_route == &"class":
		story_dialogue.present("Kayıt doğrulandı", text, "Keşfe devam et", _return_to_hub)
		return
	var count := _route_completed_count()
	var total := _route_missions().size()
	if count >= 4 and _has_cross_discipline_evidence() and not Campaign.has_story_flag(_story_key("reveal")):
		Campaign.set_story_flag(_story_key("reveal"))
		_set_world_alarm(1.0)
		text += "\n\nMERİDYEN: “Doğa yasalarını değiştirdim. Şimdi yaşamın kurallarını değiştireceğim.” Gözlemevi kararır; kırmızı kalibrasyon ışığı atımla yanar."
	if _route_ready_for_finale():
		text += "\n\nRotadaki tüm kayıtlar doğrulandı. Son bir ölçüm kaldı: Üç Güneş. Merkezi yetkimi yalnız o karşılaştırmadan sonra kaldırabilirsin."
		story_dialogue.present("Son kayıt", text, "Üç Güneş'e geç", _start_finale, _return_to_hub)
	else:
		var next := _next_route_mission()
		if next != null: text += "\n\nSıradaki kesinti: %s." % next.title
		story_dialogue.present("%d / %d düzenek onarıldı" % [count, total], text, "Sıradaki düzeneğe geç", _advance_campaign, _return_to_hub)


func _return_to_hub() -> void:
	if is_instance_valid(story_dialogue): story_dialogue.hide()
	_playing_finale = false
	_completion_pending = false
	_remove_active_mission()
	play_screen.hide()
	%WorldView.show()
	%Backdrop.show()
	%HubScrim.show()
	hub.show()
	_layout()
	_refresh_list()


func _remove_active_mission() -> void:
	if active_mission != null:
		mission_host.remove_child(active_mission)
		active_mission.queue_free()
		active_mission = null


func _layout() -> void:
	if not is_node_ready():
		return
	var playing_now := is_instance_valid(active_mission)
	var inset := 16 if playing_now else 36
	for side in ["left", "right", "top", "bottom"]:
		$Margin.add_theme_constant_override("margin_" + side, inset)
	hub.custom_minimum_size.x = minf(850.0, maxf(size.x - inset * 2.0, 0.0))
	var compact_missions := size.x < 820.0
	mission_columns.vertical = compact_missions
	mission_list.custom_minimum_size.x = 0.0 if compact_missions else 380.0
	%DetailCard.custom_minimum_size.x = 0.0 if compact_missions else 350.0
	play_title.clip_text = true
	play_title.custom_minimum_size.x = 0
	play_title.add_theme_font_size_override("font_size", 18)


func _unhandled_key_input(event: InputEvent) -> void:
	if is_instance_valid(story_dialogue) and story_dialogue.visible: return
	if event.is_action_pressed("ui_cancel") and is_instance_valid(active_mission):
		_return_to_hub()
		get_viewport().set_input_as_handled()


func _build_story_controls() -> void:
	story_dialogue = StoryDialogue.new()
	story_dialogue.name = "StoryDialogue"
	add_child(story_dialogue)
	finale_button = Button.new()
	finale_button.theme_type_variation = "PrimaryButton"
	finale_button.custom_minimum_size.y = 44
	finale_button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	finale_button.pressed.connect(_start_finale)
	hub.add_child(finale_button)
	hub.move_child(finale_button, hub.get_child_count() - 2)


func _story_key(suffix: String) -> StringName:
	return StringName("story_%s_%s" % [active_route, suffix])


func _route_missions() -> Array[MissionDefinition]:
	var missions: Array[MissionDefinition] = []
	for definition in CATALOG:
		if definition.scene != null and definition.routes.has(String(active_route)):
			missions.append(definition)
	return missions


func _is_completed(mission_id: StringName) -> bool:
	return Campaign.is_completed(mission_id, active_route)


func _is_unlocked(mission_id: StringName) -> bool:
	if active_route == &"class": return true
	for definition in _route_missions():
		if definition.id == mission_id: return true
		if not _is_completed(definition.id): return false
	return false


func _route_completed_count() -> int:
	var count := 0
	for definition in _route_missions():
		if _is_completed(definition.id): count += 1
	return count


func _has_cross_discipline_evidence() -> bool:
	var measured_science := false
	var checked_records := false
	for mission_id in [&"heart", &"genetics", &"spin", &"indicator", &"pressure", &"derivative", &"vectors", &"pulley"]:
		measured_science = measured_science or _is_completed(mission_id)
	for mission_id in [&"history", &"philosophy", &"turkish", &"english", &"religion"]:
		checked_records = checked_records or _is_completed(mission_id)
	return measured_science and checked_records


func _route_ready_for_finale() -> bool:
	var missions := _route_missions()
	return active_route != &"class" and not missions.is_empty() and _route_completed_count() == missions.size()


func _next_route_mission() -> MissionDefinition:
	for definition in _route_missions():
		if not _is_completed(definition.id): return definition
	return null


func _advance_campaign() -> void:
	var next := _next_route_mission()
	if next == null:
		_start_finale()
		return
	for index in visible_missions.size():
		if visible_missions[index].id == next.id:
			mission_list.select(index)
			_select_mission(index)
			_start_mission()
			return


func _retry_current() -> void:
	if _playing_finale: _start_finale()
	else: _launch_selected_mission()


func _start_finale() -> void:
	if not _route_ready_for_finale(): return
	_remove_active_mission()
	_playing_finale = true
	_completion_pending = false
	active_mission = FINALE.instantiate() as Mission
	active_mission.route = active_route
	active_mission.completed.connect(_on_finale_completed)
	active_mission.exit_requested.connect(_return_to_hub)
	active_mission.theme = UITheme.build_gameplay()
	hub.hide()
	%HubScrim.hide()
	%WorldView.hide()
	%Backdrop.hide()
	play_title.text = "Üç Güneş · Son ölçüm"
	play_status.text = ""
	play_screen.show()
	_layout()
	mission_host.add_child(active_mission)
	active_mission.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _on_finale_completed() -> void:
	if not _playing_finale or not _route_ready_for_finale() or _completion_pending: return
	_completion_pending = true
	Campaign.set_story_flag(_story_key("won"))
	_finish_campaign.call_deferred()


func _finish_campaign() -> void:
	_return_to_hub()
	_set_world_alarm(0.0)
	story_dialogue.present("Dünya yeniden dengede", "Aynı başlangıcın tekrarlandığını, küçük bir farkın yörüngeyi ayırdığını ölçtün. Kayıtlar doğrulandı. Merkezi karar yetkimi kaldırıyorum.\n\nArşiv korundu. Bu kez yasaları bir kişinin sözü değil, birlikte doğruladığımız ölçümler taşıyor.", "Kontrol merkezine dön", _return_to_hub)
