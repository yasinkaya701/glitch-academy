extends Control
## Deney tezgâhı tabanı: gerçek 3B laboratuvar (LabStage3D), önde kontrol konsolu (döner düğmeler, basma düğmeleri),
## arkada cihaz ekranı. Alt sınıf `_build_set()` ile kendi nesnelerini koyar, `_draw_screen()` ile ekranı çizer.

const Stage = preload("res://scripts/physics/lab_stage_3d.gd")
const Knob = preload("res://scripts/physics/knob_3d.gd")
const PushButton = preload("res://scripts/physics/button_3d.gd")
const Screen = preload("res://scripts/physics/screen_3d.gd")
const FONT = preload("res://assets/fonts/IBMPlexSans-SemiBold.ttf")
const FONT_REGULAR = preload("res://assets/fonts/IBMPlexSans-Regular.ttf")

const CONSOLE_Z := 0.92
const SLOT := 0.38
const BASE_FOV := 32.0

var stage: Stage
var screen: Screen
var repaired := false               ## onarım sonrası sahne ışığı kalıcı olarak sıcaklaşır
var _repair_t := -1.0
var _controls: Array[Node3D] = []
var _accent := Color("#f2a65a")


## Alt sınıflar geçersiz kılar.
func _build_set() -> void:
	pass


func _draw_screen(_canvas: Control, _size: Vector2) -> void:
	pass


func _camera_position() -> Vector3:
	return Vector3(0.0, 0.72, 2.75)


func _camera_target() -> Vector3:
	return Vector3(0.0, 0.3, 0.0)


func _screen_transform() -> Transform3D:
	return Transform3D(Basis(), Vector3(0.0, 0.72, -0.8))


func _screen_size() -> Vector2:
	return Vector2(1.7, 0.96)


func _ready() -> void:
	stage = Stage.new()
	stage.setup(_accent, 32.0, _camera_position(), _camera_target())
	stage.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(stage)
	_build_console()
	screen = Screen.new()
	stage.world.add_child(screen)
	screen.setup(Vector2i(1280, int(1280.0 * _screen_size().y / _screen_size().x)), _screen_size(), _draw_screen)
	screen.transform = _screen_transform()
	_build_set()


func _build_console() -> void:
	var plate := Stage.pbr_ph("metal_plate", Vector3(1.5, 1.5, 1.5), Color(0.55, 0.57, 0.62), 1.0)
	stage.box(Vector3(2.6, 0.05, 0.66), plate, Vector3(0, -0.03, CONSOLE_Z))
	var face := StandardMaterial3D.new()
	face.albedo_color = Color("#181c22")
	face.roughness = 0.7
	stage.box(Vector3(2.3, 0.004, 0.54), face, Vector3(0, -0.003, CONSOLE_Z))


func play_repair() -> void:
	repaired = true
	_repair_t = 0.0


## Alt sınıf dar kutuda sahneyi bu kadar aşağı indirir (üstteki yönerge ve Bilgi düğmesi cihaz ekranını örtmesin).
func _narrow_shift() -> float:
	return 0.0


## 16:9'dan dar kutuda (900×600 gibi) sahne iki yandan kesilmesin: görüş genişliği sabit tutulur.
func _fit_camera() -> void:
	if stage == null or stage.camera == null or stage.size.y < 1.0:
		return
	var wide := stage.size.x / stage.size.y >= 16.0 / 9.0
	var compact := stage.size.x < 760.0
	var camera := stage.camera
	camera.look_at_from_position(_camera_position(), _camera_target() + Vector3(0.0, _narrow_shift() if compact else 0.0, 0.0))
	camera.keep_aspect = Camera3D.KEEP_HEIGHT if wide else Camera3D.KEEP_WIDTH
	camera.fov = BASE_FOV if wide else rad_to_deg(2.0 * atan(tan(deg_to_rad(BASE_FOV * 0.5)) * 16.0 / 9.0))


func _process(delta: float) -> void:
	_fit_camera()
	if screen != null:
		screen.refresh()
	if _repair_t >= 0.0 and stage != null:
		_repair_t += delta
		var k := clampf(1.0 - _repair_t / 1.8, 0.0, 1.0)
		stage.key_light.light_color = Color("#ffe6c4").lerp(Color("#ffb060"), k)
		stage.key_light.light_energy = 0.9 + 1.2 * k * k
		if _repair_t > 1.8:
			_repair_t = -1.0


func add_knob(title: String, low: float, high: float, value: float, step_size: float, callback: Callable) -> Knob:
	var unit := ""
	var name_text := title
	var open := title.find("(")
	if open > 0 and title.ends_with(")"):
		name_text = title.substr(0, open).strip_edges()
		unit = title.substr(open + 1, title.length() - open - 2)
	var knob := Knob.new()
	stage.world.add_child(knob)
	knob.setup(stage, name_text, low, high, value, step_size, unit)
	knob.changed.connect(callback)
	knob.scale = Vector3.ONE * 1.25
	_controls.append(knob)
	_layout_controls()
	return knob


func add_button(title: String, callback: Callable, toggle: bool = false) -> PushButton:
	var button := PushButton.new()
	stage.world.add_child(button)
	button.setup(title, _accent, toggle)
	if toggle:
		button.toggled.connect(callback)
	else:
		button.pressed.connect(callback)
	button.scale = Vector3.ONE * 1.25
	_controls.append(button)
	_layout_controls()
	return button


func clear_controls() -> void:
	for control in _controls:
		control.queue_free()
	_controls.clear()


func _layout_controls() -> void:
	var count := _controls.size()
	var slot := minf(SLOT, 2.3 / float(maxi(count, 1)))
	for i in count:
		var control := _controls[i]
		control.position = Vector3((float(i) - float(count - 1) * 0.5) * slot, 0.0, CONSOLE_Z - 0.05)
