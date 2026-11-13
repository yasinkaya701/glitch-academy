extends Node3D
## Modular 3D frame for the heart perfusion lab. The ring provides a stable scale
## reference around the specimen and links it visually to the pressure monitor.

const STEEL := Color("#506272")
const DARK_STEEL := Color("#17232c")
const JADE := Color("#6fe3c1")
const AMBER := Color("#f2a65a")


func _ready() -> void:
	_build_specimen_gantry()
	_build_floor_scale()


func _material(color: Color, metallic: float, roughness: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = metallic
	material.roughness = roughness
	return material


func _emissive(color: Color, power: float) -> StandardMaterial3D:
	var material := _material(color, 0.12, 0.32)
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = power
	return material


func _tube_between(a: Vector3, b: Vector3, radius: float, material: Material) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = a.distance_to(b)
	mesh.radial_segments = 16
	node.mesh = mesh
	node.material_override = material
	node.position = (a + b) * 0.5
	node.quaternion = Quaternion(Vector3.UP, (b - a).normalized())
	add_child(node)
	return node


func _sphere(position: Vector3, radius: float, material: Material) -> void:
	var node := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 16
	mesh.rings = 8
	node.mesh = mesh
	node.material_override = material
	node.position = position
	add_child(node)


func _build_specimen_gantry() -> void:
	var steel := _material(STEEL, 0.78, 0.27)
	var dark := _material(DARK_STEEL, 0.68, 0.4)
	var jade := _emissive(JADE, 1.2)
	var amber := _emissive(AMBER, 0.8)
	# A restrained, open ring frames the specimen without hiding the heart or its ports.
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.91
	torus.outer_radius = 0.935
	torus.rings = 96
	torus.ring_segments = 12
	ring.mesh = torus
	ring.material_override = steel
	ring.position = Vector3(0.0, 0.02, -0.24)
	ring.rotation_degrees.x = 90.0
	add_child(ring)
	# Three short support shoes connect the open frame to the bench perimeter.
	for angle in [PI * 0.24, PI * 0.76, PI * 1.5]:
		var point := Vector3(cos(angle) * 0.93, sin(angle) * 0.93 + 0.02, -0.24)
		var foot := Vector3(point.x * 1.17, -0.76, -0.24)
		_tube_between(point, foot, 0.018, steel)
		_tube_between(foot + Vector3(0, -0.035, 0), foot + Vector3(0.12 * signf(point.x), -0.035, 0), 0.022, dark)
		_sphere(point, 0.036, jade if angle == -PI * 0.5 else steel)
	# Twelve etched index marks make the ring read as a calibration frame.
	for index in 12:
		var angle := TAU * float(index) / 12.0
		var radial := Vector3(cos(angle), sin(angle), 0.0)
		var tick := MeshInstance3D.new()
		var bar := BoxMesh.new()
		bar.size = Vector3(0.028 if index % 3 == 0 else 0.014, 0.004, 0.008)
		tick.mesh = bar
		tick.material_override = amber if index == 3 or index == 9 else jade
		tick.position = Vector3(radial.x * 0.88, radial.y * 0.88 + 0.02, -0.20)
		tick.rotation.z = angle
		add_child(tick)
	# Small illuminated datum nodes clarify the top, sides and lower return of the frame.
	for angle in [0.0, PI * 0.5, PI, PI * 1.5]:
		_sphere(Vector3(cos(angle) * 0.94, sin(angle) * 0.94 + 0.02, -0.17), 0.019, jade if angle != PI * 1.5 else amber)


func _build_floor_scale() -> void:
	var soft := _material(Color("#14242c"), 0.52, 0.56)
	var guide := _emissive(Color("#274e55"), 0.22)
	# Inlaid spacing arcs on the bench help compare organ positions and hose reach.
	for radius in [1.48, 1.82, 2.16]:
		var arc := MeshInstance3D.new()
		var torus := TorusMesh.new()
		torus.inner_radius = radius
		torus.outer_radius = radius + 0.006
		torus.rings = 96
		torus.ring_segments = 6
		arc.mesh = torus
		arc.material_override = guide
		arc.position = Vector3(0, -0.865, 0)
		add_child(arc)
	# A compact radial instrument index rests at the front edge of the platform.
	for x in range(-4, 5):
		var mark := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.026 if x % 2 == 0 else 0.014, 0.003, 0.095 if x % 2 == 0 else 0.05)
		mark.mesh = box
		mark.material_override = soft if x % 2 == 0 else guide
		mark.position = Vector3(float(x) * 0.15, -0.865, 2.22)
		add_child(mark)
