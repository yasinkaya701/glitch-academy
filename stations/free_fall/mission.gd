extends "res://scripts/mission.gd"
## AYT Fizik · Hareket. Düşüş Odası: cihaz havayı hesaba katmıyor. Oyuncu havayı boşaltıp süreyi karşılaştırır,
## nedeni seçer, g'yi ölçer ve kapsülü 3,00 s'de sensöre ulaştıracak yüksekliği hesaplar.
## Hareket fall_sim.gd'de, çizim fall_stage.gd'de.

const Stage = preload("res://stations/free_fall/fall_stage.gd")
const Fall = preload("res://stations/free_fall/fall_sim.gd")
const Hud = preload("res://scripts/mission_hud.gd")

const GOOD := Color("#a0dfbc")
const BAD := Color("#ffb093")
const MUTED := Color("#b0c4bf")

const DROP_HEIGHT := 20.0         ## m, deney yüksekliği
const TARGET_TIME := 3.0          ## s, kapsülün sensöre varış hedefi
const G_TOLERANCE := 0.3          ## m/s²
const TIME_TOLERANCE := 0.05      ## s
const VACUUM_LIMIT := 3.0         ## kPa altında "vakum" sayılır

enum Step { INTRO, OBSERVE, VACUUM, REASON, MEASURE, APPLY, DONE }

var step := Step.INTRO
var stage: Stage
var hud: Hud
var tools: HBoxContainer
var slider: HSlider
var slider_label: Label
var slow_button: Button
var entry: LineEdit
var drops := 0
var wrong := 0
var _intro_timer: SceneTreeTimer


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	stage = Stage.new()
	stage.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	stage.landed.connect(_on_landed)
	add_child(stage)
	hud = Hud.new()
	add_child(hud)
	hud.action_pressed.connect(_on_action)
	hud.skip_pressed.connect(_finish_intro)
	hud.back_pressed.connect(_go_back)
	tools = hud.tools
	_enter_intro()


func _go_back() -> void:
	if get_parent() == get_tree().root:
		get_tree().change_scene_to_file("res://scenes/control_center.tscn")
	else:
		exit_requested.emit()


func _clear_tools() -> void:
	for child in tools.get_children():
		child.queue_free()
	slider = null
	entry = null


func _screen(index: int, label: String, directive: String, action_text: String = "", note: String = "", powers: bool = false) -> void:
	hud.set_steps(index, 5, label)
	hud.set_directive(directive)
	hud.set_note(note)
	hud.set_action(action_text, action_text != "")
	hud.skip.hide()
	_clear_tools()
	stage.time_scale = 1.0
	if powers:
		_add_powers()


## Zaman Makinesi güçleri: Sar (bırakma anına dön) ve Yavaşlat (¼ hız).
func _add_powers() -> void:
	var rewind := Button.new()
	rewind.text = "⟲  Sar"
	rewind.tooltip_text = "Cisimleri bırakma anına geri götür"
	rewind.pressed.connect(func() -> void:
		stage.rewind()
		Sfx.play(&"click", -12.0)
		if hud.action.text == "Bırak" or hud.action.text == "Ayarla ve bırak":
			hud.set_action(hud.action.text, true))
	tools.add_child(rewind)
	slow_button = Button.new()
	slow_button.text = "◐  Yavaşlat"
	slow_button.toggle_mode = true
	slow_button.tooltip_text = "Zamanı ¼ hıza çek"
	slow_button.toggled.connect(func(on: bool) -> void: stage.time_scale = 0.25 if on else 1.0)
	tools.add_child(slow_button)
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(18, 0)
	tools.add_child(gap)


func _say(text: String, color: Color = MUTED) -> void:
	var tone: StringName = &"neutral"
	if color == GOOD:
		tone = &"good"
		Sfx.play(&"click", -12.0)
	elif color == BAD:
		tone = &"bad"
		Sfx.play(&"buzz", -14.0)
	hud.say(text, tone)


# --- Açılış: arıza -----------------------------------------------------------

func _enter_intro() -> void:
	step = Step.INTRO
	stage.log_rows.clear()
	stage.show_expectation = true
	stage.pressure = Fall.ATMOSPHERE
	stage.pressure_target = Fall.ATMOSPHERE
	stage.set_release_height(DROP_HEIGHT)
	stage.set_bodies([&"steel", &"foam"])
	_screen(0, "KAYMA", "Cihaz iki topun da 2,00 s'de ineceğini sanıyor.", "", "Misafirler odadaki havayı hesaptan çıkardı. Cihaz her cismin 2,00 s'de ineceğini varsayıyor, oda ise havalı.")
	hud.skip.show()
	hud.skip.text = "Açılışı geç"
	get_tree().create_timer(1.2).timeout.connect(func() -> void:
		if step == Step.INTRO:
			stage.release([&"steel", &"foam"]))
	_intro_timer = get_tree().create_timer(11.0)
	_intro_timer.timeout.connect(_finish_intro)


func _finish_intro() -> void:
	if step != Step.INTRO:
		return
	stage.reset_bodies()
	_enter_observe()


# --- 1 · Gözle ---------------------------------------------------------------

func _enter_observe() -> void:
	step = Step.OBSERVE
	stage.show_expectation = true
	stage.log_rows.clear()
	stage.set_release_height(DROP_HEIGHT)
	_screen(1, "GÖZLE", "İki topu aynı yükseklikten bırak, sürelerini karşılaştır.", "Bırak",
		"Çelik küre 33 kg, sünger top 50 g. İkisi de 20 m yükseklikten ilk hızsız bırakılır. Süreler panodan okunur.", true)
	stage.set_bodies([&"steel", &"foam"])
	stage.reset_bodies()


func _on_observe_landed(results: Dictionary) -> void:
	var steel: float = results[&"steel"]["time"]
	var foam: float = results[&"foam"]["time"]
	stage.log_rows.append("%s kPa   çelik %s   sünger %s" % [str(roundi(stage.pressure)), stage.seconds_text(steel), stage.seconds_text(foam)])
	_say("Çelik %s, sünger %s. Cihazın beklediği %s." % [stage.seconds_text(steel), stage.seconds_text(foam), stage.seconds_text(Stage.EXPECTED_TIME)], BAD)
	hud.set_action("Havayı boşalt", true)


# --- 2 · Vakum ---------------------------------------------------------------

func _enter_vacuum() -> void:
	step = Step.VACUUM
	drops = 0
	_screen(2, "VAKUM", "Basıncı düşür, her seferinde yeniden bırak.", "Bırak",
		"Havayı pompayla boşalttıkça iki topun süresi yaklaşır. Kayıtta her bırakma satır olarak kalır.", true)
	stage.reset_bodies()
	var label := Label.new()
	label.text = "Basınç"
	label.add_theme_color_override("font_color", MUTED)
	tools.add_child(label)
	slider = HSlider.new()
	slider.min_value = 0.0
	slider.max_value = Fall.ATMOSPHERE
	slider.step = 1.0
	slider.value = stage.pressure_target
	slider.custom_minimum_size = Vector2(260, 0)
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	slider.value_changed.connect(_on_pressure_changed)
	tools.add_child(slider)
	slider_label = Label.new()
	slider_label.add_theme_color_override("font_color", Color("#6fe3c1"))
	tools.add_child(slider_label)
	_on_pressure_changed(slider.value)


func _on_pressure_changed(value: float) -> void:
	stage.set_pressure_target(value)
	if slider_label != null:
		slider_label.text = "%d kPa" % roundi(value)


func _on_vacuum_landed(results: Dictionary) -> void:
	drops += 1
	var steel: float = results[&"steel"]["time"]
	var foam: float = results[&"foam"]["time"]
	stage.log_rows.append("%s kPa   çelik %s   sünger %s" % [str(roundi(stage.pressure)), stage.seconds_text(steel), stage.seconds_text(foam)])
	if absf(foam - steel) < 0.01 and stage.pressure < VACUUM_LIMIT:
		stage.show_expectation = false
		_say("İkisi de %s: farkı kütle yaratmıyordu." % stage.seconds_text(steel), GOOD)
		hud.set_action("Nedeni seç", true)
	else:
		var gap := foam - steel
		_say("Fark %s. Basınç düştükçe fark küçülüyor mu? Biraz daha boşalt." % stage.seconds_text(gap))
		hud.set_action("Bırak", true)


# --- 3 · Neden ---------------------------------------------------------------

func _enter_reason() -> void:
	step = Step.REASON
	_screen(3, "NEDEN", "Havalı odada süre farkını ne yarattı?", "",
		"Aynı iki top, aynı yükseklik. Havada fark vardı, vakumda yoktu. Değişen tek şey odadaki hava.")
	stage.reset_bodies()
	for choice in [&"mass", &"air", &"color"]:
		var button := Button.new()
		button.text = {&"mass": "Kütle farkı", &"air": "Hava direnci", &"color": "Topun rengi"}[choice]
		button.pressed.connect(_on_reason.bind(choice))
		tools.add_child(button)


func _on_reason(choice: StringName) -> void:
	match choice:
		&"air":
			_say("Doğru. Hava, hızla büyüyen bir direnç uygular. Geniş ve hafif top daha çok yavaşlar.", GOOD)
			_clear_tools()
			hud.set_action("g'yi ölç", true)
		&"mass":
			_say("Vakumda kütleler yine farklıydı ama süreler eşitti. Kütle neden olamaz.", BAD)
		_:
			_say("Renk hareketi değiştirmez. Havayı boşaltınca neyin değiştiğine bak.", BAD)


# --- 4 · Hesapla -------------------------------------------------------------

func _add_entry(placeholder: String) -> void:
	entry = LineEdit.new()
	entry.placeholder_text = placeholder
	entry.custom_minimum_size = Vector2(180, 0)
	entry.text_submitted.connect(func(_text: String) -> void: _on_action())
	tools.add_child(entry)


func _read_number() -> float:
	if entry == null or entry.text.strip_edges() == "":
		return NAN
	var text := entry.text.strip_edges().replace(",", ".")
	return text.to_float() if text.is_valid_float() else NAN


func _enter_measure() -> void:
	step = Step.MEASURE
	wrong = 0
	_screen(4, "ÖLÇ", "Vakumda 20 m, 2,00 s. g kaç m/s²?", "Onayla",
		"Aynı yükseklikten ilk hızsız bırakılan cisim için h = ½·g·t². Panodaki süreyi ve yüksekliği kullan.")
	stage.show_expectation = false
	_add_entry("g  (m/s²)")
	entry.grab_focus()


func _check_measure() -> void:
	var value := _read_number()
	if is_nan(value):
		_say("Sayı gir. Örnek: 9,8", BAD)
		return
	if absf(value - 10.0) <= G_TOLERANCE:
		_say("g = 2h / t² = 2 · 20 / 2² = 10 m/s². Bu odanın ivmesi.", GOOD)
		_enter_apply()
		return
	wrong += 1
	if absf(value - 5.0) < 0.6:
		_say("½ çarpanını gözden kaçırmışsın. h = ½gt² ise g = 2h / t².", BAD)
	elif absf(value - 20.0) < 1.0 or absf(value - 40.0) < 2.0:
		_say("t'nin karesini aldın mı? g = 2h / t², t = 2 s.", BAD)
	else:
		_say("%s olsaydı 20 m'yi %s sürede inerdi. Panodaki 2,00 s ile karşılaştır." % [str(value).replace(".", ","), stage.seconds_text(sqrt(2.0 * DROP_HEIGHT / maxf(value, 0.1)))], BAD)


# --- 5 · Uygula --------------------------------------------------------------

func _enter_apply() -> void:
	step = Step.APPLY
	wrong = 0
	stage.set_pressure_target(0.0)
	stage.set_bodies([&"capsule"])
	_screen(5, "UYGULA", "Kapsül sensöre tam 3,00 s sonra varmalı. Kaç metreden bırakılmalı?", "Ayarla ve bırak",
		"Oda vakumda. Kapsül ilk hızsız bırakılır. Bulduğun g değerini kullan: h = ½·g·t².", true)
	stage.reset_bodies()
	_add_entry("yükseklik  (m)")
	entry.grab_focus()


func _run_apply() -> void:
	var value := _read_number()
	if is_nan(value):
		_say("Yüksekliği metre olarak gir. Örnek: 45", BAD)
		return
	if value < 1.0 or value > Stage.MAX_RELEASE:
		_say("Oda 1 ile %d m arasında çalışır." % int(Stage.MAX_RELEASE), BAD)
		return
	hud.set_action("", false)
	stage.set_release_height(value)
	get_tree().create_timer(1.1).timeout.connect(func() -> void: stage.release([&"capsule"]))


func _on_apply_landed(results: Dictionary) -> void:
	var arrival: float = results[&"capsule"]["time"]
	if absf(arrival - TARGET_TIME) <= TIME_TOLERANCE:
		_finish()
		return
	wrong += 1
	var text := "Kapsül %s sürede indi, 3,00 s olmalıydı." % stage.seconds_text(arrival)
	text += " Çok yüksekten bıraktın." if arrival > TARGET_TIME else " Yetersiz yükseklik."
	text += " t = √(2h / g) denkleminden h'yi çöz."
	_say(text, BAD)
	stage.reset_bodies()
	hud.set_action("Ayarla ve bırak", true)


func _finish() -> void:
	step = Step.DONE
	stage.show_expectation = false
	stage.log_rows.append("kapsül %s: sensörde" % stage.seconds_text(TARGET_TIME))
	_screen(5, "MÜHÜR", "Kayma onarıldı: kapsül sensöre tam zamanında ulaştı.", "",
		"Kayıt: Kütle değildi. Hava hesaptan çıkarılmıştı. Yasa mühürlendi.")
	hud.set_steps(5, 5, "MÜHÜR")
	_say("Mühürlendi: kütle değildi, hava hesaptan çıkarılmıştı.", GOOD)
	Sfx.play(&"chime")
	completed.emit()


# --- Yönlendirme ---------------------------------------------------------------

func _on_action() -> void:
	match step:
		Step.OBSERVE:
			if hud.action.text == "Havayı boşalt":
				_enter_vacuum()
			else:
				hud.set_action("", false)
				stage.release([&"steel", &"foam"])
		Step.VACUUM:
			if hud.action.text == "Nedeni seç":
				_enter_reason()
			elif stage.is_pumping():
				_say("Pompa çalışıyor, basıncın oturmasını bekle.")
			else:
				hud.set_action("", false)
				stage.release([&"steel", &"foam"])
		Step.REASON:
			_enter_measure()
		Step.MEASURE:
			_check_measure()
		Step.APPLY:
			_run_apply()


func _on_landed(results: Dictionary) -> void:
	match step:
		Step.INTRO:
			_say("Çelik %s, sünger %s: cihazın beklediği %s." % [stage.seconds_text(results[&"steel"]["time"]), stage.seconds_text(results[&"foam"]["time"]), stage.seconds_text(Stage.EXPECTED_TIME)], BAD)
		Step.OBSERVE:
			_on_observe_landed(results)
		Step.VACUUM:
			_on_vacuum_landed(results)
		Step.APPLY:
			_on_apply_landed(results)
