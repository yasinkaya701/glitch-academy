extends "res://scripts/physics/experiment_mission.gd"
## AYT Kimya · Modern atom teorisi, spin (Stern–Gerlach). KRİZ: Ayırma hattı, fırından çıkan atomların yönünün sürekli
## dağıldığını sanıyor ve ekranda tek yayılmış leke bekliyor. Gerçekte ekranda iki ayrı iz var, hat bozuluyor.
## Kazanım sınırı: yalnızca birbirine dik iki eksen (Z, X). Spin dönen küre değil, ölçülen eksende iki sonuçlu özelliktir.
## Hesap spin_sim.gd'de, çizim spin_view.gd'de.

const View = preload("res://stations/spin/spin_view.gd")
const Spin = preload("res://stations/spin/spin_sim.gd")

const TARGET_REACH := 0.125       ## fırından çıkanların dedektöre ulaşması gereken oran
## Süzgeç seçenekleri: yok → Z↑ → Z↓ → X↑ → X↓
const CHOICES := [{}, {"axis": &"z", "sign": 1}, {"axis": &"z", "sign": -1}, {"axis": &"x", "sign": 1}, {"axis": &"x", "sign": -1}]

enum Step { CRISIS, TEST, REASON, MEASURE, RESCUE, DONE }

var step := Step.CRISIS
var _seen_same := false
var _seen_cross := false
var _seen_erased := false
var _choice := [0, 0, 0]
var _stage_knobs: Array = []
var _detector_knob: Node3D


func screen(index: int, label: String, directive: String, action_text: String = "", note: String = "") -> void:
	super.screen(index, label, directive, action_text, note)
	if stage != null:
		_view().clear_controls()
		_stage_knobs.clear()
		_detector_knob = null


func _begin() -> void:
	step_total = 5
	_enter_crisis()


func _make_stage() -> Control:
	return View.new()


func _view() -> View:
	return stage as View


func _label(index: int) -> String:
	var choice: Dictionary = CHOICES[_choice[index]]
	if choice.is_empty():
		return "Aşama %d: yok" % (index + 1)
	return "Aşama %d: %s %s" % [index + 1, String(choice["axis"]).to_upper(), "↑" if choice["sign"] > 0 else "↓"]


func _apply_setup() -> void:
	var view := _view()
	for i in 3:
		view.stages[i] = CHOICES[_choice[i]]
	view.reset_counts()


func _enter_crisis() -> void:
	step = Step.CRISIS
	var view := _view()
	view.show_classical = true
	view.faulty = true
	view.stages = [{}, {}, {}]
	view.detector_axis = &"z"
	view.reset_counts()
	view.play_intro()
	if not view.intro_finished.is_connected(_on_intro_finished):
		view.intro_finished.connect(_on_intro_finished)
	screen(0, "KRİZ", "Hat tek leke bekliyor, ekranda iki ayrı iz var.", "Nedenini bul",
		"Fırından çıkan atomlar mıknatıstan geçip ekrana düşüyor. Cihaz atomların yönünü sürekli sanıyor ve tek yayılmış leke için kalibre. Turuncu leke cihazın beklentisi, yeşil noktalar gerçek ölçüm.")
	hud.set_action("Nedenini bul", false)
	hud.skip.show()


func _on_intro_finished() -> void:
	if step == Step.CRISIS:
		hud.skip.hide()
		hud.set_action("Nedenini bul", true)


func _on_skip() -> void:
	_view().skip_intro()


func _enter_test() -> void:
	step = Step.TEST
	_seen_same = false
	_seen_cross = false
	_seen_erased = false
	_choice = [0, 0, 0]
	_view().show_classical = false
	_apply_setup()
	screen(1, "SINA", "Süzgeç aşamalarını ve dedektör eksenini değiştir. Yukarı/aşağı oranını izle.", "",
		"Üç şeye bak: süzülmüş atomu aynı eksende yeniden ölçünce ne çıkar? Dik eksende ölçünce? İki dik süzgeçten sonra ilk eksene dönersen?")
	_build_controls()


func _build_controls() -> void:
	_stage_knobs.clear()
	for i in 3:
		var index := i
		var knob = _view().add_knob("Aşama %d" % (i + 1), 0.0, 4.0, float(_choice[i]), 1.0, func(v: float) -> void:
			_choice[index] = int(v)
			_apply_setup()
			_after_change())
		knob.value_labels = ["yok", "Z↑", "Z↓", "X↑", "X↓"]
		knob.refresh()
		_stage_knobs.append(knob)
	_detector_knob = _view().add_knob("Dedektör", 0.0, 1.0, 0.0 if _view().detector_axis == &"z" else 1.0, 1.0, func(v: float) -> void:
		_view().detector_axis = &"x" if v > 0.5 else &"z"
		_view().reset_counts()
		_after_change())
	_detector_knob.value_labels = ["Z", "X"]
	_detector_knob.refresh()
	_view().add_knob("Alan eğimi (T/m)", 5.0, 20.0, _view().gradient * 10.0, 5.0, func(v: float) -> void:
		_view().gradient = v / 10.0
		_view().reset_counts())
	_view().add_knob("Fırın (K)", 600.0, 1400.0, _view().oven_temp, 200.0, func(v: float) -> void:
		_view().oven_temp = v
		_view().reset_counts())


## Testler ve düğme dışı çağrılar için: aşamayı bir sonraki seçeneğe geçirir.
func _cycle_stage(index: int) -> void:
	_stage_knobs[index].set_value(float((_choice[index] + 1) % CHOICES.size()))


func _toggle_detector() -> void:
	_detector_knob.set_value(1.0 if _view().detector_axis == &"z" else 0.0)


func _active() -> Array:
	var result: Array = []
	for i in 3:
		if not (CHOICES[_choice[i]] as Dictionary).is_empty():
			result.append(CHOICES[_choice[i]])
	return result


func _after_change() -> void:
	if step != Step.TEST:
		return
	var active := _active()
	if active.is_empty():
		return
	var detector := _view().detector_axis
	var f: Dictionary = Spin.fractions(_view().stages, detector)
	if f["reach"] <= 0.0:
		say("Hiç atom geçmiyor: aynı eksende yukarıyı süzdükten sonra aşağıyı süzemezsin.", BAD)
		return
	var last: Dictionary = active[active.size() - 1]
	if last["axis"] == detector and (f["up"] == 0.0 or f["up"] == 1.0):
		if not _seen_same:
			_seen_same = true
			say("Aynı eksende yeniden ölçüm: sonuç hep aynı (%%%d yukarı). Süzülmüş atom ölçümü hatırlıyor." % roundi(f["up"] * 100.0), GOOD)
	elif last["axis"] != detector and active.size() == 1:
		if not _seen_cross:
			_seen_cross = true
			say("Dik eksende ölçüm: %50 yukarı, %50 aşağı. Bir eksende belli olan sonuç dik eksen için hiçbir şey söylemiyor.", GOOD)
	elif last["axis"] != detector and active.size() >= 2 and active[0]["axis"] == detector and absf(f["up"] - 0.5) < 0.01:
		if not _seen_erased:
			_seen_erased = true
			say("Dik süzgeçten sonra ilk eksene döndün: %50 – %50. Dik süzgeç eski bilgiyi sildi.", GOOD)
	if _seen_same and _seen_cross and _seen_erased:
		hud.set_action("Nedeni seç", true)


func _enter_reason() -> void:
	step = Step.REASON
	screen(2, "NEDEN", "Ekranda neden tek leke yok, iki iz var?", "",
		"Her eksende iki sonuç çıktı. Bir eksende belirlenmiş sonuç, dik eksende belirsiz kaldı.")
	var options := {
		&"spread": "Atomlar her yöne dönüyor, yayılmış bir leke vermeli",
		&"two": "Spin, ölçülen eksende iki sonuçtan biridir; dik eksen ölçümü öncekini siler",
		&"split": "Mıknatıs atomu ikiye böler, ikisi iki ize gider",
	}
	for choice in options:
		var button := Button.new()
		button.text = options[choice]
		button.pressed.connect(_on_reason.bind(choice))
		tools.add_child(button)


func _on_reason(choice: StringName) -> void:
	match choice:
		&"two":
			say("Doğru. Ölçüm tek atomdan iki sonuçtan birini verir. Spin dönen küre değil, ölçülen eksene göre yukarı ya da aşağı olan bir özelliktir.", GOOD)
			clear_tools()
			hud.set_action("Oranı hesapla", true)
		&"spread":
			say("Yayılmış leke klasik beklentiydi. Ekranda hiç ara nokta yok, yalnızca iki iz.", BAD)
		_:
			say("Her atom tek bir izde biter, atom sayısı korunur. Bölünme yok, iki sonuçtan biri çıkıyor.", BAD)


func _enter_measure() -> void:
	step = Step.MEASURE
	_choice = [1, 3, 0]
	_view().detector_axis = &"z"
	_apply_setup()
	screen(3, "ÖLÇ", "Aşama 1: Z↑, Aşama 2: X↑ süzüyor. Dedektör Z ölçüyor. Ulaşanların yüzde kaçı yukarı?", "Onayla",
		"Sınama adımında gördüğün durumları hatırla.")
	add_entry("yukarı  (%)")


func _check_measure() -> void:
	var value := read_number()
	if is_nan(value):
		say("Yüzde olarak gir. Örnek: 50", BAD)
		return
	if absf(value - 50.0) <= 1.0:
		say("%50. Ulaşan oran 0,5 × 0,5 = %25.", GOOD)
		_enter_rescue()
	elif absf(value - 100.0) <= 1.0:
		say("%100 yalnızca arada başka bir süzgeç olmasaydı doğru olurdu. Aradaki X süzgecinin Z bilgisine etkisini düşün.", BAD)
	else:
		say("Aradaki X süzgecinin Z ölçümünü nasıl etkilediğini sınama adımındaki gözlemlerinle karşılaştır.", BAD)


func _enter_rescue() -> void:
	step = Step.RESCUE
	_choice = [0, 0, 0]
	_apply_setup()
	screen(4, "KURTAR", "Fırından çıkan atomların %12,5'i dedektöre ulaşsın ve hepsi Z'de aşağı ölçülsün.", "Düzeneği doğrula",
		"Süzgeçlerin ardışık etkisini sınama adımında gördün. Üç aşamayı ve dedektör eksenini kur.")
	_build_controls()


func _run_rescue() -> void:
	var view := _view()
	var f: Dictionary = Spin.fractions(view.stages, view.detector_axis)
	if f["reach"] <= 0.0:
		say("Hiç atom ulaşmıyor: aynı eksende ters yönü süzmek atomu yok eder.", BAD)
		return
	if absf(f["reach"] - TARGET_REACH) > 0.001:
		say("Dedektöre fırından çıkanların %%%s ulaşıyor, hedef %%12,5." % str(snappedf(f["reach"] * 100.0, 0.1)).replace(".", ","), BAD)
		return
	if view.detector_axis != &"z" or f["down"] < 0.999:
		say("Ulaşma oranı doğru, ama Z'de hepsi aşağı çıkmıyor (%%%d aşağı). Son süzgeç Z↓ olmalı, dedektör Z ölçmeli." % roundi(f["down"] * 100.0), BAD)
		return
	_finish()


func _finish() -> void:
	_view().play_repair()
	seal("Spin yayılmış bir leke değil. Ölçüm iki sonuç verir, dik eksen öncekini siler.", "Hat iki ize kalibre edildi.")


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
