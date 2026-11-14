class_name MemoryRing
extends Control
## Filozofun başının arkasındaki fikir yıldızları. Her yıldız bir ana öğedir.
## Yanmamış: içi boş ince hat. Yanmış: dolu, ışıklı. Onarılmış: yeşil ve hepsi bağlı.
## Durum renk dışında doluluk, boyut ve bağlantı çizgisiyle de okunur.

const UNLIT := Color("#41627f")
const LIT := Color("#f2a65a")
const REPAIRED := Color("#6fe3c1")

var count: int = 5:
	set(v):
		count = maxi(v, 1)
		_lit.resize(count)
		for i in count:
			if _lit[i] == null:
				_lit[i] = 0.0
		queue_redraw()
var repaired: float = 0.0
var radius: float = 300.0:
	set(v):
		radius = v
		queue_redraw()

var _lit: Array = [0.0, 0.0, 0.0, 0.0, 0.0]
var _flash: Array = [0.0, 0.0, 0.0, 0.0, 0.0]
var _clock: float = 0.0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)


## n yıldızı yakar (soldan sağa).
func set_lit_count(n: int, animate: bool = true) -> void:
	for i in count:
		var target: float = 1.0 if i < n else 0.0
		if animate and absf(float(_lit[i]) - target) > 0.01:
			var idx: int = i
			create_tween().tween_method(func(v: float) -> void: _set_lit(idx, v), float(_lit[i]), target, 0.7)\
				.set_delay(0.12 * float(idx))
			if target > 0.5:
				_flash_star(i)
		else:
			_set_lit(i, target)


func set_repaired(on: bool, animate: bool = true) -> void:
	var target: float = 1.0 if on else 0.0
	if animate:
		create_tween().tween_method(func(v: float) -> void: repaired = v; queue_redraw(), repaired, target, 1.2)
	else:
		repaired = target
		queue_redraw()


func _flash_star(i: int) -> void:
	create_tween().tween_method(func(v: float) -> void: _flash[i] = v; queue_redraw(), 1.0, 0.0, 1.0)\
		.set_delay(0.12 * float(i))


func _set_lit(i: int, v: float) -> void:
	_lit[i] = v
	queue_redraw()


func _process(delta: float) -> void:
	_clock += delta
	queue_redraw()


func _star_pos(i: int) -> Vector2:
	# başın üstünde açık bir yay: soldan sağa
	var t: float = (float(i) + 0.5) / float(count)
	var a: float = PI * (1.12 + 0.76 * t)
	return Vector2(cos(a) * radius, sin(a) * radius * 0.78)


func _draw() -> void:
	var accent: Color = LIT.lerp(REPAIRED, repaired)
	# bağlantı çizgileri: yalnızca yanmış komşular arasında
	for i in count - 1:
		var k: float = minf(float(_lit[i]), float(_lit[i + 1]))
		if k > 0.01 or repaired > 0.5:
			var c := accent
			c.a = 0.55 * maxf(k, repaired)
			draw_line(_star_pos(i), _star_pos(i + 1), c, 2.0, true)
	for i in count:
		var p: Vector2 = _star_pos(i)
		var lit: float = float(_lit[i])
		var twinkle: float = 1.0 + 0.08 * sin(_clock * 2.4 + float(i) * 1.7) * lit
		var size: float = (13.0 + 8.0 * lit) * twinkle
		var flash: float = float(_flash[i])
		if lit > 0.01:
			for g in 3:
				var glow := accent
				glow.a = (0.10 + 0.25 * flash) * lit / float(g + 1)
				draw_circle(p, size * (1.8 + 0.9 * float(g)) + 30.0 * flash, glow)
		var col: Color = UNLIT.lerp(accent, lit)
		var pts: PackedVector2Array = _star_points(p, size, size * 0.38)
		if lit > 0.5:
			draw_colored_polygon(pts, col)
		else:
			var closed: PackedVector2Array = pts.duplicate()
			closed.append(pts[0])
			draw_polyline(closed, col, 1.5, true)


func _star_points(c: Vector2, outer: float, inner: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for k in 8:
		var r: float = outer if k % 2 == 0 else inner
		var a: float = -PI * 0.5 + float(k) * PI * 0.25
		out.append(c + Vector2(cos(a), sin(a)) * r)
	return out
