extends RefCounted
## Fizik sahneleri için ortak çizim kiti: arka plan, cam panel, metalik gövde, okuma kartı, parlama.
## Hepsi bir CanvasItem'ın _draw() içinden çağrılır. Renkler docs/ART_DIRECTION.md paletinden.

const INK := Color("#eeeae0")
const MUTED := Color("#b1ac9e")
const ACCENT := Color("#6fe3c1")
const WARM := Color("#dfae63")
const DANGER := Color("#e5645a")
const BG := Color("#10110f")
const PANEL := Color("#191a17")
const EDGE := Color("#3b3d35")
const PANEL_TEX = preload("res://assets/ui/panel_glass.png")
const PHOTO_BG = preload("res://stations/free_fall/assets/chamber_bg.png")
const METAL = preload("res://assets/materials/Metal009/Metal009_2K-JPG_Color.jpg")


## Meridian cam paneli: 9 dilimli doku.
static func glass_box(margin: float = 24.0) -> StyleBoxTexture:
	var box := StyleBoxTexture.new()
	box.texture = PANEL_TEX
	box.texture_margin_left = margin
	box.texture_margin_right = margin
	box.texture_margin_top = margin
	box.texture_margin_bottom = margin
	return box


static func _box(fill: Color, border: Color, radius: int, border_width: int = 1, shadow: int = 0) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(border_width)
	box.set_corner_radius_all(radius)
	box.anti_aliasing = true
	if shadow > 0:
		box.shadow_size = shadow
		box.shadow_color = Color(0, 0, 0, 0.45)
		box.shadow_offset = Vector2(0, 4)
	return box


## Grafit dikey geçiş, iki yumuşak ışık lekesi, ince ızgara ve kenarlarda vinyet.
static func backdrop(ci: CanvasItem, size: Vector2, glow_a: Vector2 = Vector2(0.18, 0.2), glow_b: Vector2 = Vector2(0.82, 0.7), photo: bool = true, dim: float = 0.3) -> void:
	if photo:
		# Fotogerçekçi laboratuvar, koyulaştırılmış: ölçü yazıları okunsun.
		ci.draw_texture_rect(PHOTO_BG, Rect2(Vector2.ZERO, size), false, Color(0.95, 1.0, 1.05, 1.0))
		ci.draw_rect(Rect2(Vector2.ZERO, size), Color(BG, dim))
		var edge_w := size.x * 0.1
		for i in 8:
			var a := 0.5 * (1.0 - float(i) / 8.0)
			ci.draw_rect(Rect2(Vector2(i * edge_w / 8.0, 0), Vector2(edge_w / 8.0, size.y)), Color(0, 0, 0, a))
			ci.draw_rect(Rect2(Vector2(size.x - (i + 1) * edge_w / 8.0, 0), Vector2(edge_w / 8.0, size.y)), Color(0, 0, 0, a))
		return
	var top := Color("#1a1b17")
	var bottom := Color("#0d0e0c")
	ci.draw_polygon(PackedVector2Array([Vector2.ZERO, Vector2(size.x, 0), size, Vector2(0, size.y)]), PackedColorArray([top, top, bottom, bottom]))
	for glow in [[glow_a, Color("#3a3a2a"), 0.55], [glow_b, Color("#4a3a22"), 0.4]]:
		var centre: Vector2 = Vector2(size.x * glow[0].x, size.y * glow[0].y)
		for ring in 14:
			var u := float(ring) / 13.0
			ci.draw_circle(centre, size.x * (0.42 - 0.38 * u), Color(glow[1], glow[2] * 0.045))
	var step := maxf(size.x / 32.0, 24.0)
	var x := 0.0
	while x < size.x:
		ci.draw_line(Vector2(x, 0), Vector2(x, size.y), Color(1, 1, 1, 0.018), 1.0)
		x += step
	var y := 0.0
	while y < size.y:
		ci.draw_line(Vector2(0, y), Vector2(size.x, y), Color(1, 1, 1, 0.018), 1.0)
		y += step
	# Vinyet
	var edge := size.x * 0.12
	for i in 10:
		var a := 0.06 * (1.0 - float(i) / 10.0)
		ci.draw_rect(Rect2(Vector2(i * edge / 10.0, 0), Vector2(edge / 10.0, size.y)), Color(0, 0, 0, a * 3.0))
		ci.draw_rect(Rect2(Vector2(size.x - (i + 1) * edge / 10.0, 0), Vector2(edge / 10.0, size.y)), Color(0, 0, 0, a * 3.0))


## Düz panel: koyu dolgu, ince çerçeve, küçük başlık.
static func panel(ci: CanvasItem, rect: Rect2, title: String, font: Font, scale: float, _accent: Color = ACCENT) -> void:
	ci.draw_style_box(_box(Color(PANEL, 0.94), EDGE, int(8 * scale), 1, 0), rect.grow(6.0 * scale))
	if title != "":
		ci.draw_string(font, rect.position + Vector2(0, -12) * scale, title, HORIZONTAL_ALIGNMENT_LEFT, -1, int(13 * scale), MUTED)


## Düz gövde: koyu dolgu ve renkli çerçeve.
static func body(ci: CanvasItem, rect: Rect2, tint: Color, scale: float) -> void:
	ci.draw_style_box(_box(Color("#232d3a"), Color(tint, 0.9), int(5 * scale), 2, 0), rect)


## Okuma kartı: küçük etiket, büyük değer, birim.
static func readout(ci: CanvasItem, rect: Rect2, label: String, value: String, unit: String, font: Font, scale: float, colour: Color = ACCENT) -> void:
	ci.draw_style_box(_box(Color(PANEL, 0.94), EDGE, int(6 * scale), 1, 0), rect)
	ci.draw_string(font, rect.position + Vector2(14, 22) * scale, label, HORIZONTAL_ALIGNMENT_LEFT, -1, int(12 * scale), MUTED)
	ci.draw_string(font, rect.position + Vector2(14, rect.size.y / scale - 14.0) * scale, value, HORIZONTAL_ALIGNMENT_LEFT, -1, int(28 * scale), INK)
	if unit != "":
		var width := font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, int(28 * scale)).x
		ci.draw_string(font, rect.position + Vector2(14.0 * scale + width + 6.0 * scale, rect.size.y - 14.0 * scale), unit, HORIZONTAL_ALIGNMENT_LEFT, -1, int(14 * scale), colour)


## Yumuşak parlayan nokta.
static func glow(ci: CanvasItem, position: Vector2, radius: float, colour: Color) -> void:
	for i in 6:
		var u := float(i) / 5.0
		ci.draw_circle(position, radius * (2.4 - 1.8 * u), Color(colour, 0.05 + 0.1 * u))
	ci.draw_circle(position, radius, colour)
	ci.draw_circle(position - Vector2(radius, radius) * 0.3, radius * 0.35, Color(1, 1, 1, 0.55))


## Işıklı kuyruk: konum dizisi boyunca solan çizgi.
static func trail(ci: CanvasItem, points: PackedVector2Array, colour: Color, width: float) -> void:
	var count := points.size()
	if count < 2:
		return
	for i in range(1, count):
		var u := float(i) / float(count - 1)
		ci.draw_line(points[i - 1], points[i], Color(colour, 0.15 + 0.85 * u), width * (0.5 + 0.5 * u), true)


## Sakin ortam: koyu gökyüzü geçişi, hafif ufuk çizgisi, zemin gölgesi ve vinyet. Dikkat dağıtıcı efekt yok.
static func cinematic(ci: CanvasItem, size: Vector2, _t: float, top: Color, low: Color, accent: Color, horizon: float = 0.58) -> void:
	var w := size.x
	var h := size.y
	var hy := h * horizon
	ci.draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(w, 0), Vector2(w, hy), Vector2(0, hy)]), PackedColorArray([top, top, low.darkened(0.25), low.darkened(0.25)]))
	var floor_far := low.darkened(0.55)
	var floor_near := low.darkened(0.9)
	ci.draw_polygon(PackedVector2Array([Vector2(0, hy), Vector2(w, hy), Vector2(w, h), Vector2(0, h)]), PackedColorArray([floor_far, floor_far, floor_near, floor_near]))
	ci.draw_line(Vector2(0, hy), Vector2(w, hy), Color(accent, 0.12), 1.0)
	var edge := w * 0.14
	for i in 10:
		var ea := 0.3 * (1.0 - float(i) / 10.0)
		ci.draw_rect(Rect2(Vector2(i * edge / 10.0, 0), Vector2(edge / 10.0, h)), Color(0, 0, 0, ea))
		ci.draw_rect(Rect2(Vector2(w - (i + 1) * edge / 10.0, 0), Vector2(edge / 10.0, h)), Color(0, 0, 0, ea))


## Cam vakum tüpü: yatay yuvarlak gövde, iç ışın parlaması, üst yansıma.
static func tube(ci: CanvasItem, rect: Rect2, accent: Color, beam_y: float, scale: float) -> void:
	ci.draw_style_box(_box(Color(accent, 0.07), Color(accent, 0.55), int(rect.size.y * 0.5), 2, int(14 * scale)), rect)
	ci.draw_line(Vector2(rect.position.x + rect.size.y * 0.4, rect.position.y + 7.0 * scale), Vector2(rect.end.x - rect.size.y * 0.4, rect.position.y + 7.0 * scale), Color(1, 1, 1, 0.3), 2.0 * scale)
	ci.draw_line(Vector2(rect.position.x + rect.size.y * 0.5, rect.end.y - 8.0 * scale), Vector2(rect.end.x - rect.size.y * 0.5, rect.end.y - 8.0 * scale), Color(1, 1, 1, 0.1), 1.5 * scale)
	var a := Vector2(rect.position.x + rect.size.y * 0.4, beam_y)
	var b := Vector2(rect.end.x - rect.size.y * 0.4, beam_y)
	ci.draw_line(a, b, Color(accent, 0.06), 22.0 * scale)
	ci.draw_line(a, b, Color(accent, 0.14), 9.0 * scale)
	ci.draw_line(a, b, Color(accent, 0.55), 1.6 * scale)
