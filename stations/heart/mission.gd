extends "res://scripts/mission.gd"
## AYT Biyoloji · Dolaşım. Kalbi tanı, pompayı gözle, kapakçıkları yerleştir, yeni arızayı teşhis et,
## iki dolaşımı tamamla. Kurallar heart_model.gd'de, çizim heart_stage.gd'de.

const Model = preload("res://stations/heart/heart_model.gd")
const Stage = preload("res://stations/heart/heart_stage.gd")
const Hud = preload("res://scripts/mission_hud.gd")
const Network = preload("res://stations/heart/heart_network.gd")

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

const STROKE_VOLUME := 70.0
const REST_RATE := 72.0
const DEMAND_ML := 10500.0
const LINK_HINTS := {
	&"body_out": "Vücuttan dönen oksijensiz kan kalbe ana toplardamarlardan girer.",
	&"pa_out": "Akciğer atardamarı oksijensiz kanı akciğere götürür.",
	&"lungs_out": "Akciğerde oksijenlenen kan akciğer toplardamarlarıyla kalbe döner.",
	&"aorta_out": "Aort oksijenli kanı vücuda dağıtır.",
}

enum Step { INTRO, RECOGNIZE, PUMP, REPAIR, DIAGNOSE, CONNECT, RATE, DONE }

class TrayPiece extends Button:
	var valve := -1

	func _get_drag_data(_at_position: Vector2) -> Variant:
		if disabled:
			return null
		var preview := Label.new()
		preview.text = "  " + text + "  "
		preview.add_theme_color_override("font_color", Color("#8ff0d4"))
		set_drag_preview(preview)
		return {"valve": valve}

var step := Step.INTRO
var stage: Stage
var hud: Hud
var section: Label
var headline: Label
var body: Label
var feedback: Label
var status: Label
var tray: HBoxContainer
var question: HBoxContainer
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
var flips: Dictionary = {}
var defects: Dictionary = {}
var recognized := 0
var tempo := 1.0
var heart_rate := 72.0
var slider: HSlider
var rate_label: Label
var wrong_count := 0
var pump_checked := false
var intro_time := 0.0
var _oxygen_tween: Tween


func _ready() -> void:
	_build_ui()
	_enter_intro()


func _build_ui() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	stage = Stage.new()
	stage.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	stage.spot_pressed.connect(_on_spot)
	stage.valve_dropped.connect(_place_piece)
	stage.ports_connected.connect(_on_link)
	stage.port_cleared.connect(_on_unlink)
	add_child(stage)

	hud = Hud.new()
	add_child(hud)
	hud.action_pressed.connect(_on_action)
	hud.skip_pressed.connect(_finish_intro)
	hud.pause_pressed.connect(_toggle_run)
	action = hud.action
	skip = hud.skip
	pause = hud.pause
	skip.text = "Açılışı geç"
	tray = HBoxContainer.new()
	tray.add_theme_constant_override("separation", 8)
	hud.tools.add_child(tray)
	question = HBoxContainer.new()
	question.add_theme_constant_override("separation", 12)
	hud.tools.add_child(question)
	# Eski metin alanları görünmez vekillerdir: yazı yönergeye ve balona gider.
	section = Label.new()
	headline = Label.new()
	body = Label.new()
	feedback = Label.new()
	status = Label.new()
	status.theme_type_variation = "MutedLabel"
	status.position = Vector2(28, 80)
	status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(status)


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


const DIRECTIVES := {
	"Kalp tek yönlü tutamıyor": "Mitral kapak sızdırıyor: kan geri kaçıyor.",
	"Kalbin yapısını tanı": "Sorulan bölgeye tıkla.",
	"Yapıyı tanıdın": "Yapı tamam. Şimdi pompayı izle.",
	"Kapaklar nasıl çalışır?": "Bir tam turu izle.",
	"Kapakçıkları yerleştir": "Kapağı yuvaya sürükle. Ok akışı göstermeli: tıkla çevir.",
	"Kapakçıklar yerinde": "Kapaklar yerinde.",
	"Kan geri akıyor": "Geri akışı bul, arızalı kapağa tıkla.",
	"Geri akış durdu": "Geri akış durdu.",
	"Damarları kalbe bağla": "Her çıkışı doğru girişe sürükle.",
	"İki dolaşım kapandı": "İki dolaşım kapandı.",
	"Kan akışını ayarla": "Dokuların ihtiyacını karşıla.",
	"Dolaşım dengede": "Dolaşım dengede.",
}


func _set_ui(sec: String, head: String, text: String, button: String = "") -> void:
	var directive_text: String = DIRECTIVES.get(head, head)
	hud.set_directive(directive_text)
	var index := 0
	var parts := sec.split(" · ")
	if parts.size() == 2 and parts[0].is_valid_int():
		index = int(parts[0])
		hud.set_steps(index, 6, parts[1])
	elif sec == "ONARILDI":
		hud.set_steps(6, 6, sec)
	else:
		hud.set_steps(0, 6, sec)
	hud.set_note(text)
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
	var tone: StringName = &"neutral"
	if color == GOOD:
		tone = &"good"
	elif color == BAD:
		tone = &"bad"
	hud.say(text, tone)


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
	var duration: float = DURATION[phase] * tempo
	if phase_time >= duration:
		phase_time = 0.0
		phase = (phase + 1) % 4
		if phase == Model.Phase.FILLING:
			cycles += 1
			_on_cycle_complete()
		_apply_phase()
	stage.beat = sin(clampf(phase_time / duration, 0.0, 1.0) * PI) if phase == Model.Phase.EJECTION else 0.0
	stage.cycle_t = _cycle_fraction()


func _cycle_fraction() -> float:
	var total := 0.0
	var before := 0.0
	for p in DURATION:
		var d: float = DURATION[p] * tempo
		if p < phase:
			before += d
		total += d
	return clampf((before + phase_time) / total, 0.0, 1.0)


func _start_pump() -> void:
	running = true
	phase = Model.Phase.FILLING
	phase_time = 0.0
	cycles = 0
	stage.show_flow = true
	_apply_phase()


func _stop_pump() -> void:
	running = false
	stage.running = false
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


func _net_slots() -> Dictionary:
	## Ağ modeli için: yuva → {piece, flipped}. Boş yuvalar yer almaz.
	var result := {}
	for slot in slots:
		var piece: int = slots[slot]
		if piece >= 0:
			result[slot] = {"piece": piece, "flipped": flips.get(slot, false)}
	return result


func _initial_flip(slot: int, piece: int) -> bool:
	## Takılan kapak yön oku akışa bakmayabilir: oyuncu okuyup karar vermeli.
	return ((piece + 1) * (slot + 2)) % 3 == 0


func _apply_phase() -> void:
	stage.set_valves_for_phase(phase)
	for key in Stage.FLOWS:
		stage.flow_dir[key] = 0.0
		stage.flow_color_override.erase(key)
	stage.flow_dir[&"ven_in"] = 1.0
	stage.flow_dir[&"l_in"] = 1.0
	var flow_for := {
		Model.Valve.TRICUSPID: &"r_av", Model.Valve.MITRAL: &"l_av",
		Model.Valve.PULMONARY: &"r_out", Model.Valve.AORTIC: &"l_out",
	}
	var net := _net_slots()
	stage.running = running
	stage.backflow = clampf(1.0 - minf(Network.valve_health(Model.Valve.AORTIC, net, defects), Network.valve_health(Model.Valve.MITRAL, net, defects)), 0.0, 1.0)
	for slot in Model.VALVE_NAMES:
		var key: StringName = flow_for[slot]
		var piece: int = slots.get(slot, -1)
		stage.valve_present[slot] = piece >= 0
		stage.valve_flipped[slot] = flips.get(slot, false)
		var flow := Network.valve_flow(slot, net, defects, phase)
		stage.valve_target[slot] = 1.0 if flow["forward"] else 0.0
		if flow["back"]:
			stage.flow_dir[key] = -1.0
			stage.flow_color_override[key] = Color("#ffc082")
		elif flow["forward"]:
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
	flips = {}
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
	_say("Sürükle: döndür · Tekerlek: yakınlaş · Çift tık: kapağa gir")
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
		"Dört kapak sökülmüş. Kapakları listeden sürükleyip kalpteki doğru yuvaya bırak (ya da kapağı seçip yuvaya tıkla). Yerleştirdiğin kapağa tıklarsan geri alırsın. Hepsini koyunca pompayı çalıştır.", "Pompayı çalıştır")
	action.disabled = true
	tray.show()
	var group := ButtonGroup.new()
	group.allow_unpress = true
	for valve in Model.VALVE_NAMES:
		var button := TrayPiece.new()
		button.valve = valve
		button.toggle_mode = true
		button.button_group = group
		button.text = Model.VALVE_NAMES[valve]
		button.tooltip_text = "Yuvaya sürükle. Yerleşen kapağa tıkla: çevir. Shift+tık: sök."
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
			flips[slot] = not flips.get(slot, false)
			_say("%s çevrildi." % Model.VALVE_NAMES[slots[slot]])
			_refresh_repair()
		elif held >= 0:
			_place_piece(slot, held)
	elif step == Step.DIAGNOSE:
		_diagnose_click(slot)


func _remove_slot(slot: int) -> void:
	if step != Step.REPAIR or slots.get(slot, -1) < 0:
		return
	var piece: int = slots[slot]
	slots[slot] = -1
	flips.erase(slot)
	_say("%s söküldü." % Model.VALVE_NAMES[piece])
	_refresh_repair()


func _place_piece(slot: int, piece: int) -> void:
	if step != Step.REPAIR:
		return
	if slots[slot] >= 0:
		_say("Bu yuva dolu. Shift + tık ile kapağı sök.", BAD)
		return
	if slots.values().has(piece):
		_say("Bu kapak zaten yerleştirildi.", BAD)
		return
	slots[slot] = piece
	flips[slot] = _initial_flip(slot, piece)
	_say("%s yerleştirildi." % Model.VALVE_NAMES[piece])
	_release_tray()
	_refresh_repair()


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
		stage.valve_flipped[slot] = flips.get(slot, false)
		stage.valve_target[slot] = 0.0
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
	if step != Step.REPAIR:
		return
	var net := _net_slots()
	var issues: Array[String] = []
	var bad_slots: Array[int] = []
	for slot in Model.VALVE_NAMES:
		var piece: int = slots.get(slot, -1)
		if piece >= 0 and piece != slot:
			issues.append("%s yanlış yuvada." % Model.VALVE_NAMES[piece])
			bad_slots.append(slot)
		elif piece >= 0 and flips.get(slot, false):
			issues.append("%s ters: ok akış yönünü göstermeli." % Model.VALVE_NAMES[piece])
			bad_slots.append(slot)
		elif Network.valve_health(slot, net, defects) < 0.99:
			issues.append("%s çalışmıyor." % Model.VALVE_NAMES[slot])
			bad_slots.append(slot)
	_stop_pump()
	if issues.is_empty():
		_tween_oxygen(0.72)
		_say("Kan tek yönlü akıyor.", GOOD)
		_set_ui("3 · ONAR", "Kapakçıklar yerinde",
			"Kulakçık–karıncık kapakları (triküspit, mitral) dolumda açılır, atımda kapanır. Yarım ay kapakları (pulmoner, aort) tersini yapar. Yön oku her zaman akışı göstermeli.", "Yeni arızayı gör")
	else:
		for slot in bad_slots:
			stage.valve_marked[slot] = true
		_say(" ".join(issues.slice(0, 2)), BAD)
		tray.show()
		action.disabled = false
		_enter_repair_retry()


func _enter_repair_retry() -> void:
	step = Step.REPAIR
	for slot in slots.keys():
		if slots[slot] >= 0 and slots[slot] != slot:
			slots[slot] = -1
			flips.erase(slot)
	for valve in Model.VALVE_NAMES:
		stage.spots_active[StringName("valve_%d" % valve)] = true
	for button in tray.get_children():
		(button as Button).disabled = false
	_release_tray()
	_refresh_repair()
	action.text = "Pompayı çalıştır"
	action.show()


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
		"Aort kapağı gevşeme sırasında kapandı. Kan yalnız ileri akıyor. Şimdi kalbin dışındaki damarlar kopmuş, onları kendin bağlayacaksın.", "Damarları bağla")


# --- 5 · Damarları bağla -----------------------------------------------

func _enter_connect() -> void:
	step = Step.CONNECT
	_stop_pump()
	slots = _full_slots()
	defects = {}
	stage.labels.clear()
	stage.highlight = &""
	for valve in Model.VALVE_NAMES:
		stage.valve_marked.erase(valve)
		stage.spots_active[StringName("valve_%d" % valve)] = false
	for id in Stage.SPOTS:
		stage.spots_active[id] = false
	stage.connections = {}
	stage.port_warning = {}
	stage.ports_active = true
	stage.connection_flow = false
	_set_ui("5 · DAMARLAR", "Damarları kalbe bağla",
		"Dış damarlar kopmuş. Renkli bir çıkış noktasından başlayıp çizgiyi doğru girişe sürükle. Kan oksijen düzeyine göre mavi (oksijence fakir) ya da kırmızı (zengin). Dört damarın dördünü de doğru bağla.")
	status.text = "Bağlanan: 0 / 4"
	_tween_oxygen(0.35)


func _on_link(from_port: StringName, to_port: StringName) -> void:
	if step != Step.CONNECT:
		return
	stage.connections[from_port] = to_port
	var correct: bool = to_port == Stage.CORRECT_LINKS[from_port]
	stage.port_warning[from_port] = not correct
	if correct:
		_say(LINK_HINTS[from_port], GOOD)
	else:
		_say(_wrong_link_message(from_port, to_port), BAD)
	_refresh_links()


func _on_unlink(from_port: StringName) -> void:
	if step != Step.CONNECT:
		return
	stage.port_warning.erase(from_port)
	_refresh_links()


func _wrong_link_message(from_port: StringName, to_port: StringName) -> String:
	var rich: bool = Stage.PORT_RICH[from_port]
	match to_port:
		&"body_in":
			return "Oksijence fakir kan doğrudan vücuda gidiyor. Dokular oksijen alamaz." if not rich else "Doğru yön, ama bu çıkışın girişi başka."
		&"pv_in":
			return "Oksijence fakir kan sol kalbe karışıyor. Sol karıncık kanı oksijensiz pompalar." if not rich else "Akciğerden çıkan kan zaten buraya gelmeli, bu çıkış başka bir yere ait."
		&"lungs_in":
			return "Oksijenli kan yeniden akciğere gönderiliyor, vücut oksijensiz kalıyor." if rich else "Akciğere giriş, akciğer atardamarına ait."
		&"svc_in":
			return "Oksijenli kan sağ kalbe dönüyor. Gereksiz yere akciğere pompalanır, vücut yine oksijensiz kalır." if rich else "Vücuttan dönen kana ait giriş bu. Bu çıkış başka bir yere gitmeli."
	return "Bu bağlantı yanlış."


func _refresh_links() -> void:
	var good := 0
	var bad := 0
	for from_port in stage.connections:
		if stage.connections[from_port] == Stage.CORRECT_LINKS[from_port]:
			good += 1
		else:
			bad += 1
	status.text = "Doğru bağlanan: %d / 4%s" % [good, ("   ·   hatalı: %d" % bad) if bad > 0 else ""]
	stage.connection_flow = stage.connections.size() > 0
	stage.show_flow = true
	if stage.connection_flow and not running:
		running = true
		pause.hide()
		_apply_phase_connect()
	var oxygen := 0.35 + 0.1 * good - 0.05 * bad
	_tween_oxygen(clampf(oxygen, 0.1, 0.85), 0.8)
	if good == 4:
		stage.ports_active = false
		stage.port_warning = {}
		_start_pump()
		_tween_oxygen(0.85, 1.2)
		_set_ui("5 · DAMARLAR", "İki dolaşım kapandı",
			"Küçük dolaşım: sağ karıncık → akciğer atardamarı → akciğer → akciğer toplardamarları → sol kulakçık. Büyük dolaşım: sol karıncık → aort → vücut → ana toplardamarlar → sağ kulakçık. Kan tek yönlü ve kapalı bir halkada.", "Akışı ayarla")


func _apply_phase_connect() -> void:
	for key in Stage.FLOWS:
		stage.flow_dir[key] = 0.0


# --- 6 · Akışı ayarla ---------------------------------------------------

func _enter_rate() -> void:
	step = Step.RATE
	if _oxygen_tween != null:
		_oxygen_tween.kill()
	heart_rate = REST_RATE
	_set_ui("6 · AKIŞ", "Kan akışını ayarla",
		"Dakikada pompalanan kan (kalp debisi) = kalp hızı × atım hacmi. Dinlenirken 72 atım/dk × 70 mL = 5040 mL ≈ 5 L/dk. Vücut şimdi koşuyor, dokular dakikada 10,5 L kan istiyor. Atım hacmi sabit 70 mL, kalp hızını sen ayarla.", "Ayarı onayla")
	pause.hide()
	slider = HSlider.new()
	slider.min_value = 40
	slider.max_value = 200
	slider.step = 1
	slider.value = REST_RATE
	slider.value_changed.connect(_on_rate_changed)
	slider.custom_minimum_size = Vector2(320, 0)
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	question.add_child(slider)
	rate_label = Label.new()
	rate_label.add_theme_color_override("font_color", Color("#ffc082"))
	question.add_child(rate_label)
	_start_pump()
	_on_rate_changed(REST_RATE)


func _on_rate_changed(value: float) -> void:
	heart_rate = value
	tempo = REST_RATE / value
	stage.flow_speed = clampf(value / REST_RATE, 0.5, 3.0)
	var output := value * STROKE_VOLUME
	var ratio := output / DEMAND_ML
	rate_label.text = "%d atım/dk  ×  %d mL  =  %d mL/dk   (ihtiyaç %d)" % [int(value), int(STROKE_VOLUME), int(output), int(DEMAND_ML)]
	stage.body_oxygen = clampf(ratio, 0.0, 1.0)


func _check_rate() -> void:
	var ratio := heart_rate * STROKE_VOLUME / DEMAND_ML
	if ratio >= 0.95 and ratio <= 1.06:
		step = Step.DONE
		stage.body_oxygen = 1.0
		_set_ui("ONARILDI", "Dolaşım dengede",
			"Kalp hızı %d atım/dk, debi %d mL/dk: dokuların istediği kadar kan taşınıyor. Kan tek yönlü, iki dolaşım kapalı, oksijen yerine ulaşıyor." % [int(heart_rate), int(heart_rate * STROKE_VOLUME)])
		_say("Onarıldı.", GOOD)
		completed.emit()
	elif ratio < 0.95:
		_say("Debi dokuların ihtiyacının altında. Gereken hızı hesapla: 10500 mL ÷ 70 mL.", BAD)
	else:
		_say("Debi gereğinden fazla. Kalp boşuna yoruluyor. İhtiyaca eşit hızı bul.", BAD)


# --- Etkileşim yönlendirme ----------------------------------------------

func _on_spot(id: StringName) -> void:
	var text := String(id)
	if text.begins_with("valve_remove_"):
		_remove_slot(int(text.trim_prefix("valve_remove_")))
		return
	if text.begins_with("valve_"):
		_slot_click(int(text.trim_prefix("valve_")))
		return
	match step:
		Step.RECOGNIZE:
			_recognize_click(id)


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
			elif action.text == "Damarları bağla":
				_enter_connect()
		Step.CONNECT:
			if action.text == "Akışı ayarla":
				_enter_rate()
		Step.RATE:
			_check_rate()
