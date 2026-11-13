extends Node
## Spin Hattı görevini doğru ve yanlış yollarla baştan sona oynar.
## Kullanım: godot --headless --path . tests/spin_flow_test.tscn

var failures := 0

func _check(label: String, ok: bool) -> void:
	print("%s  %s" % ["ok " if ok else "HATA", label])
	if not ok:
		failures += 1

func _ready() -> void:
	var m: Control = load("res://stations/spin/mission.tscn").instantiate()
	var done := [false]
	m.completed.connect(func() -> void: done[0] = true)
	add_child(m)
	await get_tree().create_timer(0.2).timeout
	m._on_action()
	_check("spin: sına adımı", m.step == m.Step.TEST)
	# Z↑ süz, Z ölç: aynı sonuç
	m._cycle_stage(0)
	m._after_change()
	_check("spin: aynı eksen gözlemi", m._seen_same)
	m._toggle_detector()
	_check("spin: dik eksen gözlemi", m._seen_cross)
	m._cycle_stage(1); m._cycle_stage(1); m._cycle_stage(1)   # X↑
	m._toggle_detector()                                         # Z ölç
	_check("spin: silinen bilgi gözlemi, Nedeni seç açıldı", m._seen_erased and m.hud.action.text == "Nedeni seç")
	m._on_action()
	m._on_reason(&"spread")
	m._on_reason(&"split")
	_check("spin: yanlış neden ilerlemedi", m.step == m.Step.REASON)
	m._on_reason(&"two")
	m._on_action()
	_check("spin: ölç adımı", m.step == m.Step.MEASURE)
	m.entry.text = "100"
	m._on_action()
	_check("spin: %100 ilerlemedi", m.step == m.Step.MEASURE)
	m.entry.text = "50"
	m._on_action()
	_check("spin: kurtar adımı", m.step == m.Step.RESCUE)
	# Yanlış: Z↑, Z↓ (hiç atom geçmez)
	m._cycle_stage(0); m._cycle_stage(1); m._cycle_stage(1)
	m._on_action()
	_check("spin: Z↑ sonra Z↓ kurtarmadı", not done[0])
	# Yanlış: yalnız Z↓ (oran %50)
	m._choice = [2, 0, 0]; m._apply_setup()
	m._on_action()
	_check("spin: tek süzgeç kurtarmadı", not done[0])
	# Yanlış: oran doğru, dedektör X
	m._choice = [1, 3, 2]; m._apply_setup(); m._view().detector_axis = &"x"
	m._on_action()
	_check("spin: dedektör X kurtarmadı", not done[0])
	m._view().detector_axis = &"z"
	m._on_action()
	_check("spin: Z↑, X↑, Z↓ + Z dedektör → mühür", done[0])
	m.queue_free()
	print("BAŞARISIZ: %d" % failures if failures > 0 else "HEPSİ GEÇTİ")
	get_tree().quit(failures)
