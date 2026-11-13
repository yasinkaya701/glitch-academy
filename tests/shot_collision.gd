extends Node
## Çarpışma Hattı ekran görüntüleri. Kullanım: godot --path . tests/shot_collision.tscn -- <çıktı klasörü>

func _ready() -> void:
	var out: String = OS.get_cmdline_user_args()[0]
	get_window().size = Vector2i(1600, 900)
	var scene: Control = load("res://stations/collision/mission.tscn").instantiate()
	scene.theme = get_tree().root.theme
	add_child(scene)
	scene.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await get_tree().create_timer(1.4).timeout
	_save(out, "coll_a_approach")
	await get_tree().create_timer(2.2).timeout
	_save(out, "coll_b_drift")
	await get_tree().create_timer(1.0).timeout
	_save(out, "coll_c_shatter")
	await get_tree().create_timer(4.0).timeout
	scene._on_action()
	scene._collide()
	await get_tree().create_timer(2.6).timeout
	_save(out, "coll_d_test")
	get_tree().quit()

func _save(out: String, name: String) -> void:
	get_viewport().get_texture().get_image().save_png("%s/%s.png" % [out, name])
