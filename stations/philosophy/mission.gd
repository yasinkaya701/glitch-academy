extends "res://scripts/mission.gd"
## Fikir Meydanı (Felsefe) görevi.
## Kullanıcıya çoktan seçmeli şık verilmez: oyuncu doğrudan cümlesini yazar veya mikrofona konuşur;
## arka plandaki LLM / PhilosopherBrain yanıtı analiz ederek sahnedeki tetiklemeleri
## (stir, glimmer, dawn, recalled, wrong, angry_leave, chat) çalıştırır.

const ConversationStageScript = preload("res://stations/philosophy/visual/conversation_stage.gd")
const PhilosopherBrainScript = preload("res://stations/philosophy/visual/philosopher_brain.gd")
const PhilosopherActorScript = preload("res://stations/philosophy/visual/philosopher_actor.gd")
const Hud = preload("res://stations/philosophy/visual/philosophy_hud.gd")
const UITheme = preload("res://scripts/ui_theme.gd")

const ORDER: Array[StringName] = [&"socrates", &"plato", &"aristotle", &"epicurus", &"kindi", &"farabi", &"ibn_sina", &"ibn_rushd"]
const NAMES := {
	&"socrates": "Sokrates", &"plato": "Platon", &"aristotle": "Aristoteles", &"epicurus": "Epiküros",
	&"kindi": "el-Kindî", &"farabi": "el-Fârâbî", &"ibn_sina": "İbn Sînâ", &"ibn_rushd": "İbn Rüşd",
}
const NOTES := {
	&"socrates": "Sokrates (MÖ 469–399, Atina) · Bilgisizliğin farkındalığı, soruyla doğurtma (maiotik) ve erdem=bilgi ilkesi. (Temsili görsel)",
	&"plato": "Platon (MÖ 427–347, Atina) · İdealar kuramı, mağara alegorisi ve Akademia. (Temsili görsel)",
	&"aristotle": "Aristoteles (MÖ 384–322) · Mantık, dört neden, madde-form ve altın orta. (Temsili görsel)",
	&"epicurus": "Epiküros (MÖ 341–270) · Ruh dinginliği (ataraksia), ölçülü haz ve atomculuk. (Temsili görsel)",
	&"kindi": "el-Kindî (801–873, Bağdat) · İslam felsefesinin kurucusu, akıl ve vahiy uyumu. (Temsili görsel)",
	&"farabi": "el-Fârâbî (872–950) · Muallim-i Sânî, Erdemli Şehir ve mantık sınıflandırması. (Temsili görsel)",
	&"ibn_sina": "İbn Sînâ (980–1037) · Zorunlu-mümkün varlık ayrımı, Uçan Adam ve el-Kânûn fi't-Tıbb. (Temsili görsel)",
	&"ibn_rushd": "İbn Rüşd (1126–1198, Kurtuba) · Aristoteles şerhleri ve hakikatin birliği. (Temsili görsel)",
}
const FALLBACK_LINES := [
	"Zihnim sis içinde… Ben kimim?",
	"Aa… kafamın içinde bir şey kımıldadı.",
	"Evet… bunu bir yerden biliyorum.",
	"Dur, söyleme, hatırlıyorum!",
	"Şimdi hatırlıyorum: bilmediğimi biliyorum.",
]

var stage: ConversationStage
var brain: PhilosopherBrain
var hud: Hud
var _player_quote := Label.new()
var _quote_card := PanelContainer.new()
var _chat_row := VBoxContainer.new()
var _entry_row := HBoxContainer.new()
var _action_row := HBoxContainer.new()
var _input_box := LineEdit.new()
var _send_btn := Button.new()
var _mic_btn := Button.new()
var _play_title: Label
var _play_title_original_text := ""

var _index: int = 0
var _stage_level: int = 0
var _anger: float = 0.0
var _used_choices: Array[String] = []
var _failed: bool = false


func _ready() -> void:
	if get_tree().root.theme == null:
		get_tree().root.theme = UITheme.build_gameplay()
	set_anchors_preset(Control.PRESET_FULL_RECT)

	stage = ConversationStageScript.new()
	stage.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(stage)

	brain = PhilosopherBrainScript.new()
	add_child(brain)
	brain.response_ready.connect(apply_llm_trigger)

	stage.voice.speech_recognized.connect(_on_speech_recognized)

	hud = Hud.new()
	add_child(hud)
	hud.action_pressed.connect(_on_action_pressed)
	hud.skip_pressed.connect(func() -> void: _pick((_index + 1) % ORDER.size()))
	hud.skip.text = "Sonraki filozof"
	hud.skip.show()

	_build_dialogue_controls()
	_apply_display_title()
	tree_exiting.connect(_restore_display_title)

	var args := OS.get_cmdline_user_args()
	for a in args:
		if a.begins_with("--who="):
			_index = maxi(ORDER.find(StringName(a.substr(6))), 0)
	_pick(_index)

	for a in args:
		if a.begins_with("--demo"):
			_run_demo()


func _build_dialogue_controls() -> void:
	var font_cinzel_display := preload("res://fonts/CinzelDecorative-Bold.ttf")
	var font_marcellus := preload("res://fonts/Marcellus-Regular.ttf")
	var font_body: Font = UITheme.FONT

	if hud != null:
		hud.counter.add_theme_font_override("font", font_cinzel_display)
		hud.counter.add_theme_font_size_override("font_size", 16)
		hud.counter.add_theme_color_override("font_color", UITheme.GAME_TEXT)
		hud.directive.add_theme_font_override("font", font_body)
		hud.directive.add_theme_font_size_override("font_size", 18)
		hud.directive.add_theme_color_override("font_color", UITheme.GAME_TEXT)
		if hud.info_label != null:
			hud.info_label.add_theme_font_override("font", font_marcellus)
			hud.info_label.add_theme_color_override("font_color", UITheme.GAME_TEXT)

	_player_quote.add_theme_font_override("font", font_body)
	_player_quote.add_theme_font_size_override("font_size", 16)
	_player_quote.add_theme_color_override("font_color", UITheme.GAME_TEXT)
	_player_quote.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_player_quote.visible = false
	_player_quote.max_lines_visible = 3
	_quote_card.clip_contents = true
	_player_quote.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_quote_card.add_child(_player_quote)
	_quote_card.visible = false
	var quote_surface := StyleBoxFlat.new()
	quote_surface.bg_color = UITheme.GAME_PANEL
	quote_surface.border_color = UITheme.GAME_EDGE
	quote_surface.set_border_width_all(1)
	quote_surface.set_corner_radius_all(8)
	quote_surface.content_margin_left = 14
	quote_surface.content_margin_right = 14
	quote_surface.content_margin_top = 10
	quote_surface.content_margin_bottom = 10
	_quote_card.add_theme_stylebox_override("panel", quote_surface)
	stage.choice_slot.add_child(_quote_card)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 8)
	stage.choice_slot.add_child(spacer)

	_chat_row.add_theme_constant_override("separation", 8)
	_entry_row.add_theme_constant_override("separation", 8)
	_action_row.add_theme_constant_override("separation", 8)
	_action_row.alignment = BoxContainer.ALIGNMENT_BEGIN

	_input_box.placeholder_text = "Düşünceni veya sözünü yaz…"
	_input_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_input_box.custom_minimum_size = Vector2(0, 44)
	_input_box.add_theme_font_override("font", font_body)
	_input_box.add_theme_font_size_override("font_size", 16)
	_input_box.add_theme_color_override("font_color", UITheme.GAME_TEXT)
	_input_box.add_theme_color_override("font_placeholder_color", UITheme.GAME_MUTED)
	_input_box.text_submitted.connect(_on_text_submitted)

	var normal_sb := StyleBoxFlat.new()
	normal_sb.bg_color = UITheme.GAME_RAISED
	normal_sb.border_color = UITheme.GAME_EDGE
	normal_sb.set_border_width_all(1)
	normal_sb.set_corner_radius_all(7)
	normal_sb.content_margin_left = 14
	normal_sb.content_margin_right = 14
	normal_sb.content_margin_top = 8
	normal_sb.content_margin_bottom = 8
	_input_box.add_theme_stylebox_override("normal", normal_sb)

	var focus_sb := normal_sb.duplicate() as StyleBoxFlat
	focus_sb.border_color = UITheme.GAME_ACCENT
	focus_sb.set_border_width_all(2)
	_input_box.add_theme_stylebox_override("focus", focus_sb)
	_entry_row.add_child(_input_box)

	var btn_sb := StyleBoxFlat.new()
	btn_sb.bg_color = UITheme.GAME_RAISED
	btn_sb.border_color = UITheme.GAME_EDGE
	btn_sb.set_border_width_all(1)
	btn_sb.set_corner_radius_all(7)
	btn_sb.content_margin_left = 16
	btn_sb.content_margin_right = 16
	btn_sb.content_margin_top = 8
	btn_sb.content_margin_bottom = 8

	var btn_hover := btn_sb.duplicate() as StyleBoxFlat
	btn_hover.bg_color = UITheme.GAME_RAISED.lightened(0.08)
	btn_hover.border_color = UITheme.GAME_ACCENT

	_send_btn.text = "Söyle"
	_send_btn.custom_minimum_size = Vector2(112, 44)
	_send_btn.add_theme_font_override("font", font_cinzel_display)
	_send_btn.add_theme_font_size_override("font_size", 13)
	_send_btn.add_theme_color_override("font_color", UITheme.GAME_BG)
	var send_sb := btn_sb.duplicate() as StyleBoxFlat
	send_sb.bg_color = UITheme.GAME_ACCENT
	send_sb.border_color = UITheme.GAME_ACCENT
	var send_hover := send_sb.duplicate() as StyleBoxFlat
	send_hover.bg_color = UITheme.GAME_ACCENT.lightened(0.1)
	send_hover.border_color = send_hover.bg_color
	_send_btn.add_theme_stylebox_override("normal", send_sb)
	_send_btn.add_theme_stylebox_override("hover", send_hover)
	_send_btn.add_theme_stylebox_override("pressed", send_hover)
	_send_btn.pressed.connect(func() -> void: _on_text_submitted(_input_box.text))
	_action_row.add_child(_send_btn)

	_mic_btn.text = "Mikrofon (V)"
	_mic_btn.custom_minimum_size = Vector2(152, 44)
	_mic_btn.add_theme_font_override("font", font_body)
	_mic_btn.add_theme_font_size_override("font_size", 14)
	_mic_btn.add_theme_color_override("font_color", UITheme.GAME_WARM)
	_mic_btn.add_theme_stylebox_override("normal", btn_sb)
	_mic_btn.add_theme_stylebox_override("hover", btn_hover)
	_mic_btn.add_theme_stylebox_override("pressed", btn_hover)
	_mic_btn.pressed.connect(_on_mic_pressed)
	_action_row.add_child(_mic_btn)
	_chat_row.add_child(_entry_row)
	_chat_row.add_child(_action_row)

	stage.choice_slot.add_child(_chat_row)
	stage.resized.connect(_layout_dialogue_controls)
	_layout_dialogue_controls()


func _layout_dialogue_controls() -> void:
	if stage == null or stage.choice_slot == null:
		return
	var stage_size := stage.size
	var compact := stage_size.x < 700.0 or stage_size.y < 700.0
	var safe_width := maxf(240.0, stage_size.x - 40.0)
	var slot_width := minf(safe_width, 640.0 if not compact else 500.0)
	var quote_height := 42.0 if stage_size.y < 460.0 else (52.0 if stage_size.y < 560.0 else (62.0 if stage_size.y < 620.0 else (74.0 if compact else 90.0)))
	var controls_height := (96.0 if stage_size.y < 560.0 else 100.0) if compact else 112.0
	_player_quote.max_lines_visible = 1 if stage_size.y < 460.0 else (2 if compact else 3)
	stage.set_dialogue_layout(compact, slot_width)
	_quote_card.custom_minimum_size = Vector2(slot_width, 0.0)
	_player_quote.custom_minimum_size = Vector2(slot_width - 32.0, quote_height - 20.0)
	_entry_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_input_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_input_box.custom_minimum_size.x = 0.0
	_action_row.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_send_btn.custom_minimum_size.x = 100.0 if compact else 112.0
	_mic_btn.custom_minimum_size.x = 132.0 if compact else 152.0
	_chat_row.custom_minimum_size = Vector2(slot_width, controls_height)
	var line_bottom: float = stage.dialogue_line_bottom()
	var slot_height := quote_height + controls_height + 30.0
	var bottom_safe := 32.0 if stage_size.y < 460.0 else (44.0 if stage_size.y < 620.0 else (56.0 if compact else 84.0))
	var desired_y := stage_size.y * (0.57 if compact else 0.65)
	var available_y := maxf(stage_size.y - slot_height - bottom_safe, 0.0)
	var safe_top := line_bottom + 12.0
	stage.choice_slot.position = Vector2(32.0, maxf(safe_top, minf(desired_y, available_y)))
	stage.choice_slot.size = Vector2(slot_width, slot_height)
	stage.choice_slot.add_theme_constant_override("separation", 10)


func _process(_delta: float) -> void:
	if stage == null or hud == null or not is_instance_valid(hud.directive):
		return
	if stage.set_top_inset(hud.directive.position.y + hud.directive.size.y + 10.0):
		_layout_dialogue_controls()


func _apply_display_title() -> void:
	var found := get_tree().root.find_child("PlayTitle", true, false)
	_play_title = found as Label
	if _play_title == null:
		return
	_play_title_original_text = _play_title.text
	_play_title.add_theme_font_override("font", preload("res://fonts/Cinzel-Regular.ttf"))
	_play_title.add_theme_font_size_override("font_size", 18)
	_play_title.add_theme_color_override("font_color", Color("#202118"))
	_update_display_title()


func _update_display_title() -> void:
	if is_instance_valid(_play_title):
		var id: StringName = ORDER[_index]
		_play_title.text = "FİKİR MEYDANI  ·  FİLOZOF %d/%d · %s" % [_index + 1, ORDER.size(), NAMES[id].to_upper()]


func _restore_display_title() -> void:
	if is_instance_valid(_play_title):
		_play_title.text = _play_title_original_text
		_play_title.remove_theme_font_override("font")
		_play_title.remove_theme_font_size_override("font_size")
		_play_title.remove_theme_color_override("font_color")


func _unhandled_key_input(event: InputEvent) -> void:
	var e := event as InputEventKey
	if e == null or not e.pressed or e.echo:
		return
	if _input_box.has_focus():
		if e.keycode == KEY_ESCAPE:
			_input_box.release_focus()
		return
	match e.keycode:
		KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6, KEY_7, KEY_8:
			_pick(e.keycode - KEY_1)
		KEY_V:
			_on_mic_pressed()
		KEY_SPACE:
			_speak_stage_line(_stage_level)
		KEY_M:
			_set_level(_stage_level + 1)
		KEY_N:
			_set_level(_stage_level - 1)
		KEY_A:
			apply_llm_trigger({"trigger": "wrong", "reply_id": "wrong_sofist"})
		KEY_S:
			_anger = clampf(_anger - 0.25, 0.0, 1.0)
			stage.set_anger(_anger)
		KEY_R:
			if stage.has_node("PhilosopherActor"):
				stage.get_node("PhilosopherActor").call("play_reaction", &"stir")
		KEY_E:
			apply_llm_trigger({"trigger": "angry_leave", "reply_id": "angry_leave"})
		KEY_X:
			_pick(_index)


func _pick(i: int) -> void:
	_index = clampi(i, 0, ORDER.size() - 1)
	var id: StringName = ORDER[_index]
	_stage_level = 0
	_anger = 0.0
	_failed = false
	_used_choices.clear()
	_input_box.text = ""
	_player_quote.visible = false
	_quote_card.visible = false
	_chat_row.visible = true
	hud.clear_tools()

	stage.show_philosopher(id, 4)
	hud.set_steps(0, 4, "BELLEK")
	_update_display_title()
	hud.set_directive("%s ile konuşarak unuttuğu 4 temel fikri hatırlat." % NAMES[id])
	hud.set_note(NOTES.get(id, ""))
	hud.set_action("")
	_speak_stage_line(0)


func _on_text_submitted(raw_text: String) -> void:
	var clean: String = raw_text.strip_edges()
	if clean == "" or _failed:
		return
	_input_box.text = ""
	_input_box.release_focus()
	_player_quote.text = "Siz: “%s”" % (clean.substr(0, 180) + ("…" if clean.length() > 180 else ""))
	_player_quote.visible = true
	_quote_card.visible = true
	_layout_dialogue_controls()
	stage.actor.set_mood(&"thinking")
	var id: StringName = ORDER[_index]
	brain.ask(
		id,
		clean,
		_stage_level,
		_anger,
		_used_choices,
		stage.voice.get_choices(id),
		stage.voice.get_lines(id)
	)


func _on_mic_pressed() -> void:
	if _failed or _stage_level >= 4 or stage.voice.is_listening():
		return
	stage.voice.stop()
	if stage.voice.listen_microphone(4.2):
		_mic_btn.text = "Dinleniyor…"
		_mic_btn.disabled = true
		hud.say("Mikrofona Türkçe konuşun…", &"neutral")


func _on_speech_recognized(ok: bool, text: String) -> void:
	_mic_btn.text = "Mikrofon (V)"
	_mic_btn.disabled = false
	if not ok or text == "":
		hud.say("Ses anlaşılamadı; tekrar konuşun veya cümlenizi yazın.", &"bad")
		return
	_input_box.text = text
	_on_text_submitted(text)


## Arka plandaki LLM veya dış servis tarafından döndürülen tetikleyiciyi sahneye uygular.
## Desteklenen trigger değerleri:
##   "stir" | "glimmer" | "dawn" | "recalled" | "correct" -> hafıza aşamasını ilerletir ve ilgili tepkiyi oynatır
##   "wrong"       -> öfkeyi artırır ve itiraz tepkisini oynatır
##   "angry_leave" -> filozof öfkeyle meydanı terk eder, görev başarısız olur
##   "chat"        -> filozof kendi üslubuyla yanıt verir ve konuşmayı sürdürür
func apply_llm_trigger(result: Dictionary) -> void:
	if _failed:
		return
	var trig: String = String(result.get("trigger", result.get("verdict", "chat")))
	var pts: int = maxi(int(result.get("points", 2)), 2)
	var cid: String = String(result.get("choice_id", ""))
	var reply_id: String = String(result.get("reply_id", ""))
	var reply_text: String = String(result.get("reply_text", ""))
	var mood_name: StringName = StringName(String(result.get("mood", "smile")))
	var id: StringName = ORDER[_index]

	if trig in ["stir", "glimmer", "dawn", "recalled", "correct"]:
		if cid != "" and not _used_choices.has(cid):
			_used_choices.append(cid)
		_anger = maxf(_anger - 0.25, 0.0)
		stage.set_anger(_anger)
		var was_completed: bool = (_stage_level >= 4)
		_stage_level = clampi(_stage_level + pts, 1, 4)
		stage.set_memory_stage(_stage_level)
		hud.set_steps(_stage_level, 4, "ONARILDI" if _stage_level >= 4 else "BELLEK")

		if reply_text != "":
			stage.show_line(NAMES[id], reply_text)
			stage.voice.speak_live(id, reply_text, &"llm_ok")
		elif reply_id != "" and stage.voice.get_line_text(id, StringName(reply_id)) != "":
			stage.speak_line(NAMES[id], StringName(reply_id))
		else:
			_speak_stage_line(_stage_level)

		if _stage_level >= 4:
			hud.set_steps(4, 4, "ONARILDI")
			hud.set_directive("%s kendi felsefesini tamamen hatırladı! Sohbete devam edebilir veya sonraki filozofa geçebilirsin." % NAMES[id])
			hud.say("Sonuca ulaşıldı — %s tamamen uyandı!" % NAMES[id], &"good")
			hud.set_action("Yeniden Dene")
			if not was_completed:
				completed.emit()
		else:
			hud.say("Doğru söz! Hafızası hızla açılıyor (%d/4)." % _stage_level, &"good")
	elif trig == "angry_leave":
		_anger = 1.0
		stage.set_anger(_anger)
		_failed = true
		_chat_row.visible = false
		stage.actor.play_reaction(&"refuse")
		if stage.voice.get_line_text(id, &"angry_leave") != "":
			stage.speak_line(NAMES[id], &"angry_leave")
		elif reply_text != "":
			stage.show_line(NAMES[id], reply_text)
			stage.voice.speak_live(id, reply_text, &"llm_leave")
		else:
			stage.show_line(NAMES[id], "Beni kendi fikirlerimden uzaklaştırdın; tartışmayı bırakıyorum!")
		stage.actor.exit_angry(1.4)
		hud.set_directive("%s öfkeyle meydandan ayrıldı." % NAMES[id])
		hud.say("Sabrı tükendi — görev başarısız.", &"bad")
		hud.set_action("Yeniden Dene")
	elif trig == "wrong":
		_anger = clampf(_anger + 0.50, 0.0, 1.0)
		stage.set_anger(_anger)
		if _anger >= 1.0:
			apply_llm_trigger({"trigger": "angry_leave", "reply_id": "angry_leave", "reply_text": reply_text})
			return
		stage.actor.play_reaction(&"refuse")
		hud.say("Bu fikir ona ait değil — öfkelendi.", &"bad")
		if reply_id != "" and stage.voice.get_line_text(id, StringName(reply_id)) != "":
			stage.speak_line(NAMES[id], StringName(reply_id))
		elif reply_text != "":
			stage.show_line(NAMES[id], reply_text)
			stage.voice.speak_live(id, reply_text, &"llm_wrong")
		else:
			stage.show_line(NAMES[id], "Hayır! Bu fikir bana ait değil; beni dinlemiyorsun!")
	else:
		stage.actor.set_mood(mood_name)
		if reply_id != "" and stage.voice.get_line_text(id, StringName(reply_id)) != "":
			stage.speak_line(NAMES[id], StringName(reply_id))
		elif reply_text != "":
			stage.show_line(NAMES[id], reply_text)
			stage.voice.speak_live(id, reply_text, &"llm_chat")


func _on_action_pressed() -> void:
	_pick(_index)


func _set_level(level: int, custom_line_id: StringName = &"") -> void:
	_stage_level = clampi(level, 0, 4)
	var id: StringName = ORDER[_index]
	stage.set_memory_stage(_stage_level)
	hud.set_steps(_stage_level, 4, "ONARILDI" if _stage_level >= 4 else "BELLEK")
	if _stage_level >= 4:
		_chat_row.visible = false
	_speak_stage_line(_stage_level, custom_line_id)


func _speak_stage_line(level: int, custom_line_id: StringName = &"") -> void:
	var id: StringName = ORDER[_index]
	var lid: StringName = custom_line_id if custom_line_id != &"" else StringName("stage_%d" % level)
	if stage.voice.get_line_text(id, lid) != "":
		stage.speak_line(NAMES[id], lid)
	else:
		var fallback: String = FALLBACK_LINES[clampi(level, 0, FALLBACK_LINES.size() - 1)]
		stage.show_line(NAMES[id], fallback)
		stage.voice.speak_live(id, fallback, lid)


func _type_and_send(msg: String) -> void:
	_input_box.text = ""
	for i in msg.length():
		_input_box.text = msg.substr(0, i + 1)
		await get_tree().create_timer(0.032).timeout
	await get_tree().create_timer(0.30).timeout
	_on_text_submitted(msg)


func _run_demo() -> void:
	_pick(ORDER.find(&"socrates"))
	await get_tree().create_timer(6.2).timeout
	await _type_and_send("Bildiğin tek şey hiçbir şey bilmediğindir")
	await get_tree().create_timer(8.4).timeout
	await _type_and_send("Sorularla doğruyu doğurtma, yani maiotik yöntemi")
	await get_tree().create_timer(6.5).timeout
	await _type_and_send("Erdem bilgidir, kimse bilerek kötülük yapmaz")
	await get_tree().create_timer(8.0).timeout
	await _type_and_send("Sorgulanmamış hayat yaşanmaya değmez")
