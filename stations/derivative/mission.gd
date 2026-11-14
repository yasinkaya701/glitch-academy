extends "res://scripts/mission.gd"
## AYT Matematik · Türev. Levhadan en büyük hacimli kutu: V(x) = x(a − 2x)².
## Oyuncu gerçek bir atölye deneyi yapar: köşe keser, kutuyu katlar, ölçü silindirine boşaltıp hacmi ölçer.

const BoxPlot = preload("res://stations/derivative/box_plot.gd")
const Workshop = preload("res://stations/derivative/workshop.gd")
const Hud = preload("res://scripts/mission_hud.gd")
const GOOD := Color("#8fbea0")
const BAD := Color("#df9a83")
const MUTED := Color("#b1ac9e")
const KEEP_SIDE := 12.0
const NEW_SIDE := 18.0
const MIN_MEASURES := 6
const SLOPE_TOLERANCE := 0.06

enum Step { INTRO, EXPLORE, SLOPE, APPLY, DONE }

var step := Step.INTRO
var plot: BoxPlot
var workshop: Workshop
var hud: Hud
var section: Label
var headline: Label
var body: Label
var readout: Label
var feedback: Label
var slider: HSlider
var slider_row: HBoxContainer
var answer_row: HBoxContainer
var answer: LineEdit
var action: Button
var measure: Button
var skip: Button
var measures: Dictionary[int, bool] = {}
var best_volume := 0.0
var wrong_answers := 0
var intro_tween: Tween
var pour_tween: Tween


func _ready() -> void:
	_build_ui()
	_enter_intro()


func _build_ui() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var view_frame := SubViewportContainer.new()
	view_frame.stretch = true
	view_frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(view_frame)
	var viewport := SubViewport.new()
	viewport.own_world_3d = true
	viewport.msaa_3d = Viewport.MSAA_4X
	view_frame.add_child(viewport)
	workshop = Workshop.new()
	viewport.add_child(workshop)

	# Grafik: sağ üstte, ölçümlerle dolan küçük bir cihaz ekranı.
	var graph_frame := PanelContainer.new()
	graph_frame.theme_type_variation = "GlassPanel"
	graph_frame.anchor_left = 1.0
	graph_frame.anchor_right = 1.0
	graph_frame.offset_left = -470.0
	graph_frame.offset_right = -24.0
	graph_frame.offset_top = 72.0
	graph_frame.offset_bottom = 340.0
	add_child(graph_frame)
	plot = BoxPlot.new()
	plot.size_flags_vertical = Control.SIZE_EXPAND_FILL
	plot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	graph_frame.add_child(plot)

	hud = Hud.new()
	add_child(hud)
	hud.action_pressed.connect(_on_action)
	hud.skip_pressed.connect(_skip_intro)
	action = hud.action
	skip = hud.skip
	skip.text = "Açılışı geç"

	slider_row = HBoxContainer.new()
	slider_row.add_theme_constant_override("separation", 12)
	slider = HSlider.new()
	slider.min_value = 0.1
	slider.max_value = 5.9
	slider.step = 0.05
	slider.value = 1.0
	slider.custom_minimum_size = Vector2(320, 0)
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	slider.value_changed.connect(_on_slider)
	slider_row.add_child(slider)
	measure = Button.new()
	measure.text = "Ölçüm ekle"
	measure.tooltip_text = "Seçili x değerindeki hacmi kaydet."
	measure.custom_minimum_size = Vector2(120, 0)
	measure.pressed.connect(_measure)
	slider_row.add_child(measure)
	hud.tools.add_child(slider_row)

	answer_row = HBoxContainer.new()
	answer_row.add_theme_constant_override("separation", 8)
	var x_label := Label.new()
	x_label.text = "x ="
	answer = LineEdit.new()
	answer.placeholder_text = "dm"
	answer.custom_minimum_size = Vector2(110, 0)
	answer.text_submitted.connect(func(_text: String) -> void: _submit_answer())
	var unit := Label.new()
	unit.text = "dm"
	unit.theme_type_variation = "MutedLabel"
	answer_row.add_child(x_label)
	answer_row.add_child(answer)
	answer_row.add_child(unit)
	hud.tools.add_child(answer_row)

	section = Label.new()
	headline = Label.new()
	body = Label.new()
	feedback = Label.new()
	readout = Label.new()
	readout.add_theme_color_override("font_color", Color("#dfae63"))
	readout.position = Vector2(28, 80)
	readout.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(readout)


const DIRECTIVES := {
	"Depo tahminle kesiyor": "Depo köşeleri tahminle kesiyor.",
	"Kutuyu kes, kat, ölç": "x'i ayarla, kutuyu ölç.",
	"Teğet ne söylüyor?": "Eğimi sıfır yapan x'i bul.",
	"Eğim sıfırsa tepe": "Eğim sıfır: hacim tepede.",
	"Yeni levha: a = 18 dm": "a = 18 dm: en büyük hacim için x'i hesapla.",
	"Depo en iyi kutuyu kesiyor": "Depo en iyi kutuyu kesiyor.",
}


func _set_ui(sec: String, head: String, text: String, button: String) -> void:
	hud.set_directive(DIRECTIVES.get(head, head))
	var parts := sec.split(" · ")
	if parts.size() == 2 and parts[0].is_valid_int():
		hud.set_steps(int(parts[0]), 3, parts[1])
	elif sec == "ONARILDI":
		hud.set_steps(3, 3, sec)
	else:
		hud.set_steps(0, 3, sec)
	hud.set_note(text)
	section.text = sec
	headline.text = head
	body.text = text
	action.text = button
	action.visible = button != ""
	action.disabled = false
	feedback.text = ""
	readout.text = ""


func _say(text: String, color: Color = MUTED) -> void:
	feedback.text = text
	var tone: StringName = &"neutral"
	if color == GOOD:
		tone = &"good"
	elif color == BAD:
		tone = &"bad"
	hud.say(text, tone)


func _pour(volume: float, seconds: float = 1.1) -> void:
	if pour_tween != null:
		pour_tween.kill()
	pour_tween = workshop.animate_pour(volume, seconds)


# --- Açılış -------------------------------------------------------------

func _enter_intro() -> void:
	step = Step.INTRO
	plot.side = KEEP_SIDE
	plot.measured.clear()
	plot.show_curve = false
	plot.show_point = false
	slider_row.hide()
	answer_row.hide()
	skip.show()
	workshop.set_side(KEEP_SIDE, 140.0)
	workshop.set_cut(3.0)
	workshop.cut_amount = 0.0
	workshop.fold_amount = 0.0
	_set_ui("ARIZA", "Depo tahminle kesiyor",
		"Depo, aynı levhadan daha çok malzeme sığdıracak kutuyu arıyor. Kesik büyürken kutu tabanı daralıyor; gerçek tepe noktasını ölçümle bul.", "")
	action.hide()
	intro_tween = create_tween()
	intro_tween.tween_property(workshop, "cut_amount", 1.0, 1.1).set_trans(Tween.TRANS_SINE)
	intro_tween.parallel().tween_callback(func() -> void: workshop.rebuild()).set_delay(0.0)
	intro_tween.tween_method(_set_fold, 0.0, 1.0, 1.4).set_trans(Tween.TRANS_SINE)
	intro_tween.tween_callback(func() -> void:
		_pour(BoxPlot.volume(KEEP_SIDE, 3.0), 1.2)
		_say("x = 3 dm kesildiğinde 108 L çıktı. Aynı levhadan 128 L'lik kutu üretmek mümkün mü?", BAD))
	intro_tween.tween_interval(2.6)
	intro_tween.tween_callback(_skip_intro)


func _set_fold(value: float) -> void:
	workshop.fold_amount = value
	workshop.rebuild()


func _process(_delta: float) -> void:
	if step == Step.INTRO and workshop.cut_amount > 0.0 and workshop.cut_amount < 1.0:
		workshop.rebuild()


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
	measure.show()
	plot.show_point = true
	plot.measured.clear()
	plot.show_curve = false
	measures.clear()
	best_volume = 0.0
	workshop.cut_amount = 1.0
	workshop.fold_amount = 1.0
	workshop.level = 0.0
	_set_ui("1 · DENE", "Kutuyu kes, kat, ölç",
		"Kenar uzunluğu 12 dm olan levhanın köşelerinden x dm kare kes. Kutuyu katla, kapasiteyi ölç ve grafiğe kaydet. Hedef: malzemeyi artırmadan en yüksek hacmi bulmak.", "Eğimi incele")
	action.disabled = true
	_update_measure_gate()
	slider.set_value_no_signal(1.0)
	workshop.set_cut(1.0)
	plot.cut = 1.0
	_say("En az %d farklı x için ölçüm yap." % MIN_MEASURES)
	_update_readout()
	plot.queue_redraw()


func _on_slider(value: float) -> void:
	if step != Step.EXPLORE and step != Step.SLOPE:
		return
	plot.cut = value
	workshop.set_cut(value)
	if step == Step.EXPLORE:
		workshop.level = 0.0
		_update_measure_control(value)
	_update_readout()
	plot.queue_redraw()


func _update_readout() -> void:
	var x := slider.value
	if step == Step.SLOPE:
		var m := BoxPlot.slope(plot.side, x)
		var direction := "artıyor" if m > 0.05 else ("azalıyor" if m < -0.05 else "değişmiyor")
		readout.text = "x = %s dm   V = %s L\nEğim V′ = %s  (hacim %s)" % [_num(x), _num(BoxPlot.volume(plot.side, x)), _num(m), direction]
	elif step == Step.EXPLORE:
		readout.text = "FARKLI x  ·  %d / %d\nx = %s dm   ·   V = %s L\nŞimdiye kadarki en büyük: %s L" % [measures.size(), MIN_MEASURES, _num(x), _num(BoxPlot.volume(plot.side, x)), _num(best_volume)]


func _update_measure_gate() -> void:
	var count := measures.size()
	action.text = "Eğimi incele  ·  %d/%d" % [count, MIN_MEASURES]
	action.disabled = count < MIN_MEASURES
	action.tooltip_text = "Eğimi incelemek için %d farklı x ölç." % MIN_MEASURES


func _update_measure_control(value: float) -> void:
	var key := roundi(value * 20.0)
	measure.disabled = measures.has(key)
	measure.text = "Ölçüldü" if measure.disabled else "Ölçüm ekle"
	measure.tooltip_text = "Bu x zaten ölçüldü; yeni bir değer seç." if measure.disabled else "x = %s dm değerini ölçüm grafiğine ekle." % _num(value)


func _measure() -> void:
	if step != Step.EXPLORE:
		return
	var x := slider.value
	var key := roundi(x * 20.0)
	if measures.has(key):
		_say("Bu x zaten ölçüldü; yeni bir değer seç.", BAD)
		return
	var volume := BoxPlot.volume(plot.side, x)
	_pour(volume)
	measures[key] = true
	plot.measured.append(Vector2(x, volume))
	best_volume = maxf(best_volume, volume)
	_update_measure_control(x)
	_update_measure_gate()
	_update_readout()
	var count := measures.size()
	if count >= MIN_MEASURES:
		plot.show_curve = true
		action.disabled = false
		_say("Silindir %s L gösterdi. Noktalar bir eğri çiziyor. Tepeyi buldun mu? Eğim bunu kesinleştirir." % _num(volume), GOOD)
	else:
		_say("Silindir %s L gösterdi. (%d / %d ölçüm)" % [_num(volume), count, MIN_MEASURES])
	plot.queue_redraw()


# --- Eğim ---------------------------------------------------------------

func _enter_slope() -> void:
	step = Step.SLOPE
	plot.show_tangent = true
	plot.show_curve = true
	measure.hide()
	_set_ui("2 · EĞİM", "Teğet ne söylüyor?",
		"Altın çizgi, o noktadaki anlık değişim hızını gösterir: türev. Eğim pozitifken hacim artıyor, negatifken azalıyor. Eğimi 0 yapan x'i bul.", "Bu x'i işaretle")
	action.disabled = false
	_on_slider(slider.value)


func _check_slope() -> void:
	var target := KEEP_SIDE / 6.0
	if absf(slider.value - target) <= SLOPE_TOLERANCE:
		plot.show_optimum = true
		_pour(BoxPlot.volume(KEEP_SIDE, target))
		plot.queue_redraw()
		_set_ui("2 · EĞİM", "Eğim sıfırsa tepe",
			"Türev V′(x) = (a − 2x)(a − 6x). Sıfır olduğu yerde x = a/6. a = 12 için x = 2 dm ve V = 128 L. Denemeyle bulamayacağın kesinlikte.", "Yeni levhaya geç")
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
	plot.measured.clear()
	plot.show_curve = false
	plot.show_point = false
	plot.show_tangent = false
	plot.show_optimum = false
	slider_row.hide()
	answer_row.show()
	answer.text = ""
	answer.editable = true
	wrong_answers = 0
	workshop.set_side(NEW_SIDE, 480.0)
	workshop.cut_amount = 1.0
	workshop.fold_amount = 0.0
	workshop.set_cut(0.0)
	_set_ui("3 · ONAR", "Yeni levha: a = 18 dm",
		"Depo yeni, daha büyük levhalarla çalışacak. Kutunun hacmi en büyük olacak x değerini hesapla ve gir.", "Kutuyu kes")
	action.remove_meta("go")
	plot.queue_redraw()


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
	workshop.set_cut(x)
	workshop.fold_amount = 0.0
	workshop.cut_amount = 0.0
	workshop.rebuild()
	var fold := create_tween()
	fold.tween_property(workshop, "cut_amount", 1.0, 0.7)
	fold.tween_method(_set_fold, 0.0, 1.0, 1.0).set_trans(Tween.TRANS_SINE)
	var volume := BoxPlot.volume(NEW_SIDE, x)
	plot.cut = x
	plot.show_point = true
	plot.show_curve = true
	fold.tween_callback(func() -> void: _pour(volume, 1.2))
	if absf(x - NEW_SIDE / 6.0) <= 0.01:
		plot.show_optimum = true
		plot.show_tangent = true
		answer.editable = false
		step = Step.DONE
		_set_ui("ONARILDI", "Depo en iyi kutuyu kesiyor",
			"x = a/6 = 3 dm. Hacim 432 L, bundan büyük kutu yok. Türev, aramadan en iyi değeri bulmanı sağladı.", "")
		readout.text = "V(3) = 3·(18 − 6)² = 432 L"
		answer_row.hide()
		_say("Onarıldı.", GOOD)
		completed.emit()
	else:
		wrong_answers += 1
		plot.show_tangent = true
		var m := BoxPlot.slope(NEW_SIDE, x)
		var hint := "Bu x'te eğim %s: x'i %s hacim büyür." % [("pozitif" if m > 0.0 else "negatif"), ("artırırsan" if m > 0.0 else "azaltırsan")]
		readout.text = "x = %s dm   Silindir: %s L" % [_num(x), _num(volume)]
		var extra := ""
		if wrong_answers >= 2:
			extra = "\nİpucu: a = 12 için x = 2 idi. x ile a arasındaki oranı bul."
		_say("Hacim en büyük değil. " + hint + extra, BAD)
	plot.queue_redraw()


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
