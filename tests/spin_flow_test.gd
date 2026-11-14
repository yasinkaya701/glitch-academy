extends Node
## Spin Hattı akışı: kriz → sınama → neden → ölçüm → kurtarma. Çıkış kodu = başarısız denetim sayısı.

var failures := 0


func _ready() -> void:
	var scene: Control = load("res://stations/spin/mission.tscn").instantiate()
	add_child(scene)
	scene.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await get_tree().create_timer(0.5).timeout
	scene._view().skip_intro()
	scene._on_action()
	_check(scene.step == scene.Step.TEST, "sınama adımına geçti")
	scene._view().gradient = 1.0
	scene._cycle_stage(0)
	scene._after_change()
	scene._view().detector_axis = &"z"
	scene._cycle_stage(0)
	scene._cycle_stage(0)
	scene._cycle_stage(0)
	scene._on_reason(&"spread")
	scene._enter_reason()
	_check(scene.step == scene.Step.REASON, "neden adımı")
	scene._on_reason(&"two")
	scene._on_action()
	_check(scene.step == scene.Step.MEASURE, "ölçüm adımı")
	scene.entry.text = "100"
	scene._on_action()
	_check(scene.step == scene.Step.MEASURE, "yanlış %100 ilerletmez")
	scene.entry.text = "50"
	scene._on_action()
	_check(scene.step == scene.Step.RESCUE, "doğru %50 kurtarma adımına geçirir")
	# Hedef: ulaşan %12,5, hepsi Z aşağı. Z↑ → X↑ → Z↓ : 0,5 × 0,5 × 0,5
	scene._choice = [1, 3, 2]
	scene._apply_setup()
	scene._on_action()
	_check(scene._sealed, "doğru düzenek mühürler (hak sınırı yok, onarım tamam)")
	print("BAŞARISIZ: %d" % failures)
	get_tree().quit(failures)


func _check(ok: bool, what: String) -> void:
	print(("ok   " if ok else "FAIL ") + what)
	if not ok:
		failures += 1
