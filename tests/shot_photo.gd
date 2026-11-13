extends Node
## Fotoelektrik Kapısı ekran görüntüleri. Kullanım: godot --path . tests/shot_photo.tscn -- <çıktı klasörü>

func _ready() -> void:
	var out: String = OS.get_cmdline_user_args()[0]
	get_window().size = Vector2i(1600, 900)
	var scene: Control = load("res://stations/photoelectric/mission.tscn").instantiate()
	scene.theme = get_tree().root.theme
	add_child(scene)
	scene.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await get_tree().create_timer(1.5).timeout
	_save(out, "photo_crisis")
	scene._enter_test()
	scene._f = 9.0e14
	scene._i = 0.7
	scene._sync_view()
	await get_tree().create_timer(2.5).timeout
	_save(out, "photo_test")
	get_tree().quit()

func _save(out: String, name: String) -> void:
	get_viewport().get_texture().get_image().save_png("%s/%s.png" % [out, name])
