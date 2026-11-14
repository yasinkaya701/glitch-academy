extends "res://scripts/mission.gd"

const Experiment = preload("res://scenes/experiment_3d.tscn")
const ModelScene = preload("res://stations/seasons/seasons_3d.tscn")
const Model = preload("res://stations/seasons/seasons_model.gd")

const PAPER := Color("e9e5db")
const MUTED := Color("b1ac9e")
const SAGE := Color("8fbea0")
const AMBER := Color("dfae63")
const PANEL := Color("191a17")
const EDGE := Color("3b3d35")

enum Phase { INCIDENT, EXPERIMENT, APPLICATION, REPAIRED }
enum Season { UNSET, SUMMER, WINTER }

var phase := Phase.INCIDENT
var elapsed := 0.0
var december := false
var seen_june := false
var seen_december := false
var north_setting := Season.UNSET
var south_setting := Season.UNSET
var axial_tilt := Model.AXIAL_TILT
var model_3d: Node3D
var viewport: SubViewportContainer
var controls: VBoxContainer
var row: BoxContainer
var panel: PanelContainer
var tilt_toggle: CheckButton


func _ready() -> void:
	_build_interface()
	_show_incident()
	_sync_model()
	resized.connect(_layout)
	_layout()


func _build_interface() -> void:
	var background := ColorRect.new()
	background.color = Color("10110f")
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	row = BoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 18
	row.offset_top = 18
	row.offset_right = -18
	row.offset_bottom = -18
	add_child(row)

	viewport = Experiment.instantiate()
	viewport.custom_minimum_size = Vector2(360, 320)
	viewport.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	viewport.size_flags_vertical = Control.SIZE_EXPAND_FILL
	viewport.stretch = true
	row.add_child(viewport)
	var world: Node3D = viewport.get_node("Viewport/World")
	var environment: WorldEnvironment = world.get_node("WorldEnvironment")
	environment.environment.background_color = Color("10110f")
	environment.environment.ambient_light_color = Color("d8d2c3")
	environment.environment.ambient_light_energy = 0.48
	var camera: Camera3D = world.get_node("Camera3D")
	camera.position = Vector3(4.3, 3.4, 6.6)
	camera.rotation_degrees = Vector3(-23, 31, 0)
	camera.size = 8.7
	model_3d = ModelScene.instantiate()
	world.get_node("Model").add_child(model_3d)

	panel = PanelContainer.new()
	panel.custom_minimum_size.x = 352
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _style(PANEL, EDGE, 20.0))
	row.add_child(panel)
	controls = VBoxContainer.new()
	controls.add_theme_constant_override("separation", 12)
	panel.add_child(controls)


func _layout() -> void:
	if row == null or panel == null:
		return
	var compact := size.x < 920.0
	row.vertical = compact
	panel.custom_minimum_size = Vector2(0, 0) if compact else Vector2(352, 0)
	viewport.custom_minimum_size = Vector2(300, 260) if compact else Vector2(460, 360)
	viewport.size_flags_vertical = Control.SIZE_EXPAND_FILL if not compact else Control.SIZE_EXPAND_FILL


func _process(delta: float) -> void:
	if phase == Phase.INCIDENT or phase == Phase.REPAIRED:
		elapsed += delta
		_sync_model()
	if phase == Phase.INCIDENT and elapsed >= 7.0:
		_show_experiment()


func _show_incident() -> void:
	december = false
	_reset_controls()
	_heading("Güney serası", "21 Haziran ölçümü yanlış istasyona bağlandı. Güney serası kış uyarısıyla havalandırmayı kapattı.", "1 / 4   GÖZLEM")
	_metric("ARIZA", "Güney yarımkürede kış uyarısı", AMBER)
	_spacer()
	_button("Dünya modelini incele", _show_experiment).grab_focus()


func _show_experiment() -> void:
	phase = Phase.EXPERIMENT
	_sync_model()
	_reset_controls()
	_heading("%s · Güneş açısı" % ("21 Aralık" if december else "21 Haziran"), "Dünya’nın ekseni yörünge boyunca aynı yöne bakar. Tarihi değiştir; 40° kuzey ve güneydeki öğle ışınlarını karşılaştır.", "2 / 4   3B DENEY")
	var dates := HBoxContainer.new()
	dates.add_theme_constant_override("separation", 8)
	controls.add_child(dates)
	var june := _button("21 Haziran", _observe.bind(false), dates)
	var winter := _button("21 Aralık", _observe.bind(true), dates)
	june.toggle_mode = true
	winter.toggle_mode = true
	june.set_pressed_no_signal(not december)
	winter.set_pressed_no_signal(december)
	var north := Model.sample(40.0, december, axial_tilt)
	var south := Model.sample(-40.0, december, axial_tilt)
	_metric("40° KUZEY", "%s° öğle açısı  ·  %s sa gündüz" % [_fmt(north.x), _fmt(north.y)], SAGE if north.x > south.x else MUTED)
	_metric("40° GÜNEY", "%s° öğle açısı  ·  %s sa gündüz" % [_fmt(south.x), _fmt(south.y)], AMBER if south.x > north.x else MUTED)
	_text("Işın yüzeye dikleştikçe aynı enerji daha küçük alana yayılır. Gündüz uzadıkça yüzey daha uzun süre enerji alır.", 15, MUTED)
	tilt_toggle = CheckButton.new()
	tilt_toggle.text = "Eksen eğikliğini kaldır · 0°"
	tilt_toggle.button_pressed = is_zero_approx(axial_tilt)
	tilt_toggle.toggled.connect(_change_tilt)
	controls.add_child(tilt_toggle)
	_text("Modeldeki 23,4° eğikliği kaldırıp iki yarımkürenin farkının nasıl kaybolduğunu gözlemle.", 14, MUTED)
	_spacer()
	var advance := _button("Ölçümleri karşılaştır", _show_application)
	advance.disabled = not (seen_june and seen_december)
	if advance.disabled:
		_text("İki tarihi de inceleyince karşılaştırma açılır.", 13, MUTED)
	_sync_model()


func _observe(next_december: bool) -> void:
	december = next_december
	if december:
		seen_december = true
	else:
		seen_june = true
	_show_experiment()


func _change_tilt(disabled_tilt: bool) -> void:
	axial_tilt = 0.0 if disabled_tilt else Model.AXIAL_TILT
	_show_experiment()


func _show_application(feedback := "") -> void:
	phase = Phase.APPLICATION
	december = true
	_sync_model()
	_reset_controls()
	_heading("İstasyonları düzelt", "21 Aralık ölçümü: daha dik öğle ışınını ve uzun gündüzü doğru yarımküreye bağla.", "3 / 4   YKS UYGULAMASI")
	var north_menu := _select_season("40° Kuzey istasyonu", north_setting, true)
	_select_season("40° Güney serası", south_setting, false)
	_metric("İPUCU", "Öğle Güneş yüksekliği ve gündüz süresini birlikte kullan.", AMBER)
	if not feedback.is_empty():
		_text(feedback, 14, AMBER)
	_spacer()
	_button("İstasyon ayarlarını gönder", _apply_settings)
	north_menu.grab_focus()


func _select_season(title: String, selected: int, north: bool) -> OptionButton:
	_text(title, 14, PAPER)
	var menu := OptionButton.new()
	menu.add_item("Mevsim seç")
	menu.add_item("Yaz")
	menu.add_item("Kış")
	menu.set_item_disabled(Season.UNSET, true)
	menu.select(selected)
	menu.custom_minimum_size.y = 40
	menu.add_theme_color_override("font_color", PAPER)
	menu.item_selected.connect(_store_setting.bind(north))
	controls.add_child(menu)
	return menu


func _store_setting(index: int, north: bool) -> void:
	if north:
		north_setting = index
	else:
		south_setting = index


func _apply_settings() -> void:
	if phase != Phase.APPLICATION:
		return
	if north_setting == Season.UNSET or south_setting == Season.UNSET:
		_show_application("İki istasyon için de bir mevsim seç.")
		return
	if north_setting != Season.WINTER or south_setting != Season.SUMMER:
		_show_application("21 Aralık’ta güney yarımküre Güneş’e doğru eğiktir.")
		return
	phase = Phase.REPAIRED
	elapsed = 0.0
	_sync_model()
	_reset_controls()
	_heading("Sera yeniden çalışıyor", "21 Aralık’ta kuzey kış, güney yaz yaşar. Güneş’e doğru eğilen yarımkürede öğle ışınları daha dik, gündüz daha uzundur.", "4 / 4   ONARIM")
	_metric("YKS KAZANIMI", "Eksen eğikliği → ışın açısı ve gündüz süresi → mevsimler", SAGE)
	_text("Dünya’nın Güneş’e uzaklığı mevsimleri açıklamaz. Belirleyici olan eksen eğikliği ve yarımkürelerin ışığı alış biçimidir.", 15, MUTED)
	completed.emit()


func _heading(title: String, description: String, progress: String) -> void:
	_text(progress, 12, SAGE)
	_text(title, 25, PAPER)
	_text(description, 15, MUTED)


func _metric(title: String, value: String, tint: Color) -> void:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", _style(Color("242520"), EDGE, 10.0))
	controls.add_child(card)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 4)
	card.add_child(content)
	var tag := _label(title, 11, tint)
	content.add_child(tag)
	content.add_child(_label(value, 14, PAPER))


func _text(value: String, font_size: int, color: Color) -> Label:
	var label := _label(value, font_size, color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	controls.add_child(label)
	return label


func _label(value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _spacer() -> void:
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	controls.add_child(spacer)


func _button(value: String, callback: Callable, parent: Control = null) -> Button:
	var button := Button.new()
	button.text = value
	button.custom_minimum_size.y = 42
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_color_override("font_color", PAPER)
	button.pressed.connect(callback)
	(controls if parent == null else parent).add_child(button)
	return button


func _style(fill: Color, line: Color, inset: float) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = line
	style.set_border_width_all(1)
	style.set_corner_radius_all(10)
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		style.set_content_margin(side, inset)
	return style


func _reset_controls() -> void:
	for child in controls.get_children():
		controls.remove_child(child)
		child.queue_free()


func _sync_model() -> void:
	if model_3d == null:
		return
	var showing_greenhouse := phase == Phase.INCIDENT or phase == Phase.REPAIRED
	model_3d.set_state(december, axial_tilt, showing_greenhouse, phase == Phase.REPAIRED, elapsed)


func _fmt(value: float) -> String:
	return "%.1f" % value
