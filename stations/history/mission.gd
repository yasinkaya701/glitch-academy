extends "res://scripts/mission.gd"
## Tarih Meydanı ve LGS T.C. İnkılap Tarihi İstasyonu.
## MEB 8. Sınıf İnkılap Tarihi (LGS · İTA.8.2.2) ve Genel Tarih kazanımları.
## Oyuncu doğrudan cümlesini yazabilir, mikrofona konuşabilir veya ekrandaki tarihî karar kartlarını seçebilir.

const HistoryStageScript = preload("res://stations/history/visual/history_stage.gd")
const HistoryBrainScript = preload("res://stations/history/visual/history_brain.gd")
const Hud = preload("res://scripts/mission_hud.gd")
const UITheme = preload("res://scripts/ui_theme.gd")

const ORDER: Array[StringName] = [&"mete_han", &"alparslan", &"fatih", &"kanuni", &"mimar_sinan", &"ataturk"]
const NAMES := {
	&"mete_han": "Mete Han",
	&"alparslan": "Sultan Alparslan",
	&"fatih": "Fatih Sultan Mehmed",
	&"kanuni": "Kanuni Sultan Süleyman",
	&"mimar_sinan": "Mimar Sinan",
	&"ataturk": "Mustafa Kemal Atatürk",
}
const NOTES := {
	&"mete_han": "Mete Han (MÖ 209–174) · Onlu askeri teşkilat, 'Toprak milletin köküdür' ve Türk birliği.",
	&"alparslan": "Sultan Alparslan (1029–1072) · 1071 Malazgirt Zaferi ve Anadolu'nun kapıları.",
	&"fatih": "Fatih Sultan Mehmed (1432–1481) · 1453 İstanbul'un fethi, Şahi topları ve Sahn-ı Seman.",
	&"kanuni": "Kanuni Sultan Süleyman (1494–1566) · Adalet ve kanun düzeni, Mohaç ve Preveze.",
	&"mimar_sinan": "Mimar Sinan (1489–1588) · Şehzade, Süleymaniye, Selimiye ve kubbe statiği.",
	&"ataturk": "Mustafa Kemal Atatürk (1881–1938) · MEB 8. Sınıf İnkılap Tarihi (LGS · İTA.8.2.2). Amasya, Erzurum, Sivas, TBMM ve Lozan.",
}
const FALLBACK_LINES := [
	"Zaman sis içinde… Biz kimiz?",
	"Evet… zihnimde bir hatıra kımıldadı.",
	"Doğru… bunu bir yerden hatırlıyorum.",
	"Dur, söyleme, hatırlıyorum!",
	"Şimdi hatırlıyorum: vatan ve millet iradesi baki kalır.",
]

var stage: Control
var brain: Node
var hud: Hud

var _player_quote := Label.new()
var _cards_container := VBoxContainer.new()
var _chat_row := HBoxContainer.new()
var _input_box := LineEdit.new()
var _send_btn := Button.new()
var _mic_btn := Button.new()

var _index: int = 0
var _stage_level: int = 0
var _anger: float = 0.0
var _used_choices: Array[String] = []
var _failed: bool = false
var _is_lgs: bool = false


func _ready() -> void:
	var shared_theme: Theme = UITheme.build()
	theme = shared_theme
	if get_tree().root.theme == null:
		get_tree().root.theme = shared_theme
	set_anchors_preset(Control.PRESET_FULL_RECT)

	var args := OS.get_cmdline_user_args()
	for a in args:
		if a == "--lgs" or a == "lgs" or a == "--route=lgs":
			route = &"lgs"

	_is_lgs = (route == &"lgs")

	stage = HistoryStageScript.new()
	stage.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(stage)

	brain = HistoryBrainScript.new()
	add_child(brain)
	brain.response_ready.connect(apply_llm_trigger)

	stage.voice.speech_recognized.connect(_on_speech_recognized)

	hud = Hud.new()
	add_child(hud)
	hud.action_pressed.connect(_on_action_pressed)

	if _is_lgs:
		hud.skip.hide()
	else:
		hud.skip_pressed.connect(func() -> void: _pick((_index + 1) % ORDER.size()))
		hud.skip.text = "Sonraki lider"
		hud.skip.show()

	_build_dialogue_controls()

	for a in args:
		if a.begins_with("--who="):
			_index = maxi(ORDER.find(StringName(a.substr(6))), 0)

	if _is_lgs:
		_index = ORDER.find(&"ataturk")

	_pick(_index)

	for a in args:
		if a.begins_with("--demo"):
			_run_demo()


func _build_dialogue_controls() -> void:
	var font_cinzel := preload("res://fonts/Cinzel-Regular.ttf")
	var font_cinzel_bold := preload("res://fonts/CinzelDecorative-Bold.ttf")
	var font_marcellus := preload("res://fonts/Marcellus-Regular.ttf")

	if hud != null:
		hud.directive.add_theme_font_override("font", font_cinzel)
		hud.directive.add_theme_font_size_override("font_size", 18)
		hud.directive.add_theme_color_override("font_color", Color("#ede4d3"))
		if hud.info_label != null:
			hud.info_label.add_theme_font_override("font", font_marcellus)
			hud.info_label.add_theme_color_override("font_color", Color("#c4baa4"))

	_player_quote.add_theme_font_override("font", font_marcellus)
	_player_quote.add_theme_font_size_override("font_size", 17)
	_player_quote.add_theme_color_override("font_color", Color("#e8dfcf"))
	_player_quote.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.90))
	_player_quote.add_theme_constant_override("shadow_offset_x", 0)
	_player_quote.add_theme_constant_override("shadow_offset_y", 2)
	_player_quote.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_player_quote.visible = false
	stage.choice_slot.add_child(_player_quote)

	# Karar ve Belge Kartları Alanı
	_cards_container.add_theme_constant_override("separation", 6)
	stage.choice_slot.add_child(_cards_container)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 4)
	stage.choice_slot.add_child(spacer)

	# Serbest Metin ve Sesli Giriş Satırı
	_chat_row.add_theme_constant_override("separation", 8)
	_chat_row.custom_minimum_size = Vector2(0, 40)

	_input_box.placeholder_text = "Tarihî ilkeyi, kararı yazın veya mikrofona söyleyin…"
	_input_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_input_box.custom_minimum_size = Vector2(260, 40)
	_input_box.add_theme_font_override("font", font_marcellus)
	_input_box.add_theme_font_size_override("font_size", 15)
	_input_box.add_theme_color_override("font_color", Color("#f5f0e6"))
	_input_box.add_theme_color_override("font_placeholder_color", Color(0.72, 0.68, 0.60, 0.55))
	_input_box.text_submitted.connect(_on_text_submitted)

	var normal_sb := StyleBoxFlat.new()
	normal_sb.bg_color = Color(0.04, 0.05, 0.07, 0.85)
	normal_sb.border_color = Color(0.75, 0.62, 0.40, 0.50)
	normal_sb.border_width_bottom = 1
	normal_sb.set_corner_radius_all(3)
	normal_sb.content_margin_left = 12
	normal_sb.content_margin_right = 12
	normal_sb.content_margin_top = 6
	normal_sb.content_margin_bottom = 6
	_input_box.add_theme_stylebox_override("normal", normal_sb)

	var focus_sb := normal_sb.duplicate() as StyleBoxFlat
	focus_sb.bg_color = Color(0.06, 0.07, 0.10, 0.95)
	focus_sb.border_color = Color("#d8b97a")
	focus_sb.border_width_bottom = 2
	_input_box.add_theme_stylebox_override("focus", focus_sb)
	_chat_row.add_child(_input_box)

	var btn_sb := StyleBoxFlat.new()
	btn_sb.bg_color = Color(0.12, 0.13, 0.17, 0.88)
	btn_sb.border_color = Color(0.75, 0.62, 0.40, 0.55)
	btn_sb.set_border_width_all(1)
	btn_sb.set_corner_radius_all(3)
	btn_sb.content_margin_left = 12
	btn_sb.content_margin_right = 12

	var btn_hover := btn_sb.duplicate() as StyleBoxFlat
	btn_hover.bg_color = Color(0.18, 0.20, 0.26, 0.95)
	btn_hover.border_color = Color("#e5c483")

	_send_btn.text = "İlet"
	_send_btn.custom_minimum_size = Vector2(64, 40)
	_send_btn.add_theme_font_override("font", font_cinzel_bold)
	_send_btn.add_theme_font_size_override("font_size", 13)
	_send_btn.add_theme_color_override("font_color", Color("#eedfc8"))
	_send_btn.add_theme_stylebox_override("normal", btn_sb)
	_send_btn.add_theme_stylebox_override("hover", btn_hover)
	_send_btn.add_theme_stylebox_override("pressed", btn_hover)
	_send_btn.pressed.connect(func() -> void: _on_text_submitted(_input_box.text))
	_chat_row.add_child(_send_btn)

	_mic_btn.text = "🎤 Konuş (V)"
	_mic_btn.custom_minimum_size = Vector2(108, 40)
	_mic_btn.add_theme_font_override("font", font_cinzel)
	_mic_btn.add_theme_font_size_override("font_size", 13)
	_mic_btn.add_theme_color_override("font_color", Color("#d8ceba"))
	_mic_btn.add_theme_stylebox_override("normal", btn_sb)
	_mic_btn.add_theme_stylebox_override("hover", btn_hover)
	_mic_btn.add_theme_stylebox_override("pressed", btn_hover)
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
		KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6:
			if not _is_lgs:
				_pick(e.keycode - KEY_1)
		KEY_V:
			_on_mic_pressed()
		KEY_SPACE:
			_speak_stage_line(_stage_level)
		KEY_M:
			_set_level(_stage_level + 1)
		KEY_N:
			_set_level(_stage_level - 1)
		KEY_X:
			_pick(_index)


func _pick(i: int) -> void:
	_index = clampi(i, 0, ORDER.size() - 1)
	if _is_lgs:
		_index = ORDER.find(&"ataturk")
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

	if _is_lgs:
		hud.set_directive("Zaman arşivi bozuldu! Mustafa Kemal Paşa ile konuşarak veya kararları seçerek Millî Mücadele'nin 4 temel adımını savun.")
		hud.set_note("İTA.8.2.2 · Amasya Genelgesi, Erzurum ve Sivas Kongreleri, TBMM'nin Açılışı ve Lozan.")
	else:
		hud.set_directive("%s ile konuşarak unuttuğu 4 temel ilkeyi ve kararı hatırlat." % NAMES[id])
		hud.set_note(NOTES.get(id, ""))

	hud.set_action("")
	_speak_stage_line(0)
	_refresh_decision_cards()


func _refresh_decision_cards() -> void:
	for child in _cards_container.get_children():
		child.queue_free()

	if _stage_level >= 4 or _failed:
		_cards_container.visible = false
		return

	_cards_container.visible = true
	var id: StringName = ORDER[_index]
	var all_choices: Array = stage.voice.get_choices(id)
	if all_choices.is_empty():
		return

	# Mevcut aşamaya uygun doğru kartı ve çeldiricileri seç
	var correct_card: Dictionary = {}
	var distractor_cards: Array[Dictionary] = []

	for item: Variant in all_choices:
		if not (item is Dictionary):
			continue
		var c := item as Dictionary
		var is_corr: bool = bool(c.get("correct", false))
		var card_stage: int = int(c.get("stage", -1))
		if is_corr:
			if card_stage == _stage_level or (card_stage == -1 and correct_card.is_empty()):
				correct_card = c
		else:
			if card_stage == _stage_level or card_stage == -1:
				distractor_cards.append(c)

	# 1 doğru + en fazla 2 çeldirici
	var display_cards: Array[Dictionary] = []
	if not correct_card.is_empty():
		display_cards.append(correct_card)

	for d in distractor_cards:
		if display_cards.size() >= 3:
			break
		display_cards.append(d)

	# Kartları karıştır (öğrencinin ezbere değil anlayarak seçmesi için)
	# Sabit bir seed ile rastgeleleştir (aşama bazlı deterministik)
	var count: int = display_cards.size()
	for k in range(count - 1, 0, -1):
		var swap_idx: int = (k * 7 + _stage_level * 3) % (k + 1)
		var tmp := display_cards[k]
		display_cards[k] = display_cards[swap_idx]
		display_cards[swap_idx] = tmp

	var font_marcellus := preload("res://fonts/Marcellus-Regular.ttf")
	var font_cinzel := preload("res://fonts/Cinzel-Regular.ttf")

	for c in display_cards:
		var btn := Button.new()
		var lbl_text: String = String(c.get("label", ""))
		var sub_text: String = String(c.get("subtitle", ""))
		btn.text = "◆  %s\n    %s" % [lbl_text, sub_text] if sub_text != "" else "◆  %s" % lbl_text
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		btn.custom_minimum_size = Vector2(0, 44 if sub_text != "" else 34)
		btn.add_theme_font_override("font", font_marcellus)
		btn.add_theme_font_size_override("font_size", 13)
		btn.add_theme_color_override("font_color", Color("#f0e6d6"))

		var card_sb := StyleBoxFlat.new()
		card_sb.bg_color = Color(0.08, 0.09, 0.13, 0.82)
		card_sb.border_color = Color(0.65, 0.55, 0.38, 0.40)
		card_sb.set_border_width_all(1)
		card_sb.set_corner_radius_all(4)
		card_sb.content_margin_left = 14
		card_sb.content_margin_right = 14
		card_sb.content_margin_top = 5
		card_sb.content_margin_bottom = 5
		btn.add_theme_stylebox_override("normal", card_sb)

		var card_hover := card_sb.duplicate() as StyleBoxFlat
		card_hover.bg_color = Color(0.15, 0.17, 0.24, 0.94)
		card_hover.border_color = Color("#e5c483")
		card_hover.set_border_width_all(1)
		btn.add_theme_stylebox_override("hover", card_hover)
		btn.add_theme_stylebox_override("focus", card_hover)
		btn.add_theme_stylebox_override("pressed", card_hover)

		btn.pressed.connect(_on_card_selected.bind(c))
		_cards_container.add_child(btn)


func _on_card_selected(c: Dictionary) -> void:
	if _failed or _stage_level >= 4:
		return
	var label: String = String(c.get("label", ""))
	_player_quote.text = "Siz: “%s”" % label
	_player_quote.visible = true

	var is_corr: bool = bool(c.get("correct", false))
	var rid: String = String(c.get("reply", ""))
	var cid: String = String(c.get("id", ""))

	if is_corr:
		apply_llm_trigger({
			"trigger": "correct",
			"points": 1,
			"choice_id": cid,
			"reply_id": rid,
			"mood": "smile",
			"reply_text": "",
		})
	else:
		apply_llm_trigger({
			"trigger": "wrong",
			"points": 0,
			"choice_id": cid,
			"reply_id": rid,
			"mood": "angry",
			"reply_text": "",
		})


func _on_text_submitted(raw_text: String) -> void:
	var clean: String = raw_text.strip_edges()
	if clean == "" or _failed:
		return
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
	if _failed or _stage_level >= 4 or stage.voice.is_listening():
		return
	stage.voice.stop()
	if stage.voice.listen_microphone(4.2):
		_mic_btn.text = "Dinleniyor…"
		_mic_btn.disabled = true
		hud.say("Mikrofona Türkçe konuşun…", &"neutral")


func _on_speech_recognized(ok: bool, text: String) -> void:
	_mic_btn.text = "🎤 Konuş (V)"
	_mic_btn.disabled = false
	if not ok or text == "":
		hud.say("Ses anlaşılamadı; tekrar konuşun veya cümlenizi yazın.", &"bad")
		return
	_input_box.text = text
	_on_text_submitted(text)


## Arka plandaki LLM veya yerel kural motoru tarafından döndürülen tetikleyiciyi sahneye uygular.
func apply_llm_trigger(result: Dictionary) -> void:
	print("[DEBUG apply_llm_trigger] result: ", result)
	if _failed:
		return
	var trig: String = String(result.get("trigger", result.get("verdict", "chat")))
	var pts: int = maxi(int(result.get("points", 1)), 1)
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

		if reply_text != "":
			stage.show_line(NAMES[id], reply_text)
			stage.voice.speak_live(id, reply_text, &"llm_ok")
		elif reply_id != "" and stage.voice.get_line_text(id, StringName(reply_id)) != "":
			stage.speak_line(NAMES[id], StringName(reply_id))
		else:
			_speak_stage_line(_stage_level)

		if _stage_level >= 4:
			hud.set_steps(4, 4, "ONARILDI")
			_cards_container.visible = false
			_chat_row.visible = false
			if _is_lgs:
				hud.set_directive("TEBRİKLER! Millî Mücadele zaman arşivi ve I. TBMM salonu onarıldı; Türkiye Cumhuriyeti tam bağımsızdır!")
				hud.say("LGS İnkılap Tarihi hedefi başarıyla tamamlandı!", &"good")
			else:
				hud.set_directive("%s hafızasını tamamen geri kazandı! Tarih çizgisi onarıldı." % NAMES[id])
				hud.say("Sonuca ulaşıldı — %s zaman çizgisine oturdu!" % NAMES[id], &"good")
			hud.set_action("Yeniden Dene")
			if not was_completed:
				completed.emit()
		else:
			hud.say("Doğru karar! Tarih çizgisi aydınlanıyor (%d/4)." % _stage_level, &"good")
			_refresh_decision_cards()
	elif trig == "angry_leave":
		_anger = 1.0
		stage.set_anger(_anger)
		_failed = true
		_cards_container.visible = false
		_chat_row.visible = false
		stage.actor.play_reaction(&"refuse")
		if stage.voice.get_line_text(id, &"angry_leave") != "":
			stage.speak_line(NAMES[id], &"angry_leave")
		elif reply_text != "":
			stage.show_line(NAMES[id], reply_text)
			stage.voice.speak_live(id, reply_text, &"llm_leave")
		else:
			stage.show_line(NAMES[id], "Millet egemenliğinden ve bağımsızlıktan taviz verilemez!")
		stage.actor.exit_angry(1.4)
		hud.set_directive("%s meclis kürsüsünden ayrıldı; zaman arşivi kilitlendi." % NAMES[id])
		hud.say("Sabrı tükendi — görev başarısız.", &"bad")
		hud.set_action("Yeniden Dene")
	elif trig == "wrong":
		_anger = clampf(_anger + 0.35, 0.0, 1.0)
		stage.set_anger(_anger)
		if _anger >= 1.0:
			apply_llm_trigger({"trigger": "angry_leave", "reply_id": "angry_leave", "reply_text": reply_text})
			return
		stage.actor.play_reaction(&"refuse")
		hud.say("Tarihî ilkeye aykırı iddia — reddedildi.", &"bad")
		if reply_id != "" and stage.voice.get_line_text(id, StringName(reply_id)) != "":
			stage.speak_line(NAMES[id], StringName(reply_id))
		elif reply_text != "":
			stage.show_line(NAMES[id], reply_text)
			stage.voice.speak_live(id, reply_text, &"llm_wrong")
		else:
			stage.show_line(NAMES[id], "Hayır! Bu teslimiyetçi fikir milletimize kabul ettirilemez!")
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
		_cards_container.visible = false
		_chat_row.visible = false
	_speak_stage_line(_stage_level, custom_line_id)
	_refresh_decision_cards()


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
	_pick(ORDER.find(&"ataturk"))
	await get_tree().create_timer(4.0).timeout
	await _type_and_send("Amasya Genelgesi: Milletin bağımsızlığını yine milletin azim ve kararı kurtaracaktır.")
	await get_tree().create_timer(6.0).timeout
	await _type_and_send("Erzurum ve Sivas Kongrelerinde milli sınırlar çizildi ve cemiyetler birleştirildi.")
	await get_tree().create_timer(6.0).timeout
	await _type_and_send("23 Nisan 1920'de TBMM açıldı: Egemenlik kayıtsız şartsız milletindir.")
	await get_tree().create_timer(6.0).timeout
	await _type_and_send("Lozan Barış Antlaşması ile kapitülasyonlar kaldırıldı ve tam bağımsızlık tescillendi.")
