extends "res://scripts/mission.gd"
## Fikir Meydanı (Felsefe) görevi.
## Kullanıcıya çoktan seçmeli şık verilmez: oyuncu doğrudan cümlesini yazar veya mikrofona konuşur;
## arka plandaki LLM / PhilosopherBrain yanıtı analiz ederek sahnedeki tetiklemeleri
## (stir, glimmer, dawn, recalled, wrong, angry_leave, chat) çalıştırır.

const ConversationStageScript = preload("res://stations/philosophy/visual/conversation_stage.gd")
const PhilosopherBrainScript = preload("res://stations/philosophy/visual/philosopher_brain.gd")
const PhilosopherActorScript = preload("res://stations/philosophy/visual/philosopher_actor.gd")
const Hud = preload("res://scripts/mission_hud.gd")
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
var _chat_row := HBoxContainer.new()
var _input_box := LineEdit.new()
var _send_btn := Button.new()
var _mic_btn := Button.new()
var _replay_btn := Button.new()
var _volume_slider := HSlider.new()
var _volume_label := Label.new()

var _index: int = 0
var _stage_level: int = 0
var _anger: float = 0.0
var _used_choices: Array[String] = []
var _failed: bool = false
var _waiting_reply: bool = false
var _completion_awaiting_voice: bool = false


func _ready() -> void:
	var shared_theme: Theme = UITheme.build()
	theme = shared_theme
	if get_tree().root.theme == null:
		get_tree().root.theme = shared_theme
	set_anchors_preset(Control.PRESET_FULL_RECT)

	stage = ConversationStageScript.new()
	stage.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(stage)

	brain = PhilosopherBrainScript.new()
	add_child(brain)
	brain.response_ready.connect(apply_llm_trigger)

	stage.voice.speech_recognized.connect(_on_speech_recognized)
	stage.voice.busy_changed.connect(func(_busy: bool) -> void: _refresh_dialogue_controls())
	stage.voice.line_finished.connect(_on_line_finished)
	stage.voice.line_failed.connect(_on_line_failed)

	hud = Hud.new()
	add_child(hud)
	hud.action_pressed.connect(_on_action_pressed)
	hud.skip_pressed.connect(func() -> void: _pick((_index + 1) % ORDER.size()))
	hud.skip.text = "Sonraki filozof"
	hud.skip.show()

	_build_dialogue_controls()

	var args := OS.get_cmdline_user_args()
	for a in args:
		if a.begins_with("--who="):
			_index = maxi(ORDER.find(StringName(a.substr(6))), 0)
	_pick(_index)

	for a in args:
		if a.begins_with("--demo"):
			_run_demo()


func _build_dialogue_controls() -> void:
	var font_cinzel: Font = UITheme.FONT
	var font_marcellus: Font = UITheme.FONT

	if hud != null:
		hud.directive.add_theme_font_override("font", font_cinzel)
		hud.directive.add_theme_font_size_override("font_size", 20)
		hud.directive.add_theme_color_override("font_color", UITheme.INK)
		if hud.info_label != null:
			hud.info_label.add_theme_font_override("font", font_marcellus)
			hud.info_label.add_theme_color_override("font_color", UITheme.INK)

	_player_quote.add_theme_font_override("font", font_marcellus)
	_player_quote.add_theme_font_size_override("font_size", 18)
	_player_quote.add_theme_color_override("font_color", UITheme.INK)
	_player_quote.add_theme_color_override("font_shadow_color", Color(1, 1, 1, 0))
	_player_quote.add_theme_constant_override("shadow_offset_x", 0)
	_player_quote.add_theme_constant_override("shadow_offset_y", 2)
	_player_quote.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_player_quote.visible = false
	stage.choice_slot.add_child(_player_quote)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 8)
	stage.choice_slot.add_child(spacer)

	_chat_row.add_theme_constant_override("separation", 10)
	_chat_row.custom_minimum_size = Vector2(0, 42)

	_input_box.placeholder_text = "Düşünceni veya sözünü yaz…"
	_input_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_input_box.custom_minimum_size = Vector2(160, 42)
	_input_box.add_theme_font_override("font", font_marcellus)
	_input_box.add_theme_font_size_override("font_size", 16)
	_input_box.add_theme_color_override("font_color", UITheme.INK)
	_input_box.add_theme_color_override("font_placeholder_color", UITheme.MUTED)
	_input_box.text_submitted.connect(_on_text_submitted)

	var normal_sb := StyleBoxFlat.new()
	normal_sb.bg_color = UITheme.PANEL
	normal_sb.border_color = UITheme.EDGE_STRONG
	normal_sb.border_width_bottom = 1
	normal_sb.set_corner_radius_all(8)
	normal_sb.content_margin_left = 14
	normal_sb.content_margin_right = 14
	normal_sb.content_margin_top = 8
	normal_sb.content_margin_bottom = 8
	_input_box.add_theme_stylebox_override("normal", normal_sb)

	var focus_sb := normal_sb.duplicate() as StyleBoxFlat
	focus_sb.bg_color = UITheme.PANEL
	focus_sb.border_color = UITheme.EDGE_STRONG
	focus_sb.border_width_bottom = 1
	_input_box.add_theme_stylebox_override("focus", focus_sb)
	_chat_row.add_child(_input_box)

	var btn_sb := StyleBoxFlat.new()
	btn_sb.bg_color = UITheme.PANEL
	btn_sb.border_color = UITheme.EDGE_STRONG
	btn_sb.set_border_width_all(1)
	btn_sb.set_corner_radius_all(8)
	btn_sb.content_margin_left = 16
	btn_sb.content_margin_right = 16
	btn_sb.content_margin_top = 8
	btn_sb.content_margin_bottom = 8

	var btn_hover := btn_sb.duplicate() as StyleBoxFlat
	btn_hover.bg_color = UITheme.PANEL_RAISED
	btn_hover.border_color = UITheme.EDGE_STRONG

	_send_btn.text = "Söyle"
	_send_btn.custom_minimum_size = Vector2(88, 42)
	_send_btn.add_theme_font_override("font", font_cinzel)
	_send_btn.add_theme_font_size_override("font_size", 14)
	_send_btn.add_theme_color_override("font_color", UITheme.INK)
	_send_btn.add_theme_stylebox_override("normal", btn_sb)
	_send_btn.add_theme_stylebox_override("hover", btn_hover)
	_send_btn.add_theme_stylebox_override("pressed", btn_hover)
	_send_btn.pressed.connect(func() -> void: _on_text_submitted(_input_box.text))
	_chat_row.add_child(_send_btn)

	_mic_btn.text = "Mikrofon (V)"
	_mic_btn.custom_minimum_size = Vector2(124, 42)
	_mic_btn.add_theme_font_override("font", font_cinzel)
	_mic_btn.add_theme_font_size_override("font_size", 14)
	_mic_btn.add_theme_color_override("font_color", UITheme.INK)
	_mic_btn.add_theme_stylebox_override("normal", btn_sb)
	_mic_btn.add_theme_stylebox_override("hover", btn_hover)
	_mic_btn.add_theme_stylebox_override("pressed", btn_hover)
	_mic_btn.pressed.connect(_on_mic_pressed)
	_chat_row.add_child(_mic_btn)

	stage.choice_slot.add_child(_chat_row)

	var audio_row := HBoxContainer.new()
	audio_row.add_theme_constant_override("separation", 12)
	var audio_panel := PanelContainer.new()
	audio_panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var audio_surface := StyleBoxFlat.new()
	audio_surface.bg_color = UITheme.PANEL
	audio_surface.set_corner_radius_all(8)
	audio_surface.content_margin_left = 8
	audio_surface.content_margin_right = 8
	audio_surface.content_margin_top = 4
	audio_surface.content_margin_bottom = 4
	audio_panel.add_theme_stylebox_override("panel", audio_surface)
	audio_panel.add_child(audio_row)
	_replay_btn.text = "Tekrar dinle"
	_replay_btn.pressed.connect(func() -> void: stage.voice.replay())
	audio_row.add_child(_replay_btn)
	_volume_label.text = "Ses %100"
	_volume_label.custom_minimum_size.x = 82
	audio_row.add_child(_volume_label)
	_volume_slider.min_value = 0
	_volume_slider.max_value = 100
	_volume_slider.step = 5
	_volume_slider.value = 100
	_volume_slider.custom_minimum_size.x = 140
	_volume_slider.tooltip_text = "Filozofun ses düzeyi"
	_volume_slider.value_changed.connect(func(value: float) -> void:
		stage.voice.set_volume(value / 100.0)
		_volume_label.text = "Ses %d" % int(value)
	)
	audio_row.add_child(_volume_slider)
	stage.choice_slot.add_child(audio_panel)


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
			if not _dialogue_busy():
				_speak_stage_line(_stage_level)
		KEY_M:
			if not _dialogue_busy():
				_set_level(_stage_level + 1)
		KEY_N:
			if not _dialogue_busy():
				_set_level(_stage_level - 1)
		KEY_A:
			if not _dialogue_busy():
				apply_llm_trigger({"trigger": "wrong", "reply_id": "wrong_sofist"})
		KEY_S:
			_anger = clampf(_anger - 0.25, 0.0, 1.0)
			stage.set_anger(_anger)
		KEY_R:
			if stage.has_node("PhilosopherActor"):
				stage.get_node("PhilosopherActor").call("play_reaction", &"stir")
		KEY_E:
			if not _dialogue_busy():
				apply_llm_trigger({"trigger": "angry_leave", "reply_id": "angry_leave"})
		KEY_X:
			_pick(_index)


func _pick(i: int) -> void:
	brain.cancel()
	_waiting_reply = false
	_completion_awaiting_voice = false
	_index = clampi(i, 0, ORDER.size() - 1)
	var id: StringName = ORDER[_index]
	_stage_level = 0
	_anger = 0.0
	_failed = false
	_used_choices.clear()
	_input_box.text = ""
	_player_quote.visible = false
	_chat_row.visible = true
	hud.clear_tools()

	stage.show_philosopher(id, 4)
	hud.set_steps(0, 4, NAMES[id].to_upper())
	hud.set_directive("%s ile konuşarak unuttuğu 4 temel fikri hatırlat." % NAMES[id])
	hud.set_note(NOTES.get(id, ""))
	hud.set_action("")
	_speak_stage_line(0)
	_refresh_dialogue_controls()


func _dialogue_busy() -> bool:
	return _waiting_reply or stage.voice.is_busy() or stage.voice.is_listening()


func _refresh_dialogue_controls() -> void:
	var busy: bool = _dialogue_busy()
	_send_btn.disabled = busy or _failed
	_mic_btn.disabled = busy or _failed
	_mic_btn.text = "Dinleniyor…" if stage.voice.is_listening() else "Mikrofon (V)"
	_send_btn.text = "Bekle…" if busy else "Söyle"
	_replay_btn.disabled = busy or _failed


func _on_line_finished(_line_id: StringName) -> void:
	_refresh_dialogue_controls()
	if _failed:
		stage.actor.exit_angry(1.4)
	if _completion_awaiting_voice:
		_completion_awaiting_voice = false
		completed.emit()


func _on_line_failed(_line_id: StringName) -> void:
	hud.say("Ses hazırlanamadı; yanıtı ekrandan okuyabilir, konuşmaya devam edebilirsin.", &"bad")
	_on_line_finished(_line_id)


func _on_text_submitted(raw_text: String) -> void:
	var clean: String = raw_text.strip_edges()
	if clean == "" or _failed or _dialogue_busy():
		return
	_waiting_reply = true
	_refresh_dialogue_controls()
	_input_box.text = ""
	_input_box.release_focus()
	_player_quote.text = "Siz: “%s”" % clean
	_player_quote.visible = true
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
	if _failed or _dialogue_busy():
		return
	if stage.voice.listen_microphone(4.2):
		_mic_btn.text = "Dinleniyor…"
		_mic_btn.disabled = true
		hud.say("Mikrofona Türkçe konuşun…", &"neutral")
	_refresh_dialogue_controls()


func _on_speech_recognized(ok: bool, text: String) -> void:
	_refresh_dialogue_controls()
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
	_waiting_reply = false
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
		hud.set_steps(_stage_level, 4, "ONARILDI" if _stage_level >= 4 else NAMES[id].to_upper())

		if reply_id != "" and stage.voice.get_line_text(id, StringName(reply_id)) != "" and (reply_text == "" or reply_text == stage.voice.get_line_text(id, StringName(reply_id))):
			stage.speak_line(NAMES[id], StringName(reply_id))
		elif reply_text != "":
			stage.show_line(NAMES[id], reply_text)
			stage.voice.speak_live(id, reply_text, &"llm_ok")
		else:
			_speak_stage_line(_stage_level)

		if _stage_level >= 4:
			hud.set_steps(4, 4, "ONARILDI")
			hud.set_directive("%s kendi felsefesini tamamen hatırladı! Sohbete devam edebilir veya sonraki filozofa geçebilirsin." % NAMES[id])
			hud.say("Sonuca ulaşıldı — %s tamamen uyandı!" % NAMES[id], &"good")
			hud.set_action("Yeniden Dene")
			if not was_completed:
				# Merkez completed sinyalinde sahneyi kaldırır; son söz önce bitsin.
				_completion_awaiting_voice = stage.voice.is_busy()
				if not _completion_awaiting_voice:
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
		if not stage.voice.is_busy():
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
	_refresh_dialogue_controls()


func _on_action_pressed() -> void:
	_pick(_index)


func _set_level(level: int, custom_line_id: StringName = &"") -> void:
	_stage_level = clampi(level, 0, 4)
	var id: StringName = ORDER[_index]
	stage.set_memory_stage(_stage_level)
	hud.set_steps(_stage_level, 4, "ONARILDI" if _stage_level >= 4 else NAMES[id].to_upper())
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
