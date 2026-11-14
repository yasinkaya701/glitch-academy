extends Node
## Kontrol merkezi yol görünümü. Kullanım: godot --path . tests/shot_hub_path.tscn -- <çıktı klasörü> [done_sayısı]

func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var out: String = args[0]
	get_window().size = Vector2i(1280, 720)
	var scene: Control = load("res://scenes/control_center.tscn").instantiate()
	add_child(scene)
	await get_tree().create_timer(0.5).timeout
	for node in scene.get_children():
		if node.has_signal("finished"):
			node.finished.emit()
	scene._select_route(&"ayt")
	for index in int(args[1]) if args.size() > 1 else 0:
		scene.completed_ids[scene._route_missions()[index].id] = true
	scene._select_route(&"ayt")
	await get_tree().create_timer(1.0).timeout
	get_viewport().get_texture().get_image().save_png(out + "/hub_path.png")
	get_tree().quit()
