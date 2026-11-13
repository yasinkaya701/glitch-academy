extends "res://scripts/mission.gd"

const DiagramScript = preload("res://stations/seasons/observatory_diagram.gd")
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
var diagram: Control
var controls: VBoxContainer
var date_buttons: Array[Button] = []
var tilt_toggle: CheckButton

enum LgsStage { CRISIS, TEST, DIAGNOSIS, REPAIR, RECOVERY, SEAL }

var _lgs_mode := false
var _lgs_stage := LgsStage.CRISIS
var _lgs_elapsed := 0.0
var _lgs_attempts := 3
var _lgs_june_recorded := false
var _lgs_december_recorded := false
var _lgs_june_readout := ""
var _lgs_december_readout := ""
var _lgs_rule_selector: OptionButton
var _lgs_layout: HBoxContainer
var _lgs_panel: VBoxContainer
var _lgs_phase: Label
var _lgs_directive: Label
var _lgs_feedback: Label
var _lgs_record: Label
var _lgs_readout: Label
var _lgs_dynamic: VBoxContainer
var _lgs_target: EvidenceTarget
var _lgs_seal_emitted := false


class EvidenceToken extends PanelContainer:
	var evidence_kind := ""
	var evidence_label := ""

	func _get_drag_data(_position: Vector2) -> Variant:
		var preview := Label.new()
		preview.text = evidence_label
		set_drag_preview(preview)
		return {"kind": evidence_kind}


class EvidenceTarget extends PanelContainer:
	signal evidence_received(data: Variant)

	func _can_drop_data(_position: Vector2, data: Variant) -> bool:
		return data is Dictionary and data.get("kind", "") == "season_rule_evidence"

	func _drop_data(_position: Vector2, data: Variant) -> void:
		evidence_received.emit(data)


func _ready() -> void:
	_lgs_mode = route == &"lgs"
	if _lgs_mode:
		_build_lgs_interface()
		_show_lgs_crisis()
		return
	_build_class_interface()


func _build_class_interface() -> void:
	var background := ColorRect.new()
	background.color = Color("0c1522")
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 0)
	add_child(row)
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	diagram = DiagramScript.new()
	diagram.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	diagram.size_flags_vertical = Control.SIZE_EXPAND_FILL
	diagram.mouse_filter = Control.MOUSE_FILTER_STOP
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
	if _lgs_mode:
		if _lgs_stage == LgsStage.CRISIS:
			_lgs_elapsed += delta
			diagram.incident_time = _lgs_elapsed
			diagram.queue_redraw()
			if _lgs_elapsed >= 7.0:
				_show_lgs_test()
		return
	if phase == Phase.INCIDENT or phase == Phase.REPAIRED:
		elapsed += delta
		diagram.incident_time = elapsed
		diagram.queue_redraw()
	if phase == Phase.INCIDENT and elapsed >= 7.0:
		_show_experiment()


func _unhandled_key_input(event: InputEvent) -> void:
	if not _lgs_mode or event.is_echo():
		return
	if event.is_action_pressed("ui_cancel"):
		exit_requested.emit()
	elif event is InputEventKey and event.pressed:
		var key_event := event as InputEventKey
		if key_event.keycode in [KEY_Q, KEY_R]:
			_use_lgs_power(key_event.keycode)
			get_viewport().set_input_as_handled()


func _build_lgs_interface() -> void:
	var background := ColorRect.new()
	background.color = UITheme.BG
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	add_child(margin)

	_lgs_layout = HBoxContainer.new()
	_lgs_layout.add_theme_constant_override("separation", 20)
	margin.add_child(_lgs_layout)
	diagram = DiagramScript.new()
	diagram.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	diagram.size_flags_vertical = Control.SIZE_EXPAND_FILL
	diagram.custom_minimum_size = Vector2(680, 500)
	_lgs_layout.add_child(diagram)

	var panel := PanelContainer.new()
	panel.theme_type_variation = "ConsolePanel"
	panel.custom_minimum_size.x = 400
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_lgs_layout.add_child(panel)
	var inner := MarginContainer.new()
	for key in ["left", "top", "right", "bottom"]:
		inner.add_theme_constant_override("margin_%s" % key, 20)
	panel.add_child(inner)
	_lgs_panel = VBoxContainer.new()
	_lgs_panel.add_theme_constant_override("separation", 14)
	inner.add_child(_lgs_panel)
	_lgs_phase = _lgs_label("LGS FEN  ·  MEVSİMLER", "SectionLabel", 14)
	_lgs_panel.add_child(_lgs_phase)
	var title := _lgs_label("Mevsim Gözlemevi", "HeadlineLabel", 28)
	_lgs_panel.add_child(title)
	_lgs_directive = _lgs_label("Güney serası aşırı ısınıyor.", "Label", 20)
	_lgs_directive.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lgs_directive.custom_minimum_size.y = 68
	_lgs_panel.add_child(_lgs_directive)
	_lgs_feedback = _lgs_label("", "MutedLabel", 16)
	_lgs_feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lgs_panel.add_child(_lgs_feedback)
	_lgs_record = _lgs_label("", "Label", 15)
	_lgs_record.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lgs_panel.add_child(_lgs_record)
	_lgs_readout = _lgs_label("", "Label", 15)
	_lgs_readout.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lgs_panel.add_child(_lgs_readout)
	_lgs_dynamic = VBoxContainer.new()
	_lgs_dynamic.add_theme_constant_override("separation", 8)
	_lgs_panel.add_child(_lgs_dynamic)
	_lgs_panel.add_spacer(false)
	# The shared theme owns all colors, fonts, and button styles.


func _show_lgs_crisis() -> void:
	_lgs_stage = LgsStage.CRISIS
	_lgs_elapsed = 0.0
	_lgs_attempts = 3
	_lgs_june_recorded = false
	_lgs_december_recorded = false
	_lgs_june_readout = ""
	_lgs_december_readout = ""
	_lgs_seal_emitted = false
	diagram.greenhouse = true
	diagram.repaired = false
	diagram.december = true
	diagram.tilt = Model.AXIAL_TILT
	diagram.guides_visible = false
	diagram.incident_time = 0.0
	_lgs_phase.text = "1 / 6  ·  KRİZ"
	_lgs_directive.text = "Güney serası ısınıyor; havalandırma kapalı."
	_lgs_feedback.text = "MERİDYEN ayarı: Mevsim = Dünya-Güneş uzaklığı."
	_lgs_record.text = ""
	_lgs_clear_actions()
	_lgs_add_button("NEDENİNİ BUL", _show_lgs_test, true)


func _show_lgs_test() -> void:
	_lgs_stage = LgsStage.TEST
	diagram.greenhouse = false
	diagram.repaired = false
	diagram.december = true
	_lgs_phase.text = "2 / 6  ·  SINA"
	_lgs_directive.text = "İki gündönümünde yarımkürelerin gündüzünü ölç."
	_lgs_feedback.text = "Tarih dışında koşulları sabit tut; iki kaydı karşılaştır."
	_lgs_clear_actions()
	_lgs_add_button("21 HAZİRAN", _set_lgs_june, false)
	_lgs_add_button("21 ARALIK", _set_lgs_december, false)
	_lgs_add_button("ÖLÇÜMÜ KAYDET", _record_lgs_measurement, true)
	_lgs_add_button("KANITI İNCELE", _show_lgs_diagnosis, false).disabled = true
	_lgs_add_button("SAR  ·  KRİZİ YENİDEN OYNAT", _show_lgs_crisis, false)
	_lgs_add_button("GÖR  ·  IŞINLARI VURGULA", _toggle_lgs_guides, false)
	_refresh_lgs_readout()
	_lgs_feedback.text = "Q Sar  ·  R Gör"


func _record_lgs_measurement() -> void:
	if _lgs_stage != LgsStage.TEST:
		return
	var north := Model.sample(40.0, diagram.december, Model.AXIAL_TILT)
	var south := Model.sample(-40.0, diagram.december, Model.AXIAL_TILT)
	var line := "%s  ·  K %s sa / G %s sa" % [
		"21 ARALIK" if diagram.december else "21 HAZİRAN",
		_decimal(north.y), _decimal(south.y)
	]
	if diagram.december:
		_lgs_december_recorded = true
		_lgs_december_readout = line
	else:
		_lgs_june_recorded = true
		_lgs_june_readout = line
	_lgs_record.text = ("KAYIT 1  ·  " + _lgs_june_readout + "\n" if _lgs_june_recorded else "")
	if _lgs_december_recorded:
		_lgs_record.text += "KAYIT 2  ·  " + _lgs_december_readout
	_lgs_feedback.text = "Gündüz süreleri ölçüm şeridine işlendi."
	var evidence_button := _lgs_find_button("KANITI İNCELE")
	if _lgs_june_recorded and _lgs_december_recorded:
		evidence_button.disabled = false
		_lgs_feedback.text = "Yörünge uzaklığı aynı; kanıtı plakaya taşı."
	_refresh_lgs_readout()


func _set_lgs_june() -> void:
	_set_lgs_date(false)


func _set_lgs_december() -> void:
	_set_lgs_date(true)


func _set_lgs_date(is_december: bool) -> void:
	if _lgs_stage != LgsStage.TEST:
		return
	diagram.december = is_december
	_refresh_lgs_readout()


func _show_lgs_diagnosis() -> void:
	if not _lgs_june_recorded or not _lgs_december_recorded:
		return
	_lgs_stage = LgsStage.DIAGNOSIS
	_lgs_phase.text = "3 / 6  ·  TEŞHİS"
	_lgs_directive.text = "Ölçüm kaydını bozuk ayara sürükle."
	_lgs_feedback.text = "Eşit uzaklıkta gündüzler değişiyor mu?"
	_lgs_clear_actions()
	var card := EvidenceToken.new()
	card.name = "LgsEvidenceToken"
	card.evidence_kind = "season_rule_evidence"
	card.evidence_label = "%s\n%s" % [_lgs_june_readout, _lgs_december_readout]
	card.custom_minimum_size = Vector2(0, 76)
	var token_label := _lgs_label(card.evidence_label, "Label", 15)
	card.add_child(token_label)
	_lgs_dynamic.add_child(card)
	_lgs_target = EvidenceTarget.new()
	_lgs_target.name = "LgsEvidenceTarget"
	_lgs_target.custom_minimum_size = Vector2(0, 74)
	_lgs_target.evidence_received.connect(_on_lgs_evidence_dropped)
	_lgs_dynamic.add_child(_lgs_target)
	_lgs_target.add_child(_lgs_label("BOZUK SATIR  ·  MEVSİM KAYNAĞI: UZAKLIK\nKanıtı buraya bırak", "Label", 15))
	_lgs_add_button("SAR  ·  KRİZİ YENİDEN OYNAT", _show_lgs_crisis, false)
	_lgs_add_button("GÖR  ·  IŞINLARI VURGULA", _toggle_lgs_guides, false)


func _on_lgs_evidence_dropped(_data: Variant) -> void:
	if _lgs_stage != LgsStage.DIAGNOSIS:
		return
	_lgs_feedback.text = "Mühür kırıldı. Mevsim kuralını düzelt."
	_lgs_show_repair()


func _lgs_show_repair() -> void:
	_lgs_stage = LgsStage.REPAIR
	diagram.tilt = Model.AXIAL_TILT
	_lgs_phase.text = "4 / 6  ·  DÜZELT"
	_lgs_directive.text = "Plakadaki mevsim kuralını düzelt."
	_lgs_clear_actions()
	_lgs_dynamic.add_child(_lgs_label("MEVSİM KAYNAĞI", "MutedLabel", 14))
	_lgs_rule_selector = OptionButton.new()
	_lgs_rule_selector.add_item("Dünya-Güneş uzaklığı", 0)
	_lgs_rule_selector.add_item("Eksen eğimi", 1)
	_lgs_rule_selector.select(0)
	_lgs_rule_selector.custom_minimum_size.y = 44
	_lgs_dynamic.add_child(_lgs_rule_selector)
	_lgs_add_button("KURALI UYGULA", _repair_lgs_setting, true)
	_lgs_add_button("GÖR  ·  IŞINLARI VURGULA", _toggle_lgs_guides, false)
	_lgs_add_button("SAR  ·  KRİZİ YENİDEN OYNAT", _show_lgs_crisis, false)
	_refresh_lgs_readout()


func _repair_lgs_setting() -> void:
	if _lgs_stage != LgsStage.REPAIR:
		return
	var north := Model.sample(40.0, true, Model.AXIAL_TILT)
	var south := Model.sample(-40.0, true, Model.AXIAL_TILT)
	_refresh_lgs_readout()
	if _lgs_rule_selector.get_selected_id() != 1:
		diagram.greenhouse = true
		diagram.repaired = false
		diagram.incident_time = 4.0
		_lgs_feedback.text = "Mühür açık kalıyor. Gündüz kayıtlarıyla kuralı karşılaştır."
		return
	_lgs_feedback.text = "Tahmin ve ölçüm örtüştü: %s / %s saat." % [_decimal(north.y), _decimal(south.y)]
	_show_lgs_recovery()


func _show_lgs_recovery() -> void:
	_lgs_stage = LgsStage.RECOVERY
	diagram.december = false
	diagram.greenhouse = false
	diagram.repaired = false
	_lgs_phase.text = "5 / 6  ·  TOPARLA  ·  %d HAK" % _lgs_attempts
	_lgs_directive.text = "21 Haziran kaydına göre sera uyarılarını kur."
	_lgs_feedback.text = "Yeni konum: 50° kuzey ve 50° güney."
	_lgs_clear_actions()
	var readings := Model.sample(50.0, false, Model.AXIAL_TILT)
	var south := Model.sample(-50.0, false, Model.AXIAL_TILT)
	_lgs_record.text = "50° K  ·  %s saat gündüz\n50° G  ·  %s saat gündüz" % [_decimal(readings.y), _decimal(south.y)]
	_lgs_readout.text = "21 HAZİRAN  ·  IŞIN SÜRESİ VE AÇISI"
	_lgs_add_season_selector("Kuzey istasyonu")
	_lgs_add_season_selector("Güney serası")
	_lgs_add_button("UYARIYI GÖNDER", _send_lgs_warning, true)


func _send_lgs_warning() -> void:
	if _lgs_stage != LgsStage.RECOVERY:
		return
	var north_choice := _lgs_season_selection("Kuzey istasyonu")
	var south_choice := _lgs_season_selection("Güney serası")
	if north_choice == "YAZ" and south_choice == "KIŞ":
		diagram.greenhouse = true
		diagram.repaired = true
		diagram.incident_time = 0.0
		_lgs_stage = LgsStage.SEAL
		_lgs_phase.text = "6 / 6  ·  MÜHÜR"
		_lgs_directive.text = "Uyarı doğru ulaştı; güney serası havalandırılıyor."
		_lgs_feedback.text = "Eksen eğimi, iki yarımkürede mevsimleri ters sıraya getirir."
		_lgs_record.text = "YASA KAYDI  ·  F.8.1.1.1"
		_lgs_clear_actions()
		_lgs_add_button("MÜHRÜ KAYDA GEÇİR", _emit_lgs_completion, true)
		_lgs_add_button("KONTROL MERKEZİNE DÖN", _request_exit, false)
		return
	_lgs_attempts -= 1
	diagram.greenhouse = true
	diagram.repaired = false
	diagram.incident_time = 4.0
	_lgs_feedback.text = "Uyarı yanlış konuma gitti; sera alarmı yükseliyor."
	if _lgs_attempts <= 0:
		_lgs_feedback.text = "Üç hak bitti. Krizi yeniden dene."
		_lgs_clear_actions()
		_lgs_add_button("SAR  ·  YENİDEN DENE", _show_lgs_crisis, true)
	else:
		_lgs_phase.text = "5 / 6  ·  TOPARLA  ·  %d HAK" % _lgs_attempts


func _emit_lgs_completion() -> void:
	if _lgs_seal_emitted:
		return
	_lgs_seal_emitted = true
	completed.emit()


func _lgs_add_season_selector(title_text: String) -> void:
	var row := HBoxContainer.new()
	_lgs_dynamic.add_child(row)
	var title := _lgs_label(title_text, "MutedLabel", 15)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(title)
	var selector := OptionButton.new()
	selector.name = "NorthSeason" if title_text == "Kuzey istasyonu" else "SouthSeason"
	selector.add_item("SEÇ")
	selector.add_item("YAZ")
	selector.add_item("KIŞ")
	row.add_child(selector)


func _lgs_season_selection(title_text: String) -> String:
	var node_name := "NorthSeason" if title_text == "Kuzey istasyonu" else "SouthSeason"
	for child in _lgs_dynamic.get_children():
		var selector := child.find_child(node_name, true, false) as OptionButton
		if selector != null:
			return selector.get_item_text(selector.selected)
	return ""


func _toggle_lgs_guides() -> void:
	diagram.guides_visible = not diagram.guides_visible
	diagram.queue_redraw()
	_lgs_feedback.text = "Eksen ve ışın çizgileri %s." % ("vurgulu" if diagram.guides_visible else "normal")


func _use_lgs_power(key: Key) -> void:
	if _lgs_stage in [LgsStage.TEST, LgsStage.DIAGNOSIS, LgsStage.REPAIR]:
		if key == KEY_Q:
			_show_lgs_crisis()
		elif key == KEY_R:
			_toggle_lgs_guides()


func _refresh_lgs_readout() -> void:
	if not is_instance_valid(_lgs_readout):
		return
	var north := Model.sample(40.0, diagram.december, diagram.tilt)
	var south := Model.sample(-40.0, diagram.december, diagram.tilt)
	var date_label := "21 ARALIK" if diagram.december else "21 HAZİRAN"
	_lgs_readout.text = "%s  ·  %s°\n40° K: %s saat  ·  40° G: %s saat" % [
		date_label,
		_decimal(diagram.tilt), _decimal(north.y), _decimal(south.y)
	]
	diagram.queue_redraw()


func _lgs_clear_actions() -> void:
	for child in _lgs_dynamic.get_children():
		_lgs_dynamic.remove_child(child)
		child.queue_free()
	_lgs_target = null


func _lgs_add_button(label_text: String, callback: Callable, primary: bool) -> Button:
	var button := Button.new()
	button.name = "LgsAction_%s" % label_text.to_snake_case()
	button.text = label_text
	button.custom_minimum_size.y = 44
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.theme_type_variation = "PrimaryButton" if primary else "Button"
	button.pressed.connect(callback)
	_lgs_dynamic.add_child(button)
	return button


func _lgs_find_button(label_text: String) -> Button:
	for child in _lgs_dynamic.get_children():
		if child is Button and (child as Button).text == label_text:
			return child as Button
	return null


func _lgs_label(value: String, variation: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = value
	label.theme_type_variation = variation
	label.add_theme_font_size_override("font_size", font_size)
	return label


func _request_exit() -> void:
	exit_requested.emit()


func _decimal(value: float) -> String:
	return ("%.1f" % value).replace(".", ",")


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
	_text("3B modeli sürükleyerek döndür · Tekerlekle yakınlaş · Çift tıklayarak sıfırla", 12, MUTED)
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
