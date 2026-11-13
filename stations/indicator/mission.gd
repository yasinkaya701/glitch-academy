extends "res://scripts/mission.gd"
## Route-aware indicator and pH measurement bench.

const BG := Color("#08121b")
const EDGE := Color("#31505b")
const INK := Color("#e8f2ef")
const MUTED := Color("#9bb4b5")
const MINT := Color("#82e0c5")
const AMBER := Color("#f0c77d")
const RED := Color("#ff8e81")
const BLUE := Color("#73baff")
const GREEN := Color("#86d9a4")

var _tyt := false
var _tested_red := false
var _tested_blue := false
var _measured: Array[bool] = [false, false]
var _open_valve := -1
var _locked := false
var _stage: Control
var _instruction: Label
var _progress: Label
var _feedback: Label
var _controls: VBoxContainer
var _workbench: BoxContainer
var _stage_panel: PanelContainer
var _instrument_scroll: ScrollContainer
var _instrument_panel: PanelContainer
var _narrow_layout := false


func _ready() -> void:
	_tyt = route == &"tyt"
	_build_interface()
	resized.connect(_sync_layout)
	_sync_layout()
	_update_stage()


func _build_interface() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var margins := MarginContainer.new()
	margins.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margins.add_theme_constant_override("margin_left", 30)
	margins.add_theme_constant_override("margin_right", 30)
	margins.add_theme_constant_override("margin_top", 22)
	margins.add_theme_constant_override("margin_bottom", 24)
	add_child(margins)
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 10)
	margins.add_child(outer)

	var overline := _label("FIELD LAB  /  %s" % ("TYT KİMYA" if _tyt else "FEN BİLİMLERİ"), 13, MINT)
	outer.add_child(overline)
	_instruction = _label("Daha asidik numuneyi ölç ve vanasını aç." if _tyt else "İki turnusol şeridini dene, numuneyi sınıflandır.", 25, INK)
	_instruction.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	outer.add_child(_instruction)
	_progress = _label("ÖLÇÜM  0 / 2" if _tyt else "KANIT  0 / 2", 13, AMBER)
	outer.add_child(_progress)

	_workbench = BoxContainer.new()
	_workbench.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_workbench.add_theme_constant_override("separation", 14)
	outer.add_child(_workbench)

	_stage_panel = _panel()
	_stage_panel.custom_minimum_size = Vector2(420, 330)
	_stage_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_stage_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_stage_panel.size_flags_stretch_ratio = 1.28
	_workbench.add_child(_stage_panel)
	_stage = Control.new()
	_stage.custom_minimum_size = Vector2(420, 340)
	_stage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_stage.draw.connect(_draw_stage)
	_stage_panel.add_child(_stage)

	_instrument_scroll = ScrollContainer.new()
	_instrument_scroll.custom_minimum_size = Vector2(360, 0)
	_instrument_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_instrument_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_instrument_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_instrument_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_instrument_scroll.size_flags_stretch_ratio = 0.82
	_workbench.add_child(_instrument_scroll)
	_instrument_panel = _panel()
	_instrument_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_instrument_scroll.add_child(_instrument_panel)
	_controls = VBoxContainer.new()
	_controls.add_theme_constant_override("separation", 6)
	_controls.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_controls.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_instrument_panel.add_child(_controls)

	var device_tag := _label("ANALİZ MASASI  ·  NUMUNE K-03" if not _tyt else "pH ÖLÇER  ·  SULU NUMUNELER", 12, MINT)
	_controls.add_child(device_tag)
	var device_note := _label("Okumalar kayıt panelinde kalır." if _tyt else "Şeritleri ayrı ayrı numuneye batır.", 15, MUTED)
	_controls.add_child(device_note)
	_controls.add_child(_rule())
	_feedback = _label("Hazır · ölçüm bekleniyor", 16, INK)
	_feedback.custom_minimum_size = Vector2(0, 54)
	_feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_controls.add_child(_feedback)
	_controls.add_child(_rule())
	if _tyt:
		_add_button("Ölç  ·  Numune A", _measure.bind(0))
		_add_button("Ölç  ·  Numune B", _measure.bind(1))
		_controls.add_child(_spacer())
		_add_button("A vanasını aç", _choose_valve.bind(0), true)
		_add_button("B vanasını aç", _choose_valve.bind(1), true)
	else:
		_add_button("Kırmızı şeridi dene", _test_strip.bind(true))
		_add_button("Mavi şeridi dene", _test_strip.bind(false))
		_controls.add_child(_spacer())
		var classify := _label("SINIFLANDIR", 12, MINT)
		_controls.add_child(classify)
		_add_button("Asit  /  pH < 7", _classify.bind("acid"))
		_add_button("Nötr  /  pH = 7", _classify.bind("neutral"))
		_add_button("Baz  /  pH > 7", _classify.bind("base"))
	_controls.add_child(_spacer())
	_add_button("↻  Deneyi sıfırla", _reset)
	_feedback.text = "pH ölçer hazır · A ve B'yi ölç." if _tyt else "K-03 hazır · iki şeritten kanıt topla."
	if not _tyt:
		for child in _controls.get_children():
			if child is Button and (child.text.begins_with("Asit") or child.text.begins_with("Nötr") or child.text.begins_with("Baz")):
				(child as Button).disabled = true
	for child in _controls.get_children():
		if child is Button and not (child as Button).disabled:
			(child as Button).grab_focus()
			break


func _sync_layout() -> void:
	if _workbench == null:
		return
	var use_narrow := size.x < 980.0
	if use_narrow == _narrow_layout:
		return
	_narrow_layout = use_narrow
	_workbench.vertical = _narrow_layout
	if _narrow_layout:
		_workbench.add_theme_constant_override("separation", 10)
		_stage_panel.custom_minimum_size = Vector2(0, 300)
		_instrument_scroll.custom_minimum_size = Vector2(0, 190)
	else:
		_workbench.add_theme_constant_override("separation", 14)
		_stage_panel.custom_minimum_size = Vector2(420, 330)
		_instrument_scroll.custom_minimum_size = Vector2(360, 0)
	_update_stage()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), BG, true)
	draw_rect(Rect2(Vector2(16, 14), size - Vector2(32, 28)), Color("#0b1922"), true)
	draw_rect(Rect2(Vector2(16, 14), size - Vector2(32, 28)), EDGE, false, 1.0)


func _draw_stage() -> void:
	var s := _stage.size
	_stage.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	_stage.draw_rect(Rect2(Vector2(18, 18), s - Vector2(36, 36)), Color("#0b1821"), true)
	_stage.draw_rect(Rect2(Vector2(18, 18), s - Vector2(36, 36)), EDGE, false, 1.0)
	_stage.draw_string(ThemeDB.fallback_font, Vector2(40, 48), "NUMUNE  K-03" if not _tyt else "İKİ ÖLÇÜM  /  pH", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, MUTED)
	_stage.draw_line(Vector2(40, 62), Vector2(s.x - 40, 62), EDGE, 1)
	var vertical_scale := minf(1.0, s.y / 500.0)
	_stage.draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, vertical_scale))
	var center := Vector2(s.x * 0.51, 240.0)
	if _tyt:
		_draw_vessel(center + Vector2(-92, -35), 148, "NUMUNE A", Color("#66c9d5", 0.86))
		_draw_vessel(center + Vector2(92, -35), 148, "NUMUNE B", Color("#bc91e8", 0.86))
		_draw_meter(center + Vector2(-92, -91), "A", _measured[0], "4,6")
		_draw_meter(center + Vector2(92, -91), "B", _measured[1], "2,8")
		_draw_valve(center + Vector2(-92, 222), "A", _open_valve == 0)
		_draw_valve(center + Vector2(92, 222), "B", _open_valve == 1)
	else:
		_draw_vessel(center, 188, "K-03  ·  BİLİNMEYEN", Color("#d0b66b", 0.82))
		_draw_strip(center + Vector2(-132, -140), true, _tested_red)
		_draw_strip(center + Vector2(120, -140), false, _tested_blue)
		_stage.draw_string(ThemeDB.fallback_font, Vector2(0, 450), "KIRMIZI ŞERİT" if _tested_red else "KIRMIZI ŞERİT  ·  BEKLİYOR", HORIZONTAL_ALIGNMENT_CENTER, s.x, 12, RED)
		_stage.draw_string(ThemeDB.fallback_font, Vector2(0, 472), "MAVİ ŞERİT" if _tested_blue else "MAVİ ŞERİT  ·  BEKLİYOR", HORIZONTAL_ALIGNMENT_CENTER, s.x, 12, BLUE)
	_stage.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_vessel(center: Vector2, width: float, label: String, liquid_color: Color) -> void:
	var vessel := Rect2(center + Vector2(-width / 2.0, 0), Vector2(width, 176))
	_stage.draw_rect(Rect2(vessel.position + Vector2(0, 14), Vector2(12, 142)), Color("#8db5b5"), true)
	_stage.draw_rect(Rect2(vessel.position + Vector2(vessel.size.x - 12, 14), Vector2(12, 142)), Color("#8db5b5"), true)
	_stage.draw_rect(Rect2(vessel.position + Vector2(0, 144), Vector2(vessel.size.x, 12)), Color("#8db5b5"), true)
	_stage.draw_rect(Rect2(vessel.position + Vector2(12, 79), Vector2(vessel.size.x - 24, 65)), liquid_color, true)
	_stage.draw_line(vessel.position + Vector2(12, 79), vessel.position + Vector2(vessel.size.x - 12, 79), Color("#f2d994"), 2)
	_stage.draw_string(ThemeDB.fallback_font, vessel.position + Vector2(0, 202), label, HORIZONTAL_ALIGNMENT_CENTER, vessel.size.x, 12, INK)


func _draw_valve(at: Vector2, label: String, open: bool) -> void:
	var tint := GREEN if open else AMBER
	_stage.draw_line(at + Vector2(-42, 0), at + Vector2(-14, 0), EDGE, 3)
	_stage.draw_line(at + Vector2(14, 0), at + Vector2(42, 0), EDGE, 3)
	_stage.draw_circle(at, 14, Color("#10212c"))
	_stage.draw_arc(at, 14, 0.0, TAU, 24, tint, 2)
	if open:
		_stage.draw_line(at + Vector2(-7, 0), at + Vector2(7, 0), GREEN, 3)
	else:
		_stage.draw_line(at + Vector2(0, -7), at + Vector2(0, 7), AMBER, 3)
	_stage.draw_string(ThemeDB.fallback_font, at + Vector2(-53, 34), "%s  ·  %s" % [label, "AKIŞ AÇIK" if open else "KAPALI"], HORIZONTAL_ALIGNMENT_CENTER, 106, 11, tint)


func _draw_strip(at: Vector2, red_strip: bool, tested: bool) -> void:
	var base := RED if red_strip else BLUE
	var result := RED if tested else base
	var rect := Rect2(at + Vector2(-12, -35), Vector2(24, 134))
	_stage.draw_rect(rect, Color("#dce6dc"), true)
	_stage.draw_rect(Rect2(rect.position + Vector2(2, 2), Vector2(20, 65)), base, true)
	_stage.draw_rect(Rect2(rect.position + Vector2(2, 70), Vector2(20, 62)), result, true)
	_stage.draw_line(at + Vector2(0, 100), at + Vector2(0, 143), Color("#cad7cf"), 2)
	_stage.draw_circle(at + Vector2(0, 145), 4, Color("#d2c68f"))


func _draw_meter(at: Vector2, name: String, measured: bool, reading: String) -> void:
	_stage.draw_circle(at, 49, Color("#142a34"))
	_stage.draw_arc(at, 38, PI * 0.75, PI * 2.25, 32, MINT if measured else EDGE, 3)
	_stage.draw_string(ThemeDB.fallback_font, at + Vector2(-30, -8), name, HORIZONTAL_ALIGNMENT_CENTER, 60, 16, INK)
	_stage.draw_string(ThemeDB.fallback_font, at + Vector2(-36, 17), reading if measured else "—", HORIZONTAL_ALIGNMENT_CENTER, 72, 17, MINT if measured else MUTED)
	_stage.draw_string(ThemeDB.fallback_font, at + Vector2(-35, 40), "pH", HORIZONTAL_ALIGNMENT_CENTER, 70, 12, MUTED)


func _test_strip(is_red: bool) -> void:
	if _locked:
		return
	if is_red:
		_tested_red = true
		_set_feedback("Kırmızı şerit kırmızı kaldı · tek başına ayırt etmez.", RED)
	else:
		_tested_blue = true
		_set_feedback("Mavi şerit kırmızıya döndü · asit kanıtı.", RED)
	_update_stage()
	_update_progress()
	if _tested_red and _tested_blue:
		for child in _controls.get_children():
			if child is Button and (child.text.begins_with("Asit") or child.text.begins_with("Nötr") or child.text.begins_with("Baz")):
				(child as Button).disabled = false


func _classify(kind: String) -> void:
	if _locked or not (_tested_red and _tested_blue):
		return
	if kind == "acid":
		_locked = true
		_set_feedback("Doğru · mavi turnusol kırmızıya döndü.", GREEN)
		_instruction.text = "Asidik hat açıldı. Kanıtlar kayıt altında."
		completed.emit()
	else:
		_set_feedback("Eşleşmedi · iki şeridin renk değişimini karşılaştır.", AMBER)


func _measure(sample: int) -> void:
	if _locked:
		return
	_measured[sample] = true
	_set_feedback("Numune %s · pH %s" % ["A" if sample == 0 else "B", "4,6" if sample == 0 else "2,8"], MINT)
	_update_stage()
	_update_progress()


func _choose_valve(sample: int) -> void:
	if _locked or not (_measured[0] and _measured[1]):
		_set_feedback("Önce iki pH değerini ölç.", AMBER)
		return
	if sample == 1:
		_locked = true
		_open_valve = 1
		_update_stage()
		_set_feedback("B açıldı · pH 2,8 en düşük, asidik etkisi daha güçlü.", GREEN)
		_instruction.text = "B hattı akıyor. Ölçüm vanayı doğruladı."
		completed.emit()
	else:
		_set_feedback("Kapalı · daha düşük pH daha asidiktir.", AMBER)


func _reset() -> void:
	_locked = false
	_tested_red = false
	_tested_blue = false
	_measured = [false, false]
	_open_valve = -1
	_instruction.text = "Daha asidik numuneyi ölç ve vanasını aç." if _tyt else "İki turnusol şeridini dene, numuneyi sınıflandır."
	_feedback.text = "pH ölçer hazır · A ve B'yi ölç." if _tyt else "K-03 hazır · iki şeritten kanıt topla."
	_feedback.add_theme_color_override("font_color", INK)
	for child in _controls.get_children():
		if child is Button:
			var button := child as Button
			button.disabled = not _tyt and (button.text.begins_with("Asit") or button.text.begins_with("Nötr") or button.text.begins_with("Baz"))
	_update_stage()
	_update_progress()


func _update_progress() -> void:
	if _tyt:
		var count := int(_measured[0]) + int(_measured[1])
		_progress.text = "ÖLÇÜM  %d / 2" % count
	else:
		var count := int(_tested_red) + int(_tested_blue)
		_progress.text = "KANIT  %d / 2" % count


func _update_stage() -> void:
	if _stage != null:
		_stage.queue_redraw()


func _set_feedback(message: String, color: Color) -> void:
	_feedback.text = "●  " + message
	_feedback.add_theme_color_override("font_color", color)


func _panel() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.theme_type_variation = "ConsolePanel"
	return panel


func _label(value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = value
	if font_size >= 24:
		label.theme_type_variation = "HeadlineLabel"
	elif font_size <= 13:
		label.theme_type_variation = "SectionLabel"
	else:
		label.theme_type_variation = "MutedLabel" if color == MUTED else "Label"
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _add_button(value: String, action: Callable, primary := false) -> Button:
	var button := Button.new()
	button.text = value
	button.custom_minimum_size = Vector2(0, 38)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.focus_mode = Control.FOCUS_ALL
	if primary:
		button.theme_type_variation = "PrimaryButton"
	button.pressed.connect(action)
	_controls.add_child(button)
	return button


func _rule() -> Control:
	var rule := ColorRect.new()
	rule.color = EDGE
	rule.custom_minimum_size = Vector2(0, 1)
	return rule


func _spacer() -> Control:
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	spacer.custom_minimum_size.y = 4
	return spacer
