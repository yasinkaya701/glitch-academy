extends Node
## Spin Hattı ekran görüntüleri. Kullanım: godot --path . tests/shot_spin.tscn -- <çıktı klasörü>

func _ready() -> void:
	var out: String = OS.get_cmdline_user_args()[0]
	get_window().size = Vector2i(1600, 900)
	var scene: Control = load("res://stations/spin/mission.tscn").instantiate()
	scene.theme = get_tree().root.theme
	add_child(scene)
	scene.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await get_tree().create_timer(1.0).timeout
	_save(out, "spin_a_normal")
	await get_tree().create_timer(1.6).timeout
	_save(out, "spin_b_glitch")
	await get_tree().create_timer(1.8).timeout
	_save(out, "spin_c_rift")
	await get_tree().create_timer(1.0).timeout
	_save(out, "spin_d_rift_full")
	await get_tree().create_timer(3.0).timeout
	_save(out, "spin_crisis")
	scene._on_action()
	scene._cycle_stage(0)
	scene._cycle_stage(1)
	scene._cycle_stage(1)
	scene._cycle_stage(1)
	await get_tree().create_timer(5.0).timeout
	_save(out, "spin_test")
	get_tree().quit()

func _save(out: String, name: String) -> void:
	get_viewport().get_texture().get_image().save_png("%s/%s.png" % [out, name])
