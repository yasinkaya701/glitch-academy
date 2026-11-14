extends Node
## Kontrol merkezi ekran görüntüleri. Kullanım: godot --path . tests/shot_hub.tscn -- <çıktı klasörü>

func _ready() -> void:
	var out: String = OS.get_cmdline_user_args()[0]
	get_window().size = Vector2i(1600, 900)
	var scene: Control = load("res://scenes/control_center.tscn").instantiate()
	add_child(scene)
	await get_tree().create_timer(4.0).timeout
	get_viewport().get_texture().get_image().save_png(out + "/hub_intro.png")
	await get_tree().create_timer(13.0).timeout
	get_viewport().get_texture().get_image().save_png(out + "/hub.png")
	get_tree().quit()
