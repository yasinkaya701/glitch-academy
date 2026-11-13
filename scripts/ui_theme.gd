extends Node
## Ortak arayüz teması. Tüm oyun bu temayı kullanır, istasyonlar kendi düğme veya panel stilini çizmez.
## Renkler docs/ART_DIRECTION.md paletinden. Özel türler: PrimaryButton, DangerButton, HeadlineLabel,
## SectionLabel, MutedLabel, GlassPanel, ConsolePanel.

const FONT = preload("res://assets/fonts/Inter.ttf")
const DISPLAY_FONT = preload("res://assets/fonts/YanlisDunyaMeridian-Display.ttf")

const BG := Color("#070b12")
const PANEL := Color("#0f1824")
const PANEL_RAISED := Color("#162538")
const EDGE := Color("#2c4560")
const EDGE_STRONG := Color("#41627f")
const INK := Color("#e8f1f2")
const MUTED := Color("#8fa6b3")
const ACCENT := Color("#6fe3c1")
const WARM := Color("#f2a65a")
const DANGER := Color("#e5645a")
const GOOD := Color("#a0dfbc")


func _ready() -> void:
	get_tree().root.theme = build()


static func build() -> Theme:
	var theme := Theme.new()
	var regular := FontVariation.new()
	regular.base_font = FONT
	regular.variation_opentype = {"wght": 450}
	var semibold := FontVariation.new()
	semibold.base_font = FONT
	semibold.variation_opentype = {"wght": 650}
	var display := FontVariation.new()
	display.base_font = DISPLAY_FONT
	theme.default_font = regular
	theme.default_font_size = 15

	# Label
	theme.set_color("font_color", "Label", INK)
	theme.set_type_variation("HeadlineLabel", "Label")
	theme.set_font("font", "HeadlineLabel", display)
	theme.set_font_size("font_size", "HeadlineLabel", 24)
	theme.set_type_variation("SectionLabel", "Label")
	theme.set_font("font", "SectionLabel", semibold)
	theme.set_font_size("font_size", "SectionLabel", 12)
	theme.set_color("font_color", "SectionLabel", ACCENT)
	theme.set_type_variation("MutedLabel", "Label")
	theme.set_color("font_color", "MutedLabel", MUTED)

	# Düğmeler
	_button(theme, "Button", PANEL_RAISED, EDGE, INK)
	theme.set_font("font", "Button", semibold)
	theme.set_type_variation("PrimaryButton", "Button")
	_button(theme, "PrimaryButton", Color("#c98638"), Color("#f2a65a"), Color("#1a1006"))
	theme.set_font("font", "PrimaryButton", semibold)
	theme.set_type_variation("DangerButton", "Button")
	_button(theme, "DangerButton", Color("#5a2420"), DANGER, INK)
	# Meridian cihaz düğmeleri (Codex): 9 dilimli, ortası uzar, kesik köşe ve yan ray sabit kalır.
	_texture_button(theme, "Button", "btn")
	_texture_button(theme, "PrimaryButton", "btn_primary")

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
	var track := _flat(Color("#1b2c3f"), Color(0, 0, 0, 0), 0, 3, 0)
	track.content_margin_top = 3
	track.content_margin_bottom = 3
	theme.set_stylebox("slider", "HSlider", track)
	theme.set_stylebox("grabber_area", "HSlider", _flat(ACCENT, Color(0, 0, 0, 0), 0, 3, 0))
	theme.set_stylebox("grabber_area_highlight", "HSlider", _flat(Color("#9af1da"), Color(0, 0, 0, 0), 0, 3, 0))
	theme.set_icon("grabber", "HSlider", _dot(ACCENT, 11))
	theme.set_icon("grabber_highlight", "HSlider", _dot(Color("#ffffff"), 12))
	theme.set_icon("grabber_disabled", "HSlider", _dot(EDGE, 10))

	# Giriş kutusu
	theme.set_stylebox("normal", "LineEdit", _flat(Color("#0a121d"), EDGE, 1, 6, 10))
	theme.set_stylebox("focus", "LineEdit", _flat(Color("#0a121d"), ACCENT, 2, 6, 10))
	theme.set_stylebox("read_only", "LineEdit", _flat(Color("#0d1623"), EDGE, 1, 6, 10))
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
	theme.set_stylebox("panel", "CampaignDock", _texture_box("res://assets/ui/panel_info.png", 24, 24, 76, 24, 24, 48, 92, 28))

	# Liste
	theme.set_stylebox("panel", "ItemList", _flat(Color(PANEL, 0.7), EDGE, 1, 8, 6))
	theme.set_stylebox("focus", "ItemList", _flat(Color(0, 0, 0, 0), ACCENT, 1, 8, 0))
	theme.set_stylebox("hover", "ItemList", _texture_box("res://assets/ui/list_row_idle.png", 22, 22, 12, 12, 16, 16, 8, 8))
	theme.set_stylebox("selected", "ItemList", _texture_box("res://assets/ui/list_row_selected.png", 22, 22, 12, 12, 16, 16, 8, 8))
	theme.set_stylebox("selected_focus", "ItemList", _texture_box("res://assets/ui/list_row_selected.png", 22, 22, 12, 12, 16, 16, 8, 8))
	theme.set_color("font_color", "ItemList", MUTED)
	theme.set_color("font_selected_color", "ItemList", INK)
	theme.set_color("font_hovered_color", "ItemList", INK)
	theme.set_constant("v_separation", "ItemList", 4)
	theme.set_constant("line_separation", "ItemList", 2)

	# OptionButton
	theme.set_stylebox("normal", "OptionButton", _flat(PANEL_RAISED, EDGE, 1, 8, 12))
	theme.set_stylebox("hover", "OptionButton", _flat(Color("#1d3149"), EDGE_STRONG, 1, 8, 12))
	theme.set_stylebox("pressed", "OptionButton", _flat(Color("#122032"), ACCENT, 1, 8, 12))
	theme.set_color("font_color", "OptionButton", INK)

	# Kaydırma çubuğu
	var scroll := _flat(Color("#1b2c3f"), Color(0, 0, 0, 0), 0, 4, 0)
	theme.set_stylebox("scroll", "VScrollBar", scroll)
	theme.set_stylebox("grabber", "VScrollBar", _flat(EDGE_STRONG, Color(0, 0, 0, 0), 0, 4, 0))
	theme.set_stylebox("grabber_highlight", "VScrollBar", _flat(ACCENT, Color(0, 0, 0, 0), 0, 4, 0))
	theme.set_stylebox("grabber_pressed", "VScrollBar", _flat(ACCENT, Color(0, 0, 0, 0), 0, 4, 0))

	# İlerleme
	theme.set_stylebox("background", "ProgressBar", _flat(Color("#1b2c3f"), Color(0, 0, 0, 0), 0, 4, 0))
	theme.set_stylebox("fill", "ProgressBar", _flat(ACCENT, Color(0, 0, 0, 0), 0, 4, 0))
	return theme


static func _texture_button(theme: Theme, type_name: String, prefix: String) -> void:
	for state in ["normal", "hover", "pressed", "disabled"]:
		var path := "res://assets/ui/%s_%s.png" % [prefix, state]
		if not ResourceLoader.exists(path):
			return
		var box := StyleBoxTexture.new()
		box.texture = load(path)
		box.texture_margin_left = 26.0
		box.texture_margin_right = 26.0
		box.texture_margin_top = 16.0
		box.texture_margin_bottom = 16.0
		# Yan ray (sol) ve gösterge noktası (sağ) yazıya binmesin.
		box.content_margin_left = 36.0
		box.content_margin_right = 36.0
		box.content_margin_top = 10.0
		box.content_margin_bottom = 10.0
		theme.set_stylebox(state, type_name, box)
	if prefix == "btn_primary":
		# Dolgu koyu seramik: yazı açık krem (Codex dolgusu koyu, eski turuncu dolgu için koyu yazı geçersiz).
		for color_name in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
			theme.set_color(color_name, type_name, Color("#ffe2b8"))
		theme.set_color("font_disabled_color", type_name, Color("#ffe2b8", 0.4))


static func _texture_box(path: String, texture_left: float, texture_right: float, texture_top: float, texture_bottom: float, content_left: float, content_right: float, content_top: float, content_bottom: float) -> StyleBoxTexture:
	var box := StyleBoxTexture.new()
	box.texture = load(path)
	box.texture_margin_left = texture_left
	box.texture_margin_right = texture_right
	box.texture_margin_top = texture_top
	box.texture_margin_bottom = texture_bottom
	box.content_margin_left = content_left
	box.content_margin_right = content_right
	box.content_margin_top = content_top
	box.content_margin_bottom = content_bottom
	return box


static func _button(theme: Theme, type_name: String, fill: Color, edge: Color, text: Color) -> void:
	theme.set_stylebox("normal", type_name, _flat(fill, edge, 1, 8, 16, 9))
	theme.set_stylebox("hover", type_name, _flat(fill.lightened(0.12), edge.lightened(0.25), 1, 8, 16, 9))
	theme.set_stylebox("pressed", type_name, _flat(fill.darkened(0.2), edge, 1, 8, 16, 10))
	theme.set_stylebox("disabled", type_name, _flat(Color(fill, 0.35), Color(edge, 0.3), 1, 8, 16, 9))
	theme.set_stylebox("focus", type_name, _flat(Color(0, 0, 0, 0), ACCENT, 2, 8, 16, 9))
	theme.set_color("font_color", type_name, text)
	theme.set_color("font_hover_color", type_name, text)
	theme.set_color("font_pressed_color", type_name, text)
	theme.set_color("font_disabled_color", type_name, Color(text, 0.4))
	theme.set_color("font_focus_color", type_name, text)
	theme.set_color("icon_normal_color", type_name, text)
	var pressed_toggle := _flat(Color(ACCENT, 0.22), ACCENT, 2, 8, 16, 9)
	theme.set_stylebox("hover_pressed", type_name, pressed_toggle)
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
			var c := color.lerp(Color("#0a121d"), 1.0 - ring) if d <= radius else color
			image.set_pixel(x, y, Color(c, edge))
	return ImageTexture.create_from_image(image)
