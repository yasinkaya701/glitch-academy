extends Node
## Vektör Limanı akışı: kriz → sınama → neden → ölçüm → kurtarma. Çıkış kodu = başarısız denetim sayısı.

var failures := 0


func _ready() -> void:
	var scene: Control = load("res://stations/vectors/mission.tscn").instantiate()
	add_child(scene)
	scene.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await get_tree().create_timer(3.4).timeout
	scene._on_action()
	_check(scene.step == scene.Step.TEST, "sınama adımı")
	for vec in [Vector3(5, 0, 0), Vector3(3, 4, 0), Vector3(2, 3, 6)]:
		scene._vec = vec
		scene._fly_test()
		await get_tree().create_timer(2.6).timeout
	_check(scene._seen_single and scene._seen_plane and scene._seen_space, "tek, iki ve üç eksen durumları görüldü")
	scene._on_action()
	_check(scene.step == scene.Step.REASON, "neden adımı")
	scene._on_reason(&"scalar")
	scene._on_reason(&"vector")
	scene._on_action()
	_check(scene.step == scene.Step.MEASURE, "ölçüm adımı")
	scene.entry.text = "11"
	scene._on_action()
	_check(scene.step == scene.Step.MEASURE, "11 (düz toplam) ilerletmez")
	scene.entry.text = "7"
	scene._on_action()
	await get_tree().create_timer(2.6).timeout
	_check(scene.step == scene.Step.RESCUE, "doğru 7 kurtarma adımına geçirir")
	scene._vec = Vector3(7, 0, 0)
	scene._run_rescue()
	await get_tree().create_timer(2.8).timeout
	_check(not scene._sealed, "yanlış bileşenler mühürlemez")
	scene._vec = Vector3(4, 4, 7)
	scene._run_rescue()
	await get_tree().create_timer(2.8).timeout
	_check(scene._sealed, "4 doğu + 4 kuzey + 7 yukarı mühürler")
	print("BAŞARISIZ: %d" % failures)
	get_tree().quit(failures)


func _check(ok: bool, what: String) -> void:
	print(("ok   " if ok else "FAIL ") + what)
	if not ok:
		failures += 1
