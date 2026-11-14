extends RefCounted
class_name ThreeBodyModel
## Boyutsuz üç cisim modeli (G = 1) ve iki cisim için Kepler'in üçüncü yasası.
## Çizim bu dosyaya bağlı değildir; Üç Güneş görevi yalnız buradan okur ve headless test edilebilir.

const GRAVITATIONAL_SCALE := 1.0
const TIME_STEP := 0.0025
const STEP_COUNT := 3200
const SAMPLE_EVERY := 4
const SOFTENING := 0.09
## İki iz arasındaki en büyük mesafe bu değeri aşınca izler "ayrıldı" sayılır.
const SEPARATION_EPSILON := 0.1


## Üç eşit kütleli cismin izlerini döndürür. Birinci cismin ilk hızına `initial_velocity_delta` eklenir.
static func simulate(initial_velocity_delta: float) -> Array[PackedVector2Array]:
	var positions := [Vector2(-1.0, 0.0), Vector2(1.0, 0.0), Vector2(0.0, 1.0)]
	var velocities := [Vector2(0.0, 0.34 + initial_velocity_delta), Vector2(0.0, -0.34), Vector2(0.24, 0.0)]
	var paths: Array[PackedVector2Array] = [PackedVector2Array(), PackedVector2Array(), PackedVector2Array()]
	for step in STEP_COUNT:
		var accelerations := _accelerations(positions)
		for body_index in 3:
			velocities[body_index] += accelerations[body_index] * TIME_STEP
			positions[body_index] += velocities[body_index] * TIME_STEP
		if step % SAMPLE_EVERY == 0:
			for body_index in 3:
				paths[body_index].append(positions[body_index])
	return paths


static func sample_time(sample_index: int) -> float:
	return sample_index * SAMPLE_EVERY * TIME_STEP


static func duration() -> float:
	return STEP_COUNT * TIME_STEP


## Aynı anda iki iz arasındaki en büyük cisim mesafesi.
static func separation_at(a: Array[PackedVector2Array], b: Array[PackedVector2Array], sample_index: int) -> float:
	var largest := 0.0
	for body_index in mini(a.size(), b.size()):
		var last := mini(sample_index, mini(a[body_index].size(), b[body_index].size()) - 1)
		if last < 0:
			continue
		largest = maxf(largest, a[body_index][last].distance_to(b[body_index][last]))
	return largest


## İzlerin ilk kez `epsilon` kadar ayrıldığı süre. Hiç ayrılmazsa -1.
static func separation_time(a: Array[PackedVector2Array], b: Array[PackedVector2Array], epsilon: float = SEPARATION_EPSILON) -> float:
	var samples := 0
	for path in a:
		samples = maxi(samples, path.size())
	for index in samples:
		if separation_at(a, b, index) > epsilon:
			return sample_time(index)
	return -1.0


## Kepler'in üçüncü yasası: T² ∝ a³. a = 1 yörüngesinin dönemi T₀ = 1 alınır.
static func kepler_period(semi_major_axis: float) -> float:
	return pow(semi_major_axis, 1.5)


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
