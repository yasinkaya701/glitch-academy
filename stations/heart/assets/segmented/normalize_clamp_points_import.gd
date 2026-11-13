@tool
extends EditorScenePostImport

const VESSELS := [
	"Aorta",
	"PulmonaryTrunk",
	"SVC",
	"IVC",
	"PulmonaryVeinL",
	"PulmonaryVeinR",
]

func _post_import(scene: Node) -> Object:
	for vessel_name in VESSELS:
		var vessel := scene.find_child(vessel_name, true, false)
		if vessel == null:
			push_warning("ClampPoint import hook could not find vessel: " + vessel_name)
			continue
		for child in vessel.get_children():
			if child.name == "ClampPoint" or String(child.name).begins_with("ClampPoint"):
				child.name = "ClampPoint"
				break
	return scene
