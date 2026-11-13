extends Node
## 3B düğme ve basma düğmesini sahte fare olaylarıyla dener (pencereli çalışır).
## Pencere pikselleri ile oyun alanı (1280×720) arasındaki ölçek hesaba katılır.
## Kullanım: godot --path . tests/knob_test.tscn
var failures := 0

func _check(label: String, ok: bool) -> void:
	print("%s  %s" % ["ok " if ok else "HATA", label])
	if not ok:
		failures += 1

func _factor() -> float:
	return float(get_window().size.x) / 1280.0

func _motion(position: Vector2, relative: Vector2 = Vector2.ZERO) -> void:
	var m := InputEventMouseMotion.new()
	m.position = position * _factor()
	m.global_position = m.position
	m.relative = relative * _factor()
	m.button_mask = MOUSE_BUTTON_MASK_LEFT
	Input.parse_input_event(m)

func _button(position: Vector2, pressed: bool) -> void:
	var b := InputEventMouseButton.new()
	b.position = position * _factor()
	b.global_position = b.position
	b.button_index = MOUSE_BUTTON_LEFT
	b.pressed = pressed
	Input.parse_input_event(b)

func _ready() -> void:
	get_window().size = Vector2i(1600, 900)
	var m: Control = load("res://stations/newton/mission.tscn").instantiate()
	m.theme = get_tree().root.theme
	add_child(m)
	m.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await get_tree().create_timer(0.5).timeout
	m._on_action()
	m._on_action()
	await get_tree().create_timer(0.6).timeout
	var view = m._view()
	var knob = view._controls[0]
	var before: float = knob.value
	var at: Vector2 = view.stage.project(knob.global_position + Vector3(0, 0.06, 0))
	_motion(at)
	await get_tree().create_timer(0.2).timeout
	_check("düğmenin üstüne gelince vurgulandı", knob._hover)
	_button(at, true)
	await get_tree().create_timer(0.1).timeout
	_check("düğme sürükleme başladı", view.stage.active_drag == knob)
	_motion(at + Vector2(160, 0), Vector2(160, 0))
	await get_tree().create_timer(0.1).timeout
	_button(at + Vector2(160, 0), false)
	await get_tree().create_timer(0.1).timeout
	_check("düğme değeri arttı (%s → %s)" % [before, knob.value], knob.value > before)
	var button = view._controls[3]
	var pressed := [false]
	button.pressed.connect(func() -> void: pressed[0] = true)
	var bat: Vector2 = view.stage.project(button.global_position + Vector3(0, 0.03, 0))
	_motion(bat)
	await get_tree().create_timer(0.2).timeout
	_button(bat, true)
	await get_tree().create_timer(0.2).timeout
	_check("basma düğmesi tetiklendi", pressed[0])
	print("BAŞARISIZ: %d" % failures if failures > 0 else "HEPSİ GEÇTİ")
	get_tree().quit(failures)
