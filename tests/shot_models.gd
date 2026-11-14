extends Node
## 3B model yönlerini yan yana gösterir. Kullanım: godot --path . tests/shot_models.tscn -- <çıktı klasörü>
const Stage = preload("res://scripts/physics/lab_stage_3d.gd")

func _ready() -> void:
	var out: String = OS.get_cmdline_user_args()[0]
	get_window().size = Vector2i(1600, 900)
	var stage := Stage.new()
	stage.setup(Color("#ff7a5e"), 30.0, Vector3(0.0, 0.6, 1.6), Vector3(0, 0.1, 0))
	stage.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(stage)
	var car := stage.model("res://assets/models/toy_car/ToyCar.glb", 0.4, null, true)
	car.position = Vector3(0, 0, 0)
	await get_tree().create_timer(2.0).timeout
	get_viewport().get_texture().get_image().save_png("%s/models.png" % out)
	get_tree().quit()
