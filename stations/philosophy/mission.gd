extends "res://scripts/mission.gd"
## Fikir Meydanı (Felsefe) görevi.
## Ortak res://scripts/mission_hud.gd arayüzünü kullanır (yazı paneli yok, docs/UX.md uyumlu).
## Filozofun unuttuğu 4 ana fikri sırayla hatırlatınca hafızası onarılır ve completed.emit() çağrılır;
## yanlış iddialarla sabrı tükenirse filozof öfkeyle meydandan ayrılır ve görev başarısız olur.

const ConversationStageScript = preload("res://stations/philosophy/visual/conversation_stage.gd")
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
var hud: Hud
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

	hud = Hud.new()
	add_child(hud)
	hud.action_pressed.connect(_on_action_pressed)
	hud.skip_pressed.connect(func() -> void: _pick((_index + 1) % ORDER.size()))
	hud.skip.text = "Sonraki filozof"
	hud.skip.show()

	var args := OS.get_cmdline_user_args()
	for a in args:
		if a.begins_with("--who="):
			_index = maxi(ORDER.find(StringName(a.substr(6))), 0)
	_pick(_index)

	for a in args:
		if a.begins_with("--demo"):
			_run_demo()


func _unhandled_key_input(event: InputEvent) -> void:
	var e := event as InputEventKey
	if e == null or not e.pressed or e.echo:
		return
	match e.keycode:
		KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6, KEY_7, KEY_8:
			_pick(e.keycode - KEY_1)
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

	stage.show_philosopher(id, 4)
	hud.set_steps(0, 4, NAMES[id].to_upper())
	hud.set_directive("%s'e unuttuğu ana fikirleri sırayla hatırlat." % NAMES[id])
	hud.set_note(NOTES.get(id, ""))
	hud.set_action("")
	_rebuild_tools()
	_speak_stage_line(0)


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
			b.custom_minimum_size = Vector2(0, 40)
			b.pressed.connect(func() -> void: _on_choice_selected(d))
			hud.tools.add_child(b)
	else:
		var b_ok := Button.new()
		b_ok.text = "Doğru fikri hatırlat"
		b_ok.custom_minimum_size = Vector2(0, 40)
		b_ok.pressed.connect(func() -> void: _on_choice_selected({"id": "step_up", "correct": true, "reply": ""}))
		hud.tools.add_child(b_ok)

		var b_bad := Button.new()
		b_bad.text = "Yanlış fikir söyle"
		b_bad.custom_minimum_size = Vector2(0, 40)
		b_bad.pressed.connect(func() -> void: _on_choice_selected({"id": "step_wrong", "correct": false, "reply": ""}))
		hud.tools.add_child(b_bad)


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
			hud.set_steps(4, 4, "ONARILDI")
			hud.set_directive("%s kendi felsefesini tamamen hatırladı." % NAMES[id])
			hud.say("Fikir halkası tamamlandı.", &"good")
			hud.set_action("Yeniden Dene")
			completed.emit()
	else:
		_apply_wrong_choice(reply_id)


func _apply_wrong_choice(reply_id: String) -> void:
	_anger = clampf(_anger + 0.50, 0.0, 1.0)
	stage.set_anger(_anger)
	var id: StringName = ORDER[_index]
	if _anger >= 1.0:
		_failed = true
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
