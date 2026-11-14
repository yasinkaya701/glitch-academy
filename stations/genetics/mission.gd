extends "res://scripts/mission.gd"
## AYT Biyoloji · Kalıtım. Çaprazlama, olasılık ve yeni duruma transfer.
## Hücreler eşit olasılıkları temsil eder; gerçek dört yavrunun kesin sayısı değildir.

const Sim = preload("res://stations/genetics/genetics_model.gd")
const GeneticsStage3D = preload("res://stations/genetics/genetics_stage_3d.gd")
const INK := Color("#eeeae0")
const MUTED := Color("#b1ac9e")
const MINT := Color("#8fbea0")
const WARM := Color("#dfae63")
const WRONG := Color("#e18b78")
const YELLOW := Color("#e9c477")
const GREEN := Color("#91c79b")

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
var _main: BoxContainer
var _right_panel: PanelContainer


func _ready() -> void:
	_build_ui()
	_build_3d_seeds()
	_show_cross("AA", "aa", true)
	_feedback.text = "Önce iki çaprazlamayı incele. Genotip ile fenotip olasılığını ayrı kaydet."
	resized.connect(_layout_ui)
	_layout_ui()


func _build_ui() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var background := ColorRect.new()
	background.color = UITheme.GAME_BG
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 18)
	add_child(margin)
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 10)
	margin.add_child(outer)
	outer.add_child(_label("AYT BİYOLOJİ  /  KALITIM VE OLASILIK", 13, MINT))
	outer.add_child(_label("Görünmeyen alel", 27, INK, true))
	_instruction = _label("Baskın fenotip çekinik aleli silmez. Ebeveyn gametlerini eşleştir, genotipi fenotipten ayır.", 16, INK)
	_instruction.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	outer.add_child(_instruction)

	_main = BoxContainer.new()
	_main.vertical = false
	var main := _main
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
	_graphite(frame)
	frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	frame.custom_minimum_size = Vector2(0, 230)
	left.add_child(frame)
	var experiment := GeneticsStage3D.new()
	experiment.name = "SeedPreview"
	experiment.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	experiment.size_flags_vertical = Control.SIZE_EXPAND_FILL
	frame.add_child(experiment)

	var board_panel := PanelContainer.new()
	_graphite(board_panel)
	board_panel.custom_minimum_size.y = 166
	left.add_child(board_panel)
	_board = Control.new()
	_board.custom_minimum_size = Vector2(360, 166)
	_board.draw.connect(_draw_board)
	board_panel.add_child(_board)

	var right := PanelContainer.new()
	_graphite(right)
	_right_panel = right
	right.custom_minimum_size.x = 320
	right.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main.add_child(right)
	var panel := VBoxContainer.new()
	panel.add_theme_constant_override("separation", 10)
	right.add_child(panel)
	_counter = _label("GÖZLEM 0 / 2", 13, WARM)
	panel.add_child(_counter)
	_rule_heading = _label("KAYITTAKİ YANILGI", 12, WRONG)
	panel.add_child(_rule_heading)
	_rule_label = _label("Baskın özellik görünürse çekinik alel kaybolur.", 15, MUTED)
	_rule_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(_rule_label)
	_feedback = _label("", 16, INK)
	_feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_feedback.custom_minimum_size.y = 82
	panel.add_child(_feedback)
	_actions = VBoxContainer.new()
	_actions.add_theme_constant_override("separation", 8)
	panel.add_child(_actions)
	_button("1  ·  AA × aa — gametleri eşleştir", _select_example.bind(0))
	_button("2  ·  Aa × Aa — çekinik fenotipi bul", _select_example.bind(1))
	_advance = _button("Yeni çaprazlamada uygula", _enter_prediction, true)
	_advance.disabled = true
	var foot := _label("Punnett karesi olasılığı verir; dört gerçek yavruda kesin sayı garantilemez.", 13, MUTED)
	foot.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	outer.add_child(foot)


## Bu istasyonun yazıları açık renktir; ortak temanın açık panelleri yerine görev içi grafit zemin kullanılır.
func _graphite(panel: PanelContainer) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#191a17")
	style.border_color = Color("#3b3d35")
	style.set_border_width_all(1)
	style.set_corner_radius_all(12)
	style.set_content_margin_all(14)
	panel.add_theme_stylebox_override("panel", style)


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
		button.custom_minimum_size.y = 36
	var bench := preview.find_child("Bench", true, false) as MeshInstance3D
	if bench != null:
		var bench_material := bench.material_override as StandardMaterial3D
		if bench_material != null:
			bench_material.albedo_color = UITheme.GAME_RAISED
	preview._readout.add_theme_color_override("font_color", INK)
	preview._readout.add_theme_color_override("font_shadow_color", UITheme.GAME_BG)
	preview._readout.add_theme_constant_override("shadow_outline_size", 5)
	preview._readout.text = "OLASILIK HÜCRELERİ"


func _layout_ui() -> void:
	if _main == null or _right_panel == null:
		return
	var width := get_viewport_rect().size.x
	var compact := width < 940.0
	_main.vertical = compact
	_main.add_theme_constant_override("separation", 10 if compact else 14)
	_right_panel.custom_minimum_size.x = 0.0 if compact else 320.0


func _select_example(index: int) -> void:
	if _phase != 0:
		return
	_observed[index] = true
	if index == 0:
		_show_cross("AA", "aa", true)
		_feedback.text = "Dört birleşmenin hepsi Aa. Baskın fenotip görünür; her yavru yine de çekinik a alelini taşır."
	else:
		_show_cross("Aa", "Aa", true)
		_feedback.text = "AA, Aa, Aa, aa: genotip oranı 1:2:1; fenotipte çekinik olasılık %25."
	_counter.text = "GÖZLEM %d / 2" % (int(_observed[0]) + int(_observed[1]))
	_advance.disabled = not (_observed[0] and _observed[1])


func _enter_prediction() -> void:
	if _phase != 0 or not (_observed[0] and _observed[1]):
		return
	_phase = 1
	_show_cross("Aa", "aa", false)
	_instruction.text = "Aktarım sorusu: Aa × aa çaprazlamasında aa genotipli yavru olasılığını bul."
	_counter.text = "AKTARIM  ·  TAHMİN"
	_feedback.text = "Önce her ebeveynin oluşturabileceği gametleri yaz. Dört olasılıktan kaçında aa oluşur?"
	_clear_actions()
	_prediction = LineEdit.new()
	_prediction.placeholder_text = "aa olasılığı (%)"
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
		_feedback.text = "Birlikte sayalım: Aa ebeveyni A ya da a; aa ebeveyni yalnız a gameti verir. Dört eş olasılığın ikisi aa olur."
		_feedback.add_theme_color_override("font_color", WRONG)
		return
	_phase = 2
	_show_cross("Aa", "aa", true)
	_rule_heading.text = "KAVRAM DOĞRULANDI"
	_rule_heading.add_theme_color_override("font_color", MINT)
	_rule_label.text = "Alel, baskın fenotipte de genotipte taşınabilir."
	_feedback.text = "DOĞRU  ·  Aa × aa → Aa, Aa, aa, aa. Genotip oranı 1:1; çekinik fenotip olasılığı %50."
	_feedback.add_theme_color_override("font_color", MINT)
	_instruction.text = "Çekinik alel, heterozigot bireyde fenotipte görünmeden taşınabilir."
	_counter.text = "AKTARIM TAMAMLANDI"
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
			material.albedo_color = Color("#55564f")
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
			var tint := Color("#384337") if genotype == "aa" else Color("#443a2c") if genotype != "?" else Color("#292a25")
			_board.draw_rect(rect, tint, true)
			_board.draw_rect(rect, Color("#777265"), false, 1.0)
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
