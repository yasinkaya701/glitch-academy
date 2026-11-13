extends "res://scripts/physics/experiment_mission.gd"
## AYT Fizik · Hareket. KRİZ: Gözlemevi'nin son ölçüm kayıtlarını taşıyan veri kapsülü, sensör kapağı 3,00 s'de açıkken
## yere ulaşmalı. Misafirler odadaki havayı cihazın hesabından çıkardı: kapsül havada yavaşlıyor, kapak kapandıktan sonra
## geliyor ve veri kayboluyor. Çözüm bütün konuyu ister: havanın etkisini kanıtla, g'yi ölç, h = ½·g·t² ile yüksekliği
## bul ve odayı vakuma al. İkisinden biri eksikse kapsül kaybolur.
## Hareket fall_sim.gd'de, çizim fall_stage.gd'de.

const Stage = preload("res://stations/free_fall/fall_stage.gd")
const Fall = preload("res://stations/free_fall/fall_sim.gd")

const CRISIS_HEIGHT := 45.0       ## m, cihazın planladığı bırakma yüksekliği
const TEST_HEIGHT := 20.0         ## m, sınama yüksekliği
const TARGET_TIME := 3.0          ## s, kapağın açık olduğu an
const G_TOLERANCE := 0.3          ## m/s²
const TIME_TOLERANCE := 0.05      ## s
const VACUUM_LIMIT := 3.0         ## kPa altında "vakum" sayılır

enum Step { CRISIS, TEST, VACUUM, REASON, MEASURE, RESCUE, DONE }

var step := Step.CRISIS
var slider: HSlider
var slider_label: Label
var _drop_pressure := 0.0
var _drop_height := 0.0


func _begin() -> void:
	step_total = 6
	_enter_crisis()


func _make_stage() -> Control:
	var view := Stage.new()
	view.landed.connect(_on_landed)
	return view


func _stage() -> Stage:
	return stage as Stage


func _powers() -> void:
	add_power("⟲  Sar", "Cisimleri bırakma anına geri götür", func() -> void:
		_stage().rewind()
		Sfx.play(&"click", -12.0))
	add_power("◐  Yavaşlat", "Zamanı ¼ hıza çek", func(on: bool) -> void: _stage().time_scale = 0.25 if on else 1.0, true)
	add_gap()


func _pressure_slider() -> void:
	slider = add_slider("Basınç", 0.0, Fall.ATMOSPHERE, _stage().pressure_target, 1.0, _on_pressure_changed)
	slider_label = Label.new()
	slider_label.add_theme_color_override("font_color", Color("#6fe3c1"))
	tools.add_child(slider_label)
	_on_pressure_changed(slider.value)


func _on_pressure_changed(value: float) -> void:
	_stage().set_pressure_target(value)
	if slider_label != null:
		slider_label.text = "%d kPa" % roundi(value)


# --- 0 · Kriz ----------------------------------------------------------------------

func _enter_crisis() -> void:
	step = Step.CRISIS
	var view := _stage()
	view.log_rows.clear()
	view.rewind()
	view.pressure = Fall.ATMOSPHERE
	view.pressure_target = Fall.ATMOSPHERE
	view.door_enabled = true
	view.show_expectation = true
	view.capsules = 3
	view.outcome = &""
	view.set_bodies([&"capsule"])
	view.set_release_height(CRISIS_HEIGHT)
	screen(0, "KRİZ", "Veri kapsülü, kapak kapandıktan sonra geldi.", "",
		"Gözlemevi'nin son ölçüm kayıtları kapsülde. Sensör kapağı 3,00 s sonra 0,05 s açık kalır. Cihaz 45 m'yi 3,00 s'de iner sanıp bıraktı: Misafirler odadaki havayı hesaptan çıkarmış.")
	hud.skip.show()
	hud.skip.text = "Açılışı geç"
	get_tree().create_timer(1.3).timeout.connect(func() -> void:
		if step == Step.CRISIS:
			_drop_pressure = view.pressure
			view.release([&"capsule"]))


func _on_skip() -> void:
	if step == Step.CRISIS:
		_stage().rewind()
		_enter_test()


# --- 1 · Sına ----------------------------------------------------------------------

func _enter_test() -> void:
	step = Step.TEST
	var view := _stage()
	view.door_enabled = false
	view.show_expectation = true
	view.log_rows.clear()
	view.set_bodies([&"steel", &"foam"])
	view.set_release_height(TEST_HEIGHT)
	view.rewind()
	screen(1, "SINA", "Kapsül neden geç geldi? İki test topunu aynı yükseklikten bırak.", "Bırak",
		"Çelik küre 33 kg, sünger top 50 g. İkisi de 20 m yükseklikten ilk hızsız bırakılır. Cihaz ikisinin de 2,00 s'de ineceğini sanıyor.")
	_powers()


func _on_test_landed(results: Dictionary) -> void:
	var view := _stage()
	var steel: float = results[&"steel"]["time"]
	var foam: float = results[&"foam"]["time"]
	view.log_rows.append("%d kPa   çelik %s   sünger %s" % [roundi(_drop_pressure), view.seconds_text(steel), view.seconds_text(foam)])
	say("Çelik %s, sünger %s. Cihaz ikisini de 2,00 s sanıyordu." % [view.seconds_text(steel), view.seconds_text(foam)], BAD)
	hud.set_action("Havayı boşalt", true)


# --- 2 · Vakum ---------------------------------------------------------------------

func _enter_vacuum() -> void:
	step = Step.VACUUM
	screen(2, "VAKUM", "Basıncı düşür, her seferinde yeniden bırak.", "Bırak",
		"Havayı pompayla boşalttıkça iki topun süresi yaklaşır. Kayıtta her bırakma satır olarak kalır.")
	_stage().rewind()
	_powers()
	_pressure_slider()


func _on_vacuum_landed(results: Dictionary) -> void:
	var view := _stage()
	var steel: float = results[&"steel"]["time"]
	var foam: float = results[&"foam"]["time"]
	view.log_rows.append("%d kPa   çelik %s   sünger %s" % [roundi(_drop_pressure), view.seconds_text(steel), view.seconds_text(foam)])
	if absf(foam - steel) < 0.01 and _drop_pressure < VACUUM_LIMIT:
		view.show_expectation = false
		say("İkisi de %s: farkı kütle yaratmıyordu." % view.seconds_text(steel), GOOD)
		hud.set_action("Nedeni seç", true)
	else:
		say("Fark %s. Basınç düştükçe fark küçülüyor mu? Biraz daha boşalt." % view.seconds_text(foam - steel))
		hud.set_action("Bırak", true)


# --- 3 · Neden ---------------------------------------------------------------------

func _enter_reason() -> void:
	step = Step.REASON
	screen(3, "NEDEN", "Havalı odada süre farkını ne yarattı?", "",
		"Aynı iki top, aynı yükseklik. Havada fark vardı, vakumda yoktu. Değişen tek şey odadaki hava.")
	_stage().rewind()
	for choice in [&"mass", &"air", &"color"]:
		var button := Button.new()
		button.text = {&"mass": "Kütle farkı", &"air": "Hava direnci", &"color": "Topun rengi"}[choice]
		button.pressed.connect(_on_reason.bind(choice))
		tools.add_child(button)


func _on_reason(choice: StringName) -> void:
	match choice:
		&"air":
			say("Doğru. Hava, hızla büyüyen bir direnç uygular. Kapsül de havada yavaşladı.", GOOD)
			clear_tools()
			hud.set_action("g'yi ölç", true)
		&"mass":
			say("Vakumda kütleler yine farklıydı ama süreler eşitti. Kütle neden olamaz.", BAD)
		_:
			say("Renk hareketi değiştirmez. Havayı boşaltınca neyin değiştiğine bak.", BAD)


# --- 4 · Ölç -----------------------------------------------------------------------

func _enter_measure() -> void:
	step = Step.MEASURE
	screen(4, "ÖLÇ", "Vakumda 20 m, 2,00 s. g kaç m/s²?", "Onayla",
		"Aynı yükseklikten ilk hızsız bırakılan cisim için h = ½·g·t². Kapsülü kurtarmak için bu odanın ivmesini bilmen gerek.")
	add_entry("g  (m/s²)")


func _check_measure() -> void:
	var value := read_number()
	if is_nan(value):
		say("Sayı gir. Örnek: 9,8", BAD)
		return
	if absf(value - 10.0) <= G_TOLERANCE:
		say("g = 2h / t² = 2 · 20 / 2² = 10 m/s². Şimdi kapsülü kurtar.", GOOD)
		_enter_rescue()
	elif absf(value - 5.0) < 0.6:
		say("½ çarpanını gözden kaçırmışsın. h = ½gt² ise g = 2h / t².", BAD)
	elif absf(value - 20.0) < 1.0 or absf(value - 40.0) < 2.0:
		say("t'nin karesini aldın mı? g = 2h / t², t = 2 s.", BAD)
	else:
		say("%s olsaydı 20 m'yi %s sürede inerdi. Panodaki 2,00 s ile karşılaştır." % [str(value).replace(".", ","), _stage().seconds_text(sqrt(2.0 * TEST_HEIGHT / maxf(value, 0.1)))], BAD)


# --- 5 · Kurtar --------------------------------------------------------------------

func _enter_rescue() -> void:
	step = Step.RESCUE
	var view := _stage()
	view.door_enabled = true
	view.show_expectation = false
	view.capsules = 3
	view.outcome = &""
	view.log_rows.clear()
	view.set_bodies([&"capsule"])
	view.rewind()
	# Oda yeniden havalandı: oyuncu vakumu kendisi kurmalı.
	view.set_pressure_target(Fall.ATMOSPHERE)
	screen(5, "KURTAR", "Kapak 3,00 s sonra açılır. Kapsülü kurtar: odayı ve yüksekliği ayarla.", "Ayarla ve bırak",
		"Kapsül üç kez bırakılabilir. Havayı ve yüksekliği doğru kurarsan kapak açıkken iner: h = ½·g·t² ve vakum.")
	_powers()
	_pressure_slider()
	add_entry("yükseklik  (m)")


func _run_rescue() -> void:
	var view := _stage()
	var height := read_number()
	if is_nan(height):
		say("Yüksekliği metre olarak gir. Örnek: 45", BAD)
		return
	if height < 1.0 or height > Stage.MAX_RELEASE:
		say("Oda 1 ile %d m arasında çalışır." % int(Stage.MAX_RELEASE), BAD)
		return
	if view.is_pumping():
		say("Pompa çalışıyor, basıncın oturmasını bekle.")
		return
	_drop_height = height
	_drop_pressure = view.pressure
	hud.set_action("", false)
	view.set_release_height(height)
	get_tree().create_timer(1.0).timeout.connect(func() -> void: view.release([&"capsule"]))


func _on_rescue_landed(results: Dictionary) -> void:
	var view := _stage()
	var arrival: float = results[&"capsule"]["time"]
	view.log_rows.append("%d kPa  %s m  →  %s" % [roundi(_drop_pressure), str(snappedf(_drop_height, 0.1)).replace(".", ","), view.seconds_text(arrival)])
	if view.outcome == &"saved":
		_finish()
		return
	var why := ""
	if _drop_pressure >= VACUUM_LIMIT:
		why = "Odada hava var, kapsül yavaşladı. Önce havayı boşalt."
	elif arrival > TARGET_TIME:
		why = "Çok yüksekten bırakıldı. t = √(2h / g) denkleminden h'yi çöz."
	else:
		why = "Yetersiz yükseklik. t = √(2h / g) denkleminden h'yi çöz."
	say("Kapsül %s'de indi, kapak %s'de açıktı. %s" % [view.seconds_text(arrival), view.seconds_text(TARGET_TIME), why], BAD)
	view.rewind()
	if view.capsules <= 0:
		view.capsules = 3
		say("Yedek kapsül hattı yenilendi. Bu kez nedenini ve sayıyı birlikte kur.")
	hud.set_action("Ayarla ve bırak", true)


func _finish() -> void:
	_stage().log_rows.append("kapak açıkken: veri kurtarıldı")
	seal("Kütle değildi. Hava hesaptan çıkarılmıştı.", "Veri kurtarıldı: kapsül sensöre tam zamanında ulaştı.")


# --- Yönlendirme ---------------------------------------------------------------------

func _on_action() -> void:
	match step:
		Step.CRISIS:
			_enter_test()
		Step.TEST:
			if hud.action.text == "Havayı boşalt":
				_enter_vacuum()
			else:
				hud.set_action("", false)
				_drop_pressure = _stage().pressure
				_stage().release([&"steel", &"foam"])
		Step.VACUUM:
			if hud.action.text == "Nedeni seç":
				_enter_reason()
			elif _stage().is_pumping():
				say("Pompa çalışıyor, basıncın oturmasını bekle.")
			else:
				hud.set_action("", false)
				_drop_pressure = _stage().pressure
				_stage().release([&"steel", &"foam"])
		Step.REASON:
			_enter_measure()
		Step.MEASURE:
			_check_measure()
		Step.RESCUE:
			_run_rescue()


func _on_landed(results: Dictionary) -> void:
	match step:
		Step.CRISIS:
			var view := _stage()
			var arrival: float = results[&"capsule"]["time"]
			say("Kapsül %s'de geldi, kapak %s'de açıktı. Veri kayboldu." % [view.seconds_text(arrival), view.seconds_text(TARGET_TIME)], BAD)
			view.capsules = 3
			hud.set_action("Nedenini bul", true)
		Step.TEST:
			_on_test_landed(results)
		Step.VACUUM:
			_on_vacuum_landed(results)
		Step.RESCUE:
			_on_rescue_landed(results)
