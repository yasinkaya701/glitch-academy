extends Node
## Vektör Limanı akışı: kriz → sınama → neden → ölçüm → kurtarma. Çıkış kodu = başarısız denetim sayısı.

var failures := 0


func _ready() -> void:
	var scene: Control = load("res://stations/vectors/mission.tscn").instantiate()
	add_child(scene)
	scene.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await get_tree().create_timer(3.2).timeout
	scene._on_action()
	_check(scene.step == scene.Step.TEST, "sınama adımı")
	for angle in [0.0, 180.0, 90.0]:
		scene._a = 3.0
		scene._b = 4.0
		scene._angle = angle
		scene._fly_test()
		await get_tree().create_timer(2.1).timeout
	_check(scene._seen_same and scene._seen_opposite and scene._seen_perpendicular, "üç durum görüldü")
	scene._on_action()
	_check(scene.step == scene.Step.REASON, "neden adımı")
	scene._on_reason(&"scalar")
	scene._on_reason(&"vector")
	scene._on_action()
	_check(scene.step == scene.Step.MEASURE, "ölçüm adımı")
	scene.entry.text = "7"
	scene._on_action()
	_check(scene.step == scene.Step.MEASURE, "7 (düz toplam) ilerletmez")
	scene.entry.text = "5"
	scene._on_action()
	await get_tree().create_timer(2.0).timeout
	_check(scene.step == scene.Step.RESCUE, "doğru 5 kurtarma adımına geçirir")
	scene._east = 10.0
	scene._north = 0.0
	scene._run_rescue()
	await get_tree().create_timer(2.2).timeout
	_check(not scene._sealed, "yanlış bileşenler mühürlemez")
	scene._east = 8.0
	scene._north = 6.0
	scene._run_rescue()
	await get_tree().create_timer(2.2).timeout
	_check(scene._sealed, "8 doğu + 6 kuzey mühürler")
	print("BAŞARISIZ: %d" % failures)
	get_tree().quit(failures)


func _check(ok: bool, what: String) -> void:
	print(("ok   " if ok else "FAIL ") + what)
	if not ok:
		failures += 1
