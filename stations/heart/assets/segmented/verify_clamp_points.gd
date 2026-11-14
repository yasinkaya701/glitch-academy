extends SceneTree

const MODELS := [
	"res://stations/heart/assets/segmented/heart_segmented.glb",
	"res://stations/heart/assets/segmented/heart_segmented_aortic_leaky.glb",
	"res://stations/heart/assets/segmented/heart_segmented_mitral_leaky.glb",
	"res://stations/heart/assets/segmented/heart_segmented_pulmonary_leaky.glb",
	"res://stations/heart/assets/segmented/heart_segmented_tricuspid_leaky.glb",
]
const VESSELS := ["Aorta", "PulmonaryTrunk", "SVC", "IVC", "PulmonaryVeinL", "PulmonaryVeinR"]

func _initialize() -> void:
	call_deferred("verify")

func verify() -> void:
	var valid := true
	for model_path in MODELS:
		var packed := load(model_path) as PackedScene
		if packed == null:
			push_error("Could not load model PackedScene: " + model_path)
			valid = false
			continue
		var model := packed.instantiate()
		root.add_child(model)
		for vessel_name in VESSELS:
			var vessel := model.find_child(vessel_name, true, false) as Node3D
			if vessel == null or vessel.get_node_or_null("ClampPoint") == null:
				push_error(model_path.get_file() + " is missing " + vessel_name + "/ClampPoint")
				valid = false
		model.queue_free()
		print(model_path.get_file(), ": all six vessel-local ClampPoint paths resolved")
	print("All five imported GLBs passed clamp path QA: ", valid)
	quit(0 if valid else 1)
