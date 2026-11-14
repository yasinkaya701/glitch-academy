extends "res://scripts/physics/experiment_mission.gd"
## AYT Fizik · Atışlar. KRİZ: Kapsül 45 m platformdan yatay atılıyor ama hedef halkasını ıskalıyor. Cihaz yatay ve düşey
## hareketi birbirine bağlıyor: hızlı atılan top geç düşer sanıyor. Çözüm: iki topu bırak ve fırlat, süre yalnızca yükseklikten
## gelir, düşüş süresini ölç, 60 m'deki hedefe gereken yatay hızı hesapla.
## Hesap projectile_sim.gd'de, çizim projectile_view.gd'de.

const View = preload("res://stations/projectile/projectile_view.gd")
const Proj = preload("res://stations/projectile/projectile_sim.gd")

const HEIGHT := 45.0
const TARGET := 60.0
const START_SPEED := 20.0

enum Step { CRISIS, TEST, REASON, MEASURE, RESCUE, DONE }

var step := Step.CRISIS
var _speed := START_SPEED
var _runs: Array[float] = []
var _seen_together := false
var _seen_speeds := false
var _tries := 3
var _crisis_launched := false


func screen(index: int, label: String, directive: String, action_text: String = "", note: String = "") -> void:
	super.screen(index, label, directive, action_text, note)
	if stage != null:
		_view().clear_controls()


func _begin() -> void:
	step_total = 5
	_enter_crisis()


func _make_stage() -> Control:
	return View.new()


func _view() -> View:
	return stage as View


func _fmt(value: float) -> String:
	return str(snappedf(value, 0.1)).replace(".", ",")


func _enter_crisis() -> void:
	step = Step.CRISIS
	_crisis_launched = false
	var view := _view()
	view.height = HEIGHT
	view.use_drop_ball = true
	view.target_range = -1.0
	view.faulty_display = true
	view.speed = START_SPEED
	view.reset()
	screen(0, "KRİZ", "İki top aynı yükseklikte: biri bırakılıyor, biri yatay atılıyor.", "Topları at",
		"Cihaz yatay hızı yüksek topun daha geç düşeceğini sanıyor ve kapsülü ona göre zamanlıyor. Kapsül hedefi ıskalıyor.")


func _on_crisis_landed(ball: StringName, _x: float, time: float) -> void:
	if step == Step.CRISIS and ball == &"thrown":
		hud.set_action("Nedenini bul", true)
		say("İki top aynı anda indi: %s s. Cihaz 5,4 s bekliyordu." % _fmt(time), BAD)


func _enter_test() -> void:
	step = Step.TEST
	_runs.clear()
	_seen_together = false
	_seen_speeds = false
	var view := _view()
	view.faulty_display = false
	view.reset()
	screen(1, "SINA", "Yatay hızı değiştir, topları aynı anda at. Düşüş süresine bak.", "",
		"Sar deneyi başa alır, hız aynı kalır. 10, 20 ve 30 m/s dene: süre değişiyor mu? Menzil değişiyor mu?")
	view.add_knob("Yatay hız (m/s)", 0.0, 40.0, _speed, 5.0, func(v: float) -> void:
		_speed = v
		view.speed = v)
	view.add_button("Yavaşlat", func(on: bool) -> void: view.slow_motion = on, true)
	view.add_button("Sar", func() -> void: view.reset())
	view.add_button("At", _throw)
	if not _view().landed.is_connected(_on_landed):
		_view().landed.connect(_on_landed)


func _throw() -> void:
	_view().launch(_speed)


func _on_landed(ball: StringName, _x: float, time: float) -> void:
	if step != Step.TEST or ball != &"thrown":
		return
	if _speed > 0.0 and not _seen_together:
		_seen_together = true
		say("İki top aynı anda indi: %s s. Yatay hız süreyi değiştirmedi." % _fmt(time), GOOD)
	if not _runs.has(_speed):
		_runs.append(_speed)
	if _runs.size() >= 3 and _seen_together and not _seen_speeds:
		_seen_speeds = true
		say("Üç farklı hızda süre hep %s s, menzil v₀·t ile büyüdü." % _fmt(time), GOOD)
	if _seen_speeds:
		hud.set_action("Nedeni seç", true)


func _enter_reason() -> void:
	step = Step.REASON
	screen(2, "NEDEN", "Topun düşme süresini ne belirliyor?", "",
		"Atılan ve bırakılan top aynı anda indi. Menzil yatay hızla büyüdü, süre sabit kaldı.")
	var options := {
		&"speed": "Yatay hız: hızlı top yere geç iner",
		&"height": "Yalnızca yükseklik; yatay hareket süreyi etkilemez",
		&"mass": "Topun kütlesi: ağır top önce düşer",
	}
	for choice in options:
		var button := Button.new()
		button.text = options[choice]
		button.pressed.connect(_on_reason.bind(choice))
		tools.add_child(button)


func _on_reason(choice: StringName) -> void:
	match choice:
		&"height":
			say("Doğru. Yatay ve düşey hareket birbirinden bağımsız: yatayda sabit hız, düşeyde serbest düşme.", GOOD)
			clear_tools()
			hud.set_action("Süreyi hesapla", true)
		&"speed":
			say("10, 20 ve 30 m/s atışlarının hepsi aynı anda indi. Yatay hız süreyi değiştirmedi.", BAD)
		_:
			say("Her iki top aynı kütledeydi, yine de farklı yatay hızlarda süre sabit çıktı. Kütle bu sorunun değişkeni değil.", BAD)


func _enter_measure() -> void:
	step = Step.MEASURE
	var view := _view()
	view.use_drop_ball = false
	view.reset()
	screen(3, "ÖLÇ", "45 m yükseklikten düşen top yere kaç saniyede iner? (g = 10 m/s²)", "Onayla",
		"Düşey hareketin türünü belirle. g = 10 m/s².")
	add_entry("t  (s)")


func _check_measure() -> void:
	var value := read_number()
	if is_nan(value):
		say("Saniye olarak gir. Örnek: 3", BAD)
		return
	if absf(value - 3.0) <= 0.05:
		say("3 s. Hedefe ulaşmak için yatay yol bu sürede alınmalı.", GOOD)
		_enter_rescue()
	elif absf(value - 4.5) <= 0.05:
		say("Yüksekliği yalnız g'ye bölmek süreyi vermez. Düşey harekette yol süreyle nasıl büyür?", BAD)
	elif absf(value - 9.0) <= 0.05:
		say("Bu değer süre değil. Birimini ve neyi hesapladığını kontrol et.", BAD)
	else:
		say("Düşey hareketin kuralını yaz ve süreyi ondan çöz.", BAD)


func _enter_rescue() -> void:
	step = Step.RESCUE
	_tries = 3
	var view := _view()
	view.use_drop_ball = false
	view.target_range = TARGET
	view.reset()
	screen(4, "KURTAR", "Hedef halkası 60 m uzakta. Kapsülün yatay atış hızı kaç m/s olmalı?", "At",
		"Halkanın yarıçapı 3 m. Topun havada kalma süresini ve yatay hareketin türünü kullan. Üç hakkın var.")
	add_entry("v₀  (m/s)")


func _run_rescue() -> void:
	var value := read_number()
	if is_nan(value):
		say("Hızı m/s olarak gir. Örnek: 20", BAD)
		return
	if value <= 0.0 or value > 80.0:
		say("Atıcı 1–80 m/s arasında çalışır.", BAD)
		return
	var view := _view()
	view.launch(value)
	var distance := Proj.range_for(HEIGHT, value)
	if absf(distance - TARGET) <= view.target_radius:
		_finish()
		return
	_tries -= 1
	if distance < TARGET:
		say("Kapsül %s m'de iniyor, hedefin %s m önünde: yatay hız yetersiz." % [_fmt(distance), _fmt(TARGET - distance)], BAD)
	else:
		say("Kapsül %s m'de iniyor, hedefi %s m aşıyor. 60 m bir mesafedir, hız değil." % [_fmt(distance), _fmt(distance - TARGET)], BAD)
	if _tries <= 0:
		_tries = 3
		say("Üç hakkın bitti. Sıra: önce düşüş süresi, sonra bu sürede 60 m alan sabit hız.")


func _finish() -> void:
	seal("Yatay ve düşey hareket bağlı değildi. Süre yükseklikten, menzil hızdan geliyordu.", "Kapsül hedef halkasına indi.")


func _on_action() -> void:
	match step:
		Step.CRISIS:
			if _crisis_launched:
				_enter_test()
			else:
				_crisis_launched = true
				_view().launch(START_SPEED)
				hud.set_action("", false)
				say("Cihaz atılan topun 5,4 s'de düşeceğini sanıyor. İzle.")
				var view := _view()
				if not view.landed.is_connected(_on_crisis_landed):
					view.landed.connect(_on_crisis_landed)
		Step.TEST:
			_enter_reason()
		Step.REASON:
			_enter_measure()
		Step.MEASURE:
			_check_measure()
		Step.RESCUE:
			_run_rescue()
