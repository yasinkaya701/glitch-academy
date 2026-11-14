extends "res://scripts/mission_hud.gd"
## Felsefe konuşmalarında koyu arayüzü korur, geri bildirimi giriş alanından ayırır.

const UITheme = preload("res://scripts/ui_theme.gd")


func _ready() -> void:
	super._ready()
	directive.add_theme_color_override("font_color", UITheme.GAME_TEXT)
	var reading_surface := StyleBoxFlat.new()
	reading_surface.bg_color = Color(UITheme.GAME_PANEL, 0.94)
	reading_surface.border_color = UITheme.GAME_EDGE
	reading_surface.set_border_width_all(1)
	reading_surface.set_corner_radius_all(8)
	reading_surface.content_margin_left = 14
	reading_surface.content_margin_right = 14
	reading_surface.content_margin_top = 10
	reading_surface.content_margin_bottom = 10
	directive.add_theme_stylebox_override("normal", reading_surface)
	toast.add_theme_color_override("font_color", UITheme.GAME_TEXT)
	var toast_surface := StyleBoxFlat.new()
	toast_surface.bg_color = Color(UITheme.GAME_PANEL, 0.97)
	toast_surface.border_color = UITheme.GAME_EDGE
	toast_surface.set_border_width_all(1)
	toast_surface.set_corner_radius_all(10)
	toast_surface.content_margin_left = 16
	toast_surface.content_margin_right = 16
	toast_surface.content_margin_top = 8
	toast_surface.content_margin_bottom = 8
	toast.add_theme_stylebox_override("normal", toast_surface)
	if info_label != null:
		info_label.add_theme_color_override("font_color", UITheme.GAME_TEXT)


func _process(delta: float) -> void:
	super._process(delta)
	if not is_instance_valid(toast) or not toast.visible:
		return
	var margin := 24.0
	var available_width := maxf(size.x - margin * 2.0, 220.0)
	var toast_width := minf(available_width, 520.0 if size.x >= 760.0 else available_width)
	toast.size.x = toast_width
	toast.size.y = maxf(toast.get_combined_minimum_size().y, 44.0)
	toast.position.x = size.x - toast_width - margin if size.x >= 760.0 else margin
	var directive_bottom := directive.position.y + maxf(directive.get_combined_minimum_size().y, 24.0)
	toast.position.y = maxf(104.0, directive_bottom + 12.0)


func _draw() -> void:
	var dark := Color(UITheme.GAME_BG, 0.94)
	var clear := Color(UITheme.GAME_BG, 0.0)
	var top := minf(size.y * 0.22, 150.0)
	draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(size.x, 0), Vector2(size.x, top), Vector2(0, top)]),
		PackedColorArray([dark, dark, clear, clear]))
	var bottom := minf(size.y * 0.24, 170.0)
	draw_polygon(PackedVector2Array([Vector2(0, size.y), Vector2(size.x, size.y), Vector2(size.x, size.y - bottom), Vector2(0, size.y - bottom)]),
		PackedColorArray([dark, dark, clear, clear]))
	# Aşama çizgisi kaldırıldı: filozof ve tarihî kişinin başının üstüne biniyordu; adımlar HUD şeridinde.


func _draw_gameplay_steps() -> void:
	if _steps_total <= 1 or size.x <= 0.0:
		return
	var track_width := minf(size.x - 48.0, 720.0)
	var gap := 4.0
	var segment_width := (track_width - gap * (_steps_total - 1)) / _steps_total
	var track_left := (size.x - track_width) * 0.5
	for index in _steps_total:
		var color := UITheme.GAME_EDGE
		if index < _steps_current:
			color = UITheme.GAME_ACCENT
		elif index == _steps_current:
			color = UITheme.GAME_WARM
		draw_rect(Rect2(track_left + index * (segment_width + gap), _progress_track_y(), segment_width, 3.0), color, true)
