extends Node3D
## Serbest 3B kamera: hedef etrafında dönme, yakınlaşma ve bir noktaya odaklanma (yumuşak geçişli).

var camera: Camera3D
var target := Vector3.ZERO
var yaw := 0.0
var pitch := 0.0
var distance := 0.5
var min_distance := 0.06
var max_distance := 7.0

var _goal_target := Vector3.ZERO
var _goal_yaw := 0.0
var _goal_pitch := 0.0
var _goal_distance := 0.5


func _ready() -> void:
	camera = Camera3D.new()
	camera.fov = 38.0
	camera.near = 0.01
	camera.far = 12.0
	add_child(camera)
	_goal_target = target
	_goal_yaw = yaw
	_goal_pitch = pitch
	_goal_distance = distance
	_apply()


func _process(delta: float) -> void:
	var k := 1.0 - exp(-delta * 9.0)
	target = target.lerp(_goal_target, k)
	yaw = lerp_angle(yaw, _goal_yaw, k)
	pitch = lerpf(pitch, _goal_pitch, k)
	distance = lerpf(distance, _goal_distance, k)
	_apply()


func _apply() -> void:
	var basis_yaw := Basis(Vector3.UP, yaw)
	var basis_pitch := Basis(Vector3.RIGHT, pitch)
	var offset := (basis_yaw * basis_pitch) * Vector3(0, 0, distance)
	camera.global_position = target + offset
	camera.look_at(target, Vector3.UP)


func orbit(relative: Vector2) -> void:
	_goal_yaw -= relative.x * 0.006
	_goal_pitch = clampf(_goal_pitch - relative.y * 0.005, -1.35, 1.35)


func zoom(factor: float) -> void:
	_goal_distance = clampf(_goal_distance * factor, min_distance, max_distance)


func focus(new_target: Vector3, new_distance: float, new_yaw: float = NAN, new_pitch: float = NAN) -> void:
	_goal_target = new_target
	_goal_distance = clampf(new_distance, min_distance, max_distance)
	if not is_nan(new_yaw):
		_goal_yaw = new_yaw
	if not is_nan(new_pitch):
		_goal_pitch = new_pitch


## Ekran noktasından dünya ışını: [başlangıç, yön].
func ray(screen_position: Vector2) -> Array:
	return [camera.project_ray_origin(screen_position), camera.project_ray_normal(screen_position)]
