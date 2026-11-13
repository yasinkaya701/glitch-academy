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
