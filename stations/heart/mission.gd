extends "res://scripts/mission.gd"
## AYT Biyoloji · Dolaşım. Kalbi tanı, pompayı gözle, kapakçıkları yerleştir, yeni arızayı teşhis et,
## iki dolaşımı tamamla. Kurallar heart_model.gd'de, çizim heart_stage.gd'de.

const Model = preload("res://stations/heart/heart_model.gd")
const Stage = preload("res://stations/heart/heart_stage.gd")
const Hud = preload("res://stations/heart/heart_hud.gd")
const Network = preload("res://stations/heart/heart_network.gd")
const Circ = preload("res://scripts/physio/circulation.gd")
const ValvePreviewPiece = preload("res://stations/heart/valve_prosthesis.gd")

const GOOD := Color("#a5ad84")
const BAD := Color("#d58d79")
const MUTED := Color("#b9b8a8")
const INK := Color("#f1ede3")
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
const VALVE_DETAILS := {
	Model.Valve.TRICUSPID: "3 yaprakçık · sağ kulakçıktan sağ karıncığa",
	Model.Valve.MITRAL: "2 yaprakçık · kordatlar papiller kaslara tutunur",
	Model.Valve.AORTIC: "3 yarım ay yaprakçığı · sol karıncıktan aorta",
	Model.Valve.PULMONARY: "3 yarım ay yaprakçığı · sağ karıncıktan akciğere",
}
## Tanı adımının soruları: hedef, istem.
const RECOGNIZE := [
	[&"right_atrium", "Vücuttan gelen kanı ilk alan odacık hangisi?"],
	[&"right_ventricle", "Kanı akciğere pompalayan odacık hangisi?"],
	[&"left_atrium", "Akciğerden gelen kanı alan odacık hangisi?"],
	[&"left_ventricle", "Kanı tüm vücuda pompalayan odacık hangisi?"],
	[&"aorta", "Kanı vücuda taşıyan büyük atardamar hangisi?"],
	[&"pulmonary_artery", "Kanı akciğere götüren damar hangisi?"],
	[&"pulmonary_veins", "Oksijenli kanı akciğerden getiren damar hangisi?"],
	[&"svc", "Üst vücuttan kanı getiren damar hangisi?"],
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
	&"body_out": "Vücuttan dönen kirli (oksijence fakir) kan, ana toplardamarla sağ kulakçığa gelir.",
	&"pa_out": "Sağ karıncık oksijence fakir kanı akciğer atardamarıyla akciğere pompalar.",
	&"lungs_out": "Akciğerde oksijenlenen kan, akciğer toplardamarıyla sol kulakçığa gelir.",
	&"aorta_out": "Sol karıncık oksijenli kanı aortla vücuda pompalar.",
}

## Kapak çalışmazsa kan, kapağın önündeki (üst akım) odacıkta birikir.
const POOL_CHAMBER := {
	Model.Valve.TRICUSPID: &"right_atrium", Model.Valve.PULMONARY: &"right_ventricle",
	Model.Valve.MITRAL: &"left_atrium", Model.Valve.AORTIC: &"left_ventricle",
}
const POOL_NAMES := {
	&"right_atrium": "sağ kulakçıkta", &"right_ventricle": "sağ karıncıkta",
	&"left_atrium": "sol kulakçıkta", &"left_ventricle": "sol karıncıkta",
}

const LINK_OF := {
	Model.Valve.TRICUSPID: Circ.TRICUSPID, Model.Valve.PULMONARY: Circ.PULMONARY,
	Model.Valve.MITRAL: Circ.MITRAL, Model.Valve.AORTIC: Circ.AORTIC,
}
## Hız yavaşlatma: öğretim adımlarında akış izlenebilsin.
const TEACH_SPEED := 0.55

enum Step { INTRO, RECOGNIZE, PUMP, REPAIR, DIAGNOSE, REPLACE, CONNECT, RATE, DONE, LAB }

class TrayPiece extends Button:
	var valve := -1

	func _get_drag_data(_at_position: Vector2) -> Variant:
		if disabled:
			return null
		var preview := Label.new()
		preview.text = "  " + text + "  "
		preview.add_theme_color_override("font_color", Color("#a5ad84"))
		set_drag_preview(preview)
		return {"valve": valve}

var step := Step.INTRO
var stage: Stage
var circ: Circ = Circ.new()
var hud: Hud
var section: Label
var headline: Label
var body: Label
var feedback: Label
var status: Label
var tray: HBoxContainer
var tray_scroll: ScrollContainer
var question: HBoxContainer
var question_scroll: ScrollContainer
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
var _ejected := false
var lab_leak: Dictionary = {}
var lab_clamp: Dictionary = {}
var intro_time := 0.0
var _oxygen_tween: Tween
var replacement_trial := false
var _valve_preview_root: Node3D
var _valve_preview_piece: Node3D
var _valve_preview_container: SubViewportContainer
var _stage_backdrop: ColorRect


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
	stage.circ = circ
	circ.beat_finished.connect(_on_beat)
	add_child(stage)
	_stage_backdrop = ColorRect.new()
	_stage_backdrop.color = Color("#0b0e14")
	_stage_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_stage_backdrop)
	move_child(_stage_backdrop, 0)

	hud = Hud.new()
	add_child(hud)
	hud.action_pressed.connect(_on_action)
	hud.skip_pressed.connect(_finish_intro)
	hud.pause_pressed.connect(_toggle_run)
	hud.back_pressed.connect(_go_back)
	hud.view_pressed.connect(stage.wide_view)
	action = hud.action
	skip = hud.skip
	pause = hud.pause
	skip.text = "Açılışı geç"
	tray_scroll = ScrollContainer.new()
	tray_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	tray_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	tray_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tray_scroll.custom_minimum_size = Vector2(0, 42)
	tray_scroll.mouse_filter = Control.MOUSE_FILTER_PASS
	hud.tools.add_child(tray_scroll)
	tray = HBoxContainer.new()
	tray.custom_minimum_size = Vector2(600, 42)
	tray.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	tray.add_theme_constant_override("separation", 8)
	tray_scroll.add_child(tray)
	question_scroll = ScrollContainer.new()
	question_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	question_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	question_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	question_scroll.size_flags_stretch_ratio = 1.0
	question_scroll.custom_minimum_size = Vector2(0, 42)
	question_scroll.mouse_filter = Control.MOUSE_FILTER_PASS
	hud.tools.add_child(question_scroll)
	question = HBoxContainer.new()
	question.custom_minimum_size = Vector2(900, 46)
	question.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	question.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	question.add_theme_constant_override("separation", 12)
	question_scroll.add_child(question)
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
	hud.bind_status(status)


func _label(font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#10110f", 0.96)
	style.set_border_width_all(1)
	style.border_color = Color("#47483f")
	style.set_corner_radius_all(10)
	style.set_content_margin_all(20)
	return style


const DIRECTIVES := {
	"Kalp tek yönlü tutamıyor": "Mitral kapak sızdırıyor: kan geri kaçıyor.",
	"Kalbin yapısını tanı": "Sorulan bölgeye tıkla.",
	"Yapıyı tanıdın": "Yapı tamam. Şimdi pompayı izle.",
	"Kapaklar nasıl çalışır?": "Bir döngüyü izle; sonra kapakları doğru yöne tak.",
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
		hud.set_steps(index - 1, 6, parts[1])
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
	tray_scroll.hide()
	question_scroll.hide()
	_valve_preview_container = null
	_valve_preview_root = null
	_valve_preview_piece = null
	for child in tray.get_children():
		child.queue_free()
	for child in question.get_children():
		child.queue_free()


func _say(text: String, color: Color = MUTED) -> void:
	feedback.text = text
	var tone: StringName = &"neutral"
	if color == GOOD:
		tone = &"good"
	elif color == BAD:
		tone = &"bad"
	hud.say(text, tone)
	if tone == &"bad":
		Sfx.play(&"buzz", -14.0)
	elif tone == &"good":
		Sfx.play(&"click", -12.0)


func _tween_oxygen(value: float, seconds: float = 1.6) -> void:
	if _oxygen_tween != null:
		_oxygen_tween.kill()
	_oxygen_tween = create_tween()
	_oxygen_tween.tween_property(stage, "body_oxygen", value, seconds).set_trans(Tween.TRANS_SINE)


# --- Pompa döngüsü ------------------------------------------------------

## Dar ekranda 3B görünüm yalnızca üst ve alt paneller arasındaki boş alana yerleşir.
func _fit_stage() -> void:
	if hud == null or stage == null:
		return
	var free: Rect2 = hud.free_rect()
	stage.offset_left = 0.0
	stage.offset_right = 0.0
	stage.offset_top = free.position.y
	stage.offset_bottom = -(size.y - free.end.y)


func _process(delta: float) -> void:
	_fit_stage()
	if step == Step.INTRO:
		intro_time += delta
		if intro_time > 9.0:
			_finish_intro()
	stage.sim_active = running
	circ.running = running
	if not running:
		return
	circ.heart_rate = heart_rate
	_sync_circulation()
	var fast := step in [Step.RATE, Step.DONE, Step.LAB]
	circ.advance(delta * (1.0 if fast else TEACH_SPEED))
	_follow_phase()
	stage.beat = circ.node(Circ.LV).activation
	stage.running = true
	for valve in Model.VALVE_NAMES:
		stage.valve_target[valve] = 1.0 if circ.valve_opening(LINK_OF[valve]) > 0.04 else 0.0
		stage.valve_present[valve] = slots.get(valve, -1) >= 0
		stage.valve_flipped[valve] = flips.get(valve, false)
	stage.backflow = clampf(float(circ.last_beat.get("regurgitation", {}).get(Circ.MITRAL, 0.0)) + float(circ.last_beat.get("regurgitation", {}).get(Circ.AORTIC, 0.0)), 0.0, 1.0)


func _follow_phase() -> void:
	## Evre, motorun anlık durumundan okunur: hangi kapak akıtıyor, karıncık kasılıyor mu.
	var ejecting := circ.flow(Circ.AORTIC) > 6.0 or circ.flow(Circ.PULMONARY) > 6.0
	var filling := circ.flow(Circ.MITRAL) > 6.0 or circ.flow(Circ.TRICUSPID) > 6.0
	var squeezing := circ.node(Circ.LV).activation > 0.02
	var next := phase
	if ejecting:
		_ejected = true
		next = Model.Phase.EJECTION
	elif squeezing and not _ejected:
		next = Model.Phase.PRESSURE_RISE
	elif squeezing or (_ejected and not filling):
		next = Model.Phase.PRESSURE_FALL
	elif filling:
		next = Model.Phase.FILLING
		_ejected = false
	if next != phase:
		phase = next
		if phase == Model.Phase.EJECTION:
			Sfx.play(&"lub")
		elif phase == Model.Phase.PRESSURE_FALL:
			Sfx.play(&"dub")


func _on_beat(_stats: Dictionary) -> void:
	cycles += 1
	_on_cycle_complete()
	if step == Step.LAB:
		_report_lab()


func _sync_circulation() -> void:
	## Oyuncunun yerleştirdiği kapaklar, çevirdikleri ve arızalar motorun parametrelerine çevrilir.
	for slot in Model.VALVE_NAMES:
		var link: StringName = LINK_OF[slot]
		var piece: int = slots.get(slot, -1)
		var defect: StringName = defects.get(slot, &"")
		var leak := 0.0
		if defect == &"stuck_open":
			leak = 0.85
		elif defect == &"leaky":
			leak = 0.6
		if piece < 0:
			circ.set_valve(link, false)
		elif piece != slot:
			circ.set_valve(link, true, false, 0.0, 0.7)
		else:
			circ.set_valve(link, true, flips.get(slot, false), 0.0, maxf(leak, lab_leak.get(slot, 0.0)))
	for vessel in Circ.VESSELS:
		var amount: float = lab_clamp.get(vessel, 0.0)
		if step == Step.CONNECT:
			amount = 0.0 if _vessel_connected(vessel) else 1.0
		circ.set_clamp(vessel, amount)
		stage.clamp_amount[vessel] = amount if step != Step.CONNECT else 0.0


func _vessel_connected(vessel: StringName) -> bool:
	for from_port in Stage.PORT_LINK:
		if Stage.PORT_LINK[from_port] == vessel:
			return stage.connections.get(from_port) == Stage.CORRECT_LINKS[from_port]
	return true


func _start_pump() -> void:
	running = true
	phase = Model.Phase.FILLING
	phase_time = 0.0
	cycles = 0
	_ejected = false
	stage.show_flow = true
	stage.running = true


func _stop_pump() -> void:
	running = false
	stage.running = false
	stage.beat = 0.0
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


func _on_cycle_complete() -> void:
	match step:
		Step.PUMP:
			if cycles == 1:
				action.text = "Kapakları yerleştir"
				action.show()
				_say("Bir döngüyü izledin. Kapakları yerleştir; her kapağı çevirip akış yönünü sınayacaksın.", GOOD)
		Step.REPAIR:
			_evaluate_cycle()
		Step.DIAGNOSE:
			if replacement_trial:
				_evaluate_replacement_cycle()


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
	stage.pooled = {&"left_atrium": true}
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
	stage.pooled = {}
	stage.consequence_hold = 0.0
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
	hud.set_directive(RECOGNIZE[recognized][1])
	status.text = "%d / %d  ·  Yapıyı işaretle" % [recognized + 1, RECOGNIZE.size()]


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
		"Kalp dolum, kasılma, atım ve gevşeme evrelerinden geçer. Basınç farkı kapakları açıp kapatır; bir döngüyü izle, ardından kapakları doğru yöne yerleştir.")
	for id in Stage.SPOTS:
		stage.spots_active[id] = false
	stage.highlight = &""
	stage.labels.clear()
	slots = _full_slots()
	defects = {}
	pause.show()
	pause.text = "Duraklat"
	action.hide()
	_start_pump()
	_tween_oxygen(0.6)


# --- 3 · Onar -----------------------------------------------------------

func _enter_repair() -> void:
	step = Step.REPAIR
	replacement_trial = false
	stage.pooled = {}
	stage.consequence_hold = 0.0
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
		"Dört kapak sökülmüş. Kapağı listeden sürükle ya da seç, kalpteki yuvaya bırak. Koyduğun kapağa tıklarsan çevrilir. Hepsini koyunca pompayı çalıştır.", "Pompayı çalıştır")
	action.disabled = true
	tray.show()
	tray_scroll.show()
	for valve in Model.VALVE_NAMES:
		stage.spots_active[StringName("valve_%d" % valve)] = true
	for id in Stage.SPOTS:
		stage.spots_active[id] = false
	_populate_valve_tray(Model.VALVE_NAMES.keys(), Model.Valve.TRICUSPID)
	_tween_oxygen(0.45)
	_refresh_repair()


func _populate_valve_tray(valves: Array, selected_valve: int) -> void:
	_create_valve_preview()
	var group := ButtonGroup.new()
	group.allow_unpress = true
	for valve_value in valves:
		var valve: int = valve_value
		var button := TrayPiece.new()
		button.valve = valve
		button.toggle_mode = true
		button.button_group = group
		button.text = _short_valve_name(valve)
		hud.style_control(button)
		button.button_pressed = valve == selected_valve
		button.tooltip_text = "%s. Yuvaya sürükle; kapağa tıklayarak çevir, Shift+tık ile sök." % VALVE_DETAILS[valve]
		button.toggled.connect(_on_tray.bind(valve))
		tray.add_child(button)
	_on_tray(true, selected_valve)


func _on_tray(pressed: bool, valve: int) -> void:
	held = valve if pressed else (held if held != valve else -1)
	if pressed:
		if _valve_preview_container != null:
			_valve_preview_container.show()
		_show_valve_preview(valve)
		hud.set_directive("Seçili kapağı doğru yuvaya yerleştir.")
		hud.set_note(VALVE_DETAILS[valve] + ". Yerleşince ok kanın geçeceği yönü gösterir.")
	else:
		if _valve_preview_container != null:
			_valve_preview_container.hide()
		if is_instance_valid(_valve_preview_piece):
			_valve_preview_piece.queue_free()
		_valve_preview_piece = null
		hud.set_directive("Kapağı seçip kalpteki doğru yuvaya bırak.")
		hud.set_note("Triküspit ve mitral kapaklarda kordatlar yaprakçıkları tutar; aort ve pulmoner kapaklar üç yarım ay yaprakçığından oluşur.")


func _create_valve_preview() -> void:
	_valve_preview_container = SubViewportContainer.new()
	_valve_preview_container.custom_minimum_size = Vector2(88, 72)
	_valve_preview_container.stretch = true
	_valve_preview_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_valve_preview_container.tooltip_text = "Seçili kapağın 3B önizlemesi"
	var viewport := SubViewport.new()
	viewport.size = Vector2i(176, 144)
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.own_world_3d = true
	_valve_preview_container.add_child(viewport)
	_valve_preview_root = Node3D.new()
	viewport.add_child(_valve_preview_root)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color(0.07, 0.065, 0.055, 0.0)
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color(0.82, 0.78, 0.68)
	environment.environment.ambient_light_energy = 0.85
	_valve_preview_root.add_child(environment)
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-32.0, -28.0, 0.0)
	key.light_color = Color(1.0, 0.88, 0.78)
	key.light_energy = 1.15
	_valve_preview_root.add_child(key)
	var rim := DirectionalLight3D.new()
	rim.rotation_degrees = Vector3(-18.0, 145.0, 0.0)
	rim.light_color = Color(0.78, 0.72, 0.61)
	rim.light_energy = 0.75
	_valve_preview_root.add_child(rim)
	var camera := Camera3D.new()
	camera.position = Vector3(0.0, 1.1, 2.8)
	camera.fov = 38.0
	camera.current = true
	_valve_preview_root.add_child(camera)
	tray.add_child(_valve_preview_container)
	_valve_preview_container.hide()
	camera.look_at(Vector3.ZERO, Vector3.UP)


func _show_valve_preview(valve: int) -> void:
	if _valve_preview_root == null:
		return
	if is_instance_valid(_valve_preview_piece):
		_valve_preview_piece.queue_free()
	_valve_preview_piece = ValvePreviewPiece.new()
	_valve_preview_root.add_child(_valve_preview_piece)
	_valve_preview_piece.call("setup", valve, 0.68)
	_valve_preview_piece.set("open_amount", 0.18)


func _slot_click(slot: int) -> void:
	if step in [Step.REPAIR, Step.REPLACE]:
		if slots[slot] >= 0 and held < 0:
			flips[slot] = not flips.get(slot, false)
			Sfx.play(&"click")
			if flips[slot]:
				_say("%s ters: kan ileri geçemez, geri kaçar." % Model.VALVE_NAMES[slots[slot]], BAD)
			else:
				_say("%s akış yönüne çevrildi." % Model.VALVE_NAMES[slots[slot]], GOOD)
			_refresh_repair()
		elif held >= 0:
			_place_piece(slot, held)
	elif step == Step.DIAGNOSE:
		_diagnose_click(slot)
	elif step == Step.LAB:
		_lab_valve(slot)


func _remove_slot(slot: int) -> void:
	if step not in [Step.REPAIR, Step.REPLACE] or slots.get(slot, -1) < 0:
		return
	if step == Step.REPLACE and slot != Model.Valve.AORTIC:
		_say("Bu ameliyatta yalnız aort kapağı değiştiriliyor.", BAD)
		return
	var piece: int = slots[slot]
	slots[slot] = -1
	flips.erase(slot)
	_say("%s söküldü." % Model.VALVE_NAMES[piece])
	_refresh_repair()


func _place_piece(slot: int, piece: int) -> void:
	if step not in [Step.REPAIR, Step.REPLACE]:
		return
	if step == Step.REPLACE and (slot != Model.Valve.AORTIC or piece != Model.Valve.AORTIC):
		_say("Aort yuvasına yalnız aort kapağı takılabilir.", BAD)
		return
	if slots[slot] >= 0:
		_say("Bu yuva dolu. Shift + tık ile kapağı sök.", BAD)
		return
	if slots.values().has(piece):
		_say("Bu kapak zaten yerleştirildi.", BAD)
		return
	Audio.play_sfx("heart_valve_seat", -8.0)
	slots[slot] = piece
	flips[slot] = _initial_flip(slot, piece)
	_say("%s yerleştirildi." % Model.VALVE_NAMES[piece])
	_release_tray()
	_refresh_repair()


func _release_tray() -> void:
	held = -1
	for button in tray.get_children():
		if button is Button:
			(button as Button).button_pressed = false


func _refresh_repair() -> void:
	var used: Array = slots.values()
	for button in tray.get_children():
		if not button is Button:
			continue
		var valve := _tray_valve(button as Button)
		(button as Button).disabled = used.has(valve)
	for slot in Model.VALVE_NAMES:
		var piece: int = slots[slot]
		stage.valve_present[slot] = piece >= 0
		stage.valve_flipped[slot] = flips.get(slot, false)
		stage.valve_target[slot] = 0.0
		if piece >= 0:
			stage.labels.erase(slot)
			stage.valve_amount[slot] = 0.0
		else:
			stage.labels.erase(slot)
	action.disabled = used.has(-1)
	var left := used.count(-1)
	status.text = "Yerleştirilecek kapak: %d" % left


func _tray_valve(button: Button) -> int:
	for valve in Model.VALVE_NAMES:
		if _short_valve_name(valve) == button.text or Model.VALVE_NAMES[valve] == button.text:
			return valve
	return -1


func _short_valve_name(valve: int) -> String:
	match valve:
		Model.Valve.TRICUSPID: return "Triküspit"
		Model.Valve.PULMONARY: return "Pulmoner"
		Model.Valve.MITRAL: return "Mitral"
		Model.Valve.AORTIC: return "Aort"
	return Model.VALVE_NAMES.get(valve, "Kapak")


func _run_repair_check() -> void:
	stage.pooled = {}
	stage.consequence_hold = 0.0
	for id in Stage.SPOTS:
		stage.spots_active[id] = false
	for valve in Model.VALVE_NAMES:
		stage.spots_active[StringName("valve_%d" % valve)] = false
	tray.hide()
	tray_scroll.hide()
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
			issues.append("%s yanlış yuvada: akış bu yuvada tıkandı." % Model.VALVE_NAMES[piece])
			bad_slots.append(slot)
		elif piece >= 0 and flips.get(slot, false):
			issues.append("%s ters: kan ileri geçmedi, geri kaçtı." % Model.VALVE_NAMES[piece])
			bad_slots.append(slot)
		elif Network.valve_health(slot, net, defects) < 0.99:
			issues.append("%s kan tutmuyor." % Model.VALVE_NAMES[slot])
			bad_slots.append(slot)
	_stop_pump()
	if issues.is_empty():
		stage.pooled = {}
		_tween_oxygen(0.72)
		_say("Kan tek yönlü akıyor.", GOOD)
		_set_ui("3 · ONAR", "Kapakçıklar yerinde",
			"Kulakçık–karıncık kapakları dolumda açılır, atımda kapanır. Yarım ay kapakları tersini yapar. Kan ileri geçti, geri kaçmadı.", "Yeni arızayı gör")
	else:
		stage.pooled = {}
		var chambers: Array[String] = []
		for slot in bad_slots:
			stage.valve_marked[slot] = true
			var chamber: StringName = POOL_CHAMBER.get(slot, &"")
			if chamber != &"":
				stage.pooled[chamber] = true
				chambers.append(POOL_NAMES[chamber])
		stage.consequence_hold = 6.0
		var where := " ve ".join(chambers.slice(0, 2))
		_say("Kan %s birikti. %s" % [where, " ".join(issues.slice(0, 1))], BAD)
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
		if button is Button:
			(button as Button).disabled = false
	_release_tray()
	_refresh_repair()
	action.text = "Pompayı çalıştır"
	action.show()


# --- 4 · Yeni arıza -----------------------------------------------------

func _enter_diagnose() -> void:
	step = Step.DIAGNOSE
	stage.pooled = {}
	stage.consequence_hold = 0.0
	replacement_trial = false
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
	step = Step.REPLACE
	replacement_trial = false
	_stop_pump()
	slots = _full_slots()
	slots[Model.Valve.AORTIC] = -1
	flips[Model.Valve.AORTIC] = false
	stage.valve_present[Model.Valve.AORTIC] = false
	stage.valve_marked.erase(Model.Valve.AORTIC)
	stage.spots_active.clear()
	stage.spots_active[StringName("valve_%d" % Model.Valve.AORTIC)] = true
	stage.labels.erase(Model.Valve.AORTIC)
	_set_ui("4 · TEŞHİS", "Aort kapağını değiştir",
		"Arızalı kapağı çıkardım. Yeni aort kapağını yuvaya yerleştir; oku aort yönüne çevir ve pompayla bir tur dene.", "Yeni kapağı test et")
	action.disabled = true
	tray.show()
	_populate_valve_tray([Model.Valve.AORTIC], Model.Valve.AORTIC)
	_refresh_repair()
	_say("Arızalı aort kapağı çıkarıldı. Yeni parçayı tak.", GOOD)
	_tween_oxygen(0.32, 0.8)


func _test_aortic_replacement() -> void:
	if slots.get(Model.Valve.AORTIC, -1) != Model.Valve.AORTIC:
		_say("Önce yeni aort kapağını yuvaya yerleştir.", BAD)
		return
	if flips.get(Model.Valve.AORTIC, false):
		stage.valve_marked[Model.Valve.AORTIC] = true
		_say("Aort kapağı ters. Kapağa tıklayıp oku aorta doğru çevir.", BAD)
		return
	defects.erase(Model.Valve.AORTIC)
	stage.valve_marked.erase(Model.Valve.AORTIC)
	stage.spots_active.clear()
	replacement_trial = true
	step = Step.DIAGNOSE
	_set_ui("4 · TEŞHİS", "Yeni kapağı test et", "Pompayı bir tam tur çalıştırıyorum. Akış tek yönlü kalırsa değişim başarılı.")
	status.text = "Kapak testi · 0 / 1 atım"
	_say("Yeni kapak takıldı. Pompa testi başladı.", GOOD)
	_start_pump()


func _evaluate_replacement_cycle() -> void:
	_stop_pump()
	if Network.valve_health(Model.Valve.AORTIC, _net_slots(), defects) >= 0.99:
		replacement_trial = false
		_tween_oxygen(0.82, 2.5)
		_say("Kapak testi başarılı. Kan tek yönlü akıyor.", GOOD)
		_finish_diagnose()
		return
	step = Step.REPLACE
	stage.valve_marked[Model.Valve.AORTIC] = true
	stage.spots_active[StringName("valve_%d" % Model.Valve.AORTIC)] = true
	_set_ui("4 · TEŞHİS", "Kapağı yeniden konumlandır", "Aort kapağı geri kaçırıyor. Yönünü düzeltip pompa testini tekrarla.", "Pompayı tekrar dene")
	action.disabled = false
	_say("Akış hâlâ geri kaçıyor. Kapağın yönünü düzelt.", BAD)


func _finish_diagnose() -> void:
	if step != Step.DIAGNOSE:
		return
	replacement_trial = false
	_stop_pump()
	_set_ui("4 · TEŞHİS", "Geri akış durdu",
		"Aort kapağı gevşeme sırasında kapandı. Kan yalnız ileri akıyor. Şimdi kalbin dışındaki damarlar kopmuş, onları kendin bağlayacaksın.", "Damarları bağla")


# --- 5 · Damarları bağla -----------------------------------------------

func _enter_connect() -> void:
	step = Step.CONNECT
	stage.pooled = {}
	stage.consequence_hold = 0.0
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
		"Kirli (oksijence fakir) kan: vücut → ana toplardamar → sağ kulakçık → sağ karıncık → akciğer atardamarı → akciğer. Oksijenlenen kan: akciğer toplardamarı → sol kulakçık → sol karıncık → aort → vücut. Bağlantıların sonucunu kan akışında ve doku O₂ göstergesinde izle.")
	hud.set_note("Kirli kanı taşıyan ana toplardamar sağ kulakçığa; akciğerden oksijenli kanı getiren akciğer toplardamarı sol kulakçığa bağlanır. Sağ karıncık → akciğer atardamarı → akciğer; sol karıncık → aort → vücut. Yanlış bağlantı dolaşım halkasını keser ve doku oksijenini düşürür. Koyu bordo: oksijence fakir kan · parlak kırmızı: oksijenli kan.")
	hud.set_directive("Damarları doğru girişlere sürükle; akışı gözle.")
	status.text = "Bağlı 0/4  ·  Doğru 0/4  ·  Doku O₂ %0"
	_tween_oxygen(0.0)


func _on_link(from_port: StringName, to_port: StringName) -> void:
	if step != Step.CONNECT:
		return
	var result: Dictionary = Network.replace_link(stage.connections, from_port, to_port)
	if not result["ok"]:
		if result["reason"] == &"occupied":
			_say("%s girişi başka bir damara bağlı. Mevcut bağlantıyı korudum; önce dolu hattı Shift+tıkla sök." % Stage.PORT_NAMES[to_port], BAD)
		else:
			_say("Bu damar ucu bu aşamada bağlanamaz.", BAD)
		return
	stage.connections = result["links"]
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
			return "Oksijence fakir kan doğrudan vücuda gidiyor; dokulara oksijen ulaşmıyor." if not rich else "Doğru yön, ama bu çıkışın girişi başka."
		&"pv_in":
			return "Oksijence fakir kan sol kulakçığa gidiyor. Önce sağ kalpten akciğere ulaşmalı." if not rich else "Akciğerde oksijenlenen kan akciğer toplardamarıyla sol kulakçığa gelir; bu çıkış başka yere ait."
		&"lungs_in":
			return "Oksijenli kan yeniden akciğere gönderiliyor; bu hatta oksijence fakir kan gelmeli." if rich else "Oksijence fakir kanı sağ karıncık akciğer atardamarıyla akciğere gönderir."
		&"svc_in":
			return "Oksijenli kan sağ kulakçığa dönüyor; akciğerden sol kulakçığa gelmeli." if rich else "Doğru: oksijence fakir kan, vücuttan ana toplardamarla sağ kulakçığa döner."
	return "Bu bağlantı yanlış."


func _refresh_links() -> void:
	var good := 0
	for from_port in stage.connections:
		if stage.connections[from_port] == Stage.CORRECT_LINKS[from_port]:
			good += 1
	var consequence: Dictionary = Network.evaluate(stage.connections, _net_slots(), defects)
	var tissue_oxygen: float = consequence["body_oxygen"]
	status.text = "Bağlı %d / 4  ·  Doğru %d / 4  ·  Doku O₂ %%%d" % [stage.connections.size(), good, roundi(tissue_oxygen * 100.0)]
	stage.connection_flow = stage.connections.size() > 0
	stage.show_flow = true
	if not stage.connection_flow:
		_stop_pump()
	elif not running:
		running = true
		pause.hide()
		_apply_phase_connect()
	_tween_oxygen(tissue_oxygen, 0.8)
	if good == 4:
		stage.ports_active = false
		stage.port_warning = {}
		_start_pump()
		_tween_oxygen(tissue_oxygen, 1.2)
		_set_ui("5 · DAMARLAR", "İki dolaşım kapandı",
			"Küçük dolaşım: sağ karıncık → akciğer atardamarı → akciğer → akciğer toplardamarları → sol kulakçık. Büyük dolaşım: sol karıncık → aort → vücut → ana toplardamarlar → sağ kulakçık. Kan tek yönlü ve kapalı bir halkada.", "Akışı ayarla")
		status.text = "Bağlı 4/4  ·  Doğru 4/4  ·  Doku O₂ %%%d" % roundi(tissue_oxygen * 100.0)


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
	rate_label.custom_minimum_size.x = 440
	rate_label.add_theme_color_override("font_color", Color("#d4a15f"))
	question.add_child(rate_label)
	question_scroll.show()
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
			"Kalp hızı %d atım/dk, debi %d mL/dk: dokuların istediği kadar kan taşınıyor. Kan tek yönlü, iki dolaşım kapalı, oksijen yerine ulaşıyor." % [int(heart_rate), int(heart_rate * STROKE_VOLUME)], "Müdahale masası")
		_say("Onarıldı.", GOOD)
		Audio.play_sfx("heart_restored_flow", -8.0)
		completed.emit()
	elif ratio < 0.95:
		_say("Debi dokuların ihtiyacının altında. Gereken hızı hesapla: 10500 mL ÷ 70 mL.", BAD)
	else:
		_say("Debi gereğinden fazla. Kalp boşuna yoruluyor. İhtiyaca eşit hızı bul.", BAD)


# --- Müdahale masası ----------------------------------------------------

const LAB_TOOLS := [
	[&"leak", "Sızdır", "Kapakta geri kaçış oluştur"], [&"flip", "Yönünü çevir", "Kapağı ters tak veya düzelt"],
	[&"fix", "Kapağı değiştir", "Sızıntıyı yeni kapakla gider"], [&"clamp", "Damarı kapat", "Damar akışını kes veya aç"],
]
const VESSEL_OF_SPOT := {
	&"svc": Circ.CAVAL, &"pulmonary_artery": Circ.LUNGS, &"pulmonary_veins": Circ.PULM_VEIN, &"aorta": Circ.BODY,
}
const VESSEL_NAMES := {
	Circ.CAVAL: "Ana toplardamar", Circ.LUNGS: "Akciğer atardamarı", Circ.PULM_VEIN: "Akciğer toplardamarı", Circ.BODY: "Aort",
}
var lab_tool: StringName = &"leak"
var _lab_last_report := ""


func _enter_lab() -> void:
	step = Step.LAB
	slots = _full_slots()
	defects = {}
	_sync_circulation()
	circ.stabilize(6.0)
	circ.last_beat = {}
	lab_leak.clear()
	lab_clamp.clear()
	heart_rate = REST_RATE
	stage.connections = Stage.CORRECT_LINKS.duplicate()
	stage.port_warning = {}
	stage.ports_active = false
	stage.connection_flow = true
	stage.labels.clear()
	stage.highlight = &""
	stage.valve_marked.clear()
	for id in Stage.SPOTS:
		stage.spots_active[id] = id in VESSEL_OF_SPOT
	for valve in Model.VALVE_NAMES:
		stage.spots_active[StringName("valve_%d" % valve)] = true
	_set_ui("MÜDAHALE", "Müdahale masası", "Aracı seç, kapağa ya da damara tıkla. Kanın yönüne ve debiye bak.")
	hud.set_directive("Bir araç seç, kapağa ya da damara tıkla. Kanın yönüne bak.")
	tray_scroll.show()
	question_scroll.show()
	pause.hide()
	var group := ButtonGroup.new()
	for entry in LAB_TOOLS:
		var button := Button.new()
		button.toggle_mode = true
		button.button_group = group
		button.text = entry[1]
		hud.style_control(button)
		button.tooltip_text = entry[2]
		button.add_theme_font_size_override("font_size", 14)
		button.button_pressed = entry[0] == lab_tool
		button.toggled.connect(func(on: bool) -> void:
			if on:
				lab_tool = entry[0])
		tray.add_child(button)
	_lab_slider("Hız", 40.0, 180.0, REST_RATE, func(v: float) -> void: heart_rate = v)
	var reset := Button.new()
	reset.text = "Sağlıklı hâle getir"
	hud.style_control(reset, true)
	reset.pressed.connect(_lab_reset)
	question.add_child(reset)
	_start_pump()
	status.text = ""


func _lab_slider(title: String, low: float, high: float, value: float, on_change: Callable) -> void:
	var label := Label.new()
	label.text = title
	label.add_theme_color_override("font_color", MUTED)
	question.add_child(label)
	var slider_node := HSlider.new()
	slider_node.min_value = low
	slider_node.max_value = high
	slider_node.step = 0.01 if high < 5.0 else 1.0
	slider_node.value = value
	slider_node.custom_minimum_size = Vector2(150, 0)
	slider_node.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	slider_node.value_changed.connect(on_change)
	question.add_child(slider_node)


func _lab_reset() -> void:
	lab_leak.clear()
	lab_clamp.clear()
	heart_rate = REST_RATE
	_say("Tüm müdahaleler geri alındı.", GOOD)
	_lab_last_report = ""
	for child in question.get_children():
		if child is HSlider:
			(child as HSlider).value = REST_RATE


func _lab_valve(slot: int) -> void:
	var name: String = Model.VALVE_NAMES[slot]
	match lab_tool:
		&"leak":
			lab_leak[slot] = minf(lab_leak.get(slot, 0.0) + 0.3, 0.9)
			Sfx.play(&"click")
			_say("%s sızdırıyor (%%%d)." % [name, roundi(lab_leak[slot] * 100.0)], BAD)
		&"flip":
			flips[slot] = not flips.get(slot, false)
			Sfx.play(&"click")
			_say("%s ters takıldı: kan ileri geçemiyor." % name if flips[slot] else "%s doğru yönde." % name, BAD if flips[slot] else GOOD)
		&"fix":
			lab_leak.erase(slot)
			flips[slot] = false
			Sfx.play(&"snap")
			_say("%s yenisiyle değişti." % name, GOOD)
		_:
			_say("Bu araç kapağa uygulanmaz. Kapak araçlarını seç.")


func _lab_click(id: StringName) -> void:
	if VESSEL_OF_SPOT.has(id):
		var vessel: StringName = VESSEL_OF_SPOT[id]
		if lab_tool == &"clamp":
			lab_clamp[vessel] = 0.0 if lab_clamp.get(vessel, 0.0) > 0.0 else 0.8
			Sfx.play(&"snap")
			_say("%s %s." % [VESSEL_NAMES[vessel], "kelepçelendi" if lab_clamp[vessel] > 0.0 else "açıldı"], BAD if lab_clamp[vessel] > 0.0 else GOOD)
		elif lab_tool == &"fix":
			lab_clamp.erase(vessel)
			_say("%s açıldı." % VESSEL_NAMES[vessel], GOOD)
		else:
			_say("Damar için kelepçe aracını seç.")


func _report_lab() -> void:
	var b := circ.last_beat
	status.text = "Debi %.1f L/dk  ·  Nabız %d  ·  Doku O₂ %%%d" % [
		b["cardiac_output"], roundi(heart_rate), roundi(b["tissue"] * 100.0)]
	stage.body_oxygen = b["tissue"]
	var text := ""
	var worst := 0.0
	for f in circ.findings():
		if f["severity"] > worst and f["kind"] in [&"regurgitation", &"occlusion"]:
			worst = f["severity"]
			text = _describe_finding(f)
	if text != "" and text != _lab_last_report:
		hud.say(text, &"bad")
	_lab_last_report = text


func _describe_finding(f: Dictionary) -> String:
	match f["kind"]:
		&"regurgitation":
			var valve := _valve_of_link(f["valve"])
			var from: String = Model.SLOT_NAMES[Model.SLOT_OF[valve][1]]
			var to: String = Model.SLOT_NAMES[Model.SLOT_OF[valve][0]]
			return "%s kapanmıyor: kan %s → %s geri kaçıyor." % [Model.VALVE_NAMES[valve], from, to]
		&"occlusion":
			return "%s kapalı: dolaşım halkası koptu, kan ilerleyemiyor." % VESSEL_NAMES.get(f["vessel"], "Damar")
	return ""


func _valve_of_link(link: StringName) -> int:
	for valve in LINK_OF:
		if LINK_OF[valve] == link:
			return valve
	return 0


# --- Geri ---------------------------------------------------------------

func _go_back() -> void:
	## Genel resme (kontrol merkezi) döner. Sahne tek başına açıldıysa merkez sahnesine geçer.
	if _oxygen_tween != null:
		_oxygen_tween.kill()
	running = false
	if get_parent() == get_tree().root:
		get_tree().change_scene_to_file("res://scenes/control_center.tscn")
	else:
		exit_requested.emit()


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
		Step.LAB:
			_lab_click(id)


func _on_action() -> void:
	match step:
		Step.RECOGNIZE:
			_enter_pump()
		Step.PUMP:
			if cycles > 0:
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
		Step.REPLACE:
			_test_aortic_replacement()
		Step.CONNECT:
			if action.text == "Akışı ayarla":
				_enter_rate()
		Step.RATE:
			_check_rate()
		Step.DONE:
			_enter_lab()
