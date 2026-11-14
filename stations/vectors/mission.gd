extends "res://scripts/physics/experiment_mission.gd"
## AYT Fizik · Vektörler (11.1.1.3), üç boyutta. KRİZ: Liman otopilotu üç itişi büyüklük olarak toplayıp (2 + 3 + 6 = 11)
## drone'u yanaşma halkasının ötesine sürüyor. Gerçekte bileşke uç uca eklenir ve dik bileşenlerde |R| = √(x² + y² + z²) = 7.
## Hesap burada, çizim harbor_stage.gd'de.

const Harbor = preload("res://stations/vectors/harbor_stage.gd")

const CRISIS_DOCK := Vector3(2, 3, 6)
const RESCUE_DOCK := Vector3(4, 4, 7)
const OFF_SCENE := Vector3(-20, -20, 0)
const DOCK_TOLERANCE := 0.5

enum Step { CRISIS, TEST, REASON, MEASURE, RESCUE }

var step := Step.CRISIS
var _vec := Vector3(2, 3, 6)
var _seen_single := false
var _seen_plane := false
var _seen_space := false
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
	# Alt şerit: araçlar + üstlerinde bildirimin sığacağı yer. Bildirim sahneyi örtmez.
	stage.offset_bottom = -(tools.size.y + 40.0 + 64.0)
	# Dar kutuda sahne tüm yüksekliği kullanır; yönerge solda kaldığı için kafes sağa kaydırılır.
	var compact := size.x < 760.0
	stage.offset_top = 0.0
	view().view_shift = Vector3(-1.5, 0.15, 0.0) if compact else Vector3.ZERO


func screen(index: int, label: String, directive: String, action_text: String = "", note: String = "") -> void:
	super.screen(index, label, directive, action_text, note)
	_readout.hide()


## Üç kaydırıcı ve eylem düğmesi dar kutuda da yan yana sığsın.
func _slider_width() -> float:
	var action_room := 190.0 + 16.0
	return clampf((size.x - 36.0 - action_room - 24.0) / 3.0, 90.0, 190.0)


func _num(value: float) -> String:
	return str(snappedf(value, 0.1)).replace(".0", "").replace(".", ",")


## x, y, z bileşenlerini uç uca eklenmiş üç ok olarak çizer; `resultant` bileşke okunu da gösterir.
func _show_vectors(vec: Vector3, resultant: bool) -> void:
	var a := Vector3(vec.x, 0, 0)
	var b := Vector3(vec.x, vec.y, 0)
	view().set_arrow("A", Vector3.ZERO, a)
	view().set_arrow("B", a, b)
	view().set_arrow("C", b, vec)
	view().set_arrow("R", Vector3.ZERO, vec, resultant)


func _path_of(vec: Vector3) -> Array:
	return [Vector3(vec.x, 0, 0), Vector3(vec.x, vec.y, 0), vec]


# --- KRİZ ---

func _enter_crisis() -> void:
	step = Step.CRISIS
	_flying = true
	view().reset_capsule()
	view().place_dock(CRISIS_DOCK)
	_show_vectors(CRISIS_DOCK, false)
	screen(0, "KRİZ", "Otopilot 2 + 3 + 6 = 11 topladı; drone halkayı geçti.", "Nedenini bul",
		"Üç itici çalışıyor: 2 birim doğuya, 3 birim kuzeye, 6 birim yukarı. Otopilot drone'u halkaya doğru 11 birim sürdü.")
	hud.set_action("Nedenini bul", false)
	hud.skip.show()
	view().fly([CRISIS_DOCK * (11.0 / CRISIS_DOCK.length())], 2.6)


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
		view().fly([CRISIS_DOCK * (11.0 / CRISIS_DOCK.length())], 0.01)


# --- SINA ---

func _enter_test() -> void:
	step = Step.TEST
	_seen_single = false
	_seen_plane = false
	_seen_space = false
	_vec = Vector3(2, 3, 6)
	view().reset_capsule()
	view().place_dock(OFF_SCENE)
	screen(1, "SINA", "Üç itişi ayarla, drone'u uçur; bileşkeye bak.", "",
		"Üç duruma bak: yalnız bir eksende, iki eksende ve üç eksende itiş verince bileşke ne kadar? Kamerayı fareyle sürükleyerek çevirebilirsin.")
	add_slider("Doğu itişi (birim)", 0.0, 8.0, _vec.x, 1.0, func(v: float) -> void:
		_vec.x = v
		_refresh_test(), _slider_width())
	add_slider("Kuzey itişi (birim)", 0.0, 8.0, _vec.y, 1.0, func(v: float) -> void:
		_vec.y = v
		_refresh_test(), _slider_width())
	add_slider("Yukarı itişi (birim)", 0.0, 8.0, _vec.z, 1.0, func(v: float) -> void:
		_vec.z = v
		_refresh_test(), _slider_width())
	add_power("Uçur", "Drone önce doğuya, sonra kuzeye, sonra yukarı gider", _fly_test)
	_refresh_test()


func _refresh_test() -> void:
	_show_vectors(_vec, true)
	_readout.text = "x = %s   y = %s   z = %s   toplam = %s   Bileşke |R| = %s" % [_num(_vec.x), _num(_vec.y), _num(_vec.z), _num(_vec.x + _vec.y + _vec.z), _num(_vec.length())]
	_readout.show()


func _fly_test() -> void:
	if _flying or step != Step.TEST:
		return
	view().reset_capsule()
	_flying = true
	view().fly(_path_of(_vec), 2.2)


func _nonzero_axes(vec: Vector3) -> int:
	return int(vec.x > 0.0) + int(vec.y > 0.0) + int(vec.z > 0.0)


func _after_test_flight() -> void:
	var axes := _nonzero_axes(_vec)
	if axes == 0:
		say("En az bir itişi sıfırdan büyük seç.", BAD)
		return
	if axes == 1 and not _seen_single:
		_seen_single = true
		say("Tek eksen: |R| = %s, itişin kendisi. Tek doğrultuda toplam ile bileşke aynı." % _num(_vec.length()), GOOD)
	elif axes == 2 and not _seen_plane:
		_seen_plane = true
		say("İki dik eksen: |R| = √(x² + y²) = %s, toplam %s. Bileşke toplamdan kısa." % [_num(_vec.length()), _num(_vec.x + _vec.y + _vec.z)], GOOD)
	elif axes == 3 and not _seen_space:
		_seen_space = true
		say("Üç eksen: |R| = √(x² + y² + z²) = %s, toplam %s. Yükseklik de bileşkeye girer." % [_num(_vec.length()), _num(_vec.x + _vec.y + _vec.z)], GOOD)
	if _seen_single and _seen_plane and _seen_space:
		hud.set_action("Nedeni seç", true)


# --- NEDEN ---

func _enter_reason() -> void:
	step = Step.REASON
	view().hide_arrows()
	view().reset_capsule()
	view().place_dock(CRISIS_DOCK)
	screen(2, "NEDEN", "Otopilot drone'u neden halkanın ötesine sürdü?", "",
		"Üç durumda gördüğün şey: bileşke ancak tek eksende toplam kadar, çok eksende toplamdan kısa.")
	var options := {
		&"scalar": "Vektörlerin büyüklükleri yön hesaba katılmadan toplanır",
		&"vector": "Bileşke uç uca eklenerek bulunur: dik bileşenlerde karelerin toplamının kökü alınır",
		&"height": "Yukarı itiş uzunluğa katılmaz, yalnız yatay itişler sayılır",
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
			say("Doğru. 2, 3 ve 6 dik bileşenler: |R| = √(4 + 9 + 36) = 7. Otopilot 11 diye toplayıp 4 birim fazla gitti.", GOOD)
			clear_tools()
			hud.set_action("Bileşkeyi hesapla", true)
		&"scalar":
			say("Düz toplam yalnızca tek doğrultuda doğru. İki ve üç eksende bileşke toplamdan kısa çıktı.", BAD)
		_:
			say("Yukarı itiş de bileşkenin bir parçası: üç eksende |R| üç bileşenin hepsinden hesaplandı.", BAD)


# --- ÖLÇ ---

func _enter_measure() -> void:
	step = Step.MEASURE
	_vec = CRISIS_DOCK
	view().reset_capsule()
	view().place_dock(OFF_SCENE)
	_show_vectors(_vec, false)
	screen(3, "ÖLÇ", "x = 2 doğu, y = 3 kuzey, z = 6 yukarı. Bileşke |R| kaç birim?", "Onayla",
		"Üç dik bileşen: önce yatay düzlemdeki bileşkeyi, sonra yükseklikle birleştir.")
	add_entry("|R|  (birim)")


func _check_measure() -> void:
	var value := read_number()
	if is_nan(value):
		say("Birim cinsinden bir sayı gir. Örnek: 7", BAD)
		return
	if absf(value - 7.0) <= 0.1:
		say("|R| = √(2² + 3² + 6²) = 7 birim. Drone bu bileşke boyunca yanaşır.", GOOD)
		_show_vectors(_vec, true)
		view().place_dock(CRISIS_DOCK)
		_flying = true
		hud.set_action("Onayla", false)
		view().fly(_path_of(_vec), 2.0)
	elif absf(value - 11.0) <= 0.1:
		say("11, üç büyüklüğün düz toplamı: otopilotun hatası. Dik bileşenlerin bileşkesi daha kısa.", BAD)
	elif absf(value - sqrt(13.0)) <= 0.15:
		say("Bu yalnız yatay düzlemdeki bileşke (√13). Yükseklik z = 6'yı da kat.", BAD)
	else:
		say("Üç dik bileşen: |R|² = x² + y² + z². Önce karelerin toplamını bul, sonra kökünü al.", BAD)


# --- KURTAR ---

func _enter_rescue() -> void:
	step = Step.RESCUE
	_vec = Vector3.ZERO
	_flying = false
	view().reset_capsule()
	view().place_dock(RESCUE_DOCK)
	_show_vectors(_vec, false)
	screen(4, "KURTAR", "Halkanın x, y, z konumunu eksenlerden oku; drone'u yanaştır.", "Yanaş",
		"Kesikli çizgiler halkanın zeminde ve eksenlerdeki izdüşümünü gösterir: x, y ve z değerlerini oradan oku.")
	add_slider("Doğu itişi (birim)", 0.0, 8.0, 0.0, 1.0, func(v: float) -> void:
		_vec.x = v
		_refresh_rescue(), _slider_width())
	add_slider("Kuzey itişi (birim)", 0.0, 8.0, 0.0, 1.0, func(v: float) -> void:
		_vec.y = v
		_refresh_rescue(), _slider_width())
	add_slider("Yukarı itişi (birim)", 0.0, 8.0, 0.0, 1.0, func(v: float) -> void:
		_vec.z = v
		_refresh_rescue(), _slider_width())


func _refresh_rescue() -> void:
	view().reset_capsule()
	view().place_dock(RESCUE_DOCK)
	_show_vectors(_vec, true)


func _run_rescue() -> void:
	if _flying:
		return
	if _vec == Vector3.ZERO:
		say("Üç itişi de sıfır bırakma: drone yerinden kıpırdamaz.", BAD)
		return
	view().reset_capsule()
	_show_vectors(_vec, true)
	_flying = true
	hud.set_action("Yanaş", false)
	view().fly(_path_of(_vec), 2.2)


func _judge_rescue() -> void:
	hud.set_action("Yanaş", true)
	if _vec.distance_to(RESCUE_DOCK) <= DOCK_TOLERANCE:
		view().set_dock_state(&"ok")
		seal("Bileşke, vektörlerin uç uca eklenmesidir; büyüklükler yön hesaba katılmadan toplanamaz.", "Otopilot vektörlerle yeniden kuruldu.")
		return
	view().set_dock_state(&"miss")
	if is_equal_approx(_vec.x + _vec.y + _vec.z, RESCUE_DOCK.length()) or absf(_vec.length() - RESCUE_DOCK.length()) <= 0.6:
		say("Uzaklık doğru (|R| = %s) ama yön yanlış: drone halkanın yanından geçti. Her bileşeni halkanın izdüşümünden oku." % _num(_vec.length()), BAD)
	else:
		say("Drone (%s, %s, %s) noktasına vardı, halkaya %s birim kaldı. Kesikli çizgilerden x, y ve z'yi yeniden oku." % [_num(_vec.x), _num(_vec.y), _num(_vec.z), _num(_vec.distance_to(RESCUE_DOCK))], BAD)


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
