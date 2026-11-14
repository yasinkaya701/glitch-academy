extends Control

const INK := Color("#e8f1f2")
const MUTED := Color("#8fa6b3")
const CYAN := Color("#6fe3c1")
const AMBER := Color("#f2a65a")
const GRID_COL := Color("#263b4e")

var dim_l: int = 4 # Length (en)
var dim_w: int = 3 # Width (boy)
var dim_h: int = 3 # Height (yükseklik)
var visible_layers: int = 1
var is_full: bool = false


func _draw() -> void:
	if size.x < 100 or size.y < 100:
		return

	var origin := size * 0.5 + Vector2(0, 80)
	var cube_size := 36.0
	
	# Isometric projection basis vectors
	var u_x := Vector2(cos(deg_to_rad(30)), sin(deg_to_rad(30))) * cube_size
	var u_y := Vector2(-cos(deg_to_rad(30)), sin(deg_to_rad(30))) * cube_size
	var u_z := Vector2(0, -cube_size * 0.85)

	# 1. Draw outer wireframe crate bounding box
	_draw_crate_wireframe(origin, u_x, u_y, u_z)

	# 2. Draw packed unit cubes up to visible_layers
	for z in range(visible_layers):
		for y in range(dim_w):
			for x in range(dim_l):
				var pos := origin + u_x * float(x) + u_y * float(y) + u_z * float(z)
				_draw_iso_cube(pos, u_x, u_y, u_z, z == visible_layers - 1)

	# 3. Draw dimension labels
	var base_mid_x := origin + u_x * (dim_l * 0.5) + u_y * dim_w + Vector2(0, 18)
	var base_mid_y := origin + u_y * (dim_w * 0.5) + Vector2(-36, 12)
	var h_top := origin + u_x * dim_l + u_z * (dim_h * 0.5) + Vector2(28, 0)
	
	draw_string(ThemeDB.fallback_font, base_mid_x, "%d birim" % dim_l, HORIZONTAL_ALIGNMENT_CENTER, 80, 13, CYAN)
	draw_string(ThemeDB.fallback_font, base_mid_y, "%d birim" % dim_w, HORIZONTAL_ALIGNMENT_CENTER, 80, 13, AMBER)
	draw_string(ThemeDB.fallback_font, h_top, "%d kat" % dim_h, HORIZONTAL_ALIGNMENT_CENTER, 80, 13, INK)


func _draw_iso_cube(p: Vector2, ux: Vector2, uy: Vector2, uz: Vector2, is_top_layer: bool) -> void:
	var c_top := Color("#41627f") if is_top_layer else Color("#22374e")
	var c_left := Color("#1b2c3f")
	var c_right := Color("#2a425b")
	
	# Top Face
	var p0 := p + uz
	var p1 := p0 + ux
	var p2 := p0 + ux + uy
	var p3 := p0 + uy
	draw_colored_polygon(PackedVector2Array([p0, p1, p2, p3]), c_top)
	draw_polyline(PackedVector2Array([p0, p1, p2, p3, p0]), Color("#6fe3c1", 0.4), 1.0)
	
	# Left Face
	var p4 := p + uy
	var p5 := p
	draw_colored_polygon(PackedVector2Array([p0, p3, p4, p5]), c_left)
	draw_polyline(PackedVector2Array([p0, p3, p4, p5, p0]), Color("#101924"), 1.0)
	
	# Right Face
	var p6 := p + ux
	draw_colored_polygon(PackedVector2Array([p0, p1, p6, p5]), c_right)
	draw_polyline(PackedVector2Array([p0, p1, p6, p5, p0]), Color("#101924"), 1.0)


func _draw_crate_wireframe(o: Vector2, ux: Vector2, uy: Vector2, uz: Vector2) -> void:
	var l := float(dim_l)
	var w := float(dim_w)
	var h := float(dim_h)
	
	var b0 := o
	var b1 := o + ux * l
	var b2 := o + ux * l + uy * w
	var b3 := o + uy * w
	
	var t0 := b0 + uz * h
	var t1 := b1 + uz * h
	var t2 := b2 + uz * h
	var t3 := b3 + uz * h
	
	# Base boundary
	draw_polyline(PackedVector2Array([b0, b1, b2, b3, b0]), GRID_COL, 1.5)
	# Top boundary
	draw_polyline(PackedVector2Array([t0, t1, t2, t3, t0]), Color(CYAN, 0.6), 1.5)
	# Vertical pillars
	draw_line(b0, t0, GRID_COL, 1.2)
	draw_line(b1, t1, Color(CYAN, 0.4), 1.5)
	draw_line(b2, t2, Color(CYAN, 0.4), 1.5)
	draw_line(b3, t3, GRID_COL, 1.2)
