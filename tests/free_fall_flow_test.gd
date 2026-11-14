extends Node
## Düşüş Odası'nı doğru çözümle baştan sona oynar ve görevin tamamlandığını doğrular. Yanlış yollar da denenir.
## Kullanım: godot --headless --path . tests/free_fall_flow_test.tscn

var mission: Control
var completed := false
var failures := 0

func _check(label: String, ok: bool) -> void:
	print("%s  %s" % ["ok " if ok else "HATA", label])
	if not ok:
		failures += 1

func _wait_until(condition: Callable, timeout: float = 20.0) -> bool:
	var waited := 0.0
	while not condition.call() and waited < timeout:
		await get_tree().create_timer(0.1).timeout
		waited += 0.1
	return condition.call()

func _ready() -> void:
	mission = load("res://stations/free_fall/mission.tscn").instantiate()
	mission.completed.connect(func() -> void: completed = true)
	add_child(mission)
	await get_tree().create_timer(0.3).timeout
	var view = mission.stage
	# Kriz: kapsül kaçırılır
	await _wait_until(func() -> bool: return mission.hud.action.visible and mission.hud.action.text == "Nedenini bul", 12.0)
	_check("kriz: kapsül kapağı kaçırdı", view.outcome == &"lost")
	mission._on_action()
	_check("sına adımına geçildi", mission.step == mission.Step.TEST)
	# Hava açık bırak (yanlış neden), sonra vakumda bırak
	view.set_pressure_target(101.0)
	await _wait_until(func() -> bool: return not view.is_pumping(), 10.0)
	mission._on_action()
	await _wait_until(func() -> bool: return mission.hud.action.visible, 15.0)
	_check("havada bırakma: hâlâ Bırak", mission.hud.action.text == "Bırak")
	view.set_pressure_target(0.0)
	await _wait_until(func() -> bool: return not view.is_pumping(), 10.0)
	mission._on_action()
	await _wait_until(func() -> bool: return mission.hud.action.text == "Nedeni seç", 15.0)
	_check("vakumda eşit süre: neden adımı açıldı", mission.hud.action.text == "Nedeni seç")
	mission._on_action()
	mission._on_reason(&"mass")
	_check("yanlış neden: ilerlemedi", mission.step == mission.Step.REASON)
	mission._on_reason(&"gravity")
	mission._on_action()
	_check("ölç adımı", mission.step == mission.Step.MEASURE)
	mission.entry.text = "10"
	mission._on_action()
	_check("yanlış g (10): ilerlemedi", mission.step == mission.Step.MEASURE)
	mission.entry.text = "6,0"
	mission._on_action()
	_check("doğru g: kurtar adımı", mission.step == mission.Step.RESCUE)
	# Yanlış yükseklik (havasız çekimde 45 m), sonra doğru 27 m
	mission.entry.text = "45"
	mission._on_action()
	await _wait_until(func() -> bool: return view.capsules < 3, 15.0)
	_check("45 m: kapsül kaybedildi", view.capsules == 2)
	await _wait_until(func() -> bool: return mission.hud.action.visible, 8.0)
	mission.entry.text = "27"
	mission._on_action()
	await _wait_until(func() -> bool: return view.outcome == &"saved", 15.0)
	_check("27 m: veri kurtarıldı", view.outcome == &"saved")
	await _wait_until(func() -> bool: return mission.hud.action.text == "Çekimi onar", 6.0)
	mission._on_action()
	_check("onar adımı", mission.step == mission.Step.REPAIR)
	# Dengeleyici: önce yanlış ayar (25 → g 6), sonra 50
	mission.dial = 40.0
	mission._on_action()
	await _wait_until(func() -> bool: return mission.hud.action.visible, 15.0)
	_check("ayar 40 (g 8,4): onarılmadı", not completed)
	mission.dial = 50.0
	mission._on_action()
	await _wait_until(func() -> bool: return completed, 15.0)
	_check("ayar 50 (g 10): görev tamamlandı", completed)
	print("BAŞARISIZ: %d" % failures if failures > 0 else "HEPSİ GEÇTİ")
	get_tree().quit(failures)
