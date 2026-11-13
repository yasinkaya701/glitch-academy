extends "res://scripts/mission.gd"
## LGS · Kalıtım Laboratuvarı. Deneysel çaprazlama, kanıt ve yeni duruma transfer.
## Hücreler eşit olasılıkları temsil eder; gerçek dört yavrunun kesin sayısı değildir.

const Sim = preload("res://stations/genetics/genetics_model.gd")
const LAB = preload("res://scenes/experiment_3d.tscn")
const INK := Color("#e8f1f2")
const MUTED := Color("#a7bbc5")
const MINT := Color("#6fe3c1")
const WARM := Color("#f2a65a")
const WRONG := Color("#e5645a")
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


func _ready() -> void:
	_build_ui()
	_build_3d_seeds()
	_show_cross("AA", "aa", true)
	_feedback.text = "MERİDYEN, çekinik a alelini kayıtlardan siliyor. İki çaprazlamayı incele."


func _build_ui() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var background := ColorRect.new()
	background.color = Color("#070b12")
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
	frame.custom_minimum_size = Vector2(420, 225)
	left.add_child(frame)
	var experiment := LAB.instantiate() as Control
	experiment.name = "SeedPreview"
	experiment.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	experiment.size_flags_vertical = Control.SIZE_EXPAND_FILL
	frame.add_child(experiment)

	var board_panel := PanelContainer.new()
	board_panel.theme_type_variation = "GlassPanel"
	board_panel.custom_minimum_size.y = 180
	left.add_child(board_panel)
	_board = Control.new()
	_board.custom_minimum_size = Vector2(400, 184)
	_board.draw.connect(_draw_board)
	board_panel.add_child(_board)

	var right := PanelContainer.new()
	right.theme_type_variation = "ConsolePanel"
	right.custom_minimum_size.x = 350
	right.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main.add_child(right)
	var panel := VBoxContainer.new()
	panel.add_theme_constant_override("separation", 10)
	right.add_child(panel)
	_counter = _label("KANIT 0 / 2", 13, WARM)
	panel.add_child(_counter)
	panel.add_child(_label("MERİDYEN'İN HATASI", 12, WRONG))
	var warning := _label("Baskın alel görünüyorsa çekinik alel yok sayılır. Bu yüzden yeşil tohum oluşamaz.", 15, MUTED)
	warning.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(warning)
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
	panel.add_child(foot)


func _build_3d_seeds() -> void:
	var preview := find_child("SeedPreview", true, false) as Control
	var stage := preview.get_node("Viewport/World/Model") as Node3D
	for index in range(4):
		var seed := MeshInstance3D.new()
		var mesh := SphereMesh.new()
		mesh.radius = 0.34
		mesh.height = 0.68
		seed.mesh = mesh
		seed.position = Vector3(-0.65 if index % 2 == 0 else 0.65, 0.43, -0.50 if index < 2 else 0.50)
		var material := StandardMaterial3D.new()
		material.roughness = 0.58
		seed.material_override = material
		stage.add_child(seed)
		_seeds.append(seed)


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
	for percent in [0, 25, 50, 75, 100]:
		_button("Çekinik olasılığı  %d%%" % percent, _predict.bind(percent), percent == 50)


func _predict(percent: int) -> void:
	if _phase != 1:
		return
	if percent != 50:
		_feedback.text = "Ölçüm uyuşmadı. İlk ebeveyn A veya a, ikinci ebeveyn daima a verir. Hangi birleşmeler aa?"
		_feedback.add_theme_color_override("font_color", WRONG)
		return
	_phase = 2
	_show_cross("Aa", "aa", true)
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


func _draw_board() -> void:
	var s := _board.size
	var cell := minf(68.0, (s.y - 34.0) * 0.43)
	var x := 130.0
	var y := 31.0
	var font := ThemeDB.fallback_font
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
			var tint := Color("#17322c") if genotype == "aa" else Color("#3b3420") if genotype != "?" else Color("#1b2936")
			_board.draw_rect(rect, tint, true)
			_board.draw_rect(rect, Color("#506778"), false, 1.0)
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
	button.custom_minimum_size.y = 43
	if primary:
		button.theme_type_variation = "PrimaryButton"
	button.pressed.connect(callback)
	_actions.add_child(button)
	return button
