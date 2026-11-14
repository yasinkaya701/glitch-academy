extends Node
## Spin Hattı her adım için iki boyutta ekran görüntüsü. Kullanım: godot --path . tests/shot_spin_states.tscn -- <çıktı klasörü>

const SIZES := [Vector2(1280, 720), Vector2(900, 600)]
const SCALES := [1.0, 1.3]


func _ready() -> void:
	var out: String = OS.get_cmdline_user_args()[0]
	get_window().size = Vector2i(1280, 720)
	for index in SIZES.size():
		var host := Control.new()
		host.theme = get_tree().root.theme
		host.scale = Vector2(SCALES[index], SCALES[index])
		host.size = SIZES[index] / SCALES[index]
		host.clip_contents = true
		add_child(host)
		var scene: Control = load("res://stations/spin/mission.tscn").instantiate()
		scene.theme = UITheme.build_gameplay()
		host.add_child(scene)
		scene.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		var tag := "%dx%d" % [SIZES[index].x, SIZES[index].y]
		await get_tree().create_timer(1.2).timeout
		_save(out, "1_crisis_" + tag)
		scene._view().skip_intro()
		await get_tree().create_timer(0.8).timeout
		scene._on_action()
		await get_tree().create_timer(0.6).timeout
		_save(out, "2_test_" + tag)
		scene._view().gradient = 1.0
		scene._cycle_stage(0)
		scene._cycle_stage(1)
		scene._cycle_stage(1)
		scene._cycle_stage(1)
		await get_tree().create_timer(3.0).timeout
		_save(out, "3_test_filters_" + tag)
		scene._on_action()
		await get_tree().create_timer(0.4).timeout
		_save(out, "4_reason_" + tag)
		scene._on_reason(&"two")
		scene._on_action()
		await get_tree().create_timer(1.5).timeout
		_save(out, "5_measure_" + tag)
		scene._enter_rescue()
		await get_tree().create_timer(1.5).timeout
		_save(out, "6_rescue_" + tag)
		host.queue_free()
		await get_tree().process_frame
	get_tree().quit()


func _save(out: String, name: String) -> void:
	get_viewport().get_texture().get_image().save_png("%s/%s.png" % [out, name])
