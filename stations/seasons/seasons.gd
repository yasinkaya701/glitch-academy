extends "res://scripts/mission.gd"

const Diagram = preload("res://stations/seasons/observatory_diagram.gd")
const Model = preload("res://stations/seasons/seasons_model.gd")
const PAPER := Color("e6f1ef")
const MUTED := Color("a3b9bf")
const AQUA := Color("77d2bd")
const GOLD := Color("f0aa70")

enum Phase { INCIDENT, EXPERIMENT, APPLICATION, REPAIRED }
enum Season { UNSET, SUMMER, WINTER }

var phase := Phase.INCIDENT
var elapsed := 0.0
var december := false
var seen_june := false
var seen_december := false
var north_setting := Season.UNSET
var south_setting := Season.UNSET
var diagram: Diagram
var controls: VBoxContainer
var date_buttons: Array[Button] = []
var tilt_toggle: CheckButton


func _ready() -> void:
	var background := ColorRect.new()
	background.color = Color("0c1522")
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 0)
	add_child(row)
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	diagram = Diagram.new()
	diagram.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	diagram.size_flags_vertical = Control.SIZE_EXPAND_FILL
	diagram.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(diagram)

	var panel := PanelContainer.new()
	panel.custom_minimum_size.x = 352
	panel.add_theme_stylebox_override("panel", _style(Color("142334"), Color("354e60"), 26.0))
	row.add_child(panel)
	controls = VBoxContainer.new()
	controls.add_theme_constant_override("separation", 13)
	panel.add_child(controls)
	_show_incident()


func _process(delta: float) -> void:
	if phase == Phase.INCIDENT or phase == Phase.REPAIRED:
		elapsed += delta
		diagram.incident_time = elapsed
		diagram.queue_redraw()
	if phase == Phase.INCIDENT and elapsed >= 7.0:
		_show_experiment()


func _show_incident() -> void:
	_reset_controls()
	_heading("Güney serası", "Aralık ayında güney istasyonuna da kış uyarısı gitti. Sera, yaz güneşi altında havalandırmayı kapattı.", "1 / 4   ARIZA")
	_spacer()
	_button("Deneye geç", _show_experiment).grab_focus()


func _show_experiment() -> void:
	phase = Phase.EXPERIMENT
	diagram.greenhouse = false
	_reset_controls()
	_heading("Mevsimler", "İki tarihte Dünya’nın eksenine bak. Sonra ekvatora eşit uzaklıktaki iki konumun ölçümlerini karşılaştır.", "2 / 4   DENEY")
	var dates := HBoxContainer.new()
	dates.add_theme_constant_override("separation", 8)
	controls.add_child(dates)
	date_buttons = [
		_button("21 Haziran", _observe.bind(false), dates),
		_button("21 Aralık", _observe.bind(true), dates),
	]
	for index in date_buttons.size():
		var button := date_buttons[index]
		button.toggle_mode = true
		button.set_pressed_no_signal(index == int(december))
	tilt_toggle = CheckButton.new()
	tilt_toggle.text = "Eksen eğikliğini kaldır"
	tilt_toggle.button_pressed = is_zero_approx(diagram.tilt)
	tilt_toggle.toggled.connect(_change_tilt)
	controls.add_child(tilt_toggle)
	if is_zero_approx(diagram.tilt):
		_text("Eğiklik 0°. İki konum aynı açıda ışık alır ve gündüz süreleri eşitlenir.", 16, AQUA)
	else:
		var side := "güney" if december else "kuzey"
		_text("Eğiklik 23,4°. Bu tarihte %s daha dik ışık alır ve gündüz daha uzun sürer." % side, 16, AQUA)
		_text("Aynı genişlikteki ışın demeti eğik geldiğinde daha geniş yüzeye yayılır. Birim alana düşen enerji azalır.", 15, MUTED)
	_spacer()
	var advance := _button("Uyarı sistemini onar", _show_application)
	advance.disabled = not (seen_june and seen_december)
	if advance.disabled:
		_text("Onarıma geçmek için iki tarihi de seç.", 14, MUTED)
	diagram.queue_redraw()
	date_buttons[int(december)].grab_focus()


func _observe(next_december: bool) -> void:
	december = next_december
	diagram.december = december
	if december:
		seen_december = true
	else:
		seen_june = true
	_show_experiment()


func _change_tilt(disabled_tilt: bool) -> void:
	diagram.tilt = 0.0 if disabled_tilt else Model.AXIAL_TILT
	_show_experiment()
	tilt_toggle.grab_focus()


func _show_application(feedback := "") -> void:
	phase = Phase.APPLICATION
	diagram.december = true
	diagram.tilt = Model.AXIAL_TILT
	diagram.queue_redraw()
	_reset_controls()
	_heading("Sera uyarısını onar", "Tarih 21 Aralık. Ölçümlere bakıp iki istasyona doğru mevsim ayarını gönder.", "3 / 4   UYGULAMA")
	var first_menu := _select_season("Kuzey istasyonu", north_setting, true)
	_select_season("Güney serası", south_setting, false)
	if not feedback.is_empty():
		_text(feedback, 15, GOLD)
	_spacer()
	_button("Ayarları gönder", _apply_settings)
	first_menu.grab_focus()


func _select_season(title: String, selected: int, north: bool) -> OptionButton:
	_text(title, 15, PAPER)
	var menu := OptionButton.new()
	menu.add_item("Mevsim seç")
	menu.add_item("Yaz")
	menu.add_item("Kış")
	menu.set_item_disabled(Season.UNSET, true)
	menu.select(selected)
	menu.custom_minimum_size.y = 36
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
		_show_application("İki istasyon için de bir ayar seç.")
		return
	if north_setting != Season.WINTER or south_setting != Season.SUMMER:
		_show_application("Uyarı düzelmedi. Daha dik ışık ve daha uzun gündüz hangi yarımkürede?")
		return
	phase = Phase.REPAIRED
	elapsed = 0.0
	diagram.greenhouse = true
	diagram.repaired = true
	_reset_controls()
	_heading("Sera yeniden çalışıyor", "Aralık ayında güney yarımküre yazı, kuzey yarımküre kışı yaşar. Güney serasına yaz uyarısı ulaştı ve havalandırma açıldı.", "4 / 4   ONARIM")
	_text("Dünya yörüngede ilerlerken eksenin yönü sabit kalır. Güneş’e doğru eğilen yarımküre daha dik ışık alır ve orada gündüz daha uzun sürer.", 16, AQUA)
	completed.emit()


func _heading(title: String, description: String, progress: String) -> void:
	_text(progress, 13, AQUA)
	_text(title, 28, PAPER)
	_text(description, 17, MUTED)


func _text(value: String, font_size: int, color: Color) -> void:
	var label := Label.new()
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	controls.add_child(label)


func _spacer() -> void:
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	controls.add_child(spacer)


func _button(value: String, callback: Callable, parent: Control = null) -> Button:
	var button := Button.new()
	button.text = value
	button.custom_minimum_size.y = 43
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
	style.set_corner_radius_all(5)
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		style.set_content_margin(side, inset)
	return style


func _reset_controls() -> void:
	for child in controls.get_children():
		controls.remove_child(child)
		child.queue_free()
