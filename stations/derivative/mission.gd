extends "res://scripts/mission.gd"
## AYT Matematik · Türev. Levhadan en büyük hacimli kutu: V(x) = x(a − 2x)².

const BoxPlot = preload("res://stations/derivative/box_plot.gd")
const GOOD := Color("#a0dfbc")
const BAD := Color("#ffb093")
const MUTED := Color("#b0c4bf")
const KEEP_SIDE := 12.0
const NEW_SIDE := 18.0
const MIN_TRIES := 6
const SLOPE_TOLERANCE := 0.06

enum Step { INTRO, EXPLORE, SLOPE, APPLY, DONE }

var step := Step.INTRO
var plot: BoxPlot
var section: Label
var headline: Label
var body: Label
var readout: Label
var feedback: Label
var slider: HSlider
var slider_row: Control
var answer_row: HBoxContainer
var answer: LineEdit
var action: Button
var skip: Button
var tried: Dictionary[int, bool] = {}
var best_volume := 0.0
var wrong_answers := 0
var intro_tween: Tween


func _ready() -> void:
	_build_ui()
	_enter_intro()


func _build_ui() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var root := HBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 16)
	add_child(root)

	var plot_frame := PanelContainer.new()
	plot_frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	plot_frame.add_theme_stylebox_override("panel", _panel_style(Color("#101f30")))
	root.add_child(plot_frame)
	plot = BoxPlot.new()
	plot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	plot.size_flags_vertical = Control.SIZE_EXPAND_FILL
	plot_frame.add_child(plot)

	var console := PanelContainer.new()
	console.custom_minimum_size = Vector2(360, 0)
	console.add_theme_stylebox_override("panel", _panel_style(Color("#13233a")))
	root.add_child(console)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	console.add_child(column)

	section = _label(13, Color("#77dfba"))
	headline = _label(21, Color("#e9f1ee"))
	body = _label(15, Color("#e9f1ee"))
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(section)
	column.add_child(headline)
	column.add_child(body)

	slider_row = VBoxContainer.new()
	slider = HSlider.new()
	slider.min_value = 0.1
	slider.max_value = 5.9
	slider.step = 0.05
	slider.value = 1.0
	slider.value_changed.connect(_on_slider)
	slider_row.add_child(slider)
	column.add_child(slider_row)

	readout = _label(16, Color("#ffc082"))
	readout.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(readout)

	answer_row = HBoxContainer.new()
	var x_label := _label(16, Color("#e9f1ee"))
	x_label.text = "x ="
	answer = LineEdit.new()
	answer.placeholder_text = "dm"
	answer.custom_minimum_size = Vector2(110, 0)
	answer.text_submitted.connect(func(_text: String) -> void: _submit_answer())
	var unit := _label(16, Color("#a0b5bf"))
	unit.text = "dm"
	answer_row.add_theme_constant_override("separation", 8)
	answer_row.add_child(x_label)
	answer_row.add_child(answer)
	answer_row.add_child(unit)
	column.add_child(answer_row)

	feedback = _label(15, MUTED)
	feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(feedback)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(spacer)

	action = Button.new()
	action.custom_minimum_size = Vector2(0, 44)
	action.pressed.connect(_on_action)
	column.add_child(action)
	skip = Button.new()
	skip.text = "Açılışı geç"
	skip.pressed.connect(_skip_intro)
	column.add_child(skip)


func _label(size: int, color: Color) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label


func _panel_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_border_width_all(1)
	style.border_color = Color("#35506a")
	style.set_corner_radius_all(10)
	style.set_content_margin_all(20)
	return style


func _set_ui(sec: String, head: String, text: String, button: String) -> void:
	section.text = sec
	headline.text = head
	body.text = text
	action.text = button
	feedback.text = ""
	readout.text = ""


func _say(text: String, color: Color = MUTED) -> void:
	feedback.text = text
	feedback.add_theme_color_override("font_color", color)


func _redraw() -> void:
	plot.queue_redraw()


# --- Açılış -------------------------------------------------------------

func _enter_intro() -> void:
	step = Step.INTRO
	plot.side = KEEP_SIDE
	plot.cut = 0.4
	plot.show_tangent = false
	plot.show_optimum = false
	plot.show_waste = false
	slider_row.hide()
	answer_row.hide()
	skip.show()
	action.hide()
	_set_ui("ARIZA", "Depo tahminle kesiyor",
		"Depo her levhada köşe karesini tahminle seçiyor. Kutular olabileceğinden küçük çıkıyor, malzeme boşa gidiyor.", "")
	intro_tween = create_tween()
	intro_tween.tween_method(_set_cut, 0.4, 3.0, 2.4).set_trans(Tween.TRANS_SINE)
	intro_tween.tween_callback(func() -> void:
		plot.show_waste = true
		_say("Seçilen x = 3 dm, hacim 108 dm³. Daha büyük bir kutu mümkün mü?", BAD)
		_redraw())
	intro_tween.tween_interval(1.6)
	intro_tween.tween_callback(_skip_intro)


func _set_cut(value: float) -> void:
	plot.cut = value
	_redraw()


func _skip_intro() -> void:
	if step != Step.INTRO:
		return
	if intro_tween != null:
		intro_tween.kill()
	_enter_explore()


# --- Keşif --------------------------------------------------------------

func _enter_explore() -> void:
	step = Step.EXPLORE
	skip.hide()
	action.show()
	slider_row.show()
	plot.show_waste = false
	plot.show_point = true
	tried.clear()
	best_volume = 0.0
	_set_ui("1 · DENE", "En büyük hacmi ara",
		"Kenarı 12 dm olan kare levhanın dört köşesinden x kadar kare kesilip katlanıyor. Kaydırıcıyla x'i değiştir, hacmin nasıl değiştiğini izle.", "Eğimi incele")
	action.disabled = true
	slider.set_value_no_signal(1.0)
	plot.cut = 1.0
	_on_slider(1.0)


func _on_slider(value: float) -> void:
	if step != Step.EXPLORE and step != Step.SLOPE:
		return
	plot.cut = value
	var volume := BoxPlot.volume(plot.side, value)
	if step == Step.EXPLORE:
		tried[roundi(value * 2.0)] = true
		best_volume = maxf(best_volume, volume)
		readout.text = "x = %s dm   V = %s dm³\nDenediğin en büyük: %s dm³" % [_num(value), _num(volume), _num(best_volume)]
		action.disabled = tried.size() < MIN_TRIES
		if action.disabled:
			_say("Farklı x değerleri dene (%d / %d)." % [tried.size(), MIN_TRIES])
		else:
			_say("Tepeyi buldun mu? Tahmin güvenilmez olabilir. Eğim bunu kesinleştirir.", GOOD)
	else:
		var m := BoxPlot.slope(plot.side, value)
		var direction := "artıyor" if m > 0.05 else ("azalıyor" if m < -0.05 else "değişmiyor")
		readout.text = "x = %s dm   V = %s dm³\nEğim V′ = %s  (hacim %s)" % [_num(value), _num(volume), _num(m), direction]
	_redraw()


# --- Eğim ---------------------------------------------------------------

func _enter_slope() -> void:
	step = Step.SLOPE
	plot.show_tangent = true
	_set_ui("2 · EĞİM", "Teğet ne söylüyor?",
		"Altın çizgi, o noktadaki anlık değişim hızını gösterir: türev. Eğim pozitifken hacim artıyor, negatifken azalıyor. Eğimi 0 yapan x'i bul.", "Bu x'i işaretle")
	action.disabled = false
	_on_slider(slider.value)


func _check_slope() -> void:
	var target := KEEP_SIDE / 6.0
	if absf(slider.value - target) <= SLOPE_TOLERANCE:
		plot.show_optimum = true
		_redraw()
		_set_ui("2 · EĞİM", "Eğim sıfırsa tepe",
			"Türev V′(x) = (a − 2x)(a − 6x). Sıfır olduğu yerde x = a/6. a = 12 için x = 2 dm ve V = 128 dm³. Denemeyle bulamayacağın kesinlikte.", "Yeni levhaya geç")
		readout.text = "V′(x) = (a − 2x)(a − 6x) = 0   →   x = a/6"
		_say("Doğru. Eğimin işaret değiştirdiği nokta en büyük hacimdir.", GOOD)
		action.set_meta("go", &"apply")
	else:
		var m := BoxPlot.slope(plot.side, slider.value)
		if m > 0.0:
			_say("Eğim hâlâ pozitif, hacim artıyor. x'i biraz daha büyüt.", BAD)
		else:
			_say("Eğim negatif, hacim azalıyor. x'i biraz küçült.", BAD)


# --- Uygulama -----------------------------------------------------------

func _enter_apply() -> void:
	step = Step.APPLY
	plot.side = NEW_SIDE
	plot.cut = 0.0
	plot.show_point = false
	plot.show_tangent = false
	plot.show_optimum = false
	slider_row.hide()
	answer_row.show()
	answer.text = ""
	answer.editable = true
	wrong_answers = 0
	_set_ui("3 · ONAR", "Yeni levha: a = 18 dm",
		"Depo yeni, daha büyük levhalarla çalışacak. Kutunun hacmi en büyük olacak x değerini hesapla ve gir.", "Kutuyu kes")
	action.disabled = false
	action.remove_meta("go")
	_redraw()


func _submit_answer() -> void:
	if step != Step.APPLY:
		return
	var text := answer.text.strip_edges().replace(",", ".")
	if not text.is_valid_float():
		_say("Bir sayı gir, örneğin 2,5.", BAD)
		return
	var x := text.to_float()
	if x <= 0.0 or x >= NEW_SIDE / 2.0:
		_say("x, 0 ile %s dm arasında olmalı. Aksi halde kutu oluşmaz." % _num(NEW_SIDE / 2.0), BAD)
		return
	plot.cut = x
	plot.show_point = true
	var volume := BoxPlot.volume(NEW_SIDE, x)
	if absf(x - NEW_SIDE / 6.0) <= 0.01:
		plot.show_optimum = true
		plot.show_tangent = true
		answer.editable = false
		step = Step.DONE
		_set_ui("ONARILDI", "Depo en iyi kutuyu kesiyor",
			"x = a/6 = 3 dm. Hacim 432 dm³, bundan büyük kutu yok. Türev, aramadan en iyi değeri bulmanı sağladı.", "Tamam")
		readout.text = "V(3) = 3·(18 − 6)² = 432 dm³"
		answer_row.hide()
		_say("Onarıldı.", GOOD)
		action.disabled = true
		completed.emit()
	else:
		wrong_answers += 1
		plot.show_tangent = true
		var m := BoxPlot.slope(NEW_SIDE, x)
		var hint := "Bu x'te eğim %s: x'i %s hacim büyür." % [("pozitif" if m > 0.0 else "negatif"), ("artırırsan" if m > 0.0 else "azaltırsan")]
		readout.text = "x = %s dm   V = %s dm³" % [_num(x), _num(volume)]
		var extra := ""
		if wrong_answers >= 2:
			extra = "\nİpucu: a = 12 için x = 2 idi. x ile a arasındaki oranı bul."
		_say("Hacim en büyük değil. " + hint + extra, BAD)
	_redraw()


# --- Akış ---------------------------------------------------------------

func _on_action() -> void:
	match step:
		Step.EXPLORE:
			_enter_slope()
		Step.SLOPE:
			if action.has_meta("go"):
				_enter_apply()
			else:
				_check_slope()
		Step.APPLY:
			_submit_answer()


func _num(value: float) -> String:
	if absf(value - roundf(value)) < 0.005:
		return str(int(roundf(value)))
	return ("%.2f" % value).replace(".", ",")
