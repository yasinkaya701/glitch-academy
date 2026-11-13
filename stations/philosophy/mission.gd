extends "res://scripts/mission.gd"
## Fikir Meydanı (Felsefe) görevi.
## Ortak res://scripts/mission_hud.gd arayüzünü kullanır (yazı paneli yok, docs/UX.md uyumlu).
## Oyuncu filozofla üç yoldan konuşabilir:
##   1. Alt bardaki kavram düğmelerine tıklayarak,
##   2. Mesaj kutusuna kendi cümlesini yazıp Gönder / Enter ile göndererek (PhilosopherBrain LLM + kavram motoru),
##   3. "Sesle Konuş" düğmesine (veya V tuşuna) basıp mikrofona Türkçe konuşarak.

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
var _chat_bar := HBoxContainer.new()
var _input_box := LineEdit.new()
var _send_btn := Button.new()
var _mic_btn := Button.new()

var _index: int = 0
var _stage_level: int = 0
var _anger: float = 0.0
var _used_choices: Array[String] = []
var _failed: bool = false


func _ready() -> void:
	if get_tree().root.theme == null:
		get_tree().root.theme = UITheme.build()
	set_anchors_preset(Control.PRESET_FULL_RECT)

	stage = ConversationStageScript.new()
	stage.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(stage)

	brain = PhilosopherBrainScript.new()
	add_child(brain)
	brain.response_ready.connect(_on_brain_response)

	stage.voice.speech_recognized.connect(_on_speech_recognized)

	hud = Hud.new()
	add_child(hud)
	hud.action_pressed.connect(_on_action_pressed)
	hud.skip_pressed.connect(func() -> void: _pick((_index + 1) % ORDER.size()))
	hud.skip.text = "Sonraki filozof"
	hud.skip.show()

	_build_chat_bar()
	resized.connect(_layout_chat_bar)
	_layout_chat_bar()

	var args := OS.get_cmdline_user_args()
	for a in args:
		if a.begins_with("--who="):
			_index = maxi(ORDER.find(StringName(a.substr(6))), 0)
	_pick(_index)

	for a in args:
		if a.begins_with("--demo"):
			_run_demo()


func _process(_delta: float) -> void:
	_layout_chat_bar()


func _build_chat_bar() -> void:
	_chat_bar.add_theme_constant_override("separation", 8)
	add_child(_chat_bar)

	_input_box.placeholder_text = "Filozofa mesaj yaz veya Sesle Konuş'a bas (ör. 'dört neden', 'erdem bilgidir', 'sen kimsin?')…"
	_input_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_input_box.custom_minimum_size = Vector2(280, 40)
	_input_box.text_submitted.connect(_on_text_submitted)
	var box_style := StyleBoxFlat.new()
	box_style.bg_color = Color(0.04, 0.07, 0.11, 0.86)
	box_style.border_color = Color("#41627f")
	box_style.set_border_width_all(1)
	box_style.set_corner_radius_all(10)
	box_style.content_margin_left = 14
	box_style.content_margin_right = 14
	box_style.content_margin_top = 6
	box_style.content_margin_bottom = 6
	_input_box.add_theme_stylebox_override("normal", box_style)
	var focus_style := box_style.duplicate() as StyleBoxFlat
	focus_style.border_color = Color("#6fe3c1")
	_input_box.add_theme_stylebox_override("focus", focus_style)
	_chat_bar.add_child(_input_box)

	_send_btn.text = "Gönder"
	_send_btn.theme_type_variation = &"PrimaryButton"
	_send_btn.custom_minimum_size = Vector2(96, 40)
	_send_btn.pressed.connect(func() -> void: _on_text_submitted(_input_box.text))
	_chat_bar.add_child(_send_btn)

	_mic_btn.text = "Sesle Konuş (V)"
	_mic_btn.custom_minimum_size = Vector2(142, 40)
	_mic_btn.pressed.connect(_on_mic_pressed)
	_chat_bar.add_child(_mic_btn)


func _layout_chat_bar() -> void:
	var w: float = size.x
	var h: float = size.y
	var bottom: float = h - 22.0
	_chat_bar.position = Vector2(28.0, bottom - 102.0)
	_chat_bar.size = Vector2(clampf(w * 0.56, 420.0, 760.0), 40.0)


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
			_apply_wrong_choice("wrong_sofist")
		KEY_S:
			_anger = clampf(_anger - 0.25, 0.0, 1.0)
			stage.set_anger(_anger)
		KEY_R:
			stage.actor.play_reaction(&"stir")
		KEY_E:
			stage.actor.exit_angry()
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
	_chat_bar.visible = true

	stage.show_philosopher(id, 4)
	hud.set_steps(0, 4, NAMES[id].to_upper())
	hud.set_directive("%s ile konuşarak veya alt kavramları seçerek unuttuğu 4 fikri hatırlat." % NAMES[id])
	hud.set_note(NOTES.get(id, ""))
	hud.set_action("")
	_rebuild_tools()
	_speak_stage_line(0)


func _on_text_submitted(raw_text: String) -> void:
	var clean: String = raw_text.strip_edges()
	if clean == "" or _failed or _stage_level >= 4:
		return
	_input_box.text = ""
	_input_box.release_focus()
	hud.say("Siz: “%s”" % clean, &"neutral")
	var id: StringName = ORDER[_index]
	brain.ask(
		id,
		clean,
		_stage_level,
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
	_mic_btn.text = "Sesle Konuş (V)"
	_mic_btn.disabled = false
	if not ok or text == "":
		hud.say("Ses anlaşılamadı; tekrar konuşun veya mesaj yazın.", &"bad")
		return
	_input_box.text = text
	_on_text_submitted(text)


func _on_brain_response(result: Dictionary) -> void:
	if _failed or _stage_level >= 4:
		return
	var verdict: String = String(result.get("verdict", "chat"))
	var cid: String = String(result.get("choice_id", ""))
	var reply_id: String = String(result.get("reply_id", ""))
	var reply_text: String = String(result.get("reply_text", ""))
	var id: StringName = ORDER[_index]

	if verdict == "correct":
		if cid != "" and not _used_choices.has(cid):
			_used_choices.append(cid)
		_anger = maxf(_anger - 0.20, 0.0)
		stage.set_anger(_anger)
		_stage_level = clampi(_stage_level + 1, 0, 4)
		stage.set_memory_stage(_stage_level)
		hud.set_steps(_stage_level, 4, "ONARILDI" if _stage_level >= 4 else NAMES[id].to_upper())
		_rebuild_tools()
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
			_chat_bar.visible = false
			hud.set_steps(4, 4, "ONARILDI")
			hud.set_directive("%s kendi felsefesini tamamen hatırladı." % NAMES[id])
			hud.say("Fikir halkası tamamlandı.", &"good")
			hud.set_action("Yeniden Dene")
			completed.emit()
	elif verdict == "wrong":
		_apply_wrong_choice(reply_id, reply_text)
	else:
		# Sohbet / soru / ipucu yanıtı
		stage.actor.play_reaction(&"glimmer")
		if reply_id != "" and stage.voice.get_line_text(id, StringName(reply_id)) != "":
			stage.speak_line(NAMES[id], StringName(reply_id))
		elif reply_text != "":
			stage.show_line(NAMES[id], reply_text)
			stage.voice.speak_live(id, reply_text, &"llm_chat")


func _rebuild_tools() -> void:
	hud.clear_tools()
	if _failed or _stage_level >= 4:
		return
	var id: StringName = ORDER[_index]
	var choices: Array = stage.voice.get_choices(id)
	if not choices.is_empty():
		for item: Variant in choices:
			if not (item is Dictionary):
				continue
			var d := item as Dictionary
			var cid: String = String(d.get("id", ""))
			if _used_choices.has(cid):
				continue
			var b := Button.new()
			b.text = String(d.get("label", ""))
			b.custom_minimum_size = Vector2(0, 38)
			b.pressed.connect(func() -> void: _on_choice_selected(d))
			hud.tools.add_child(b)


func _on_choice_selected(choice_data: Dictionary) -> void:
	if _failed or _stage_level >= 4:
		return
	var cid: String = String(choice_data.get("id", ""))
	var is_correct: bool = bool(choice_data.get("correct", false))
	var reply_id: String = String(choice_data.get("reply", ""))
	var id: StringName = ORDER[_index]

	if is_correct:
		if cid != "step_up" and not _used_choices.has(cid):
			_used_choices.append(cid)
		_anger = maxf(_anger - 0.20, 0.0)
		stage.set_anger(_anger)
		_set_level(_stage_level + 1, StringName(reply_id))
		_rebuild_tools()
		if _stage_level == 1:
			hud.say("Hafızasında bir kıpırtı uyandı.", &"good")
		elif _stage_level >= 4:
			_chat_bar.visible = false
			hud.set_steps(4, 4, "ONARILDI")
			hud.set_directive("%s kendi felsefesini tamamen hatırladı." % NAMES[id])
			hud.say("Fikir halkası tamamlandı.", &"good")
			hud.set_action("Yeniden Dene")
			completed.emit()
	else:
		_apply_wrong_choice(reply_id)


func _apply_wrong_choice(reply_id: String, custom_text: String = "") -> void:
	_anger = clampf(_anger + 0.50, 0.0, 1.0)
	stage.set_anger(_anger)
	var id: StringName = ORDER[_index]
	if _anger >= 1.0:
		_failed = true
		_chat_bar.visible = false
		hud.clear_tools()
		stage.actor.play_reaction(&"refuse")
		if stage.voice.get_line_text(id, &"angry_leave") != "":
			stage.speak_line(NAMES[id], &"angry_leave")
		else:
			stage.show_line(NAMES[id], "Beni kendi fikirlerimden uzaklaştırdın; tartışmayı bırakıyorum!")
		stage.actor.exit_angry(1.4)
		hud.set_directive("%s öfkeyle meydandan ayrıldı." % NAMES[id])
		hud.say("Sabrı tükendi — görev başarısız.", &"bad")
		hud.set_action("Yeniden Dene")
	else:
		stage.actor.play_reaction(&"refuse")
		hud.say("Bu fikir ona ait değil — öfkelendi.", &"bad")
		if reply_id != "" and stage.voice.get_line_text(id, StringName(reply_id)) != "":
			stage.speak_line(NAMES[id], StringName(reply_id))
		elif custom_text != "":
			stage.show_line(NAMES[id], custom_text)
			stage.voice.speak_live(id, custom_text, &"llm_wrong")
		else:
			stage.show_line(NAMES[id], "Hayır! Bu fikir bana ait değil; beni dinlemiyorsun!")


func _on_action_pressed() -> void:
	_pick(_index)


func _set_level(level: int, custom_line_id: StringName = &"") -> void:
	_stage_level = clampi(level, 0, 4)
	var id: StringName = ORDER[_index]
	stage.set_memory_stage(_stage_level)
	hud.set_steps(_stage_level, 4, "ONARILDI" if _stage_level >= 4 else NAMES[id].to_upper())
	if _stage_level >= 4:
		_chat_bar.visible = false
		hud.clear_tools()
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


func _run_demo() -> void:
	for lvl in range(1, 5):
		await get_tree().create_timer(2.4).timeout
		_set_level(lvl)
		if lvl == 1:
			hud.say("Hafızasında bir kıpırtı uyandı.", &"good")
		elif lvl == 4:
			hud.set_directive("Sokrates kendi felsefesini tamamen hatırladı.")
			hud.say("Fikir halkası tamamlandı.", &"good")
			hud.set_action("Yeniden Dene")
	await get_tree().create_timer(2.4).timeout
	_pick(_index)
	await get_tree().create_timer(1.4).timeout
	_apply_wrong_choice("wrong_sofist")
	await get_tree().create_timer(1.8).timeout
	_apply_wrong_choice("wrong_empedokles")
