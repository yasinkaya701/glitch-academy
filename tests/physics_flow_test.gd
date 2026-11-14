extends Node
## Fotoelektrik Kapısı ve Dalga Girişimi görevlerini doğru ve yanlış yollarla baştan sona oynar.
## Kullanım: godot --headless --path . tests/physics_flow_test.tscn

const Photo = preload("res://stations/photoelectric/photo_sim.gd")
var failures := 0

func _check(label: String, ok: bool) -> void:
	print("%s  %s" % ["ok " if ok else "HATA", label])
	if not ok:
		failures += 1

func _ready() -> void:
	await _photoelectric()
	await _waves()
	await _newton()
	await _projectile()
	await _collision()
	print("BAŞARISIZ: %d" % failures if failures > 0 else "HEPSİ GEÇTİ")
	get_tree().quit(failures)

func _photoelectric() -> void:
	var m: Control = load("res://stations/photoelectric/mission.tscn").instantiate()
	var done := [false]
	m.completed.connect(func() -> void: done[0] = true)
	add_child(m)
	await get_tree().create_timer(0.2).timeout
	_check("foto: kriz, kırmızı ışık akım vermiyor", Photo.photocurrent(m._f, m._i, 2.07) == 0.0)
	m._on_action()
	_check("foto: sına adımı", m.step == m.Step.TEST)
	# Gözlemleri üret: eşik altı şiddet, eşik üstü şiddet değişimi, frekans değişimi
	m._f = 4.3e14; m._i = 1.0; m._after_change()
	_check("foto: eşik altı gözlemi", m._seen_below)
	m._anchor_f = 9e14; m._anchor_i = 0.3; m._anchor_k = Photo.k_max(9e14, 2.07)
	m._f = 9e14; m._i = 0.9; m._after_change()
	_check("foto: şiddet gözlemi", m._seen_intensity)
	m._anchor_f = 9e14; m._anchor_i = 0.9; m._anchor_k = Photo.k_max(9e14, 2.07)
	m._f = 12e14; m._after_change()
	_check("foto: frekans gözlemi ve Nedeni seç açıldı", m._seen_frequency and m.hud.action.text == "Nedeni seç")
	m._on_action()
	m._on_reason(&"intensity")
	_check("foto: yanlış neden ilerlemedi", m.step == m.Step.REASON)
	m._on_reason(&"frequency")
	m._on_action()
	_check("foto: ölç adımı", m.step == m.Step.MEASURE)
	m.entry.text = "0,5"
	m._on_action()
	_check("foto: yanlış eşik (0,5) ilerlemedi", m.step == m.Step.MEASURE)
	m.entry.text = "5"
	m._on_action()
	_check("foto: doğru eşik, kurtar adımı", m.step == m.Step.RESCUE)
	var cases := [["4.5", "100", false], ["15", "100", false], ["6", "100", false], ["8", "20", false]]
	for c in cases:
		m.entry.text = c[0]
		(m.tools.get_node("IntensityEntry") as LineEdit).text = c[1]
		m._on_action()
		await get_tree().create_timer(0.05).timeout
	_check("foto: yanlış denemeler kapıyı açmadı", not done[0])
	m.entry.text = "8"
	(m.tools.get_node("IntensityEntry") as LineEdit).text = "70"
	m._on_action()
	_check("foto: 8·10¹⁴ Hz, %70 → kapı açıldı", done[0])
	m.queue_free()

func _waves() -> void:
	var m: Control = load("res://stations/waves/mission.tscn").instantiate()
	var done := [false]
	m.completed.connect(func() -> void: done[0] = true)
	add_child(m)
	await get_tree().create_timer(0.2).timeout
	m._on_action()
	_check("dalga: sına adımı", m.step == m.Step.TEST)
	var view = m._view()
	view.two_sources = false
	m._seen_single = true
	view.two_sources = true
	view.frequency = 4.0; m._after_change()
	view.frequency = 6.0; m._after_change()
	_check("dalga: gözlemler tamam, Nedeni seç açıldı", m.hud.action.text == "Nedeni seç")
	m._on_action()
	m._on_reason(&"speed")
	_check("dalga: yanlış neden ilerlemedi", m.step == m.Step.REASON)
	m._on_reason(&"path")
	m._on_action()
	m.entry.text = "0,67"
	m._on_action()
	_check("dalga: ters oran ilerlemedi", m.step == m.Step.MEASURE)
	m.entry.text = "1,5"
	m._on_action()
	_check("dalga: kurtar adımı", m.step == m.Step.RESCUE)
	for f in ["4", "2", "3"]:
		m.entry.text = f
		m._on_action()
	_check("dalga: 4, 2, 3 Hz kurtarmadı", not done[0])
	m.entry.text = "6"
	m._on_action()
	_check("dalga: 6 Hz → A söndü, B parladı", done[0])
	m.queue_free()

func _newton() -> void:
	var m: Control = load("res://stations/newton/mission.tscn").instantiate()
	var done := [false]
	m.completed.connect(func() -> void: done[0] = true)
	add_child(m)
	await get_tree().create_timer(0.2).timeout
	m._on_action()
	_check("newton: kızaklar bırakıldı, eylem Nedenini bul", m.hud.action.text == "Nedenini bul")
	m._on_action()
	_check("newton: sına adımı", m.step == m.Step.TEST)
	m._release()
	_check("newton: kütle gözlemi (2 kg ve 5 kg, 10 N)", m._seen_mass)
	m._force = 20.0; m._apply_test_setup(); m._release()
	_check("newton: kuvvet gözlemi, Nedeni seç açıldı", m._seen_force and m.hud.action.text == "Nedeni seç")
	m._on_action()
	m._on_reason(&"force_only")
	_check("newton: yanlış neden ilerlemedi", m.step == m.Step.REASON)
	m._on_reason(&"ratio")
	m._on_action()
	m.entry.text = "20"
	m._on_action()
	_check("newton: a = F (20) ilerlemedi", m.step == m.Step.MEASURE)
	m.entry.text = "5"
	m._on_action()
	_check("newton: kurtar adımı", m.step == m.Step.RESCUE)
	for f in ["5", "6", "60"]:
		m.entry.text = f
		m._on_action()
	_check("newton: 5, 6, 60 N kurtarmadı", not done[0])
	m.entry.text = "30"
	m._on_action()
	_check("newton: 30 N → kızak tam zamanında", done[0])
	m.queue_free()


func _projectile() -> void:
	var m: Control = load("res://stations/projectile/mission.tscn").instantiate()
	var done := [false]
	m.completed.connect(func() -> void: done[0] = true)
	add_child(m)
	await get_tree().create_timer(0.2).timeout
	m._on_action()
	m._view().time = 2.9; await get_tree().create_timer(0.6).timeout
	_check("atış: toplar indi, eylem Nedenini bul", m.hud.action.text == "Nedenini bul")
	m._on_action()
	_check("atış: sına adımı", m.step == m.Step.TEST)
	for v in [10.0, 20.0, 30.0]:
		m._speed = v
		m._view().speed = v
		m._on_landed(&"thrown", 0.0, 3.0)
	_check("atış: gözlemler tamam, Nedeni seç açıldı", m._seen_speeds and m.hud.action.text == "Nedeni seç")
	m._on_action()
	m._on_reason(&"speed")
	_check("atış: yanlış neden ilerlemedi", m.step == m.Step.REASON)
	m._on_reason(&"height")
	m._on_action()
	m.entry.text = "4,5"
	m._on_action()
	_check("atış: 4,5 s ilerlemedi", m.step == m.Step.MEASURE)
	m.entry.text = "3"
	m._on_action()
	_check("atış: kurtar adımı", m.step == m.Step.RESCUE)
	for v in ["15", "60", "25"]:
		m.entry.text = v
		m._on_action()
	_check("atış: 15, 60, 25 m/s kurtarmadı", not done[0])
	m.entry.text = "20"
	m._on_action()
	_check("atış: 20 m/s → hedef halkası", done[0])
	m.queue_free()


func _collision() -> void:
	var m: Control = load("res://stations/collision/mission.tscn").instantiate()
	var done := [false]
	m.completed.connect(func() -> void: done[0] = true)
	add_child(m)
	await get_tree().create_timer(0.2).timeout
	m._on_action()
	_check("çarpışma: sına adımı", m.step == m.Step.TEST)
	var view = m._view()
	view.m1 = 2.0; view.v1 = 3.0; view.m2 = 1.0; view.v2 = -3.0
	m._after_collision()
	_check("çarpışma: yönlü momentum ve ısı gözlemi", m._seen_vector and m._seen_loss)
	view.elastic = true
	m._after_collision()
	_check("çarpışma: esnek gözlemi, Nedeni seç açıldı", m._seen_elastic and m.hud.action.text == "Nedeni seç")
	m._on_action()
	m._on_reason(&"magnitude")
	m._on_reason(&"energy")
	_check("çarpışma: yanlış nedenler ilerlemedi", m.step == m.Step.REASON)
	m._on_reason(&"vector")
	m._on_action()
	m.entry.text = "3"
	m._on_action()
	_check("çarpışma: 3 m/s (cihazın yanlışı) ilerlemedi", m.step == m.Step.MEASURE)
	m.entry.text = "1"
	m._on_action()
	_check("çarpışma: kurtar adımı", m.step == m.Step.RESCUE)
	for v in ["2", "-1", "-3"]:
		m.entry.text = v
		m._on_action()
	_check("çarpışma: 2, -1, -3 m/s durdurmadı", m.step == m.Step.RESCUE and not done[0])
	m.entry.text = "-1,2"
	m._on_action()
	_check("çarpışma: -1,2 m/s durdurdu, ısı adımı", m.step == m.Step.HEAT)
	m.entry.text = "38,4"
	m._on_action()
	_check("çarpışma: yanlış ısı kapıyı açmadı", not done[0])
	m.entry.text = "9,6"
	m._on_action()
	_check("çarpışma: 9,6 J → kapı sağlam, mühür", done[0])
	m.queue_free()
