extends Node3D
## Standalone, close-up preview of the detailed heart and the four interactive valve assets.

const Model = preload("res://stations/heart/heart_model.gd")
const VALVES := {
	Model.Valve.TRICUSPID: {
		"scene": preload("res://stations/heart/assets/segmented/valves/tricuspid.glb"),
		"position": Vector3(-0.0204, 0.0559, 0.0159), "direction": Vector3(0.12, -1.0, 0.18), "radius": 0.0092,
	},
	Model.Valve.MITRAL: {
		"scene": preload("res://stations/heart/assets/segmented/valves/mitral.glb"),
		"position": Vector3(0.0184, 0.0582, 0.0189), "direction": Vector3(0.10, -1.0, 0.14), "radius": 0.0085,
	},
	Model.Valve.AORTIC: {
		"scene": preload("res://stations/heart/assets/segmented/valves/aortic.glb"),
		"position": Vector3(-0.0083, 0.0888, 0.0165), "direction": Vector3(0.44, 0.9, 0.0), "radius": 0.0058,
	},
	Model.Valve.PULMONARY: {
		"scene": preload("res://stations/heart/assets/segmented/valves/pulmonary.glb"),
		"position": Vector3(0.0018, 0.0752, 0.0160), "direction": Vector3(0.6, 0.8, 0.0), "radius": 0.0056,
	},
}


func _ready() -> void:
	for valve in VALVES:
		var data: Dictionary = VALVES[valve]
		var model: Node3D = data["scene"].instantiate()
		model.name = Model.VALVE_NAMES[valve].replace(" ", "_")
		model.position = data["position"] + Vector3(0.0, 0.0, 0.0025)
		model.quaternion = Quaternion(Vector3.UP, (data["direction"] as Vector3).normalized())
		model.scale = Vector3.ONE * float(data["radius"]) / 0.88
		add_child(model)
