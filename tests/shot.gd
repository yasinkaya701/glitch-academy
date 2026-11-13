extends Node
## Kalp görevini normal çalıştırır ve durumları oyunun kendi çıktısından kaydeder.
## Kullanım: godot --path . tests/shot.tscn -- <çıktı klasörü>

func _ready() -> void:
	var out: String = OS.get_cmdline_user_args()[0]
	get_window().size = Vector2i(1600, 900)
	var scene: Control = load("res://stations/heart/mission.tscn").instantiate()
	scene.theme = get_tree().root.theme  # Düz Node ata olduğundan tema kendiliğinden geçmez
	add_child(scene)
	scene.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await get_tree().create_timer(3.5).timeout
	_save(out, "intro")
	scene._finish_intro()
	scene._enter_lab()
	await get_tree().create_timer(3.0).timeout
	_save(out, "lab_healthy")
	scene.lab_tool = &"clamp"
	scene._lab_click(&"pulmonary_veins")
	scene.stage.rig.distance = 3.5
	scene.lab_leak[scene.Model.Valve.AORTIC] = 0.6
	await get_tree().create_timer(5.0).timeout
	_save(out, "lab_fault")
	get_tree().quit()

func _save(out: String, name: String) -> void:
	get_viewport().get_texture().get_image().save_png("%s/%s.png" % [out, name])
