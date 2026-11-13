extends RefCounted
## Anatomi motoru için ortak yardımcılar: sınır kutusu, boru meshi, yol üzerinde nokta, Bezier.


static func bounds(node: Node) -> AABB:
	var box := AABB()
	var first := true
	var stack: Array[Node] = [node]
	while not stack.is_empty():
		var current: Node = stack.pop_back()
		stack.append_array(current.get_children())
		if current is MeshInstance3D:
			var local: AABB = (current as MeshInstance3D).get_aabb()
			box = local if first else box.merge(local)
			first = false
	return box


static func path_length(points: Array) -> float:
	var total := 0.0
	for i in points.size() - 1:
		total += (points[i] as Vector3).distance_to(points[i + 1])
	return total


static func point_on_path(points: Array, distance: float) -> Vector3:
	var remaining := distance
	for i in points.size() - 1:
		var a: Vector3 = points[i]
		var b: Vector3 = points[i + 1]
		var seg := a.distance_to(b)
		if remaining <= seg:
			return a.lerp(b, remaining / maxf(seg, 0.00001))
		remaining -= seg
	return points[points.size() - 1]


static func bezier(p0: Vector3, c0: Vector3, c1: Vector3, p1: Vector3, steps: int = 48) -> PackedVector3Array:
	var points := PackedVector3Array()
	for i in steps + 1:
		var t := float(i) / float(steps)
		points.append(p0 * pow(1 - t, 3) + c0 * 3 * pow(1 - t, 2) * t + c1 * 3 * (1 - t) * t * t + p1 * pow(t, 3))
	return points


## Eğri boyunca yarı saydam boru. `material` verilmezse cam benzeri bir malzeme kurulur.
static func tube_mesh(points: PackedVector3Array, color: Color, radius: float, material: Material = null) -> MeshInstance3D:
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var indices := PackedInt32Array()
	var sides := 14
	for i in points.size():
		var tangent: Vector3
		if i == 0:
			tangent = points[1] - points[0]
		elif i == points.size() - 1:
			tangent = points[i] - points[i - 1]
		else:
			tangent = points[i + 1] - points[i - 1]
		tangent = tangent.normalized()
		var helper := Vector3.UP if absf(tangent.dot(Vector3.UP)) < 0.95 else Vector3.RIGHT
		var side := tangent.cross(helper).normalized()
		var up := side.cross(tangent).normalized()
		for j in sides:
			var angle := TAU * float(j) / float(sides)
			var normal := side * cos(angle) + up * sin(angle)
			vertices.append(points[i] + normal * radius)
			normals.append(normal)
	for i in points.size() - 1:
		for j in sides:
			var a := i * sides + j
			var b := i * sides + (j + 1) % sides
			var c := (i + 1) * sides + j
			var d := (i + 1) * sides + (j + 1) % sides
			indices.append_array([a, c, b, b, c, d])
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	if material == null:
		var glass := StandardMaterial3D.new()
		glass.albedo_color = Color(color.r, color.g, color.b, 0.28)
		glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		glass.roughness = 0.08
		glass.metallic = 0.1
		glass.emission_enabled = true
		glass.emission = color
		glass.emission_energy_multiplier = 0.25
		glass.cull_mode = BaseMaterial3D.CULL_DISABLED
		material = glass
	instance.material_override = material
	return instance


## Parçacık demeti: bir yol boyunca akan küreler (MultiMesh).
static func make_particles(parent: Node3D, radius: float, count: int) -> MultiMeshInstance3D:
	var holder := MultiMeshInstance3D.new()
	var multi := MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.use_colors = true
	var sphere := SphereMesh.new()
	sphere.radius = radius
	sphere.height = radius * 2.0
	sphere.radial_segments = 8
	sphere.rings = 4
	multi.mesh = sphere
	multi.instance_count = count
	multi.visible_instance_count = 0
	holder.multimesh = multi
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.vertex_color_use_as_albedo = true
	holder.material_override = material
	parent.add_child(holder)
	return holder


static func flow_particles(holder: MultiMeshInstance3D, points: Array, color: Color, time: float, speed: float, direction: float) -> void:
	var multi := holder.multimesh
	if direction == 0.0 or points.size() < 2:
		multi.visible_instance_count = 0
		return
	var length := path_length(points)
	var count := multi.instance_count
	multi.visible_instance_count = count
	for i in count:
		var t := fposmod(float(i) / count + time * 0.35 * direction * speed, 1.0)
		var fade := sin(t * PI)
		multi.set_instance_transform(i, Transform3D(Basis.from_scale(Vector3.ONE * (0.6 + 0.8 * fade)), point_on_path(points, t * length)))
		multi.set_instance_color(i, Color(color, 0.95))
