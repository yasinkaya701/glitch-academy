extends Node
## Ortak açık tema: Inter gövde, Space Grotesk başlık, beyaz yüzey ve adaçayı vurgu.

const FONT = preload("res://assets/fonts/Inter.ttf")
const FONT_CONDENSED = FONT
const FAINT := Color("#87958c")
const ACCENT_DIM := Color("#e0eee6")
const PANEL_SUNKEN := Color("#edf1ec")
const DISPLAY_FONT = preload("res://assets/fonts/SpaceGrotesk.ttf")

const BG := Color("#f4f6f2")
const PANEL := Color("#ffffff")
const PANEL_RAISED := Color("#e9eee8")
const EDGE := Color("#d8e0d8")
const EDGE_STRONG := Color("#bdccc3")
const INK := Color("#22332f")
const MUTED := Color("#66766d")
const ACCENT := Color("#3b7867")
const WARM := Color("#c88755")
const DANGER := Color("#b85f56")
const GOOD := Color("#53826c")

# İç oyun yüzeyleri: nötr kömür, mavi içermeyen adaçayı ve amber vurgular.
const GAME_BG := Color("#10110f")
const GAME_PANEL := Color("#191a17")
const GAME_RAISED := Color("#242520")
const GAME_EDGE := Color("#3b3d35")
const GAME_TEXT := Color("#eeeae0")
const GAME_MUTED := Color("#b1ac9e")
const GAME_ACCENT := Color("#8fbea0")
const GAME_WARM := Color("#dfae63")


func _ready() -> void:
	get_tree().root.theme = build()


static func build() -> Theme:
	var theme := Theme.new()
	var regular := FontVariation.new()
	regular.base_font = FONT
	regular.variation_opentype = {"weight": 400}
	var semibold := FontVariation.new()
	semibold.base_font = FONT
	semibold.variation_opentype = {"weight": 600}
	var display := FontVariation.new()
	display.base_font = DISPLAY_FONT
	display.variation_opentype = {"weight": 600}
	theme.default_font = regular
	theme.default_font_size = 16

	# Label
	theme.set_color("font_color", "Label", INK)
	theme.set_type_variation("HeadlineLabel", "Label")
	theme.set_font("font", "HeadlineLabel", display)
	theme.set_font_size("font_size", "HeadlineLabel", 27)
	theme.set_type_variation("SectionLabel", "Label")
	theme.set_font("font", "SectionLabel", semibold)
	theme.set_font_size("font_size", "SectionLabel", 14)
	theme.set_color("font_color", "SectionLabel", ACCENT)
	theme.set_type_variation("KickerLabel", "SectionLabel")
	theme.set_font_size("font_size", "KickerLabel", 13)
	theme.set_type_variation("StrongLabel", "Label")
	theme.set_font("font", "StrongLabel", semibold)
	theme.set_type_variation("MutedLabel", "Label")
	theme.set_color("font_color", "MutedLabel", MUTED)

	# Düğmeler
	_button(theme, "Button", PANEL, EDGE, INK)
	theme.set_font("font", "Button", semibold)
	theme.set_type_variation("PrimaryButton", "Button")
	_button(theme, "PrimaryButton", Color("#285b4d"), Color("#285b4d"), Color("#ffffff"))
	theme.set_font("font", "PrimaryButton", semibold)
	theme.set_type_variation("DangerButton", "Button")
	_button(theme, "DangerButton", Color("#f5e7e3"), DANGER, DANGER)

	_theme_mode_tabs(theme, semibold)
	_theme_route_tabs(theme, semibold)
	_theme_compact_button(theme, semibold)

	# Onay ve seçenek
	for type_name in ["CheckButton", "CheckBox"]:
		theme.set_color("font_color", type_name, INK)
		theme.set_color("font_hover_color", type_name, ACCENT)
		theme.set_color("font_pressed_color", type_name, ACCENT)
		theme.set_stylebox("normal", type_name, _flat(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 0, 6, 6))
		theme.set_stylebox("hover", type_name, _flat(PANEL_RAISED, Color(0, 0, 0, 0), 0, 6, 6))
		theme.set_stylebox("pressed", type_name, _flat(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 0, 6, 6))
		theme.set_stylebox("focus", type_name, _flat(Color(0, 0, 0, 0), ACCENT, 1, 6, 6))

	# Kaydırıcı
	var track := _flat(Color("#d8e0d8"), Color(0, 0, 0, 0), 0, 3, 0)
	track.content_margin_top = 3
	track.content_margin_bottom = 3
	theme.set_stylebox("slider", "HSlider", track)
	theme.set_stylebox("grabber_area", "HSlider", _flat(ACCENT, Color(0, 0, 0, 0), 0, 3, 0))
	theme.set_stylebox("grabber_area_highlight", "HSlider", _flat(Color("#5d9a85"), Color(0, 0, 0, 0), 0, 3, 0))
	theme.set_icon("grabber", "HSlider", _dot(ACCENT, 11))
	theme.set_icon("grabber_highlight", "HSlider", _dot(Color("#ffffff"), 12))
	theme.set_icon("grabber_disabled", "HSlider", _dot(EDGE, 10))

	# Giriş kutusu
	theme.set_stylebox("normal", "LineEdit", _flat(Color("#ffffff"), EDGE, 1, 6, 10))
	theme.set_stylebox("focus", "LineEdit", _flat(Color("#ffffff"), ACCENT, 2, 6, 10))
	theme.set_stylebox("read_only", "LineEdit", _flat(Color("#edf1ec"), EDGE, 1, 6, 10))
	theme.set_color("font_color", "LineEdit", INK)
	theme.set_color("font_placeholder_color", "LineEdit", MUTED)
	theme.set_color("caret_color", "LineEdit", ACCENT)
	theme.set_color("selection_color", "LineEdit", Color(ACCENT, 0.35))

	# Paneller
	theme.set_stylebox("panel", "PanelContainer", _flat(PANEL, EDGE, 1, 10, 18))
	theme.set_type_variation("GlassPanel", "PanelContainer")
	theme.set_stylebox("panel", "GlassPanel", _flat(Color(PANEL, 0.82), EDGE, 1, 12, 18))
	theme.set_type_variation("ConsolePanel", "PanelContainer")
	theme.set_stylebox("panel", "ConsolePanel", _flat(PANEL, EDGE_STRONG, 1, 12, 20))
	theme.set_type_variation("CampaignDock", "PanelContainer")
	theme.set_stylebox("panel", "CampaignDock", _flat(PANEL, EDGE, 1, 10, 22))

	# Liste
	theme.set_stylebox("panel", "ItemList", _flat(Color(PANEL, 0.94), EDGE, 1, 8, 6))
	theme.set_stylebox("focus", "ItemList", _flat(Color(0, 0, 0, 0), ACCENT, 1, 8, 0))
	theme.set_stylebox("hover", "ItemList", _flat(PANEL_RAISED, Color(0, 0, 0, 0), 0, 5, 14, 10))
	theme.set_stylebox("selected", "ItemList", _flat(ACCENT_DIM, Color(0, 0, 0, 0), 0, 5, 14, 10))
	theme.set_stylebox("selected_focus", "ItemList", _flat(ACCENT_DIM, Color(0, 0, 0, 0), 0, 5, 14, 10))
	theme.set_color("font_color", "ItemList", MUTED)
	theme.set_color("font_selected_color", "ItemList", INK)
	theme.set_color("font_hovered_color", "ItemList", INK)
	theme.set_constant("v_separation", "ItemList", 4)
	theme.set_constant("line_separation", "ItemList", 2)

	# OptionButton
	theme.set_stylebox("normal", "OptionButton", _flat(PANEL_RAISED, EDGE, 1, 8, 12))
	theme.set_stylebox("hover", "OptionButton", _flat(Color("#e9eee8"), EDGE_STRONG, 1, 8, 12))
	theme.set_stylebox("pressed", "OptionButton", _flat(Color("#e0eee6"), ACCENT, 1, 8, 12))
	theme.set_color("font_color", "OptionButton", INK)

	# Açılır menüler de açık tema kullanır.
	theme.set_stylebox("panel", "PopupMenu", _flat(PANEL, EDGE, 1, 10, 8))
	theme.set_stylebox("hover", "PopupMenu", _flat(ACCENT_DIM, EDGE, 0, 6, 8))
	theme.set_color("font_color", "PopupMenu", INK)
	theme.set_color("font_hover_color", "PopupMenu", INK)
	theme.set_constant("v_separation", "PopupMenu", 12)
	theme.set_color("default_color", "RichTextLabel", INK)
	# Kaydırma çubuğu
	var scroll := _flat(Color("#d8e0d8"), Color(0, 0, 0, 0), 0, 4, 0)
	theme.set_stylebox("scroll", "VScrollBar", scroll)
	theme.set_stylebox("grabber", "VScrollBar", _flat(EDGE_STRONG, Color(0, 0, 0, 0), 0, 4, 0))
	theme.set_stylebox("grabber_highlight", "VScrollBar", _flat(ACCENT, Color(0, 0, 0, 0), 0, 4, 0))
	theme.set_stylebox("grabber_pressed", "VScrollBar", _flat(ACCENT, Color(0, 0, 0, 0), 0, 4, 0))

	# İlerleme
	theme.set_stylebox("background", "ProgressBar", _flat(Color("#d8e0d8"), Color(0, 0, 0, 0), 0, 4, 0))
	theme.set_stylebox("fill", "ProgressBar", _flat(ACCENT, Color(0, 0, 0, 0), 0, 4, 0))
	return theme


static func build_gameplay() -> Theme:
	var theme := build()
	theme.default_font_size = 16
	theme.set_color("font_color", "Label", GAME_TEXT)
	theme.set_color("font_color", "HeadlineLabel", GAME_TEXT)
	theme.set_color("font_color", "SectionLabel", GAME_ACCENT)
	theme.set_color("font_color", "MutedLabel", GAME_MUTED)
	_button(theme, "Button", GAME_RAISED, GAME_EDGE, GAME_TEXT)
	theme.set_type_variation("PrimaryButton", "Button")
	_button(theme, "PrimaryButton", GAME_WARM, Color("#f0c98a"), Color("#1c1a14"))
	theme.set_stylebox("disabled", "PrimaryButton", _flat(GAME_RAISED, GAME_EDGE, 1, 8, 16, 9))
	theme.set_color("font_disabled_color", "PrimaryButton", Color("#8d8a7e"))
	theme.set_font("font", "PrimaryButton", theme.get_font("font", "Button"))
	theme.set_type_variation("DangerButton", "Button")
	_button(theme, "DangerButton", Color("#442b27"), Color("#9f6658"), Color("#f0c5b4"))
	_theme_gameplay_tabs(theme)
	for type_name in ["CheckButton", "CheckBox"]:
		theme.set_color("font_color", type_name, GAME_TEXT)
		theme.set_color("font_hover_color", type_name, GAME_ACCENT)
		theme.set_color("font_pressed_color", type_name, GAME_ACCENT)
		theme.set_stylebox("normal", type_name, _flat(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 0, 6, 6))
		theme.set_stylebox("hover", type_name, _flat(GAME_RAISED, Color(0, 0, 0, 0), 0, 6, 6))
		theme.set_stylebox("focus", type_name, _flat(Color(0, 0, 0, 0), GAME_ACCENT, 1, 6, 6))
	var slider_track := _flat(GAME_EDGE, Color(0, 0, 0, 0), 0, 3, 0)
	slider_track.content_margin_top = 3
	slider_track.content_margin_bottom = 3
	theme.set_stylebox("slider", "HSlider", slider_track)
	theme.set_stylebox("grabber_area", "HSlider", _flat(GAME_ACCENT, Color(0, 0, 0, 0), 0, 3, 0))
	theme.set_stylebox("grabber_area_highlight", "HSlider", _flat(Color("#a8cfad"), Color(0, 0, 0, 0), 0, 3, 0))
	theme.set_icon("grabber", "HSlider", _dot(GAME_ACCENT, 11))
	theme.set_icon("grabber_highlight", "HSlider", _dot(GAME_TEXT, 12))
	theme.set_icon("grabber_disabled", "HSlider", _dot(GAME_EDGE, 10))
	var panel := _flat(GAME_PANEL, GAME_EDGE, 1, 10, 18)
	theme.set_stylebox("panel", "PanelContainer", panel)
	theme.set_type_variation("GlassPanel", "PanelContainer")
	theme.set_stylebox("panel", "GlassPanel", _flat(Color(GAME_PANEL, 0.96), GAME_EDGE, 1, 12, 18))
	theme.set_type_variation("ConsolePanel", "PanelContainer")
	theme.set_stylebox("panel", "ConsolePanel", _flat(GAME_PANEL, GAME_EDGE, 1, 12, 20))
	theme.set_type_variation("CampaignDock", "PanelContainer")
	theme.set_stylebox("panel", "CampaignDock", _flat(GAME_PANEL, GAME_EDGE, 1, 10, 22))
	theme.set_stylebox("normal", "LineEdit", _flat(GAME_RAISED, GAME_EDGE, 1, 6, 10))
	theme.set_stylebox("focus", "LineEdit", _flat(GAME_RAISED, GAME_ACCENT, 2, 6, 10))
	theme.set_stylebox("read_only", "LineEdit", _flat(GAME_PANEL, GAME_EDGE, 1, 6, 10))
	theme.set_color("font_color", "LineEdit", GAME_TEXT)
	theme.set_color("font_placeholder_color", "LineEdit", GAME_MUTED)
	theme.set_color("caret_color", "LineEdit", GAME_ACCENT)
	theme.set_color("selection_color", "LineEdit", Color(GAME_ACCENT, 0.35))
	theme.set_color("font_color", "ItemList", GAME_TEXT)
	theme.set_color("font_selected_color", "ItemList", GAME_TEXT)
	theme.set_color("font_hovered_color", "ItemList", GAME_TEXT)
	theme.set_stylebox("panel", "ItemList", _flat(GAME_PANEL, GAME_EDGE, 1, 8, 6))
	theme.set_stylebox("selected", "ItemList", _flat(Color("#3a3427"), Color(0, 0, 0, 0), 0, 5, 14, 10))
	theme.set_stylebox("selected_focus", "ItemList", _flat(Color("#3a3427"), Color(0, 0, 0, 0), 0, 5, 14, 10))
	theme.set_stylebox("hover", "ItemList", _flat(GAME_RAISED, Color(0, 0, 0, 0), 0, 5, 14, 10))
	theme.set_color("font_color", "OptionButton", GAME_TEXT)
	theme.set_stylebox("normal", "OptionButton", _flat(GAME_RAISED, GAME_EDGE, 1, 8, 12))
	theme.set_stylebox("hover", "OptionButton", _flat(Color("#30312b"), GAME_EDGE, 1, 8, 12))
	theme.set_stylebox("pressed", "OptionButton", _flat(Color("#3a3427"), GAME_ACCENT, 1, 8, 12))
	theme.set_stylebox("panel", "PopupMenu", _flat(GAME_PANEL, GAME_EDGE, 1, 10, 8))
	theme.set_stylebox("hover", "PopupMenu", _flat(Color("#3a3427"), GAME_EDGE, 0, 6, 8))
	theme.set_color("font_color", "PopupMenu", GAME_TEXT)
	theme.set_color("font_hover_color", "PopupMenu", GAME_TEXT)
	theme.set_stylebox("scroll", "VScrollBar", _flat(GAME_EDGE, Color(0, 0, 0, 0), 0, 4, 0))
	theme.set_stylebox("grabber", "VScrollBar", _flat(Color("#66675d"), Color(0, 0, 0, 0), 0, 4, 0))
	theme.set_stylebox("grabber_highlight", "VScrollBar", _flat(GAME_ACCENT, Color(0, 0, 0, 0), 0, 4, 0))
	theme.set_stylebox("background", "ProgressBar", _flat(GAME_RAISED, Color(0, 0, 0, 0), 0, 4, 0))
	theme.set_stylebox("fill", "ProgressBar", _flat(GAME_ACCENT, Color(0, 0, 0, 0), 0, 4, 0))
	return theme


static func _theme_gameplay_tabs(theme: Theme) -> void:
	var idle := _flat(GAME_RAISED, GAME_EDGE, 1, 10, 14, 8)
	var active := _flat(Color("#3a3427"), GAME_ACCENT, 1, 10, 14, 8)
	var hover := _flat(Color("#30312b"), GAME_EDGE, 1, 10, 14, 8)
	for type_name in ["RouteTab", "ModeTab"]:
		theme.set_type_variation(type_name, "Button")
		theme.set_stylebox("normal", type_name, idle)
		theme.set_stylebox("disabled", type_name, idle)
		theme.set_stylebox("hover", type_name, hover)
		theme.set_stylebox("pressed", type_name, active)
		theme.set_stylebox("hover_pressed", type_name, active)
		theme.set_stylebox("focus", type_name, _flat(Color(0, 0, 0, 0), GAME_ACCENT, 1, 4, 10, 6))
		theme.set_color("font_color", type_name, GAME_MUTED)
		theme.set_color("font_hover_color", type_name, GAME_TEXT)
		theme.set_color("font_pressed_color", type_name, GAME_TEXT)
		theme.set_color("font_hover_pressed_color", type_name, GAME_TEXT)
		theme.set_color("font_disabled_color", type_name, Color(GAME_MUTED, 0.45))
	theme.set_type_variation("CompactButton", "Button")
	theme.set_stylebox("normal", "CompactButton", idle)
	theme.set_stylebox("disabled", "CompactButton", idle)
	theme.set_stylebox("hover", "CompactButton", hover)
	theme.set_stylebox("pressed", "CompactButton", active)
	theme.set_stylebox("focus", "CompactButton", _flat(Color(0, 0, 0, 0), GAME_ACCENT, 2, 5, 8, 6))
	theme.set_color("font_color", "CompactButton", GAME_TEXT)
	theme.set_color("font_hover_color", "CompactButton", GAME_TEXT)
	theme.set_color("font_pressed_color", "CompactButton", GAME_TEXT)


static func _theme_mode_tabs(theme: Theme, font: Font) -> void:
	theme.set_type_variation("ModeTab", "Button")
	var idle := _flat(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 0, 0, 8, 8)
	idle.border_width_bottom = 2
	var hover := _flat(Color(PANEL_RAISED, 0.58), EDGE, 1, 4, 8, 8)
	var active := _flat(Color(PANEL, 0.8), ACCENT, 1, 4, 8, 8)
	active.border_width_top = 0
	active.border_width_left = 0
	active.border_width_right = 0
	active.border_width_bottom = 2
	active.border_color = ACCENT
	theme.set_stylebox("normal", "ModeTab", idle)
	theme.set_stylebox("disabled", "ModeTab", idle)
	theme.set_stylebox("hover", "ModeTab", hover)
	theme.set_stylebox("pressed", "ModeTab", active)
	theme.set_stylebox("hover_pressed", "ModeTab", active)
	theme.set_stylebox("focus", "ModeTab", _flat(Color(0, 0, 0, 0), ACCENT, 1, 4, 8, 8))
	theme.set_font("font", "ModeTab", font)
	theme.set_color("font_color", "ModeTab", MUTED)
	theme.set_color("font_hover_color", "ModeTab", INK)
	theme.set_color("font_pressed_color", "ModeTab", INK)
	theme.set_color("font_hover_pressed_color", "ModeTab", INK)
	theme.set_color("font_disabled_color", "ModeTab", Color(MUTED, 0.45))


static func _theme_route_tabs(theme: Theme, font: Font) -> void:
	theme.set_type_variation("RouteTab", "Button")
	var idle := _flat(Color("#edf1ec"), EDGE, 1, 10, 14, 8)
	var active := _flat(Color("#e0eee6"), ACCENT, 1, 10, 14, 8)
	var hover := _flat(Color("#e9eee8"), EDGE_STRONG, 1, 10, 14, 8)
	theme.set_stylebox("normal", "RouteTab", idle)
	theme.set_stylebox("disabled", "RouteTab", idle)
	theme.set_stylebox("hover", "RouteTab", hover)
	theme.set_stylebox("pressed", "RouteTab", active)
	theme.set_stylebox("hover_pressed", "RouteTab", active)
	theme.set_stylebox("focus", "RouteTab", _flat(Color(0, 0, 0, 0), ACCENT, 1, 4, 10, 6))
	theme.set_font("font", "RouteTab", font)
	theme.set_color("font_color", "RouteTab", MUTED)
	theme.set_color("font_hover_color", "RouteTab", INK)
	theme.set_color("font_pressed_color", "RouteTab", INK)
	theme.set_color("font_hover_pressed_color", "RouteTab", INK)
	theme.set_color("font_disabled_color", "RouteTab", Color(MUTED, 0.45))


static func _theme_compact_button(theme: Theme, font: Font) -> void:
	theme.set_type_variation("CompactButton", "Button")
	theme.set_stylebox("normal", "CompactButton", _flat(PANEL_RAISED, EDGE, 1, 5, 8, 6))
	theme.set_stylebox("hover", "CompactButton", _flat(Color("#e9eee8"), EDGE_STRONG, 1, 5, 8, 6))
	theme.set_stylebox("pressed", "CompactButton", _flat(Color("#e0eee6"), ACCENT, 1, 5, 8, 6))
	theme.set_stylebox("disabled", "CompactButton", _flat(Color(PANEL_RAISED, 0.4), Color(EDGE, 0.35), 1, 5, 8, 6))
	theme.set_stylebox("focus", "CompactButton", _flat(Color(0, 0, 0, 0), ACCENT, 2, 5, 8, 6))
	theme.set_font("font", "CompactButton", font)
	theme.set_color("font_color", "CompactButton", INK)
	theme.set_color("font_hover_color", "CompactButton", INK)
	theme.set_color("font_pressed_color", "CompactButton", INK)
	theme.set_color("font_disabled_color", "CompactButton", Color(INK, 0.42))


static func _button(theme: Theme, type_name: String, fill: Color, edge: Color, text: Color) -> void:
	theme.set_stylebox("normal", type_name, _flat(fill, edge, 1, 8, 16, 9))
	theme.set_stylebox("hover", type_name, _flat(fill.lightened(0.12), edge.lightened(0.25), 1, 8, 16, 9))
	theme.set_stylebox("pressed", type_name, _flat(fill.darkened(0.2), edge, 1, 8, 16, 10))
	theme.set_stylebox("disabled", type_name, _flat(Color(fill, 0.35), Color(edge, 0.3), 1, 8, 16, 9))
	theme.set_stylebox("focus", type_name, _flat(Color(0, 0, 0, 0), ACCENT, 2, 8, 16, 9))
	theme.set_color("font_color", type_name, text)
	theme.set_color("font_hover_color", type_name, text)
	theme.set_color("font_pressed_color", type_name, text)
	theme.set_color("font_disabled_color", type_name, Color(text, 0.56))
	theme.set_color("font_focus_color", type_name, text)
	theme.set_color("icon_normal_color", type_name, text)
	var pressed_toggle := _flat(Color(ACCENT, 0.14), ACCENT, 2, 8, 16, 9)
	theme.set_stylebox("hover_pressed", type_name, pressed_toggle)
	if type_name == "Button":
		theme.set_stylebox("pressed", type_name, pressed_toggle)
	if type_name == "Button":
		theme.set_color("font_hover_pressed_color", type_name, INK)


static func _flat(fill: Color, edge: Color, border: int, radius: int, margin: int, vertical_margin: int = -1) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = edge
	style.set_border_width_all(border)
	style.set_corner_radius_all(radius)
	style.content_margin_left = margin
	style.content_margin_right = margin
	var v := margin if vertical_margin < 0 else vertical_margin
	style.content_margin_top = v
	style.content_margin_bottom = v
	style.anti_aliasing = true
	return style


static func _dot(color: Color, radius: int) -> ImageTexture:
	var size := radius * 2 + 4
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center := Vector2(size * 0.5, size * 0.5)
	for y in size:
		for x in size:
			var d := Vector2(x + 0.5, y + 0.5).distance_to(center)
			var edge := clampf(radius - d + 0.5, 0.0, 1.0)
			var ring := clampf(radius - 3.0 - d + 0.5, 0.0, 1.0)
			var c := color.lerp(Color("#edf1ec"), 1.0 - ring) if d <= radius else color
			image.set_pixel(x, y, Color(c, edge))
	return ImageTexture.create_from_image(image)
