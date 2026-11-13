extends RefCounted
class_name ThreeBodyModel

const GRAVITATIONAL_SCALE := 1.0
const TIME_STEP := 0.0025
const STEP_COUNT := 3200
const SOFTENING := 0.09


static func simulate(initial_velocity_delta: float) -> Array[PackedVector2Array]:
	var positions := [Vector2(-1.0, 0.0), Vector2(1.0, 0.0), Vector2(0.0, 1.0)]
	var velocities := [Vector2(0.0, 0.34 + initial_velocity_delta), Vector2(0.0, -0.34), Vector2(0.24, 0.0)]
	var paths: Array[PackedVector2Array] = [PackedVector2Array(), PackedVector2Array(), PackedVector2Array()]
	for step in STEP_COUNT:
		var accelerations := _accelerations(positions)
		for body_index in 3:
			velocities[body_index] += accelerations[body_index] * TIME_STEP
			positions[body_index] += velocities[body_index] * TIME_STEP
		if step % 4 == 0:
			for body_index in 3:
				paths[body_index].append(positions[body_index])
	return paths


static func _accelerations(positions: Array) -> Array[Vector2]:
	var result: Array[Vector2] = [Vector2.ZERO, Vector2.ZERO, Vector2.ZERO]
	for body_index in 3:
		for other_index in 3:
			if body_index == other_index:
				continue
			var displacement: Vector2 = positions[other_index] - positions[body_index]
			var softened_distance_squared: float = displacement.length_squared() + SOFTENING * SOFTENING
			result[body_index] += GRAVITATIONAL_SCALE * displacement / pow(softened_distance_squared, 1.5)
	return result
