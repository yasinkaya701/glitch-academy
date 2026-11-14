extends Node3D
## Selects the topic-specific 3D diorama used by each YKS subject task.

const ScienceModels := preload("res://stations/yks/visuals/science_models.gd")
const TextModels := preload("res://stations/yks/visuals/text_models.gd")
const SocietyModels := preload("res://stations/yks/visuals/society_models.gd")

const SCIENCE_THEMES: Array[StringName] = [&"math", &"geometry", &"chemistry", &"biology"]
const TEXT_THEMES: Array[StringName] = [&"reading", &"literature", &"history", &"geography"]

var _model: Node3D


func _ready() -> void:
	var camera := get_viewport().get_camera_3d()
	if camera != null:
		camera.projection = Camera3D.PROJECTION_ORTHOGONAL
		camera.position = Vector3(0.0, 4.8, 10.8)
		camera.rotation_degrees = Vector3(-24.0, 0.0, 0.0)
		camera.size = 7.2
		camera.current = true


func build(theme_id: StringName) -> void:
	if _model != null:
		_model.queue_free()
	_model = null
	var model_script: Script
	if theme_id in SCIENCE_THEMES:
		model_script = ScienceModels
	elif theme_id in TEXT_THEMES:
		model_script = TextModels
	else:
		model_script = SocietyModels
	_model = model_script.new() as Node3D
	_model.name = "%sModel" % String(theme_id).capitalize()
	add_child(_model)
	_model.call("build", theme_id)


func update_stage(state: Dictionary) -> void:
	if _model != null:
		_model.call("update_stage", state)
		_model.call("set_result", int(state.get("result", 0)), float(state.get("progress", 1.0)))
