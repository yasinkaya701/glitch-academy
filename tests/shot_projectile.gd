extends Node
## Atış Alanı ekran görüntüleri. Kullanım: godot --path . tests/shot_projectile.tscn -- <çıktı klasörü>

func _ready() -> void:
	var out: String = OS.get_cmdline_user_args()[0]
	get_window().size = Vector2i(1600, 900)
	var scene: Control = load("res://stations/projectile/mission.tscn").instantiate()
	scene.theme = get_tree().root.theme
	add_child(scene)
	scene.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await get_tree().create_timer(0.6).timeout
	scene._on_action()
	await get_tree().create_timer(1.9).timeout
	_save(out, "proj_mid")
	await get_tree().create_timer(2.0).timeout
	scene._on_action()
	scene._enter_measure()
	scene._enter_rescue()
	scene.entry.text = "20"
	scene._on_action()
	await get_tree().create_timer(4.0).timeout
	_save(out, "proj_rescue")
	get_tree().quit()

func _save(out: String, name: String) -> void:
	get_viewport().get_texture().get_image().save_png("%s/%s.png" % [out, name])
