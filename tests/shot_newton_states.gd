extends Node
## Newton Kızağı sınama ve neden adımı, 900×600 (%130). Kullanım: godot --path . tests/shot_newton_states.tscn -- <çıktı klasörü>

func _ready() -> void:
	var out: String = OS.get_cmdline_user_args()[0]
	get_window().size = Vector2i(1280, 720)
	var host := Control.new()
	host.theme = UITheme.build_gameplay()
	host.scale = Vector2(1.3, 1.3)
	host.size = Vector2(900, 600) / 1.3
	host.clip_contents = true
	add_child(host)
	var scene: Control = load("res://stations/newton/mission.tscn").instantiate()
	host.add_child(scene)
	scene.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await get_tree().create_timer(1.0).timeout
	scene._enter_test()
	await get_tree().create_timer(1.2).timeout
	scene._release()
	await get_tree().create_timer(2.5).timeout
	get_viewport().get_texture().get_image().save_png(out + "/test_900.png")
	scene._enter_reason()
	await get_tree().create_timer(1.0).timeout
	get_viewport().get_texture().get_image().save_png(out + "/reason_900.png")
	get_tree().quit()
