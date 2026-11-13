extends Control

signal finished
signal alarm_changed(strength: float)

const DURATION := 8.0
const CUE_STARTS := [0.0, 1.8, 4.2, 6.3, DURATION]
const HEADLINES := [
	"Ölçüm tutarlıydı.",
	"MERİDYEN: “Önemsiz bir sapma.”",
	"Kalibratör, ölç ve zamanı geri sar.",
	"İlk sinyal: Mevsim Gözlemevi.",
]
const CAPTIONS := [
	"Dünya'nın yasaları yerinde duruyordu.",
	"Yapay zekâ, küçük kaymalarla dünya dengesini bozdu.",
	"Zaman Makinesi kaymanın başladığı ana dönüyor.",
	"Sapma sürüyor. Onarım senden bekleniyor.",
]
const ACCENT_NORMAL := Color("#87cfc4")
const ACCENT_ALARM := Color("#e5645a")
const CUE_TOP := -210.0
const CUE_BOTTOM := -67.0
const MERIDYEN_TEXTURE := preload("res://assets/characters/meridyen/meridyen_ai_concept.png")
const CINEMATIC_BACKDROP := preload("res://assets/intro/meridyen_opening_backdrop.png")

@onready var cue: VBoxContainer = %Cue
@onready var headline: Label = %Headline
@onready var caption: Label = %Caption
@onready var location: Label = %Location
@onready var trace: Label = %Trace
@onready var progress: ProgressBar = %Progress
@onready var skip: Button = %Skip

var meridyen: TextureRect
var elapsed := 0.0
var cue_index := -1
var started := false
var playing := false


func _ready() -> void:
	_build_meridyen()
	location.text = "YANLIŞ DÜNYA  /  AÇILIŞ"
	trace.hide()
	hide()
	set_process(false)
	set_process_input(false)
	skip.pressed.connect(_finish)


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and is_instance_valid(meridyen):
		_layout_meridyen()


func start() -> void:
	if started:
		return
	started = true
	playing = true
	elapsed = 0.0
	show()
	_layout_meridyen()
	_update_frame()
	set_process(true)
	set_process_input(true)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_finish()


func _process(delta: float) -> void:
	elapsed += delta
	if elapsed >= DURATION:
		_finish()
		return
	_update_frame()
	_update_meridyen()
	queue_redraw()


func _update_frame() -> void:
	modulate.a = smoothstep(0.0, 0.42, elapsed) * (1.0 - smoothstep(7.72, DURATION, elapsed))
	var next_cue := 0
	for index in range(1, HEADLINES.size()):
		if elapsed >= CUE_STARTS[index]:
			next_cue = index
	if next_cue != cue_index:
		cue_index = next_cue
		headline.text = HEADLINES[cue_index]
		caption.text = CAPTIONS[cue_index]
		headline.add_theme_font_size_override("font_size", 36)
	var cue_start: float = CUE_STARTS[cue_index]
	var cue_end: float = CUE_STARTS[cue_index + 1]
	var fade_in := smoothstep(cue_start, cue_start + 0.42, elapsed)
	var fade_out := 1.0 - smoothstep(cue_end - 0.32, cue_end, elapsed)
	var cue_alpha: float = fade_in * fade_out
	cue.modulate.a = cue_alpha
	var rise := (1.0 - fade_in) * 9.0
	cue.offset_top = CUE_TOP + rise
	cue.offset_bottom = CUE_BOTTOM + rise
	var alarm := smoothstep(1.75, 2.45, elapsed) * (1.0 - smoothstep(4.15, 5.7, elapsed))
	var alarm_color := ACCENT_NORMAL.lerp(ACCENT_ALARM, alarm)
	location.add_theme_color_override("font_color", alarm_color)
	progress.value = elapsed / DURATION
	alarm_changed.emit(alarm)


func _build_meridyen() -> void:
	meridyen = TextureRect.new()
	meridyen.name = "MeridyenIntrusion"
	meridyen.texture = MERIDYEN_TEXTURE
	meridyen.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	meridyen.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	meridyen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	meridyen.pivot_offset = Vector2(210, 210)
	meridyen.z_index = 2
	meridyen.modulate.a = 0.0
	add_child(meridyen)
	_layout_meridyen()


func _layout_meridyen() -> void:
	var height := clampf(size.y * 0.50, 220.0, 500.0)
	var width := height * 1.094
	meridyen.size = Vector2(width, height)
	meridyen.pivot_offset = meridyen.size * 0.5
	var center := Vector2(size.x * 0.73, size.y * 0.50)
	meridyen.position = center - meridyen.size * 0.5


func _update_meridyen() -> void:
	var enter := smoothstep(1.82, 2.24, elapsed)
	var fade := 1.0 - smoothstep(7.05, 7.45, elapsed)
	var visibility := enter * fade
	var glitch := (1.0 - smoothstep(2.2, 2.75, elapsed)) * enter
	var drift := sin(elapsed * 1.1) * 0.012
	var shake := sin(elapsed * 83.0) * 0.028 * glitch
	meridyen.modulate = Color(1.0, lerpf(0.55, 1.0, 1.0 - glitch), lerpf(0.48, 1.0, 1.0 - glitch), visibility)
	meridyen.rotation = lerpf(deg_to_rad(-13.0), 0.0, enter) + drift + shake
	meridyen.scale = Vector2.ONE * lerpf(0.70, 1.0 + sin(elapsed * 1.35) * 0.012, enter)
	var center := Vector2(size.x * 0.73, size.y * 0.50)
	var entry_offset := Vector2(size.x * 0.14, -size.y * 0.07) * (1.0 - enter)
	meridyen.position = center - meridyen.size * 0.5 + entry_offset + Vector2(shake * 58.0, sin(elapsed * 0.9) * 4.0 * visibility)


func _draw() -> void:
	var h := size.y
	if h <= 0.0:
		return
	var texture_size := CINEMATIC_BACKDROP.get_size()
	var cover_scale := maxf(size.x / texture_size.x, size.y / texture_size.y)
	var background_size := texture_size * cover_scale
	var camera_shift := Vector2(sin(elapsed * 0.18) * h * 0.008, cos(elapsed * 0.14) * h * 0.003)
	var impact := 1.0 - smoothstep(2.12, 2.55, elapsed)
	camera_shift += Vector2(sin(elapsed * 73.0) * h * 0.004, sin(elapsed * 61.0) * h * 0.002) * impact
	draw_texture_rect(CINEMATIC_BACKDROP, Rect2((size - background_size) * 0.5 + camera_shift, background_size), false)
	draw_rect(Rect2(Vector2.ZERO, size), Color("#070b12", 0.10), true)
	var center := Vector2(size.x * 0.73, size.y * 0.50)
	var radius_x := minf(h * 0.25, size.x * 0.29)
	var radius_y := h * 0.22
	var disturbance := smoothstep(1.8, 2.4, elapsed)
	var fault := disturbance * (1.0 - 0.45 * smoothstep(6.4, 7.7, elapsed))
	_draw_orbit(center, radius_x, radius_y, 0.0, Color("#6fe3c1", 0.36))
	_draw_orbit(center, radius_x, radius_y, deg_to_rad(11.0) * fault, Color("#e5645a", 0.68 * fault))
	_draw_tear(center, radius_x, radius_y, fault)
	_draw_time_rewind(center, maxf(radius_x, radius_y) * 1.10, elapsed)


func _draw_orbit(center: Vector2, rx: float, ry: float, angle: float, color: Color) -> void:
	var points := PackedVector2Array()
	for index in range(97):
		var theta := TAU * float(index) / 96.0
		var point := Vector2(cos(theta) * rx, sin(theta) * ry).rotated(angle)
		points.append(center + point)
	draw_polyline(points, color, 2.0, true)


func _draw_tear(center: Vector2, rx: float, ry: float, fault: float) -> void:
	if fault <= 0.01:
		return
	var pulse := 0.72 + 0.28 * sin(elapsed * 17.0)
	var start := center + Vector2(-rx * 0.30, -ry * 0.53)
	var points := PackedVector2Array()
	for index in range(9):
		var t := float(index) / 8.0
		var jitter := sin(elapsed * 51.0 + float(index) * 2.7) * 5.0 * fault
		points.append(start + Vector2(rx * 0.68 * t, ry * 1.25 * t + jitter))
	draw_polyline(points, Color("#6fe3c1", 0.62 * pulse * fault), 2.0, true)
	var offset_points := PackedVector2Array()
	for point in points:
		offset_points.append(point + Vector2(4.0, -1.5))
	draw_polyline(offset_points, Color("#e5645a", 0.82 * pulse * fault), 1.6, true)


func _draw_time_rewind(center: Vector2, radius: float, time: float) -> void:
	var appear := smoothstep(4.15, 4.75, time)
	if appear <= 0.01:
		return
	var sweep := TAU * 0.88 * smoothstep(4.2, 6.15, time)
	var points := PackedVector2Array()
	for index in range(49):
		var t := float(index) / 48.0
		var angle := -PI * 0.5 - sweep * t
		points.append(center + Vector2(cos(angle) * radius, sin(angle) * radius))
	draw_polyline(points, Color("#6fe3c1", 0.82 * appear), 3.0, true)
	var tip_angle := -PI * 0.5 - sweep
	var tip := center + Vector2(cos(tip_angle), sin(tip_angle)) * radius
	var tangent := Vector2(sin(tip_angle), -cos(tip_angle))
	var arrow_back := -tangent * 12.0
	var arrow_side := Vector2(-arrow_back.y, arrow_back.x).normalized() * 6.0
	draw_colored_polygon(PackedVector2Array([tip, tip + arrow_back + arrow_side, tip + arrow_back - arrow_side]), Color("#6fe3c1", 0.9 * appear))


func _finish() -> void:
	if not playing:
		return
	playing = false
	set_process(false)
	set_process_input(false)
	hide()
	alarm_changed.emit(0.0)
	finished.emit()
