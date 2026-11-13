extends "res://scripts/physics/experiment_mission.gd"
## Adjustable one dimensional collision bench. Collision outcomes come from collision_sim.gd.

const Stage = preload("res://stations/collision/collision_stage.gd")
const Collision = preload("res://stations/collision/collision_sim.gd")

var mass_a := 1.0
var speed_a := 2.0
var mass_b := 2.0
var speed_b := -1.0
var mode := 1 # 0: elastic, 1: inelastic
var collision_running := false
var has_result := false
var mass_a_value: Label
var speed_a_value: Label
var mass_b_value: Label
var speed_b_value: Label


func _make_stage() -> Control:
	return Stage.new()


func _begin() -> void:
	step_total = 1
	screen(1, "ÇARPIŞMA LABORATUVARI", "Kütleyi, yönü ve çarpışma türünü ayarla.", "Çarpıştır", "Pozitif hız sağa, negatif hız sola. Ray üzerindeki yay temas anını gösterir.")
	var view := _stage()
	view.set_conditions(mass_a, speed_a, mass_b, speed_b, Collision.momentum(mass_a, speed_a, mass_b, speed_b))
	mass_a_value = Label.new()
	speed_a_value = Label.new()
	mass_b_value = Label.new()
	speed_b_value = Label.new()
	_add_control("A kütle", 0.5, 5.0, mass_a, 0.1, _on_mass_a, mass_a_value)
	_add_control("A hız", -4.0, 4.0, speed_a, 0.1, _on_speed_a, speed_a_value)
	_add_control("B kütle", 0.5, 5.0, mass_b, 0.1, _on_mass_b, mass_b_value)
	_add_control("B hız", -4.0, 4.0, speed_b, 0.1, _on_speed_b, speed_b_value)
	var mode_button := Button.new()
	mode_button.text = "Tür: Yapışmalı"
	mode_button.tooltip_text = "Esnek ve yapışmalı çarpışma arasında geçiş yap"
	mode_button.pressed.connect(_toggle_mode.bind(mode_button))
	tools.add_child(mode_button)
	add_power("⟲  Sıfırla", "Arabaları başlangıç konumuna al", _reset)
	_refresh()


func _stage() -> Stage:
	return stage as Stage


func _add_control(title: String, low: float, high: float, value: float, increment: float, callback: Callable, value_label: Label) -> void:
	var group := VBoxContainer.new()
	group.custom_minimum_size.x = 145
	group.add_theme_constant_override("separation", 1)
	var row := HBoxContainer.new()
	var name := Label.new()
	name.text = title
	name.add_theme_font_size_override("font_size", 12)
	name.add_theme_color_override("font_color", Color("#8fa6b3"))
	row.add_child(name)
	value_label.add_theme_font_size_override("font_size", 12)
	value_label.add_theme_color_override("font_color", Color("#6fe3c1"))
	row.add_child(value_label)
	group.add_child(row)
	var slider := HSlider.new()
	slider.min_value = low
	slider.max_value = high
	slider.step = increment
	slider.value = value
	slider.custom_minimum_size = Vector2(135, 18)
	slider.value_changed.connect(callback)
	group.add_child(slider)
	tools.add_child(group)
	_set_value_label(value_label, value)


func _set_value_label(target: Label, value: float) -> void:
	target.text = ("%+.1f" % value).replace(".", ",") if value < 0.0 else ("%.1f" % value).replace(".", ",")


func _on_mass_a(value: float) -> void:
	mass_a = value
	mass_a_value.text = "%.1f kg" % value
	_refresh()


func _on_speed_a(value: float) -> void:
	speed_a = value
	speed_a_value.text = ("%+.1f" % value).replace(".", ",") + " m/s"
	_refresh()


func _on_mass_b(value: float) -> void:
	mass_b = value
	mass_b_value.text = "%.1f kg" % value
	_refresh()


func _on_speed_b(value: float) -> void:
	speed_b = value
	speed_b_value.text = ("%+.1f" % value).replace(".", ",") + " m/s"
	_refresh()


func _toggle_mode(button: Button) -> void:
	mode = 1 - mode
	button.text = "Tür: Esnek" if mode == 0 else "Tür: Yapışmalı"
	_refresh()


func _refresh() -> void:
	if mass_a_value != null:
		mass_a_value.text = "%.1f kg" % mass_a
	if speed_a_value != null:
		speed_a_value.text = ("%+.1f" % speed_a).replace(".", ",") + " m/s"
	if mass_b_value != null:
		mass_b_value.text = "%.1f kg" % mass_b
	if speed_b_value != null:
		speed_b_value.text = ("%+.1f" % speed_b).replace(".", ",") + " m/s"
	if stage != null:
		if has_result:
			_stage().reset_stage()
			has_result = false
		_stage().set_conditions(mass_a, speed_a, mass_b, speed_b, Collision.momentum(mass_a, speed_a, mass_b, speed_b))


func _on_action() -> void:
	if collision_running:
		return
	if has_result:
		_stage().reset_stage()
		has_result = false
	collision_running = true
	tools.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var momentum_before: float = Collision.momentum(mass_a, speed_a, mass_b, speed_b)
	var after: Vector2
	var stuck := mode == 1
	if stuck:
		var shared_speed: float = Collision.stick_speed(mass_a, speed_a, mass_b, speed_b)
		after = Vector2(shared_speed, shared_speed)
	else:
		after = Collision.elastic(mass_a, speed_a, mass_b, speed_b)
	hud.set_action("Çarpışıyor…", false)
	await _stage().play_collision(after.x, after.y, stuck)
	_stage().set_result(after.x, after.y, momentum_before, stuck)
	collision_running = false
	has_result = true
	tools.mouse_filter = Control.MOUSE_FILTER_STOP
	hud.set_action("Yeniden dene", true)
	say("Birleşik momentum: %s kg·m/s" % _fmt(momentum_before), GOOD)


func _reset() -> void:
	if collision_running:
		return
	_stage().reset_stage()
	has_result = false
	tools.mouse_filter = Control.MOUSE_FILTER_STOP
	_refresh()
	hud.set_action("Çarpıştır", true)


func _fmt(value: float) -> String:
	return ("%.2f" % value).replace(".", ",")
