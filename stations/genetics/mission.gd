extends "res://scripts/mission.gd"
## LGS · Kalıtım Laboratuvarı. Deneysel çaprazlama, kanıt ve yeni duruma transfer.
## Hücreler eşit olasılıkları temsil eder; gerçek dört yavrunun kesin sayısı değildir.

const Sim = preload("res://stations/genetics/genetics_model.gd")
const GeneticsStage3D = preload("res://stations/genetics/genetics_stage_3d.gd")
const INK := Color("#22332f")
const MUTED := Color("#66766d")
const MINT := Color("#3b7867")
const WARM := Color("#a46535")
const WRONG := Color("#b04e45")
const YELLOW := Color("#e5c15c")
const GREEN := Color("#78ba8c")

var _phase := 0   # 0: örnekle, 1: öngör, 2: onarıldı
var _parent_a := "AA"
var _parent_b := "aa"
var _offspring := PackedStringArray()
var _revealed := true
var _observed: Array[bool] = [false, false]
var _seeds: Array[MeshInstance3D] = []
var _board: Control
var _actions: VBoxContainer
var _instruction: Label
var _feedback: Label
var _counter: Label
var _advance: Button
var _prediction: LineEdit
var _rule_label: Label
var _rule_heading: Label


func _ready() -> void:
	_build_ui()
	_build_3d_seeds()
	_show_cross("AA", "aa", true)
	_feedback.text = "İlk örneği seç, sonra ikinci çaprazlamayı karşılaştır."


func _build_ui() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var background := ColorRect.new()
	background.color = Color("#f4f6f2")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 22)
	add_child(margin)
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 10)
	margin.add_child(outer)
	outer.add_child(_label("LGS / FEN BİLİMLERİ / KALITIM", 13, MINT))
	outer.add_child(_label("Silinen Alel", 27, INK, true))
	_instruction = _label("A baskın (sarı), a çekinik (yeşil). Ebeveynlerden gelen alelleri karşılaştır.", 16, INK)
	_instruction.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	outer.add_child(_instruction)

	var main := HBoxContainer.new()
	main.add_theme_constant_override("separation", 14)
	main.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer.add_child(main)
	var left := VBoxContainer.new()
	left.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.size_flags_stretch_ratio = 1.4
	left.add_theme_constant_override("separation", 10)
	main.add_child(left)

	var frame := PanelContainer.new()
	frame.theme_type_variation = "GlassPanel"
	frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	frame.custom_minimum_size = Vector2(420, 210)
	left.add_child(frame)
	var experiment := GeneticsStage3D.new()
	experiment.name = "SeedPreview"
	experiment.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	experiment.size_flags_vertical = Control.SIZE_EXPAND_FILL
	frame.add_child(experiment)

	var board_panel := PanelContainer.new()
	board_panel.theme_type_variation = "GlassPanel"
	board_panel.custom_minimum_size.y = 150
	left.add_child(board_panel)
	_board = Control.new()
	_board.custom_minimum_size = Vector2(400, 150)
	_board.draw.connect(_draw_board)
	board_panel.add_child(_board)

	var right := PanelContainer.new()
	right.theme_type_variation = "ConsolePanel"
	right.custom_minimum_size.x = 400
	right.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main.add_child(right)
	var panel := VBoxContainer.new()
	panel.add_theme_constant_override("separation", 10)
	right.add_child(panel)
	_counter = _label("KANIT 0 / 2", 13, WARM)
	panel.add_child(_counter)
	_rule_heading = _label("MERİDYEN'İN HATASI", 12, WRONG)
	panel.add_child(_rule_heading)
	_rule_label = _label("MERİDYEN çekinik a alelini kayıttan siliyor.", 15, MUTED)
	_rule_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(_rule_label)
	_feedback = _label("", 16, INK)
	_feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_feedback.custom_minimum_size.y = 72
	panel.add_child(_feedback)
	_actions = VBoxContainer.new()
	_actions.add_theme_constant_override("separation", 8)
	panel.add_child(_actions)
	_button("01  AA × aa  ·  İlk gözlem", _select_example.bind(0))
	_button("02  Aa × Aa  ·  İkinci gözlem", _select_example.bind(1))
	_advance = _button("Yeni duruma uygula", _enter_prediction, true)
	_advance.disabled = true
	var foot := _label("Her kutu %25 olasılıktır; dört gerçek yavrunun kesin dağılımı değildir.", 13, MUTED)
	foot.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	outer.add_child(foot)


func _build_3d_seeds() -> void:
	var preview = find_child("SeedPreview", true, false)
	_seeds = preview.seeds
	var camera_controls := preview.get_node("CameraControls") as HBoxContainer
	preview.remove_child(camera_controls)
	_board.add_child(camera_controls)
	camera_controls.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	camera_controls.offset_left = -300
	camera_controls.offset_right = -12
	camera_controls.offset_top = -44
	camera_controls.offset_bottom = -6
	var names := ["Sola", "Sağa", "Sıfırla"]
	for index in camera_controls.get_child_count():
		var button := camera_controls.get_child(index) as Button
		button.text = names[index]
		button.tooltip_text = "3D kamera: " + names[index].to_lower()


func _select_example(index: int) -> void:
	if _phase != 0:
		return
	_observed[index] = true
	if index == 0:
		_show_cross("AA", "aa", true)
		_feedback.text = "Dört eşit olasılıklı birleşmenin hepsi Aa: sarı görünür, a aleli kaybolmaz."
	else:
		_show_cross("Aa", "Aa", true)
		_feedback.text = "AA, Aa, Aa, aa: %25 çekinik fenotip mümkün. MERİDYEN'in kaydı yanlış."
	_counter.text = "KANIT %d / 2" % (int(_observed[0]) + int(_observed[1]))
	_advance.disabled = not (_observed[0] and _observed[1])


func _enter_prediction() -> void:
	if _phase != 0 or not (_observed[0] and _observed[1]):
		return
	_phase = 1
	_show_cross("Aa", "aa", false)
	_instruction.text = "Yeni arıza: Aa × aa. Yeşil (aa) tohum olasılığını tahmin et."
	_counter.text = "UYGULAMA  ·  TAHMİN"
	_feedback.text = "Dört eşit olasılıklı hücre var. Sonucu görmeden kaçının aa olacağını düşün."
	_clear_actions()
	_prediction = LineEdit.new()
	_prediction.placeholder_text = "Çekinik olasılığı (%)"
	_prediction.text_submitted.connect(func(_value): _submit_prediction())
	_actions.add_child(_prediction)
	_button("Tahmini sına", _submit_prediction, true)
	_prediction.grab_focus()


func _submit_prediction() -> void:
	if _phase != 1:
		return
	var value := _prediction.text.strip_edges().trim_suffix("%").strip_edges()
	if not value.is_valid_int() or int(value) < 0 or int(value) > 100:
		_feedback.text = "Yüzdeyi 0 ile 100 arasında bir tam sayı olarak yaz."
		return
	_predict(int(value))


func _predict(percent: int) -> void:
	if _phase != 1:
		return
	if percent != 50:
		_feedback.text = "Ölçüm uyuşmadı. İlk ebeveyn A veya a, ikinci ebeveyn daima a verir. Hangi birleşmeler aa?"
		_feedback.add_theme_color_override("font_color", WRONG)
		return
	_phase = 2
	_show_cross("Aa", "aa", true)
	_rule_heading.text = "Onarılan kayıt"
	_rule_heading.add_theme_color_override("font_color", MINT)
	_rule_label.text = "Çekinik a aleli kayıtta korunuyor."
	_feedback.text = "ONARILDI  ·  Aa, Aa, aa, aa. Çekinik fenotip olasılığı %50."
	_feedback.add_theme_color_override("font_color", MINT)
	_instruction.text = "Çekinik alel silinmez. Yeni kuşakta yeniden görünür."
	_counter.text = "GENETİK KAYIT DÜZELTİLDİ"
	_clear_actions()
	completed.emit()


func _show_cross(first: String, second: String, visible_result: bool) -> void:
	_parent_a = first
	_parent_b = second
	_revealed = visible_result
	_offspring = Sim.cross(first, second)
	for index in range(_seeds.size()):
		var material := _seeds[index].material_override as StandardMaterial3D
		if not _revealed:
			material.albedo_color = Color("#61717e")
		elif _offspring[index] == "aa":
			material.albedo_color = GREEN
		else:
			material.albedo_color = YELLOW
	if _board != null:
		_board.queue_redraw()
	var preview = find_child("SeedPreview", true, false)
	if preview != null:
		preview.show_genotypes(_offspring, _revealed)


func _draw_board() -> void:
	var s := _board.size
	var cell := minf(60.0, (s.y - 66.0) / 2.0)
	var x := 130.0
	var y := 31.0
	var font := UITheme.FONT
	_board.draw_string(font, Vector2(20, 24), "%s × %s" % [_parent_a, _parent_b], HORIZONTAL_ALIGNMENT_LEFT, -1, 17, INK)
	var first := Sim.gametes(_parent_a)
	var second := Sim.gametes(_parent_b)
	for col in range(2):
		_board.draw_string(font, Vector2(x + cell * col, y + 18), first[col], HORIZONTAL_ALIGNMENT_CENTER, cell, 17, WARM)
	for row in range(2):
		_board.draw_string(font, Vector2(x - 32, y + 45 + cell * row), second[row], HORIZONTAL_ALIGNMENT_CENTER, 28, 17, MINT)
		for col in range(2):
			var index := col * 2 + row
			var genotype := _offspring[index] if _revealed else "?"
			var rect := Rect2(x + cell * col, y + 25 + cell * row, cell - 4, cell - 4)
			var tint := Color("#e0eee6") if genotype == "aa" else Color("#f6eadf") if genotype != "?" else Color("#edf1ec")
			_board.draw_rect(rect, tint, true)
			_board.draw_rect(rect, Color("#bdccc3"), false, 1.0)
			_board.draw_string(font, rect.position + Vector2(0, cell * 0.59), genotype, HORIZONTAL_ALIGNMENT_CENTER, cell - 4, 18, INK)
	var note := "Olasılık: %d%% çekinik" % roundi(Sim.recessive_probability(_parent_a, _parent_b) * 100.0) if _revealed else "Önce tahmin et"
	_board.draw_string(font, Vector2(x + 2 * cell + 12, y + 70), note, HORIZONTAL_ALIGNMENT_LEFT, maxf(10.0, s.x - x - 2 * cell - 12), 13, MUTED)


func _clear_actions() -> void:
	for child in _actions.get_children():
		_actions.remove_child(child)
		child.queue_free()


func _label(value: String, font_size: int, tint: Color, heading: bool = false) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", tint)
	if heading:
		label.theme_type_variation = "HeadlineLabel"
	return label


func _button(value: String, callback: Callable, primary: bool = false) -> Button:
	var button := Button.new()
	button.text = value
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.custom_minimum_size.y = 43
	if primary:
		button.theme_type_variation = "PrimaryButton"
	button.pressed.connect(callback)
	_actions.add_child(button)
	return button
