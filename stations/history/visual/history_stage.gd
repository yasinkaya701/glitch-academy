class_name HistoryStage
extends Control
## Historical sources on a quiet archive surface. Text and art occupy separate columns.

const ActorScript = preload("res://stations/history/visual/history_actor.gd")
const VoicePlayerScript = preload("res://stations/history/visual/voice_player.gd")
const MemoryRingScript = preload("res://stations/history/visual/memory_ring.gd")
const UI = preload("res://scripts/ui_theme.gd")

var actor: Node2D
var ring: Control
var voice: Node
var choice_slot := VBoxContainer.new()
var _choice_scroll := ScrollContainer.new()

var _backdrop_rect := ColorRect.new()
var _art_panel := Panel.new()
var _source_label := RichTextLabel.new()
var _inspect_button := Button.new()
var _speaker_label := Label.new()
var _line_label := Label.new()
var _line_group := VBoxContainer.new()
var _line_tween: Tween
var _current_id: StringName = &"mete_han"
var _viewer := PanelContainer.new()
var _viewer_image := TextureRect.new()
var _viewer_caption := Label.new()
var _art_area := Rect2()


func _ready() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_backdrop_rect.color = UI.GAME_BG
	_backdrop_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_backdrop_rect)
	_art_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := StyleBoxFlat.new()
	mat.bg_color = UI.GAME_PANEL
	mat.border_color = UI.GAME_EDGE
	mat.set_border_width_all(1)
	_art_panel.add_theme_stylebox_override("panel", mat)
	add_child(_art_panel)
	ring = MemoryRingScript.new()
	ring.hide()
	add_child(ring)
	actor = ActorScript.new()
	add_child(actor)
	voice = VoicePlayerScript.new()
	add_child(voice)
	voice.bind_actor(actor)
	_build_line_ui()
	_build_source_ui()
	_build_viewer()
	resized.connect(_layout)
	_layout()


func show_philosopher(id: StringName, star_count: int = 4) -> bool:
	_current_id = id
	_viewer.hide()
	voice.stop()
	var ok: bool = actor.load_philosopher(id)
	ring.count = star_count
	ring.set_lit_count(0, false)
	_inspect_button.disabled = not ok
	var meta: Dictionary = actor.get_metadata() if ok else {}
	_source_label.text = "[b]%s[/b]\n%s\n%s\n%s\n[url=%s]Görsel kaynağı[/url]  ·  [url=%s]%s[/url]" % [
		meta.get("caption", "Görsel bulunamadı"), meta.get("credit", ""),
		meta.get("collection", ""), meta.get("nature", ""),
		meta.get("source_url", ""), meta.get("license_url", ""), meta.get("license", "")]
	_layout()
	return ok


func _build_source_ui() -> void:
	_source_label.bbcode_enabled = true
	_source_label.scroll_active = true
	_source_label.add_theme_font_override("normal_font", UI.FONT)
	_source_label.add_theme_font_override("bold_font", UI.FONT)
	_source_label.add_theme_font_size_override("normal_font_size", 14)
	_source_label.add_theme_font_size_override("bold_font_size", 15)
	_source_label.add_theme_color_override("default_color", UI.GAME_MUTED)
	_source_label.meta_clicked.connect(func(url: Variant) -> void:
		if String(url).begins_with("https://"):
			OS.shell_open(String(url)))
	add_child(_source_label)
	_inspect_button.text = "Eseri incele"
	_inspect_button.add_theme_font_override("font", UI.FONT)
	_inspect_button.add_theme_font_size_override("font_size", 14)
	_inspect_button.pressed.connect(_show_viewer)
	add_child(_inspect_button)


func _build_viewer() -> void:
	_viewer.z_index = 50
	var style := StyleBoxFlat.new()
	style.bg_color = UI.GAME_BG
	style.border_color = UI.GAME_EDGE
	style.set_border_width_all(1)
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 16
	style.content_margin_bottom = 16
	_viewer.add_theme_stylebox_override("panel", style)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	_viewer.add_child(column)
	var top := HBoxContainer.new()
	_viewer_caption.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_viewer_caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_viewer_caption.add_theme_color_override("font_color", UI.GAME_TEXT)
	top.add_child(_viewer_caption)
	var close := Button.new()
	close.text = "Kapat"
	close.pressed.connect(func() -> void: _viewer.hide())
	top.add_child(close)
	column.add_child(top)
	_viewer_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_viewer_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_viewer_image.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_viewer_image.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	column.add_child(_viewer_image)
	_viewer.hide()
	add_child(_viewer)


func _show_viewer() -> void:
	var meta: Dictionary = actor.get_metadata()
	_viewer_image.texture = load(meta["image"]) as Texture2D
	_viewer_caption.text = "%s\n%s · %s" % [meta["caption"], meta["credit"], meta["license"]]
	_viewer.show()


func show_line(speaker: String, text: String) -> void:
	_speaker_label.text = "%s · Kurgusal diyalog" % speaker
	_line_label.text = text
	if _line_tween != null and _line_tween.is_valid():
		_line_tween.kill()
	_line_group.show()
	_line_group.modulate.a = 1.0


func speak_line(speaker: String, line_id: StringName) -> void:
	var text: String = voice.play_line(_current_id, line_id)
	if not text.is_empty():
		show_line(speaker, text)


func hide_line() -> void:
	_line_group.hide()


func set_memory_stage(stage: int, animate: bool = true) -> void:
	actor.set_memory_stage(stage, animate)
	ring.set_lit_count(clampi(stage, 0, 4) * ring.count / 4, animate)
	ring.set_repaired(stage >= 4, animate)


func set_anger(value: float, animate: bool = true) -> void:
	actor.set_anger(value, animate)


func _build_line_ui() -> void:
	_line_group.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_line_group.add_theme_constant_override("separation", 12)
	_speaker_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_speaker_label.add_theme_font_override("font", UI.FONT)
	_speaker_label.add_theme_font_size_override("font_size", 16)
	_speaker_label.add_theme_color_override("font_color", UI.GAME_ACCENT)
	_line_label.add_theme_font_override("font", UI.FONT)
	_line_label.add_theme_font_size_override("font_size", 22)
	_line_label.add_theme_color_override("font_color", UI.GAME_TEXT)
	_line_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_line_group.add_child(_speaker_label)
	_line_group.add_child(_line_label)
	_line_group.hide()
	add_child(_line_group)
	choice_slot.mouse_filter = Control.MOUSE_FILTER_PASS
	choice_slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	choice_slot.add_theme_constant_override("separation", 8)
	_choice_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_choice_scroll.add_child(choice_slot)
	add_child(_choice_scroll)


func _layout() -> void:
	if actor == null:
		return
	var w := size.x
	var h := size.y
	_backdrop_rect.size = size
	var margin := 32.0 if w >= 920 else 20.0
	# The portrait fits inside its area; no per-frame zoom can override this fit.
	var right_x := w * 0.57
	var art_width := w - right_x - margin
	var art_top := 110.0
	var art_bottom := maxf(art_top + 80, h - 188.0)
	_art_area = Rect2(right_x, art_top, art_width, art_bottom - art_top)
	_art_panel.position = _art_area.position - Vector2(10, 10)
	_art_panel.size = _art_area.size + Vector2(20, 20)
	actor.position = Vector2(_art_area.get_center().x, art_bottom)
	actor.fit_to_box(_art_area.size)
	_source_label.position = Vector2(right_x, art_bottom + 22)
	_source_label.size = Vector2(art_width, 116)
	_inspect_button.position = Vector2(right_x, h - 42)
	_inspect_button.size = Vector2(132, 30)
	_line_group.position = Vector2(margin, 120)
	_line_group.size = Vector2(right_x - margin * 2, 150)
	_choice_scroll.position = Vector2(margin, 292)
	_choice_scroll.size = Vector2(right_x - margin * 2, maxf(100, h - 308))
	if w < 920:
		_art_area = Rect2(margin, 144, w * 0.36, 166)
		_art_panel.position = _art_area.position - Vector2(6, 6)
		_art_panel.size = _art_area.size + Vector2(12, 12)
		actor.position = Vector2(_art_area.get_center().x, _art_area.end.y)
		actor.fit_to_box(_art_area.size)
		_source_label.position = Vector2(w * 0.43, 144)
		_source_label.size = Vector2(w * 0.57 - margin, 120)
		_inspect_button.position = Vector2(w * 0.43, 280)
		_line_group.position = Vector2(margin, 330)
		_line_group.size = Vector2(w - margin * 2, 120)
		_choice_scroll.position = Vector2(margin, 460)
		_choice_scroll.size = Vector2(w - margin * 2, maxf(100, h - 476))
	_viewer.position = Vector2(16, 96)
	_viewer.size = Vector2(maxf(w - 32, 100), maxf(h - 112, 100))
