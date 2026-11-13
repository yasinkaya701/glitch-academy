extends Control

@onready var experiment: SubViewportContainer = $Experiment3D
@onready var model: Node3D = $Experiment3D/Viewport/World/Model/MeasurementModel


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	experiment.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var camera: Camera3D = experiment.get_node("Viewport/World/Camera3D")
	camera.size = 7.5


func show_state(kind: StringName, reading: bool, progress: float, state: StringName) -> void:
	if model != null:
		model.set_state(kind, reading, progress, state)
