extends "res://scripts/physics/experiment_mission.gd"
## AYT Fizik · Vektörler (11.1.1.3). KRİZ: Liman otopilotu iki itişi büyüklük olarak toplayıp (3 + 4 = 7) kapsülü yanaşma
## noktasının ötesine fırlatıyor. Gerçekte bileşke iki vektörün uç uca eklenmesiyle bulunur ve yön de hesaba girer (|R| = 5).
## Hesap burada, çizim harbor_stage.gd'de. İki itiş arasındaki açı yalnızca TEST adımında seçilir.

const Harbor = preload("res://stations/vectors/harbor_stage.gd")

const BOTTOM_BAND := 88.0
const CRISIS_DOCK := Vector2(3, 4)
const RESCUE_DOCK := Vector2(8, 6)
const OFF_QUAY := Vector2(-20, -20)
const DOCK_TOLERANCE := 0.5

enum Step { CRISIS, TEST, REASON, MEASURE, RESCUE }

var step := Step.CRISIS
var _a := 3.0
var _b := 4.0
var _angle := 90.0
var _seen_same := false
var _seen_opposite := false
var _seen_perpendicular := false
var _east := 0.0
var _north := 0.0
var _readout: Label
var _flying := false


func _begin() -> void:
	process_priority = 10
	step_total = 5
	_readout = Label.new()
	_readout.add_theme_font_size_override("font_size", 15)
	_readout.add_theme_color_override("font_color", UITheme.GAME_TEXT)
	hud.add_child(_readout)
	hud.below_directive.append(_readout)
	_readout.hide()
	view().flight_finished.connect(_on_flight_finished)
	_enter_crisis()


func _make_stage() -> Control:
	return Harbor.new()


func view() -> Harbor:
	return stage as Harbor


func _process(_delta: float) -> void:
	if hud == null or stage == null:
		return
	stage.offset_bottom = -maxf(BOTTOM_BAND, tools.size.y + 40.0)
	# Dar kutuda yönerge ve ölçü satırı sahnenin üstünü örtmesin: sahne onların altından başlar.
	var top := 0.0
	if size.x < 700.0:
		top = hud.directive.position.y + hud.directive.size.y + 8.0
		if _readout.visible:
			top = _readout.position.y + _readout.size.y + 6.0
	stage.offset_top = top


func screen(index: int, label: String, directive: String, action_text: String = "", note: String = "") -> void:
	super.screen(index, label, directive, action_text, note)
	_readout.hide()


func _vector_b() -> Vector2:
	return Vector2.from_angle(deg_to_rad(_angle)) * _b


func _show_vectors(a_vec: Vector2, b_vec: Vector2, resultant: bool) -> void:
	view().set_arrow("A", Vector2.ZERO, a_vec)
	view().set_arrow("B", a_vec, a_vec + b_vec)
	view().set_arrow("R", Vector2.ZERO, a_vec + b_vec, resultant)


func _num(value: float) -> String:
	return str(snappedf(value, 0.1)).replace(".0", "").replace(".", ",")


# --- KRİZ ---

func _enter_crisis() -> void:
	step = Step.CRISIS
	_flying = true
	view().reset_capsule()
	view().place_dock(CRISIS_DOCK)
	_a = 3.0
	_b = 4.0
	_angle = 90.0
	_show_vectors(Vector2(3, 0), Vector2(0, 4), false)
	screen(0, "KRİZ", "Otopilot 3 + 4 = 7 birim topladı, kapsül yanaşma noktasını geçti.", "Nedenini bul",
		"Rıhtımda iki itici çalışıyor: biri 3 birim doğuya, diğeri 4 birim kuzeye. Otopilot kapsülü yanaşma noktasına doğru 7 birim sürüyor.")
	hud.set_action("Nedenini bul", false)
	hud.skip.show()
	view().fly([CRISIS_DOCK * (7.0 / 5.0)], 2.4)


func _on_flight_finished() -> void:
	_flying = false
	match step:
		Step.CRISIS:
			view().set_dock_state(&"miss")
			hud.skip.hide()
			hud.set_action("Nedenini bul", true)
		Step.TEST:
			_after_test_flight()
		Step.MEASURE:
			_enter_rescue()
		Step.RESCUE:
			_judge_rescue()


func _on_skip() -> void:
	if step == Step.CRISIS:
		view().reset_capsule()
		view().place_dock(CRISIS_DOCK)
		var end := CRISIS_DOCK * (7.0 / 5.0)
		view().fly([end], 0.01)


# --- SINA ---

func _enter_test() -> void:
	step = Step.TEST
	_seen_same = false
	_seen_opposite = false
	_seen_perpendicular = false
	_a = 3.0
	_b = 4.0
	_angle = 90.0
	view().reset_capsule()
	view().place_dock(OFF_QUAY)
	screen(1, "SINA", "İtişleri ve açıyı değiştir, kapsülü uçur. Bileşke nereye varıyor?", "",
		"Üç duruma bak: iki itiş aynı yöne (0°), zıt yöne (180°) ve birbirine dik (90°) olunca bileşke ne kadar?")
	_make_sliders()
	add_power("Uçur", "Kapsül önce A, sonra B boyunca gider", _fly_test)
	_refresh_test()


func _make_sliders() -> void:
	add_slider("İtiş A (birim)", 0.0, 8.0, _a, 1.0, func(v: float) -> void:
		_a = v
		_refresh_test(), 170.0)
	add_slider("İtiş B (birim)", 0.0, 8.0, _b, 1.0, func(v: float) -> void:
		_b = v
		_refresh_test(), 170.0)
	add_slider("A ile B arası açı (°)", 0.0, 180.0, _angle, 30.0, func(v: float) -> void:
		_angle = v
		_refresh_test(), 190.0)


func _refresh_test() -> void:
	var b_vec := _vector_b()
	_show_vectors(Vector2(_a, 0), b_vec, true)
	var resultant := Vector2(_a, 0) + b_vec
	_readout.text = "|A| = %s   |B| = %s   |A| + |B| = %s   Bileşke |R| = %s" % [_num(_a), _num(_b), _num(_a + _b), _num(resultant.length())]
	_readout.show()


func _fly_test() -> void:
	if _flying or step != Step.TEST:
		return
	view().reset_capsule()
	var a_vec := Vector2(_a, 0)
	_flying = true
	view().fly([a_vec, a_vec + _vector_b()], 1.8)


func _after_test_flight() -> void:
	if _a <= 0.0 or _b <= 0.0:
		say("İki itişi de sıfırdan büyük seç; tek itişte bileşke o itişin kendisi.", BAD)
		return
	var resultant := (Vector2(_a, 0) + _vector_b()).length()
	if is_equal_approx(_angle, 0.0) and not _seen_same:
		_seen_same = true
		say("Aynı yön: |R| = %s = %s + %s. Aynı doğrultuda büyüklükler toplanır." % [_num(resultant), _num(_a), _num(_b)], GOOD)
	elif is_equal_approx(_angle, 180.0) and not _seen_opposite and not is_equal_approx(_a, _b):
		_seen_opposite = true
		say("Zıt yön: |R| = %s = |%s − %s|. Zıt doğrultuda büyüklükler çıkarılır." % [_num(resultant), _num(_a), _num(_b)], GOOD)
	elif is_equal_approx(_angle, 90.0) and not _seen_perpendicular:
		_seen_perpendicular = true
		say("Dik: |R| = %s, oysa |A| + |B| = %s. Bileşke toplamdan kısa, çünkü iki itiş farklı yönlerde." % [_num(resultant), _num(_a + _b)], GOOD)
	if _seen_same and _seen_opposite and _seen_perpendicular:
		hud.set_action("Nedeni seç", true)


# --- NEDEN ---

func _enter_reason() -> void:
	step = Step.REASON
	view().hide_arrows()
	view().reset_capsule()
	view().place_dock(CRISIS_DOCK)
	screen(2, "NEDEN", "Otopilot kapsülü neden yanaşma noktasının ötesine gönderdi?", "",
		"Üç durumda gördüğün şey: bileşke bazen toplam, bazen fark, dik olunca ikisinden de farklı.")
	var options := {
		&"scalar": "Vektörlerin büyüklüğü yön hesaba katılmadan toplanır",
		&"vector": "Bileşke, vektörler uç uca eklenerek bulunur; açı büyüklüğü değiştirir",
		&"longer": "Bileşke her zaman iki vektörden uzundur",
	}
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 6)
	tools.add_child(list)
	for choice in options:
		var button := Button.new()
		button.text = options[choice]
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.pressed.connect(_on_reason.bind(choice))
		list.add_child(button)


func _on_reason(choice: StringName) -> void:
	match choice:
		&"vector":
			say("Doğru. 3 birim doğu ve 4 birim kuzey uç uca eklenince bileşke 5 birim; otopilot 7 diye toplayıp 2 birim fazla gitti.", GOOD)
			clear_tools()
			hud.set_action("Bileşkeyi hesapla", true)
		&"scalar":
			say("Büyüklükleri düz toplamak yalnızca aynı yönde doğru. Dik duruma bak: |R| toplam kadar çıkmadı.", BAD)
		_:
			say("Zıt yönde bileşke iki vektörden de kısa kalabiliyor. Bileşke her zaman uzun değil.", BAD)


# --- ÖLÇ ---

func _enter_measure() -> void:
	step = Step.MEASURE
	_a = 3.0
	_b = 4.0
	_angle = 90.0
	view().reset_capsule()
	view().place_dock(OFF_QUAY)
	_show_vectors(Vector2(3, 0), Vector2(0, 4), false)
	screen(3, "ÖLÇ", "A = 3 doğu, B = 4 kuzey. Bileşke |R| kaç birim?", "Onayla",
		"Rıhtımdaki iki oku uç uca düşün: bir dik üçgenin iki kenarı.")
	add_entry("|R|  (birim)")


func _check_measure() -> void:
	var value := read_number()
	if is_nan(value):
		say("Birim cinsinden bir sayı gir. Örnek: 5", BAD)
		return
	if absf(value - 5.0) <= 0.1:
		say("|R| = √(3² + 4²) = 5 birim. Kapsül bu bileşke boyunca yanaşır.", GOOD)
		_show_vectors(Vector2(3, 0), Vector2(0, 4), true)
		view().place_dock(CRISIS_DOCK)
		_flying = true
		hud.set_action("Onayla", false)
		view().fly([Vector2(3, 0), Vector2(3, 4)], 1.6)
	elif absf(value - 7.0) <= 0.1:
		say("7, iki büyüklüğün düz toplamı: otopilotun hatası. Dik iki kenarın bileşkesi daha kısa.", BAD)
	elif absf(value - 1.0) <= 0.1:
		say("Fark yalnızca zıt yönde alınır. Burada iki itiş birbirine dik.", BAD)
	else:
		say("Dik iki itiş: bileşke, 3 ve 4 kenarlı dik üçgenin hipotenüsü.", BAD)


# --- KURTAR ---

func _enter_rescue() -> void:
	step = Step.RESCUE
	_east = 0.0
	_north = 0.0
	_flying = false
	view().reset_capsule()
	view().place_dock(RESCUE_DOCK)
	_show_vectors(Vector2.ZERO, Vector2.ZERO, false)
	screen(4, "KURTAR", "Hedef 10 birim uzakta, doğudan 37° kuzeyde. Doğu ve kuzey itişlerini seç.", "Yanaş",
		"Yedek iticiler yalnızca doğuya ve kuzeye çalışıyor. cos 37° ≈ 0,8 ve sin 37° ≈ 0,6 al.")
	add_slider("Doğu itişi (birim)", 0.0, 12.0, _east, 1.0, func(v: float) -> void:
		_east = v
		_refresh_rescue(), 190.0)
	add_slider("Kuzey itişi (birim)", 0.0, 12.0, _north, 1.0, func(v: float) -> void:
		_north = v
		_refresh_rescue(), 190.0)


func _refresh_rescue() -> void:
	view().reset_capsule()
	view().place_dock(RESCUE_DOCK)
	_show_vectors(Vector2(_east, 0), Vector2(0, _north), true)


func _run_rescue() -> void:
	if _flying:
		return
	if _east <= 0.0 and _north <= 0.0:
		say("İki itişi de sıfır bırakma: kapsül yerinden kıpırdamaz.", BAD)
		return
	view().reset_capsule()
	_show_vectors(Vector2(_east, 0), Vector2(0, _north), true)
	_flying = true
	hud.set_action("Yanaş", false)
	view().fly([Vector2(_east, 0), Vector2(_east, _north)], 1.8)


func _judge_rescue() -> void:
	hud.set_action("Yanaş", true)
	var landing := Vector2(_east, _north)
	if landing.distance_to(RESCUE_DOCK) <= DOCK_TOLERANCE:
		view().set_dock_state(&"ok")
		seal("Bileşke, vektörlerin uç uca eklenmesidir; büyüklükler yön hesaba katılmadan toplanamaz.", "Otopilot vektörlerle yeniden kuruldu.")
		return
	view().set_dock_state(&"miss")
	if is_equal_approx(_east + _north, 10.0):
		say("Büyüklüklerin toplamı 10 ama bileşke 10 değil: %s + %s dik duruyor, |R| = %s." % [_num(_east), _num(_north), _num(landing.length())], BAD)
	elif absf(landing.length() - 10.0) <= 0.6:
		say("Uzaklık doğru (|R| = %s) ama yön yanlış: kapsül doğudan %s° kuzeye gitti, hedef 37°." % [_num(landing.length()), _num(rad_to_deg(landing.angle()))], BAD)
	else:
		say("Kapsül (%s, %s) noktasına vardı. Hedefe %s birim kaldı. Doğu ve kuzey bileşenlerini 10 birimlik bileşkeden çıkar." % [_num(_east), _num(_north), _num(landing.distance_to(RESCUE_DOCK))], BAD)
	view().set_dock_state(&"miss")


func _on_action() -> void:
	match step:
		Step.CRISIS:
			_enter_test()
		Step.TEST:
			_enter_reason()
		Step.REASON:
			_enter_measure()
		Step.MEASURE:
			_check_measure()
		Step.RESCUE:
			_run_rescue()
