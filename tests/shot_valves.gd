extends Node
## Kalp kapakçıklarını yakından gösterir. Kullanım: godot --path . tests/shot_valves.tscn -- <çıktı klasörü>
const Stage = preload("res://scripts/physics/lab_stage_3d.gd")
const Valve = preload("res://stations/heart/valve_prosthesis.gd")
const Model = preload("res://stations/heart/heart_model.gd")

func _ready() -> void:
	var out: String = OS.get_cmdline_user_args()[0]
	get_window().size = Vector2i(1600, 900)
	var stage := Stage.new()
	stage.setup(Color("#ff7a5e"), 26.0, Vector3(0.0, 0.3, 0.8), Vector3(0, 0.0, 0))
	stage.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(stage)
	var openness := [0.0, 0.5, 1.0]
	for row in 2:
		for i in 3:
			var valve := Valve.new()
			stage.world.add_child(valve)
			valve.setup(Model.Valve.MITRAL if row == 0 else Model.Valve.AORTIC, 0.05)
			valve.open_amount = openness[i]
			valve.position = Vector3(-0.2 + 0.2 * i, 0.08 - 0.16 * row, 0)
			valve.rotation_degrees = Vector3(35, 25, 0)
	await get_tree().create_timer(1.5).timeout
	get_viewport().get_texture().get_image().save_png("%s/valves.png" % out)
	get_tree().quit()
