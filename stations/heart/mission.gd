extends "res://scripts/mission.gd"
## AYT Biyoloji · Dolaşım. Kalbi tanı, pompayı gözle, kapakçıkları yerleştir, yeni arızayı teşhis et,
## iki dolaşımı tamamla. Kurallar heart_model.gd'de, çizim heart_stage.gd'de.

const Model = preload("res://stations/heart/heart_model.gd")
const Stage = preload("res://stations/heart/heart_stage.gd")

const GOOD := Color("#a0dfbc")
const BAD := Color("#ffb093")
const MUTED := Color("#b0c4bf")
const INK := Color("#e9f1ee")
const DURATION := {
	Model.Phase.FILLING: 1.5,
	Model.Phase.PRESSURE_RISE: 0.6,
	Model.Phase.EJECTION: 1.2,
	Model.Phase.PRESSURE_FALL: 0.6,
}
const SPOT_NAMES := {
	&"svc": "Üst ana toplardamar",
	&"right_atrium": "Sağ kulakçık",
	&"right_ventricle": "Sağ karıncık",
	&"pulmonary_artery": "Akciğer atardamarı",
	&"pulmonary_veins": "Akciğer toplardamarları",
	&"left_atrium": "Sol kulakçık",
	&"left_ventricle": "Sol karıncık",
	&"aorta": "Aort",
	&"lungs": "Akciğerler",
	&"body": "Vücut",
}
## Tanı adımının soruları: hedef, istem.
const RECOGNIZE := [
	[&"right_atrium", "Vücuttan gelen oksijence fakir kanı ilk karşılayan odacığı göster."],
	[&"right_ventricle", "Kanı akciğerlere pompalayan odacığı göster."],
	[&"left_atrium", "Akciğerlerden dönen oksijence zengin kanı toplayan odacığı göster."],
	[&"left_ventricle", "Kanı tüm vücuda pompalayan, duvarı en kalın odacığı göster."],
	[&"aorta", "Kalpten vücuda kan taşıyan en büyük atardamarı göster."],
	[&"pulmonary_artery", "Kalpten akciğere kan götüren damarı göster."],
	[&"pulmonary_veins", "Akciğerden kalbe oksijenli kan getiren damarları göster."],
	[&"svc", "Vücudun üst bölümünden kalbe kan getiren damarı göster."],
]
## Dolaşım turu sırası: kanın kalpten kalbe izlediği yol.
const LOOP := [&"svc", &"right_atrium", &"right_ventricle", &"pulmonary_artery", &"lungs",
	&"pulmonary_veins", &"left_atrium", &"left_ventricle", &"aorta", &"body"]
const LOOP_HINT := {
	&"svc": "Vücuttan dönen kan kalbe ana toplardamarlarla girer.",
	&"right_atrium": "Toplardamardan gelen kanı ilk alan sağ kulakçıktır.",
	&"right_ventricle": "Triküspit kapaktan geçen kan sağ karıncığa iner.",
	&"pulmonary_artery": "Sağ karıncık kanı akciğer atardamarına pompalar.",
	&"lungs": "Atardamar kanı akciğere götürür, gaz alışverişi orada olur.",
	&"pulmonary_veins": "Akciğerden oksijenlenen kan toplardamarlarla kalbe döner.",
	&"left_atrium": "Akciğer toplardamarları kanı sol kulakçığa boşaltır.",
	&"left_ventricle": "Mitral kapaktan geçen kan sol karıncığa iner.",
	&"aorta": "Sol karıncık kanı aorta pompalar.",
	&"body": "Aort kanı vücut dokularına taşır, tur tamamlanır.",
}
const LOOP_OXYGEN := {
	&"svc": false, &"right_atrium": false, &"right_ventricle": false, &"pulmonary_artery": false,
	&"lungs": true, &"pulmonary_veins": true, &"left_atrium": true, &"left_ventricle": true,
	&"aorta": true, &"body": false,
}

enum Step { INTRO, RECOGNIZE, PUMP, REPAIR, DIAGNOSE, LOOP, DONE }

var step := Step.INTRO
var stage: Stage
var section: Label
var headline: Label
var body: Label
var feedback: Label
var status: Label
var tray: HFlowContainer
var question: VBoxContainer
var question_toggles: Dictionary[int, CheckButton] = {}
var action: Button
var skip: Button
var pause: Button

var phase: int = Model.Phase.FILLING
var phase_time := 0.0
var running := false
var cycles := 0
var held: int = -1
var slots: Dictionary = {}
var defects: Dictionary = {}
var recognized := 0
var loop_index := 0
var wrong_count := 0
var pump_checked := false
var intro_time := 0.0
var _oxygen_tween: Tween


func _ready() -> void:
	_build_ui()
	_enter_intro()


func _build_ui() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var root := HBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 16)
	add_child(root)

	stage = Stage.new()
	stage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stage.spot_pressed.connect(_on_spot)
	root.add_child(stage)

	var console := PanelContainer.new()
	console.custom_minimum_size = Vector2(350, 0)
	console.add_theme_stylebox_override("panel", _panel_style())
	root.add_child(console)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	console.add_child(column)

	section = _label(13, Color("#8ff0d4"))
	headline = _label(21, INK)
	headline.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body = _label(15, INK)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status = _label(15, Color("#ffc082"))
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(section)
	column.add_child(headline)
	column.add_child(body)
	column.add_child(status)

	tray = HFlowContainer.new()
	tray.add_theme_constant_override("h_separation", 6)
	tray.add_theme_constant_override("v_separation", 6)
	column.add_child(tray)

	question = VBoxContainer.new()
	column.add_child(question)

	feedback = _label(15, MUTED)
	feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(feedback)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(spacer)

	pause = Button.new()
	pause.pressed.connect(_toggle_run)
	column.add_child(pause)
	action = Button.new()
	action.custom_minimum_size = Vector2(0, 44)
	action.pressed.connect(_on_action)
	column.add_child(action)
	skip = Button.new()
	skip.text = "Açılışı geç"
	skip.pressed.connect(_finish_intro)
	column.add_child(skip)


func _label(font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#0f1c2e", 0.96)
	style.set_border_width_all(1)
	style.border_color = Color("#35506a")
	style.set_corner_radius_all(10)
	style.set_content_margin_all(20)
	return style


func _set_ui(sec: String, head: String, text: String, button: String = "") -> void:
	section.text = sec
	headline.text = head
	body.text = text
	action.text = button
	action.visible = button != ""
	action.disabled = false
	feedback.text = ""
	status.text = ""
	pause.hide()
	skip.hide()
	for child in tray.get_children():
		child.queue_free()
	for child in question.get_children():
		child.queue_free()
	question_toggles.clear()


func _say(text: String, color: Color = MUTED) -> void:
	feedback.text = text
	feedback.add_theme_color_override("font_color", color)


func _tween_oxygen(value: float, seconds: float = 1.6) -> void:
	if _oxygen_tween != null:
		_oxygen_tween.kill()
	_oxygen_tween = create_tween()
	_oxygen_tween.tween_property(stage, "body_oxygen", value, seconds).set_trans(Tween.TRANS_SINE)


# --- Pompa döngüsü ------------------------------------------------------

func _process(delta: float) -> void:
	if step == Step.INTRO:
		intro_time += delta
		if intro_time > 9.0:
			_finish_intro()
	if not running:
		return
	phase_time += delta
	var duration: float = DURATION[phase]
	if phase_time >= duration:
		phase_time = 0.0
		phase = (phase + 1) % 4
		if phase == Model.Phase.FILLING:
			cycles += 1
			_on_cycle_complete()
		_apply_phase()
	stage.beat = sin(clampf(phase_time / duration, 0.0, 1.0) * PI) if phase == Model.Phase.EJECTION else 0.0


func _start_pump() -> void:
	running = true
	phase = Model.Phase.FILLING
	phase_time = 0.0
	cycles = 0
	stage.show_flow = true
	_apply_phase()


func _stop_pump() -> void:
	running = false
	stage.beat = 0.0
	for key in Stage.FLOWS:
		stage.flow_dir[key] = 0.0
	for valve in Model.VALVE_NAMES:
		stage.valve_target[valve] = 0.0


func _toggle_run() -> void:
	if running:
		running = false
		pause.text = "Devam et"
	else:
		running = true
		pause.text = "Duraklat"


func _placement() -> Dictionary:
	var placement := {}
	for slot in slots:
		var piece: int = slots[slot]
		if piece >= 0:
			placement[piece] = Model.SLOT_OF[slot]
	return placement


func _leaks(slot: int) -> bool:
	## Yuvadaki kapak, kapalı olması gereken evrede sızdırır mı?
	if phase_closes(slot):
		var piece: int = slots.get(slot, -1)
		if piece != slot:
			return true
		var defect: StringName = defects.get(slot, &"")
		if defect == &"stuck_open":
			return true
		if defect == &"leaky":
			return true
	return false


func phase_closes(slot: int) -> bool:
	return not Model.is_open(slot, phase)


func _apply_phase() -> void:
	stage.set_valves_for_phase(phase)
	for key in Stage.FLOWS:
		stage.flow_dir[key] = 0.0
		stage.flow_color_override.erase(key)
	stage.flow_dir[&"ven_in"] = 1.0
	stage.flow_dir[&"l_in"] = 1.0
	stage.flow_dir[&"art_out"] = 1.0
	var flow_for := {
		Model.Valve.TRICUSPID: &"r_av", Model.Valve.MITRAL: &"l_av",
		Model.Valve.PULMONARY: &"r_out", Model.Valve.AORTIC: &"l_out",
	}
	for slot in Model.VALVE_NAMES:
		var key: StringName = flow_for[slot]
		var piece: int = slots.get(slot, -1)
		if piece < 0:
			stage.valve_present[slot] = false
		else:
			stage.valve_present[slot] = true
		if _leaks(slot):
			stage.flow_dir[key] = -1.0
			stage.flow_color_override[key] = Color("#ffc082")
		elif Model.is_open(slot, phase) and piece == slot:
			stage.flow_dir[key] = 1.0


func _on_cycle_complete() -> void:
	match step:
		Step.PUMP:
			if cycles == 1:
				_say("Bir tam tur izledin. Şimdi aşağıdaki soruyu yanıtla.", GOOD)
				_show_question()
		Step.REPAIR, Step.DIAGNOSE:
			_evaluate_cycle()


# --- Açılış -------------------------------------------------------------

func _enter_intro() -> void:
	step = Step.INTRO
	intro_time = 0.0
	slots = _full_slots()
	defects = {Model.Valve.MITRAL: &"leaky"}
	stage.spots_active.clear()
	stage.labels.clear()
	stage.body_oxygen = 1.0
	_set_ui("ARIZA", "Kalp tek yönlü tutamıyor",
		"Sol karıncık kasılırken mitral kapak kanı geri bırakıyor. Kan vücuda gitmek yerine sol kulakçığa kaçıyor ve dokulara giden oksijen azalıyor.")
	skip.show()
	_start_pump()
	_tween_oxygen(0.45, 7.0)


func _full_slots() -> Dictionary:
	var result := {}
	for valve in Model.VALVE_NAMES:
		result[valve] = valve
	return result


func _finish_intro() -> void:
	if step != Step.INTRO:
		return
	_enter_recognize()


# --- 1 · Tanı -----------------------------------------------------------

func _enter_recognize() -> void:
	step = Step.RECOGNIZE
	_stop_pump()
	slots = _full_slots()
	defects = {}
	recognized = 0
	wrong_count = 0
	_set_ui("1 · TANI", "Kalbin yapısını tanı",
		"Şemada hastanın sağ tarafı ekranın solundadır. Soruyu oku, ilgili bölgeye tıkla.")
	_tween_oxygen(0.45)
	for id in Stage.SPOTS:
		stage.spots_active[id] = id != &"lungs" and id != &"body"
	stage.labels.clear()
	_next_recognition()


func _next_recognition() -> void:
	if recognized >= RECOGNIZE.size():
		_set_ui("1 · TANI", "Yapıyı tanıdın",
			"Atardamar kanı kalpten uzaklaştırır, toplardamar kalbe getirir. Oksijen düzeyi bu yönden bağımsızdır: akciğer atardamarı oksijence fakir kan taşır.", "Pompayı incele")
		stage.highlight = &""
		for id in Stage.SPOTS:
			stage.spots_active[id] = false
		return
	stage.highlight = RECOGNIZE[recognized][0]
	status.text = "%d / %d  ·  %s" % [recognized + 1, RECOGNIZE.size(), RECOGNIZE[recognized][1]]


func _recognize_click(id: StringName) -> void:
	var target: StringName = RECOGNIZE[recognized][0]
	if id == target:
		stage.labels[id] = SPOT_NAMES[id]
		recognized += 1
		wrong_count = 0
		_say("Doğru: %s." % SPOT_NAMES[id], GOOD)
		_next_recognition()
	else:
		wrong_count += 1
		var text := "Burası %s." % SPOT_NAMES.get(id, "başka bir bölge").to_lower()
		if wrong_count >= 2:
			text += " İpucu: ekranın %s tarafına bak." % ("sol" if target in [&"right_atrium", &"right_ventricle", &"svc"] else "sağ")
		_say(text, BAD)


# --- 2 · Pompa ----------------------------------------------------------

func _enter_pump() -> void:
	step = Step.PUMP
	_set_ui("2 · POMPA", "Kapaklar nasıl çalışır?",
		"Kalp dört evrede çalışır: dolum, basınç yükselişi, atım, basınç düşüşü. Kapaklar basınç farkıyla kendiliğinden açılır ve kapanır. Bir tur izle.")
	for id in Stage.SPOTS:
		stage.spots_active[id] = false
	stage.highlight = &""
	stage.labels.clear()
	slots = _full_slots()
	defects = {}
	pause.show()
	pause.text = "Duraklat"
	pump_checked = false
	_start_pump()
	_tween_oxygen(0.6)


func _show_question() -> void:
	for child in question.get_children():
		child.queue_free()
	question_toggles.clear()
	var ask := _label(15, INK)
	ask.text = "Atım evresinde hangi kapaklar açık? İşaretle."
	ask.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	question.add_child(ask)
	for valve in Model.VALVE_NAMES:
		var toggle := CheckButton.new()
		toggle.text = Model.VALVE_NAMES[valve]
		question.add_child(toggle)
		question_toggles[valve] = toggle
	var verify := Button.new()
	verify.text = "Doğrula"
	verify.pressed.connect(_check_question)
	question.add_child(verify)


func _check_question() -> void:
	var correct := true
	for valve in question_toggles:
		if question_toggles[valve].button_pressed != Model.is_open(valve, Model.Phase.EJECTION):
			correct = false
	if correct:
		pump_checked = true
		_say("Doğru. Atımda karıncık basıncı atardamarı aşar, yarım ay kapaklar açılır. Kulakçık–karıncık kapakları kapanır, geri akış olmaz.", GOOD)
		action.text = "Kapakları onar"
		action.show()
	else:
		_say("Basınç nerede yüksek? Atımda karıncıklar kasılır. Kan karıncıktan çıkışa mı, kulakçığa mı gider?", BAD)


# --- 3 · Onar -----------------------------------------------------------

func _enter_repair() -> void:
	step = Step.REPAIR
	_stop_pump()
	held = -1
	defects = {}
	slots = {}
	for valve in Model.VALVE_NAMES:
		slots[valve] = -1
		stage.valve_present[valve] = false
		stage.valve_marked.erase(valve)
	stage.labels.clear()
	_set_ui("3 · ONAR", "Kapakçıkları yerleştir",
		"Dört kapak sökülmüş. Bir kapak seç, kalpteki doğru yuvaya tıkla. Yerleştirdiğin kapağa tekrar tıklarsan geri alırsın. Hepsini koyunca pompayı çalıştır.", "Pompayı çalıştır")
	action.disabled = true
	tray.show()
	var group := ButtonGroup.new()
	group.allow_unpress = true
	for valve in Model.VALVE_NAMES:
		var button := Button.new()
		button.toggle_mode = true
		button.button_group = group
		button.text = Model.VALVE_NAMES[valve]
		button.toggled.connect(_on_tray.bind(valve))
		tray.add_child(button)
	for valve in Model.VALVE_NAMES:
		stage.spots_active[StringName("valve_%d" % valve)] = true
	for id in Stage.SPOTS:
		stage.spots_active[id] = false
	_tween_oxygen(0.45)
	_refresh_repair()


func _on_tray(pressed: bool, valve: int) -> void:
	held = valve if pressed else (held if held != valve else -1)


func _slot_click(slot: int) -> void:
	if step == Step.REPAIR:
		if slots[slot] >= 0 and held < 0:
			var piece: int = slots[slot]
			slots[slot] = -1
			_say("%s geri alındı." % Model.VALVE_NAMES[piece])
		elif held >= 0:
			if slots[slot] >= 0:
				_say("Bu yuva dolu. Önce içindeki kapağı geri al.", BAD)
			else:
				slots[slot] = held
				_say("%s yerleştirildi." % Model.VALVE_NAMES[held])
				_release_tray()
		_refresh_repair()
	elif step == Step.DIAGNOSE:
		_diagnose_click(slot)


func _release_tray() -> void:
	held = -1
	for button in tray.get_children():
		(button as Button).button_pressed = false


func _refresh_repair() -> void:
	var used: Array = slots.values()
	for button in tray.get_children():
		var valve := _tray_valve(button as Button)
		(button as Button).disabled = used.has(valve)
	for slot in Model.VALVE_NAMES:
		var piece: int = slots[slot]
		stage.valve_present[slot] = piece >= 0
		if piece >= 0:
			stage.labels[slot] = Model.VALVE_NAMES[piece]
			stage.valve_amount[slot] = 0.0
		else:
			stage.labels.erase(slot)
	action.disabled = used.has(-1)
	var left := used.count(-1)
	status.text = "Yerleştirilecek kapak: %d" % left


func _tray_valve(button: Button) -> int:
	for valve in Model.VALVE_NAMES:
		if Model.VALVE_NAMES[valve] == button.text:
			return valve
	return -1


func _run_repair_check() -> void:
	for id in Stage.SPOTS:
		stage.spots_active[id] = false
	for valve in Model.VALVE_NAMES:
		stage.spots_active[StringName("valve_%d" % valve)] = false
	tray.hide()
	action.disabled = true
	_say("Pompa çalışıyor, bir turu izle.")
	_start_pump()


func _evaluate_cycle() -> void:
	var problems := Model.all_problems(_placement(), defects)
	var wrong_slots: Array[int] = []
	for slot in slots:
		if slots[slot] != slot and slots[slot] >= 0:
			wrong_slots.append(slot)
	if step == Step.REPAIR:
		if wrong_slots.is_empty() and problems.is_empty():
			_stop_pump()
			_tween_oxygen(0.72)
			stage.valve_target[Model.Valve.TRICUSPID] = 0.0
			_say("Kan artık tek yönlü akıyor, geri kaçış yok. Doku oksijeni yükseldi.", GOOD)
			_set_ui("3 · ONAR", "Kapakçıklar yerinde",
				"Her kapak, kanın gideceği yönü kapatır. Kulakçık–karıncık kapakları (triküspit, mitral) dolumda açılır, atımda kapanır. Yarım ay kapakları (pulmoner, aort) tersini yapar.", "Yeni arızayı gör")
		else:
			_stop_pump()
			var lines: Array[String] = []
			for slot in wrong_slots:
				stage.valve_marked[slot] = true
				lines.append("%s yanlış yuvada. Akış yönüne göre kapağın bulunduğu odaları kontrol et." % Model.VALVE_NAMES[slots[slot]])
			_say("Geri kaçış var. " + "\n".join(lines), BAD)
			tray.show()
			action.disabled = false
			_enter_repair_retry()
	elif step == Step.DIAGNOSE:
		pass


func _enter_repair_retry() -> void:
	step = Step.REPAIR
	for slot in slots:
		if stage.valve_marked.get(slot, false):
			slots[slot] = -1
			stage.valve_marked.erase(slot)
	for valve in Model.VALVE_NAMES:
		stage.spots_active[StringName("valve_%d" % valve)] = true
	for button in tray.get_children():
		(button as Button).disabled = false
	_release_tray()
	_refresh_repair()
	action.text = "Pompayı çalıştır"


# --- 4 · Yeni arıza -----------------------------------------------------

func _enter_diagnose() -> void:
	step = Step.DIAGNOSE
	slots = _full_slots()
	defects = {Model.Valve.AORTIC: &"stuck_open"}
	wrong_count = 0
	for valve in Model.VALVE_NAMES:
		stage.valve_marked.erase(valve)
		stage.valve_present[valve] = true
		stage.spots_active[StringName("valve_%d" % valve)] = true
	stage.labels.clear()
	_set_ui("4 · TEŞHİS", "Kan geri akıyor",
		"Yeni bir arıza var. Pompayı izle, kanın hangi evrede ve hangi yönde geri aktığını bul, ardından arızalı kapağa tıkla.")
	pause.show()
	pause.text = "Duraklat"
	_tween_oxygen(0.5)
	_start_pump()


func _diagnose_click(slot: int) -> void:
	if slot == Model.Valve.AORTIC:
		for valve in Model.VALVE_NAMES:
			stage.spots_active[StringName("valve_%d" % valve)] = false
		stage.valve_marked[Model.Valve.AORTIC] = true
		_say("Doğru. Gevşeme sırasında aort kapağı açık kalıyor, kan aorttan sol karıncığa geri akıyor.", GOOD)
		action.text = "Aort kapağını değiştir"
		action.show()
	else:
		wrong_count += 1
		var text := "%s sağlam. Kanın tersine aktığı yeri ara." % Model.VALVE_NAMES[slot]
		if wrong_count >= 2:
			text += " Geri akış, karıncık gevşerken aorttan karıncığa doğru."
		_say(text, BAD)


func _repair_aortic() -> void:
	defects = {}
	stage.valve_marked.erase(Model.Valve.AORTIC)
	action.hide()
	_say("Yeni kapak takıldı. Bir tur izle.")
	_tween_oxygen(0.82, 2.5)
	get_tree().create_timer(5.4).timeout.connect(_finish_diagnose, CONNECT_ONE_SHOT)


func _finish_diagnose() -> void:
	if step != Step.DIAGNOSE:
		return
	_stop_pump()
	_set_ui("4 · TEŞHİS", "Geri akış durdu",
		"Aort kapağı gevşeme sırasında kapandı. Kan yalnız ileri akıyor. Şimdi iki dolaşımı baştan sona kuracaksın.", "Dolaşımı kur")


# --- 5 · Dolaşım turu ---------------------------------------------------

func _enter_loop() -> void:
	step = Step.LOOP
	_stop_pump()
	loop_index = 0
	wrong_count = 0
	slots = _full_slots()
	defects = {}
	stage.labels.clear()
	for valve in Model.VALVE_NAMES:
		stage.valve_marked.erase(valve)
		stage.spots_active[StringName("valve_%d" % valve)] = false
	for id in Stage.SPOTS:
		stage.spots_active[id] = true
	_set_ui("5 · DOLAŞIM", "Kanın yolunu kur",
		"Kan vücuttan çıkıp kalbe girer, akciğerlere gider, kalbe döner ve vücuda dağılır. Bu yolu, kanın izlediği sırayla işaretle. Başlangıç: vücuttan kalbe dönen damar.")
	_next_loop()


func _next_loop() -> void:
	if loop_index >= LOOP.size():
		_finish_loop()
		return
	stage.highlight = LOOP[loop_index]
	status.text = "%d / %d" % [loop_index + 1, LOOP.size()]


func _loop_click(id: StringName) -> void:
	var target: StringName = LOOP[loop_index]
	if id == target:
		var rich: bool = LOOP_OXYGEN[id]
		stage.labels[id] = "%s · %s" % [SPOT_NAMES[id], "oksijence zengin" if rich else "oksijence fakir"]
		_say(LOOP_HINT[id], GOOD)
		loop_index += 1
		wrong_count = 0
		_next_loop()
	else:
		wrong_count += 1
		var text := "Kan şimdi burada değil. Son işaretlediğin: %s." % (SPOT_NAMES[LOOP[loop_index - 1]] if loop_index > 0 else "henüz yok")
		if wrong_count >= 2:
			text += " " + LOOP_HINT[target]
		_say(text, BAD)


func _finish_loop() -> void:
	step = Step.DONE
	for id in Stage.SPOTS:
		stage.spots_active[id] = false
	stage.highlight = &""
	_start_pump()
	_tween_oxygen(1.0, 3.0)
	_set_ui("ONARILDI", "Dolaşım çalışıyor",
		"Kan tek yönlü ve sürekli bir halkada akıyor. Sağ kalp oksijence fakir kanı akciğere, sol kalp oksijence zengin kanı vücuda pompalıyor. Dokular oksijene yeniden kavuştu.")
	pause.hide()
	_say("Onarıldı.", GOOD)
	completed.emit()


# --- Etkileşim yönlendirme ----------------------------------------------

func _on_spot(id: StringName) -> void:
	var text := String(id)
	if text.begins_with("valve_"):
		_slot_click(int(text.trim_prefix("valve_")))
		return
	match step:
		Step.RECOGNIZE:
			_recognize_click(id)
		Step.LOOP:
			_loop_click(id)


func _on_action() -> void:
	match step:
		Step.RECOGNIZE:
			_enter_pump()
		Step.PUMP:
			if pump_checked:
				_enter_repair()
		Step.REPAIR:
			if action.text == "Yeni arızayı gör":
				_enter_diagnose()
			else:
				_run_repair_check()
		Step.DIAGNOSE:
			if action.text == "Aort kapağını değiştir":
				_repair_aortic()
			elif action.text == "Dolaşımı kur":
				_enter_loop()
