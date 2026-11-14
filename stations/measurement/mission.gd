extends "res://scripts/mission.gd"

const Bench = preload("res://stations/measurement/bench.gd")
const TOOLS: Array[StringName] = [&"length", &"mass", &"time"]
const TITLES := ["Cetvel", "Terazi", "Sayaç"]
const HINTS := [
	"Parçanın bir ucunu sıfıra hizala ve cetvelden uzunluğunu oku.",
	"Yükü teraziye koy ve kütleyi ölç.",
	"Olayın başı ile sonu arasında geçen süreyi sayaçtan oku.",
]
const READINGS := ["Uzunluk  ·  180 cm", "Kütle  ·  1,2 kg", "Süre  ·  1,5 s"]
const SI_UNITS := ["m", "kg", "s"]
const UNIT_FEEDBACK := [
	"Metre uzunluğun SI birimidir. 1 m = 100 cm.",
	"Kilogram kütlenin SI birimidir.",
	"Saniye zamanın SI birimidir.",
]
const COLOR_MUTED := Color("#b0c4bf")
const COLOR_GOOD := Color("#a0dfbc")
const COLOR_BAD := Color("#ffb093")
const INTRO_DURATION := 3.0

@onready var bench: Bench = %Bench
@onready var section: Label = %Section
@onready var headline: Label = %Headline
@onready var body: Label = %Body
@onready var reading: Label = %Reading
@onready var feedback: Label = %Feedback
@onready var skip: Button = %Skip
@onready var measure: Button = %Measure
@onready var units: HBoxContainer = %Units
@onready var next: Button = %Next
@onready var answer_row: HBoxContainer = %AnswerRow
@onready var answer: LineEdit = %Answer
@onready var answer_unit: Label = %AnswerUnit
@onready var submit: Button = %Submit

var phase := &"intro"
var instrument_index := 0
var measured := false
var elapsed := 0.0
var motion: Tween


func _ready() -> void:
	skip.pressed.connect(_skip_intro)
	measure.pressed.connect(_measure)
	next.pressed.connect(_next)
	submit.pressed.connect(_submit_answer)
	answer.text_submitted.connect(_submit_answer)
	for button: Button in units.get_children():
		button.pressed.connect(_choose_unit.bind(button.text))
	_update_intro()


func _process(delta: float) -> void:
	if phase != &"intro":
		return
	elapsed += delta
	_update_intro()
	if elapsed >= INTRO_DURATION:
		_skip_intro()


func _unhandled_key_input(event: InputEvent) -> void:
	if phase == &"intro" and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_skip_intro()


func _update_intro() -> void:
	bench.show_state(&"fault", false, smoothstep(0.3, 1.15, elapsed), &"fault")
	if elapsed >= 1.15:
		_set_feedback("Taşıyıcı durdu. Kontrol cihazı santimetreyi metre olarak okuyor.", COLOR_BAD)


func _skip_intro() -> void:
	if phase != &"intro":
		return
	set_process(false)
	skip.hide()
	_show_instrument()


func _show_instrument() -> void:
	phase = &"instrument"
	measured = false
	section.text = "Ölçüm  %d / 3" % (instrument_index + 1)
	headline.text = TITLES[instrument_index]
	body.text = HINTS[instrument_index]
	reading.text = ""
	_set_feedback("")
	units.hide()
	measure.show()
	measure.disabled = false
	measure.text = "Ölç"
	bench.show_state(TOOLS[instrument_index], false, 0.0, &"idle")
	measure.grab_focus()


func _measure() -> void:
	if phase == &"instrument" and not measured:
		if TOOLS[instrument_index] == &"time":
			measure.disabled = true
			_animate_run(1.5, &"time", &"connected", _show_measurement)
			return
		_show_measurement()
	elif phase == &"guided":
		measure.disabled = true
		_set_feedback("")
		_animate_run(2.0, &"guided", &"connected", _show_guided_result)


func _show_measurement() -> void:
	measured = true
	reading.text = READINGS[instrument_index]
	_set_feedback("Bu büyüklüğün SI birimini seç.")
	measure.hide()
	units.show()
	var instrument := TOOLS[instrument_index]
	var final_progress := 1.0 if instrument == &"time" else 0.0
	var state := &"connected" if instrument == &"time" else &"idle"
	bench.show_state(instrument, true, final_progress, state)
	units.get_child(0).grab_focus()


func _choose_unit(unit: String) -> void:
	if phase != &"instrument" or not measured:
		return
	if unit != SI_UNITS[instrument_index]:
		_set_feedback("%s birimi %s için kullanılır. Yeniden seç." % [unit, _quantity_for_unit(unit)], COLOR_BAD)
		return
	_set_feedback(UNIT_FEEDBACK[instrument_index], COLOR_GOOD)
	units.hide()
	if instrument_index < TOOLS.size() - 1:
		instrument_index += 1
		phase = &"instrument_done"
		next.text = "Sonraki ölçüm"
	else:
		phase = &"guided_ready"
		next.text = "Taşıyıcıyı izle"
	next.show()
	next.grab_focus()


func _quantity_for_unit(unit: String) -> String:
	match unit:
		"m":
			return "uzunluk"
		"kg":
			return "kütle"
		_:
			return "süre"


func _next() -> void:
	next.hide()
	match phase:
		&"instrument_done":
			_show_instrument()
		&"guided_ready":
			_show_guided()
		&"guided_done":
			_show_conversion()


func _show_guided() -> void:
	phase = &"guided"
	section.text = "Yönlendirmeli ölçüm"
	headline.text = "Sürat ve yön"
	body.text = "Taşıyıcı 3 m boyunca doğuya gider. Hareketi başlat ve süreyi izle."
	reading.text = ""
	_set_feedback("")
	measure.text = "Hareketi başlat"
	measure.disabled = false
	measure.show()
	bench.show_state(&"guided", false, 0.0, &"connected")
	measure.grab_focus()


func _show_guided_result() -> void:
	phase = &"guided_done"
	bench.show_state(&"guided", true, 1.0, &"connected")
	reading.text = "Ortalama sürat = toplam yol ÷ toplam süre\n3 m ÷ 2 s = 1,5 m/s"
	_set_feedback("Sürat skalerdir. Hız vektörü yön de taşır. Bu hareket doğuya doğru.")
	measure.hide()
	next.text = "Rayı onar"
	next.show()
	next.grab_focus()


func _show_conversion() -> void:
	phase = &"convert"
	section.text = "Uygulama  1 / 2"
	headline.text = "Bağlantıyı tak"
	body.text = "Yeni ray parçasının uzunluğu 240 cm. Kontrol cihazına metre cinsinden gir."
	reading.text = "1 m = 100 cm"
	bench.show_state(&"convert", true, 0.0, &"idle")
	_set_feedback("")
	_prepare_input("m")


func _show_speed() -> void:
	phase = &"speed"
	section.text = "Uygulama  2 / 2"
	headline.text = "Taşıyıcıyı çalıştır"
	body.text = "Taşıyıcı 6 m yolu 3 s’de almalı. Gerekli ortalama sürati gir."
	reading.text = "Ortalama sürat = toplam yol ÷ toplam süre"
	bench.show_state(&"speed", true, 0.0, &"connected")
	_set_feedback("Bağlantı oturdu.", COLOR_GOOD)
	_prepare_input("m/s")


func _prepare_input(unit: String) -> void:
	answer_unit.text = unit
	answer.text = ""
	answer_row.show()
	answer.grab_focus()


func _submit_answer(_submitted := "") -> void:
	if phase != &"convert" and phase != &"speed":
		return
	var normalized := answer.text.strip_edges().replace(",", ".")
	if not normalized.is_valid_float() or not is_finite(normalized.to_float()) or normalized.to_float() <= 0.0:
		_set_feedback("Sıfırdan büyük bir sayı gir. Birim girişin yanında yazıyor.", COLOR_BAD)
		return
	var value := normalized.to_float()
	if phase == &"convert":
		if is_equal_approx(value, 2.4):
			_show_speed()
		else:
			var state := &"too_long" if value > 2.4 else &"too_short"
			bench.show_state(&"convert", true, 0.0, state)
			_set_feedback("Bu uzunluk yuvaya sığmaz." if value > 2.4 else "Parça kısa kaldı. Raydaki boşluk kapanmadı.", COLOR_BAD)
			answer.select_all()
		return
	if not is_equal_approx(value, 2.0):
		_set_feedback("Bu süratle 6 m yol 3 s’de tamamlanmaz. Taşıyıcı bekliyor.", COLOR_BAD)
		answer.select_all()
		return
	phase = &"running"
	answer_row.hide()
	_set_feedback("Bağlantı ve sürat ayarı doğrulandı.", COLOR_GOOD)
	_animate_run(3.0, &"running", &"connected", _complete)


func _animate_run(duration: float, kind: StringName, state: StringName, done: Callable) -> void:
	if motion != null:
		motion.kill()
	motion = create_tween()
	var update := func(progress: float) -> void:
		bench.show_state(kind, false, progress, state)
	motion.tween_method(update, 0.0, 1.0, duration)
	motion.tween_callback(done)


func _complete() -> void:
	phase = &"complete"
	section.text = "Onarıldı"
	headline.text = "Ray yeniden çalışıyor"
	body.text = "Bağlantı 2,4 m. Taşıyıcı 6 m yolu 3 s’de tamamladı."
	reading.text = "6 m ÷ 3 s = 2 m/s"
	_set_feedback("")
	bench.show_state(&"complete", true, 1.0, &"complete")
	completed.emit()


func _set_feedback(value: String, color := COLOR_MUTED) -> void:
	feedback.text = value
	feedback.add_theme_color_override("font_color", color)
