extends "res://scripts/mission.gd"
## Fikir Meydanı (Felsefe) görevi.
## Kullanıcıya çoktan seçmeli şık verilmez: oyuncu doğrudan cümlesini yazar veya mikrofona konuşur;
## arka plandaki LLM / PhilosopherBrain yanıtı analiz ederek sahnedeki tetiklemeleri
## (stir, glimmer, dawn, recalled, wrong, angry_leave, chat) çalıştırır.

const ConversationStageScript = preload("res://stations/philosophy/visual/conversation_stage.gd")
const PhilosopherBrainScript = preload("res://stations/philosophy/visual/philosopher_brain.gd")
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

var _index: int = 0
var _stage_level: int = 0
var _anger: float = 0.0
var _used_choices: Array[String] = []
var _failed: bool = false


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
	_player_quote.add_theme_font_size_override("font_size", 17)
	_player_quote.add_theme_color_override("font_color", Color("#9fb6c3"))
	_player_quote.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.90))
	_player_quote.add_theme_constant_override("shadow_offset_x", 0)
	_player_quote.add_theme_constant_override("shadow_offset_y", 2)
	_player_quote.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_player_quote.visible = false
	stage.choice_slot.add_child(_player_quote)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 10)
	stage.choice_slot.add_child(spacer)

	_chat_row.add_theme_constant_override("separation", 8)
	_chat_row.custom_minimum_size = Vector2(0, 40)

	_input_box.placeholder_text = "Filozofla konuş (cümleni yazıp Enter'a bas)…"
	_input_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_input_box.custom_minimum_size = Vector2(260, 40)
	_input_box.text_submitted.connect(_on_text_submitted)

	var normal_sb := StyleBoxFlat.new()
	normal_sb.bg_color = Color(0.03, 0.05, 0.08, 0.65)
	normal_sb.border_color = Color(0.95, 0.65, 0.35, 0.55)
	normal_sb.border_width_bottom = 2
	normal_sb.set_corner_radius_all(6)
	normal_sb.content_margin_left = 14
	normal_sb.content_margin_right = 14
	normal_sb.content_margin_top = 8
	normal_sb.content_margin_bottom = 8
	_input_box.add_theme_stylebox_override("normal", normal_sb)

	var focus_sb := normal_sb.duplicate() as StyleBoxFlat
	focus_sb.bg_color = Color(0.05, 0.08, 0.13, 0.85)
	focus_sb.border_color = Color("#f2a65a")
	focus_sb.border_width_bottom = 2
	_input_box.add_theme_stylebox_override("focus", focus_sb)
	_chat_row.add_child(_input_box)

	_send_btn.text = "Gönder"
	_send_btn.theme_type_variation = &"PrimaryButton"
	_send_btn.custom_minimum_size = Vector2(92, 40)
	_send_btn.pressed.connect(func() -> void: _on_text_submitted(_input_box.text))
	_chat_row.add_child(_send_btn)

	_mic_btn.text = "Sesle Söyle (V)"
	_mic_btn.custom_minimum_size = Vector2(134, 40)
	_mic_btn.pressed.connect(_on_mic_pressed)
	_chat_row.add_child(_mic_btn)

	stage.choice_slot.add_child(_chat_row)


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
			stage.actor.play_reaction(&"stir")
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
	_chat_row.visible = true
	hud.clear_tools()

	stage.show_philosopher(id, 4)
	hud.set_steps(0, 4, NAMES[id].to_upper())
	hud.set_directive("%s ile konuşarak unuttuğu 4 temel fikri hatırlat." % NAMES[id])
	hud.set_note(NOTES.get(id, ""))
	hud.set_action("")
	_speak_stage_line(0)


func _on_text_submitted(raw_text: String) -> void:
	var clean: String = raw_text.strip_edges()
	if clean == "" or _failed or _stage_level >= 4:
		return
	_input_box.text = ""
	_input_box.release_focus()
	_player_quote.text = "Siz: “%s”" % clean
	_player_quote.visible = true
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
	_mic_btn.text = "Sesle Söyle (V)"
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
	if _failed or _stage_level >= 4:
		return
	var trig: String = String(result.get("trigger", result.get("verdict", "chat")))
	var cid: String = String(result.get("choice_id", ""))
	var reply_id: String = String(result.get("reply_id", ""))
	var reply_text: String = String(result.get("reply_text", ""))
	var mood_name: StringName = StringName(String(result.get("mood", "thinking")))
	var id: StringName = ORDER[_index]

	if trig in ["stir", "glimmer", "dawn", "recalled", "correct"]:
		if cid != "" and not _used_choices.has(cid):
			_used_choices.append(cid)
		_anger = maxf(_anger - 0.20, 0.0)
		stage.set_anger(_anger)
		_stage_level = clampi(_stage_level + 1, 0, 4)
		stage.set_memory_stage(_stage_level)
		hud.set_steps(_stage_level, 4, "ONARILDI" if _stage_level >= 4 else NAMES[id].to_upper())

		if reply_id != "" and stage.voice.get_line_text(id, StringName(reply_id)) != "":
			stage.speak_line(NAMES[id], StringName(reply_id))
		elif reply_text != "":
			stage.show_line(NAMES[id], reply_text)
			stage.voice.speak_live(id, reply_text, &"llm_ok")
		else:
			_speak_stage_line(_stage_level)

		if _stage_level == 1:
			hud.say("Hafızasında bir kıpırtı uyandı.", &"good")
		elif _stage_level >= 4:
			_chat_row.visible = false
			hud.set_steps(4, 4, "ONARILDI")
			hud.set_directive("%s kendi felsefesini tamamen hatırladı." % NAMES[id])
			hud.say("Fikir halkası tamamlandı.", &"good")
			hud.set_action("Yeniden Dene")
			completed.emit()
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
