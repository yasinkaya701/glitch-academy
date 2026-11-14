extends Node
## Newton Kızağı ekran görüntüleri. Kullanım: godot --path . tests/shot_newton.tscn -- <çıktı klasörü>

func _ready() -> void:
	var out: String = OS.get_cmdline_user_args()[0]
	get_window().size = Vector2i(1600, 900)
	var scene: Control = load("res://stations/newton/mission.tscn").instantiate()
	scene.theme = get_tree().root.theme
	add_child(scene)
	scene.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await get_tree().create_timer(0.6).timeout
	scene._on_action()
	await get_tree().create_timer(3.0).timeout
	_save(out, "newton_crisis")
	scene._on_action()
	scene._release()
	await get_tree().create_timer(2.5).timeout
	_save(out, "newton_test")
	get_tree().quit()

func _save(out: String, name: String) -> void:
	get_viewport().get_texture().get_image().save_png("%s/%s.png" % [out, name])
