extends Control
## Çok kanallı dalga monitörü (EKG, basınç). SubViewport içinde çizilir, 3B quad'a doku olur.
## Kanallar: {name, color, min, max, samples: PackedFloat32Array}. Pencere saniye cinsinden.

var channels: Array[Dictionary] = []
var window := 6.0
var title_left := ""
var _clock := 0.0
const BG := Color("#03090e")
const GRID := Color("#0f2a33")


func add_channel(channel_name: String, color: Color, min_value: float, max_value: float) -> int:
	channels.append({"name": channel_name, "color": color, "min": min_value, "max": max_value, "t": PackedFloat32Array(), "v": PackedFloat32Array()})
	return channels.size() - 1


func push(index: int, time_s: float, value: float) -> void:
	_clock = maxf(_clock, time_s)
	var channel: Dictionary = channels[index]
	var t: PackedFloat32Array = channel["t"]
	var v: PackedFloat32Array = channel["v"]
	t.append(time_s)
	v.append(value)
	while t.size() > 0 and t[0] < time_s - window:
		t.remove_at(0)
		v.remove_at(0)
	channel["t"] = t
	channel["v"] = v


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), BG)
	var count := channels.size()
	if count == 0:
		return
	var lane_height := (size.y - 24.0) / float(count)
	for i in 21:
		var x := 10.0 + (size.x - 20.0) * float(i) / 20.0
		draw_line(Vector2(x, 8), Vector2(x, size.y - 8), GRID, 1.0)
	for index in count:
		var channel: Dictionary = channels[index]
		var top := 12.0 + lane_height * index
		var rect := Rect2(10.0, top, size.x - 20.0, lane_height - 10.0)
		draw_rect(rect, Color("#051118"))
		draw_line(Vector2(rect.position.x, rect.end.y), Vector2(rect.end.x, rect.end.y), GRID, 1.0)
		var color: Color = channel["color"]
		var t: PackedFloat32Array = channel["t"]
		var v: PackedFloat32Array = channel["v"]
		var points := PackedVector2Array()
		for k in t.size():
			var x := rect.position.x + rect.size.x * (t[k] - (_clock - window)) / window
			var norm := clampf((v[k] - float(channel["min"])) / (float(channel["max"]) - float(channel["min"])), 0.0, 1.0)
			points.append(Vector2(x, rect.end.y - 6.0 - (rect.size.y - 12.0) * norm))
		if points.size() > 1:
			draw_polyline(points, Color(color, 0.22), 7.0, true)
			draw_polyline(points, color, 2.6, true)
		draw_string(ThemeDB.fallback_font, Vector2(rect.position.x + 8, rect.position.y + 22), String(channel["name"]), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 17, color)
