extends Node
## Vektör Limanı sınama ve kurtarma adımı. Kullanım: godot --path . tests/shot_vectors_states.tscn -- <çıktı klasörü>

func _ready() -> void:
	var out: String = OS.get_cmdline_user_args()[0]
	get_window().size = Vector2i(1280, 720)
	var host := Control.new()
	host.theme = UITheme.build_gameplay()
	host.scale = Vector2(1.3, 1.3)
	host.size = Vector2(900, 600) / 1.3
	host.clip_contents = true
	add_child(host)
	var scene: Control = load("res://stations/vectors/mission.tscn").instantiate()
	host.add_child(scene)
	scene.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await get_tree().create_timer(3.2).timeout
	scene._on_action()
	await get_tree().create_timer(0.8).timeout
	scene._fly_test()
	await get_tree().create_timer(2.3).timeout
	get_viewport().get_texture().get_image().save_png(out + "/test_900.png")
	scene._enter_rescue()
	scene._east = 6.0
	scene._north = 8.0
	scene._refresh_rescue()
	await get_tree().create_timer(0.8).timeout
	get_viewport().get_texture().get_image().save_png(out + "/rescue_900.png")
	get_tree().quit()
