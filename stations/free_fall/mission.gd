extends "res://scripts/physics/experiment_mission.gd"
## AYT Fizik · Hareket. KRİZ: Misafirler Dünya'nın yer çekimini zayıflattı. Gözlemevi'nin veri kapsülü, sensör kapağı
## 3,00 s'de açıkken yere ulaşmalıydı, ama her şey olması gerekenden yavaş düşüyor ve kapsül kapak kapandıktan sonra
## geliyor. Çözüm bütün konuyu ister: hava ve kütlenin neden olmadığını kanıtla, g'yi h = ½·g·t² ile ölç, kapsülü bu
## çekime göre kurtar, sonra çekim dengeleyiciyi ayarlayıp Dünya'nın çekimini gerçekten onar.
## Hareket fall_sim.gd'de, çizim fall_stage.gd'de.

const Stage = preload("res://stations/free_fall/fall_stage.gd")
const Fall = preload("res://stations/free_fall/fall_sim.gd")

const BROKEN_DIAL := 25.0         ## g = 6 m/s²
const HEALTHY_G := 10.0
const CRISIS_HEIGHT := 45.0       ## m, cihazın planladığı bırakma yüksekliği
const TEST_HEIGHT := 20.0         ## m, sınama yüksekliği
const TARGET_TIME := 3.0          ## s, kapağın açık olduğu an
const G_TOLERANCE := 0.3          ## m/s², oyuncunun ölçümü için
const REPAIR_TOLERANCE := 0.2     ## m/s², dengeleyici onarımı için
const VACUUM_LIMIT := 3.0         ## kPa altında "vakum" sayılır

enum Step { CRISIS, TEST, REASON, MEASURE, RESCUE, REPAIR, DONE }

var step := Step.CRISIS
var dial := BROKEN_DIAL
var slider_label: Label
var _drop_pressure := 0.0
var _drop_height := 0.0
var _vacuum_equal := false
var _measured_g := 6.0


func _begin() -> void:
	step_total = 6
	_enter_crisis()


func _make_stage() -> Control:
	var view := Stage.new()
	view.landed.connect(_on_landed)
	return view


func _stage() -> Stage:
	return stage as Stage


func _current_g() -> float:
	return Fall.gravity_for_dial(dial)


func _apply_gravity() -> void:
	var view := _stage()
	view.gravity = _current_g()


func _powers() -> void:
	add_power("⟲  Sar", "Cisimleri bırakma anına geri götür", func() -> void:
		_stage().rewind()
		Sfx.play(&"click", -12.0))
	add_power("◐  Yavaşlat", "Zamanı ¼ hıza çek", func(on: bool) -> void: _stage().time_scale = 0.25 if on else 1.0, true)
	add_gap()


func _air_slider() -> void:
	add_slider("Hava", 0.0, Fall.ATMOSPHERE, _stage().pressure_target, 1.0, _on_air_changed, 200.0)
	slider_label = Label.new()
	slider_label.add_theme_color_override("font_color", Color("#6fe3c1"))
	tools.add_child(slider_label)
	_on_air_changed(_stage().pressure_target)


func _on_air_changed(value: float) -> void:
	_stage().set_pressure_target(value)
	if slider_label != null:
		slider_label.text = "%d kPa" % roundi(value)


# --- 0 · Kriz ----------------------------------------------------------------------

func _enter_crisis() -> void:
	step = Step.CRISIS
	var view := _stage()
	view.log_rows.clear()
	view.rewind()
	dial = BROKEN_DIAL
	_apply_gravity()
	view.gravity_label = ""
	view.gravity_fixed = false
	view.pressure = 0.0
	view.pressure_target = 0.0
	view.door_enabled = true
	view.show_expectation = true
	view.capsules = 3
	view.outcome = &""
	view.set_bodies([&"capsule"])
	view.set_release_height(CRISIS_HEIGHT)
	screen(0, "KRİZ", "Oda vakumda ama kapsül yine kapak kapandıktan sonra geldi.", "",
		"Gözlemevi'nin son ölçüm kayıtları kapsülde. Sensör kapağı 3,00 s sonra 0,05 s açık kalır. Cihaz 45 m'yi 3,00 s'de iner sanıp bıraktı. Misafirler Dünya'nın yer çekimine dokunmuş.")
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
	_vacuum_equal = false
	view.door_enabled = false
	view.show_expectation = true
	view.log_rows.clear()
	view.set_bodies([&"steel", &"foam"])
	view.set_release_height(TEST_HEIGHT)
	view.rewind()
	screen(1, "SINA", "Oda vakumda. İki test topunu bırak, sonra havayı açıp yeniden dene.", "Bırak",
		"Çelik küre 33 kg, sünger top 50 g, ikisi de 20 m'den ilk hızsız bırakılır. Cihaz ikisinin de 2,00 s'de ineceğini sanıyor. Havayı açıp kapatarak neyin süreyi değiştirdiğine bak.")
	_powers()
	_air_slider()


func _on_test_landed(results: Dictionary) -> void:
	var view := _stage()
	var steel: float = results[&"steel"]["time"]
	var foam: float = results[&"foam"]["time"]
	view.log_rows.append("%d kPa   çelik %s   sünger %s" % [roundi(_drop_pressure), view.seconds_text(steel), view.seconds_text(foam)])
	if _drop_pressure < VACUUM_LIMIT and absf(foam - steel) < 0.01:
		_vacuum_equal = true
		say("Vakumda ikisi de %s: kütle fark yaratmıyor. Ama cihaz %s bekliyordu." % [view.seconds_text(steel), view.seconds_text(Stage.EXPECTED_TIME)], BAD)
	elif _drop_pressure >= VACUUM_LIMIT:
		say("Havada fark %s: hava hafif topu yavaşlatıyor. Ama oda zaten vakumdaydı." % view.seconds_text(foam - steel))
	if _vacuum_equal:
		hud.set_action("Nedeni seç", true)
	else:
		hud.set_action("Bırak", true)


# --- 2 · Neden ---------------------------------------------------------------------

func _enter_reason() -> void:
	step = Step.REASON
	screen(2, "NEDEN", "Vakumda bile her şey beklenenden yavaş düşüyor. Neden?", "",
		"Vakumda iki top aynı sürede indi, ama cihazın 2,00 s beklentisinden uzun sürdü. Kütle de hava da bunu açıklamıyor.")
	_stage().rewind()
	for choice in [&"mass", &"air", &"gravity"]:
		var button := Button.new()
		button.text = {&"mass": "Kütle farkı", &"air": "Hava direnci", &"gravity": "Yer çekimi ivmesi"}[choice]
		button.pressed.connect(_on_reason.bind(choice))
		tools.add_child(button)


func _on_reason(choice: StringName) -> void:
	match choice:
		&"gravity":
			say("Doğru. Hava ve kütle çıkınca geriye çekim kalır: g değişmiş. Şimdi ne kadar olduğunu ölç.", GOOD)
			clear_tools()
			hud.set_action("g'yi ölç", true)
		&"mass":
			say("Vakumda 33 kg ile 50 g aynı sürede indi. Kütle neden olamaz.", BAD)
		_:
			say("Oda vakumda: hava yok, yine de yavaş. Hava neden olamaz.", BAD)


# --- 3 · Ölç -----------------------------------------------------------------------

func _enter_measure() -> void:
	step = Step.MEASURE
	var view := _stage()
	var t := Fall.vacuum_time(TEST_HEIGHT, _current_g())
	view.pressure_target = 0.0
	screen(3, "ÖLÇ", "Vakumda 20 m, %s. g kaç m/s²?" % view.seconds_text(t), "Onayla",
		"Aynı yükseklikten ilk hızsız bırakılan cisim için h = ½·g·t². Panodaki süre ve yükseklikle çekimi hesapla.")
	add_entry("g  (m/s²)")


func _check_measure() -> void:
	var value := read_number()
	var truth := _current_g()
	if is_nan(value):
		say("Sayı gir. Örnek: 6,0", BAD)
		return
	if absf(value - truth) <= G_TOLERANCE:
		_measured_g = value
		_stage().gravity_label = "%s m/s²" % str(snappedf(truth, 0.1)).replace(".", ",")
		say("g = 2h / t² = 2 · 20 / %s² ≈ %s m/s². Dünya'nın çekimi 10 olmalıydı: zayıflamış." % [str(snappedf(Fall.vacuum_time(TEST_HEIGHT, truth), 0.01)).replace(".", ","), str(snappedf(truth, 0.1)).replace(".", ",")], GOOD)
		_enter_rescue()
	elif absf(value - truth / 2.0) < 0.5:
		say("½ çarpanını gözden kaçırmışsın. h = ½gt² ise g = 2h / t².", BAD)
	elif value > truth * 1.6:
		say("t'nin karesini aldın mı? g = 2h / t²; payda saniyenin karesi.", BAD)
	else:
		say("%s olsaydı 20 m'yi %s sürede inerdi. Panodaki süre ile karşılaştır." % [str(value).replace(".", ","), _stage().seconds_text(Fall.vacuum_time(TEST_HEIGHT, maxf(value, 0.1)))], BAD)


# --- 4 · Kurtar --------------------------------------------------------------------

func _enter_rescue() -> void:
	step = Step.RESCUE
	var view := _stage()
	view.door_enabled = true
	view.show_expectation = false
	view.capsules = 3
	view.outcome = &""
	view.log_rows.clear()
	view.set_bodies([&"capsule"])
	view.pressure_target = 0.0
	view.rewind()
	screen(4, "KURTAR", "Kapak 3,00 s sonra açılır. Bu çekimde kapsül kaç metreden bırakılmalı?", "Ayarla ve bırak",
		"Çekimi ölçtün. Kapsül ilk hızsız bırakılır, oda vakumda. Üç kapsülün var: h = ½·g·t² ile yüksekliği bul.")
	_powers()
	add_entry("yükseklik  (m)")


func _run_rescue() -> void:
	var view := _stage()
	var height := read_number()
	if is_nan(height):
		say("Yüksekliği metre olarak gir. Örnek: 27", BAD)
		return
	if height < 1.0 or height > Stage.MAX_RELEASE:
		say("Oda 1 ile %d m arasında çalışır." % int(Stage.MAX_RELEASE), BAD)
		return
	_drop_height = height
	_drop_pressure = view.pressure
	hud.set_action("", false)
	view.set_release_height(height)
	get_tree().create_timer(1.0).timeout.connect(func() -> void: view.release([&"capsule"]))


func _on_rescue_landed(results: Dictionary) -> void:
	var view := _stage()
	var arrival: float = results[&"capsule"]["time"]
	view.log_rows.append("%s m  →  %s" % [str(snappedf(_drop_height, 0.1)).replace(".", ","), view.seconds_text(arrival)])
	if view.outcome == &"saved":
		say("Veri kurtarıldı. Ama çekim hâlâ bozuk: Dünya'yı onarmak gerek.", GOOD)
		hud.set_action("Çekimi onar", true)
		return
	var why := "Çok yüksekten bırakıldı. t = √(2h / g), g bu odada 6 m/s²." if arrival > TARGET_TIME else "Yetersiz yükseklik. t = √(2h / g), g bu odada 6 m/s²."
	say("Kapsül %s'de indi, kapak %s'de açıktı. %s" % [view.seconds_text(arrival), view.seconds_text(TARGET_TIME), why], BAD)
	view.rewind()
	if view.capsules <= 0:
		view.capsules = 3
		say("Yedek kapsül hattı yenilendi. Ölçtüğün g ile yüksekliği yeniden hesapla.")
	hud.set_action("Ayarla ve bırak", true)


# --- 5 · Onar ----------------------------------------------------------------------

func _enter_repair() -> void:
	step = Step.REPAIR
	var view := _stage()
	view.door_enabled = false
	view.show_expectation = true
	view.log_rows.clear()
	view.outcome = &""
	view.set_bodies([&"steel", &"foam"])
	view.set_release_height(TEST_HEIGHT)
	view.pressure_target = 0.0
	view.rewind()
	screen(5, "ONAR", "Çekim dengeleyiciyi ayarla. Dünya 10 m/s² ile çekmeli.", "Ayarla ve ölç",
		"Dengeleyicinin ayarı 0–100 arasında, değeri g'ye doğrusal bağlı ama hangi ayarın kaç m/s² verdiğini ölçerek bulacaksın. 20 m'de cihaz 2,00 s bekliyor.")
	_powers()
	var label := Label.new()
	slider_label = label
	label.add_theme_color_override("font_color", Color("#6fe3c1"))
	add_slider("Dengeleyici", 0.0, 100.0, dial, 1.0, func(value: float) -> void:
		dial = value
		slider_label.text = "ayar %d" % roundi(value), 260.0)
	tools.add_child(label)
	label.text = "ayar %d" % roundi(dial)


func _run_repair() -> void:
	var view := _stage()
	_apply_gravity()
	_drop_pressure = view.pressure
	hud.set_action("", false)
	view.release([&"steel", &"foam"])


func _on_repair_landed(results: Dictionary) -> void:
	var view := _stage()
	var time: float = results[&"steel"]["time"]
	var measured := 2.0 * TEST_HEIGHT / (time * time)
	view.gravity_label = "%s m/s²" % str(snappedf(measured, 0.1)).replace(".", ",")
	view.log_rows.append("ayar %d   %s   g ≈ %s" % [roundi(dial), view.seconds_text(time), str(snappedf(measured, 0.1)).replace(".", ",")])
	if absf(_current_g() - HEALTHY_G) <= REPAIR_TOLERANCE:
		view.gravity_fixed = true
		view.show_expectation = false
		_finish()
		return
	var direction := "güçlendir" if measured < HEALTHY_G else "zayıflat"
	say("g ≈ %s m/s², hedef 10. Çekimi %s ve yeniden ölç." % [str(snappedf(measured, 0.1)).replace(".", ","), direction], BAD)
	view.rewind()
	hud.set_action("Ayarla ve ölç", true)


func _finish() -> void:
	seal("Kütle de hava da değildi. Çekimin kendisi kaymıştı.", "Dünya'nın çekimi onarıldı: her şey 10 m/s² ile düşüyor.")


# --- Yönlendirme ---------------------------------------------------------------------

func _on_action() -> void:
	match step:
		Step.CRISIS:
			_enter_test()
		Step.TEST:
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
			if hud.action.text == "Çekimi onar":
				_enter_repair()
			else:
				_run_rescue()
		Step.REPAIR:
			_run_repair()


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
		Step.RESCUE:
			_on_rescue_landed(results)
		Step.REPAIR:
			_on_repair_landed(results)
