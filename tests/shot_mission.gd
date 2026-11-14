extends Node
## Tek bir görev sahnesinin ekran görüntüsü, 1280×720 ve 900×600 (%130).
## Kullanım: godot --path . tests/shot_mission.tscn -- <mission.tscn yolu> <çıktı klasörü> [bekleme saniyesi] [rota]

const SIZES := [Vector2(1280, 720), Vector2(900, 600)]
const SCALES := [1.0, 1.3]


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var wait := float(args[2]) if args.size() > 2 else 1.5
	get_window().size = Vector2i(1280, 720)
	for index in SIZES.size():
		var host := Control.new()
		host.theme = UITheme.build_gameplay()
		host.scale = Vector2(SCALES[index], SCALES[index])
		host.size = SIZES[index] / SCALES[index]
		host.clip_contents = true
		add_child(host)
		var scene: Control = load(args[0]).instantiate()
		if args.size() > 3:
			scene.set("route", StringName(args[3]))
		host.add_child(scene)
		scene.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		await get_tree().create_timer(wait).timeout
		get_viewport().get_texture().get_image().save_png("%s/%s_%dx%d.png" % [args[1], args[0].get_base_dir().get_file(), SIZES[index].x, SIZES[index].y])
		host.queue_free()
		await get_tree().process_frame
	get_tree().quit()
