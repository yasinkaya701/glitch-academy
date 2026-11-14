extends Control
## Rota yolu: düzenekler dolambaçlı bir yol üzerinde sıralanır. Onarılanlar dolu çizgiyle bağlanır, sıradaki düzenek
## vurgulanır, kilitliler kesikli çizgiyle bekler. Durum renkle birlikte simge (✓, sayı, kilit) ve yazıyla da verilir.

signal selected(index: int)
signal activated(index: int)

const DONE := Color("#2f6b5a")
const NEXT := Color("#9a5a14")
const LOCKED := Color("#7d8782")
const INK := Color("#22332f")
const MUTED := Color("#66766d")
const ROW := 66.0
const PAD := 14.0
const RADIUS := 21.0

## Her öğe: {title, subject, state: &"done" | &"next" | &"locked", tooltip}
var items: Array[Dictionary] = []
var current := -1


func _ready() -> void:
	focus_mode = Control.FOCUS_ALL
	mouse_filter = Control.MOUSE_FILTER_STOP


func set_items(new_items: Array[Dictionary]) -> void:
	items = new_items
	custom_minimum_size.y = PAD * 2.0 + ROW * items.size()
	queue_redraw()


func select(index: int) -> void:
	current = clampi(index, -1, items.size() - 1)
	queue_redraw()
	_scroll_to_current.call_deferred()


## Seçili düzenek kaydırma alanının görünür kısmında kalsın.
func _scroll_to_current() -> void:
	var scroll := get_parent() as ScrollContainer
	if scroll == null or current < 0:
		return
	var top := PAD + ROW * current
	if top < scroll.scroll_vertical or top + ROW > scroll.scroll_vertical + scroll.size.y:
		scroll.scroll_vertical = int(top - scroll.size.y * 0.5 + ROW * 0.5)


func _node_center(index: int) -> Vector2:
	var wave := sin(float(index) * 1.25) * minf(34.0, size.x * 0.09)
	return Vector2(PAD + RADIUS + 22.0 + wave, PAD + ROW * (float(index) + 0.5))


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var index := int((event.position.y - PAD) / ROW)
		if index >= 0 and index < items.size():
			grab_focus()
			select(index)
			selected.emit(index)
			if event.double_click:
				activated.emit(index)
	elif event is InputEventKey and event.pressed and not items.is_empty():
		var step := 0
		if event.keycode == KEY_DOWN:
			step = 1
		elif event.keycode == KEY_UP:
			step = -1
		if step != 0:
			select(clampi(current + step, 0, items.size() - 1))
			selected.emit(current)
			accept_event()
		elif event.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE] and current >= 0:
			activated.emit(current)
			accept_event()


func _get_tooltip(at_position: Vector2) -> String:
	var index := int((at_position.y - PAD) / ROW)
	if index >= 0 and index < items.size():
		return String(items[index].get("tooltip", ""))
	return ""


func _draw() -> void:
	var font := get_theme_default_font()
	if items.is_empty() or font == null:
		return
	for index in items.size() - 1:
		var from := _node_center(index)
		var to := _node_center(index + 1)
		var mid_y := (from.y + to.y) * 0.5
		var points := PackedVector2Array()
		for step in 21:
			var t := float(step) / 20.0
			var a := from.lerp(Vector2(from.x, mid_y), t)
			var b := Vector2(to.x, mid_y).lerp(to, t)
			points.append(a.lerp(b, t))
		var reached: bool = items[index]["state"] == &"done"
		if reached:
			draw_polyline(points, DONE, 4.0, true)
		else:
			for step in range(0, points.size() - 1, 2):
				draw_line(points[step], points[step + 1], Color(LOCKED, 0.7), 3.0, true)
	for index in items.size():
		_draw_item(index, font)


func _draw_item(index: int, font: Font) -> void:
	var item := items[index]
	var center := _node_center(index)
	var state: StringName = item["state"]
	var color := DONE if state == &"done" else NEXT if state == &"next" else LOCKED
	if index == current:
		var row := Rect2(Vector2(4.0, PAD + ROW * index + 3.0), Vector2(size.x - 8.0, ROW - 6.0))
		var box := StyleBoxFlat.new()
		box.bg_color = Color(color, 0.1)
		box.border_color = Color(color, 0.55)
		box.set_border_width_all(1)
		box.set_corner_radius_all(10)
		draw_style_box(box, row)
	if state == &"next":
		draw_circle(center, RADIUS + 5.0, Color(NEXT, 0.16))
	draw_circle(center, RADIUS, color if state != &"locked" else Color("#eef1ee"))
	draw_arc(center, RADIUS, 0.0, TAU, 36, color, 2.5, true)
	var glyph := "✓" if state == &"done" else str(index + 1)
	var glyph_color := Color.WHITE if state != &"locked" else color
	var glyph_size := 20
	var glyph_width := font.get_string_size(glyph, HORIZONTAL_ALIGNMENT_LEFT, -1, glyph_size).x
	draw_string(font, center + Vector2(-glyph_width * 0.5, glyph_size * 0.36), glyph, HORIZONTAL_ALIGNMENT_LEFT, -1, glyph_size, glyph_color)
	var text_x := center.x + RADIUS + 16.0
	var text_width := maxf(size.x - text_x - 10.0, 40.0)
	var title_color := INK if state != &"locked" else MUTED
	draw_string(font, Vector2(text_x, center.y - 3.0), item["title"], HORIZONTAL_ALIGNMENT_LEFT, text_width, 16, title_color)
	var word := "Onarıldı" if state == &"done" else "Sıradaki" if state == &"next" else "Kilitli"
	draw_string(font, Vector2(text_x, center.y + 17.0), "%s  ·  %s" % [item["subject"], word], HORIZONTAL_ALIGNMENT_LEFT, text_width, 13, color)
	if state == &"locked":
		_draw_lock(Vector2(size.x - 26.0, center.y), color)


func _draw_lock(at: Vector2, color: Color) -> void:
	draw_rect(Rect2(at + Vector2(-7.0, -2.0), Vector2(14.0, 10.0)), color)
	draw_arc(at + Vector2(0.0, -2.0), 5.0, PI, TAU, 12, color, 2.0, true)
