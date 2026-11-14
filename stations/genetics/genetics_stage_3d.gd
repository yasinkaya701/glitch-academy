extends "res://scripts/lgs_stage_3d.gd"
## Four equal-probability offspring cells, not a sample of four actual births.

var seeds: Array[MeshInstance3D] = []
var _genotype_labels: Array[Label] = []


func _build_model() -> void:
	view_size = 5.2
	camera_target = Vector3(0, 0.35, 0)
	_readout.hide()
	for index in range(4):
		var point := Vector3(-0.65 if index < 2 else 0.65, 0.4, -0.5 if index % 2 == 0 else 0.5)
		box("ProbabilityCell%d" % index, point - Vector3(0, 0.3, 0), Vector3(1.1, 0.10, 0.8), UITheme.PANEL_RAISED)
		var mesh := SphereMesh.new()
		mesh.radius = 0.27
		mesh.height = 0.54
		var seed := shape("Seed%d" % index, mesh, point, UITheme.MUTED)
		seeds.append(seed)
		_genotype_labels.append(annotate(seed, "", Vector3(0, 0.50, 0)))


func show_genotypes(offspring: PackedStringArray, revealed: bool) -> void:
	for index in _genotype_labels.size():
		_genotype_labels[index].text = offspring[index] if revealed else "?"
