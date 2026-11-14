extends RefCounted
## Anatomi motoru için ortak yardımcılar: sınır kutusu, boru meshi, yol üzerinde nokta, Bezier.

const ERYTHROCYTE = preload("res://stations/heart/assets/segmented/blood/red_blood_cell.glb")


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
static func tube_mesh(points: PackedVector3Array, color: Color, radius: float, material: Material = null, start_scale: float = 1.0, end_scale: float = 1.0) -> MeshInstance3D:
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var indices := PackedInt32Array()
	var uvs := PackedVector2Array()
	var sides := 14
	var total := maxf(path_length(Array(points)), 0.0001)
	var walked := 0.0
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
		if i > 0:
			walked += points[i].distance_to(points[i - 1])
		var progress := walked / total
		var taper_length := 0.18
		var radius_scale := 1.0
		if progress < taper_length:
			radius_scale = lerpf(start_scale, 1.0, smoothstep(0.0, taper_length, progress))
		elif progress > 1.0 - taper_length:
			radius_scale = lerpf(1.0, end_scale, smoothstep(1.0 - taper_length, 1.0, progress))
		for j in sides:
			var angle := TAU * float(j) / float(sides)
			var normal := side * cos(angle) + up * sin(angle)
			vertices.append(points[i] + normal * radius * radius_scale)
			normals.append(normal)
			uvs.append(Vector2(walked / total, float(j) / float(sides)))
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
	arrays[Mesh.ARRAY_TEX_UV] = uvs
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
	var asset := ERYTHROCYTE.instantiate()
	var cell_mesh := _first_mesh(asset)
	multi.mesh = cell_mesh
	asset.free()
	multi.instance_count = count
	multi.visible_instance_count = 0
	holder.multimesh = multi
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.roughness = 0.28
	material.clearcoat_enabled = true
	material.clearcoat = 0.32
	material.clearcoat_roughness = 0.16
	holder.material_override = material
	holder.set_meta("particle_radius", radius)
	parent.add_child(holder)
	return holder


static func _first_mesh(node: Node) -> Mesh:
	if node is MeshInstance3D:
		return (node as MeshInstance3D).mesh
	for child in node.get_children():
		var found := _first_mesh(child)
		if found != null:
			return found
	return null


static func flow_particles(holder: MultiMeshInstance3D, points: Array, color: Color, time: float, speed: float, direction: float) -> void:
	var multi := holder.multimesh
	if direction == 0.0 or points.size() < 2:
		multi.visible_instance_count = 0
		return
	var length := path_length(points)
	var count := multi.instance_count
	multi.visible_instance_count = count
	var radius: float = holder.get_meta("particle_radius", 0.001)
	for i in count:
		var t := fposmod(float(i) / count + time * 0.35 * direction * speed, 1.0)
		var fade := sin(t * PI)
		var tangent := _tangent_on_path(points, t * length)
		var orientation := Basis(Quaternion(Vector3.BACK, tangent))
		var scale := radius * (0.72 + 0.32 * fade)
		multi.set_instance_transform(i, Transform3D(orientation * Basis.from_scale(Vector3.ONE * scale), point_on_path(points, t * length)))
		multi.set_instance_color(i, Color(color, 0.95))


## Debiye bağlı akış: `phase` yol üzerinde biriken konumdur (işaretli debiyle artar, geri akışta azalır).
## `density` 0–1 görünen parçacık oranı. Debi sıfıra inince parçacıklar yok olur, hız ani sıçramaz.
static func flow_dots(holder: MultiMeshInstance3D, points: Array, color: Color, phase: float, density: float) -> void:
	var multi := holder.multimesh
	var count := multi.instance_count
	var shown := int(round(float(count) * clampf(density, 0.0, 1.0)))
	if shown == 0 or points.size() < 2:
		multi.visible_instance_count = 0
		return
	multi.visible_instance_count = shown
	var length := path_length(points)
	var radius: float = holder.get_meta("particle_radius", 0.001)
	for i in shown:
		var t := fposmod(float(i) / float(count) + phase, 1.0)
		var fade := sin(t * PI)
		var tangent := _tangent_on_path(points, t * length)
		var orientation := Basis(Quaternion(Vector3.BACK, tangent))
		var scale := radius * (0.72 + 0.32 * fade)
		multi.set_instance_transform(i, Transform3D(orientation * Basis.from_scale(Vector3.ONE * scale), point_on_path(points, t * length)))
		multi.set_instance_color(i, Color(color, 0.95))


static func _tangent_on_path(points: Array, distance: float) -> Vector3:
	var remaining := distance
	for i in points.size() - 1:
		var segment: Vector3 = points[i + 1] - points[i]
		var segment_length := segment.length()
		if remaining <= segment_length:
			return segment.normalized()
		remaining -= segment_length
	return (points[points.size() - 1] - points[points.size() - 2]).normalized()
