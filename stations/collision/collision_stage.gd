extends Control
## Asset-driven side view for the collision experiment. The rule lives in collision_sim.gd.

signal collision_finished(final_state: Dictionary)

const BG := preload("res://stations/collision/assets/track_bg.png")
const CART_A := preload("res://stations/collision/assets/cart_a.png")
const CART_B := preload("res://stations/collision/assets/cart_b.png")
const CART_STUCK := preload("res://stations/collision/assets/cart_stuck.png")
const SPRING := preload("res://stations/collision/assets/bumper_spring.png")

const VIEW_SIZE := Vector2(1280, 720)
const TRACK_Y := 431.0
const START_A := 350.0
const START_B := 930.0
const CONTACT_A := 554.0
const CONTACT_B := 726.0

var cart_a: TextureRect
var cart_b: TextureRect
var stuck_pair: TextureRect
var spring: TextureRect
var headline: Label
var readout: Label
var momentum_label: Label
var momentum_panel: PanelContainer
var running := false
var _fit_scale := 1.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(_layout)
	_build_stage()
	_layout()


func _build_stage() -> void:
	var backdrop := TextureRect.new()
	backdrop.texture = BG
	backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backdrop.stretch_mode = TextureRect.STRETCH_SCALE
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)

	spring = _make_sprite(SPRING, Vector2(204.8, 153.6))
	spring.position = _to_view(Vector2(640, TRACK_Y)) - spring.size * 0.5
	add_child(spring)

	cart_a = _make_sprite(CART_A, Vector2(256, 128))
	cart_a.position = _to_view(Vector2(START_A, TRACK_Y)) - cart_a.size * 0.5
	add_child(cart_a)
	cart_b = _make_sprite(CART_B, Vector2(256, 128))
	cart_b.position = _to_view(Vector2(START_B, TRACK_Y)) - cart_b.size * 0.5
	add_child(cart_b)
	stuck_pair = _make_sprite(CART_STUCK, Vector2(341.3, 128))
	stuck_pair.position = _to_view(Vector2(640, TRACK_Y)) - stuck_pair.size * 0.5
	stuck_pair.hide()
	add_child(stuck_pair)

	momentum_panel = PanelContainer.new()
	momentum_panel.name = "MomentumPanel"
	momentum_panel.position = _to_view(Vector2(894, 94))
	momentum_panel.size = Vector2(342, 134) * _fit_scale
	momentum_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#0b1521", 0.84)
	style.border_color = Color("#446072", 0.68)
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	momentum_panel.add_theme_stylebox_override("panel", style)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	momentum_panel.add_child(column)
	headline = Label.new()
	headline.text = "MOMENTUM / TRACK 01"
	headline.add_theme_color_override("font_color", Color("#78dce2"))
	headline.add_theme_font_size_override("font_size", 13)
	column.add_child(headline)
	readout = Label.new()
	readout.text = "A   1,0 kg   +2,0 m/s\nB   2,0 kg   −1,0 m/s"
	readout.add_theme_color_override("font_color", Color("#e6eeef"))
	readout.add_theme_font_size_override("font_size", 17)
	column.add_child(readout)
	momentum_label = Label.new()
	momentum_label.text = "p total      0,00 kg·m/s"
	momentum_label.add_theme_color_override("font_color", Color("#f1b16d"))
	momentum_label.add_theme_font_size_override("font_size", 14)
	column.add_child(momentum_label)
	add_child(momentum_panel)


func _make_sprite(texture: Texture2D, base_size: Vector2) -> TextureRect:
	var sprite := TextureRect.new()
	sprite.texture = texture
	sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sprite.stretch_mode = TextureRect.STRETCH_SCALE
	sprite.size = base_size * _fit_scale
	sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return sprite


func _fit() -> float:
	return minf(size.x / VIEW_SIZE.x, size.y / VIEW_SIZE.y)


func _to_view(point: Vector2) -> Vector2:
	return (point - VIEW_SIZE * 0.5) * _fit_scale + size * 0.5


func _layout() -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return
	_fit_scale = _fit()
	for item in [spring, cart_a, cart_b, stuck_pair]:
		if item == null:
			continue
		var base := Vector2(256, 128)
		var center := Vector2(START_A, TRACK_Y)
		match item:
			spring:
				base = Vector2(204.8, 153.6)
				center = Vector2(640, TRACK_Y)
			cart_a:
				base = Vector2(256, 128)
				center = Vector2(START_A, TRACK_Y)
			cart_b:
				base = Vector2(256, 128)
				center = Vector2(START_B, TRACK_Y)
			stuck_pair:
				base = Vector2(341.3, 128)
				center = Vector2(640, TRACK_Y)
		item.size = base * _fit_scale
		item.position = _to_view(center) - item.size * 0.5
		item.pivot_offset = item.size * 0.5
	if momentum_panel != null:
		momentum_panel.position = _to_view(Vector2(894, 94))
		momentum_panel.size = Vector2(342, 134) * _fit_scale


func set_conditions(m1: float, v1: float, m2: float, v2: float, momentum: float) -> void:
	readout.text = "A   %s kg   %s m/s\nB   %s kg   %s m/s" % [_number(m1), _signed(v1), _number(m2), _signed(v2)]
	momentum_label.text = "p total      %s kg·m/s" % _signed(momentum, 2)


func set_result(v1: float, v2: float, momentum: float, stuck: bool) -> void:
	headline.text = "POST-IMPACT / %s" % ("LATCHED" if stuck else "ELASTIC")
	readout.text = "A   %s m/s\nB   %s m/s" % [_signed(v1), _signed(v2)]
	momentum_label.text = "p conserved   %s kg·m/s" % _signed(momentum, 2)


func play_collision(v1_after: float, v2_after: float, stuck: bool) -> void:
	if running:
		return
	running = true
	stuck_pair.hide()
	spring.show()
	cart_a.show()
	cart_b.show()
	var approach := create_tween().set_parallel(true)
	approach.tween_property(cart_a, "position:x", _to_view(Vector2(CONTACT_A, TRACK_Y)).x - cart_a.size.x * 0.5, 0.95)
	approach.tween_property(cart_b, "position:x", _to_view(Vector2(CONTACT_B, TRACK_Y)).x - cart_b.size.x * 0.5, 0.95)
	await approach.finished
	if stuck:
		spring.hide()
		cart_a.hide()
		cart_b.hide()
		stuck_pair.show()
	else:
		var travel := 185.0 * _fit_scale
		var rebound := create_tween().set_parallel(true)
		rebound.tween_property(cart_a, "position:x", cart_a.position.x + (-travel if v1_after < 0.0 else travel), 0.78)
		rebound.tween_property(cart_b, "position:x", cart_b.position.x + (-travel if v2_after < 0.0 else travel), 0.78)
		await rebound.finished
		spring.hide()
	running = false
	collision_finished.emit({"v1": v1_after, "v2": v2_after, "stuck": stuck})


func reset_stage() -> void:
	running = false
	headline.text = "MOMENTUM / TRACK 01"
	spring.show()
	stuck_pair.hide()
	cart_a.show()
	cart_b.show()
	_layout()


func _number(value: float) -> String:
	return ("%.1f" % value).replace(".", ",")


func _signed(value: float, decimals: int = 1) -> String:
	var text := ("%.*f" % [decimals, absf(value)]).replace(".", ",")
	if value > 0.0001:
		return "+" + text
	if value < -0.0001:
		return "−" + text
	return "0," + "0".repeat(decimals)
