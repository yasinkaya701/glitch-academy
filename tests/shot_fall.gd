extends Node
## Düşüş Odası ekran görüntüleri. Kullanım: godot --path . tests/shot_fall.tscn -- <çıktı klasörü>

func _ready() -> void:
	var out: String = OS.get_cmdline_user_args()[0]
	get_window().size = Vector2i(1600, 900)
	var scene: Control = load("res://stations/free_fall/mission.tscn").instantiate()
	scene.theme = get_tree().root.theme  # Düz Node ata olduğundan tema kendiliğinden geçmez
	add_child(scene)
	scene.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await get_tree().create_timer(0.9).timeout
	_save(out, "fall_idle")
	await get_tree().create_timer(3.0).timeout
	_save(out, "fall_mid")
	await get_tree().create_timer(4.2).timeout
	_save(out, "fall_end")
	get_tree().quit()

func _save(out: String, name: String) -> void:
	get_viewport().get_texture().get_image().save_png("%s/%s.png" % [out, name])
