extends "res://scripts/physics/experiment_mission.gd"
## AYT Fizik · İtme ve momentum. KRİZ: Arşiv kapısına gelen iki araba çarpışıp yapışıyor ve cihazın yanlış ortak hızıyla
## kapıya savrulup onu kırıyor. Cihaz momentumu yönsüz topluyor. Çözüm bütün konuyu ister: momentumun vektör olduğunu kanıtla,
## ortak hızı hesapla, enerjinin ısıya gittiğini gör, sonra 3 kg arabanın +2 m/s ile gelişine karşı 5 kg arabanın işaretli
## hızını bul ve ısıya giden enerjinin kapının 15 J sınırının altında kaldığını doğrula.
## Hesap collision_sim.gd'de, çizim collision_view.gd'de.

const View = preload("res://stations/collision/collision_view.gd")
const Coll = preload("res://stations/collision/collision_sim.gd")

const HEAT_LIMIT := 15.0           ## J
const RESCUE_M1 := 3.0
const RESCUE_V1 := 2.0
const RESCUE_M2 := 5.0

enum Step { CRISIS, TEST, REASON, MEASURE, RESCUE, HEAT, DONE }

var step := Step.CRISIS
var _seen_vector := false
var _seen_elastic := false
var _seen_loss := false
var _tries := 3
var _rescue_speed := 0.0


func screen(index: int, label: String, directive: String, action_text: String = "", note: String = "") -> void:
	super.screen(index, label, directive, action_text, note)
	if stage != null:
		_view().clear_controls()


func _begin() -> void:
	step_total = 5
	_enter_crisis()


func _make_stage() -> Control:
	return View.new()


func _view() -> View:
	return stage as View


func _fmt(value: float) -> String:
	return str(snappedf(value, 0.01)).replace(".", ",")


func _enter_crisis() -> void:
	step = Step.CRISIS
	var view := _view()
	view.m1 = 2.0
	view.v1 = 3.0
	view.m2 = 1.0
	view.v2 = -3.0
	view.elastic = false
	view.faulty = true
	view.show_arrows = false
	view.heat_limit = -1.0
	view.reset()
	view.play_intro()
	if not view.intro_finished.is_connected(_on_intro_finished):
		view.intro_finished.connect(_on_intro_finished)
	screen(0, "KRİZ", "İki araba karşılıklı geliyor. Cihaz ortak hızı 3 m/s sanıyor.", "Nedenini bul",
		"2 kg araba +3 m/s, 1 kg araba −3 m/s ile geliyor ve çarpışınca yapışacaklar. Cihaz momentumların büyüklüğünü toplayıp ortak hızı 3 m/s buluyor, arabalar kapıya savruluyor.")
	hud.set_action("Nedenini bul", false)
	hud.skip.show()


func _on_intro_finished() -> void:
	if step == Step.CRISIS:
		hud.skip.hide()
		hud.set_action("Nedenini bul", true)
		_view().reset()


func _on_skip() -> void:
	_view().skip_intro()


func _enter_test() -> void:
	step = Step.TEST
	_seen_vector = false
	_seen_elastic = false
	_seen_loss = false
	var view := _view()
	view.faulty = false
	view.show_arrows = true
	view.reset()
	screen(1, "SINA", "Kütleleri ve hızları ayarla, arabaları çarpıştır. Okları ve enerji kartlarını izle.", "",
		"Gör momentum oklarını açar. Sağ yön +, sol yön −. Üç şeye bak: toplam ok çarpışmadan önce ve sonra aynı mı? Yapışkan çarpışmada enerji ne olur? Esnek çarpışmada?")
	view.add_knob("m₁ (kg)", 1.0, 6.0, view.m1, 1.0, func(v: float) -> void: _change(&"m1", v))
	view.add_knob("v₁ (m/s)", -6.0, 6.0, view.v1, 1.0, func(v: float) -> void: _change(&"v1", v))
	view.add_knob("m₂ (kg)", 1.0, 6.0, view.m2, 1.0, func(v: float) -> void: _change(&"m2", v))
	view.add_knob("v₂ (m/s)", -6.0, 6.0, view.v2, 1.0, func(v: float) -> void: _change(&"v2", v))
	var mode := view.add_button("Yapışkan", func(on: bool) -> void:
		view.elastic = on
		view.reset(), true)
	mode.set_on(view.elastic)
	var gor := view.add_button("Gör", func(on: bool) -> void: view.show_arrows = on, true)
	gor.set_on(true)
	view.add_button("Çarpıştır", _collide)


func _slider(title: String, low: float, high: float, value: float, step_size: float, callback: Callable) -> void:
	add_slider(title, low, high, value, step_size, callback, 112.0)
	add_gap(12.0)


func _change(key: StringName, value: float) -> void:
	_view().set(key, value)
	_view().reset()


func _collide() -> void:
	_view().launch()
	if not _view().collided.is_connected(_after_collision):
		_view().collided.connect(_after_collision)


func _after_collision() -> void:
	if step != Step.TEST:
		return
	var view := _view()
	var f := view.final_velocities()
	var before := Coll.momentum(view.m1, view.v1, view.m2, view.v2)
	var after := Coll.momentum(view.m1, f.x, view.m2, f.y)
	if absf(before - after) < 0.001 and view.v1 * view.v2 < 0.0 and not _seen_vector:
		_seen_vector = true
		say("Ters yönlü arabalar: p önce %s, p sonra %s kg·m/s. Toplam momentum işaretli toplanınca korunuyor." % [_fmt(before), _fmt(after)], GOOD)
	var lost := Coll.kinetic(view.m1, view.v1) + Coll.kinetic(view.m2, view.v2) - Coll.kinetic(view.m1, f.x) - Coll.kinetic(view.m2, f.y)
	if not view.elastic and lost > 0.5 and not _seen_loss:
		_seen_loss = true
		say("Yapışkan çarpışma: %s J kinetik enerji kayboldu, ısıya gitti. Momentum kaybolmadı." % _fmt(lost), GOOD)
	if view.elastic and absf(lost) < 0.01 and not _seen_elastic:
		_seen_elastic = true
		say("Esnek çarpışma: hem momentum hem kinetik enerji korundu, arabalar geri sekti.", GOOD)
	if _seen_vector and _seen_loss and _seen_elastic:
		hud.set_action("Nedeni seç", true)


func _enter_reason() -> void:
	step = Step.REASON
	screen(2, "NEDEN", "Çarpışmada ne korunuyor?", "",
		"Toplam momentum her çarpışmada aynı kaldı. Kinetik enerji yalnızca esnek çarpışmada aynı kaldı.")
	var options := {
		&"magnitude": "Momentumların büyüklükleri toplanır: |p₁| + |p₂|",
		&"vector": "Momentum vektördür: yönlü (işaretli) toplam korunur, enerji yapışkanda ısıya gider",
		&"energy": "Kinetik enerji her çarpışmada korunur, momentum ısıya gider",
	}
	for choice in options:
		var button := Button.new()
		button.text = options[choice]
		button.pressed.connect(_on_reason.bind(choice))
		tools.add_child(button)


func _on_reason(choice: StringName) -> void:
	match choice:
		&"vector":
			say("Doğru. p = m·v yönlüdür: karşı yönü eksi alırsın. Çarpışmada p korunur, Ek yalnızca esnekte korunur.", GOOD)
			clear_tools()
			hud.set_action("Hızı hesapla", true)
		&"magnitude":
			say("Büyüklükleri toplayınca 6 + 3 = 9 çıkardı, oysa ok toplamı 3 verdi. Karşı yönü eksi say.", BAD)
		_:
			say("Yapışkan çarpışmada enerji kartı düştü ama momentum kartı aynı kaldı. Momentum her çarpışmada korunur.", BAD)


func _enter_measure() -> void:
	step = Step.MEASURE
	var view := _view()
	view.m1 = 2.0
	view.v1 = 3.0
	view.m2 = 1.0
	view.v2 = -3.0
	view.elastic = false
	view.show_arrows = true
	view.reset()
	screen(3, "ÖLÇ", "2 kg araba +3 m/s, 1 kg araba −3 m/s. Yapışınca ortak hız kaç m/s? (Sağ +)", "Onayla",
		"Önce toplam momentumu işaretli bul: p = m₁v₁ + m₂v₂. Sonra yapışmış toplam kütleye böl.")
	add_entry("v  (m/s)")
	_view().add_button("Çarpıştır", _collide)


func _check_measure() -> void:
	var value := read_number()
	if is_nan(value):
		say("Sayı gir. Örnek: 1", BAD)
		return
	if absf(value - 1.0) <= 0.03:
		say("1 m/s, ağır arabanın yönünde.", GOOD)
		_enter_rescue()
	elif absf(value - 3.0) <= 0.03:
		say("3 cihazın yanlış sonucu. Karşı yönden gelen araba toplamı nasıl etkiler?", BAD)
	elif absf(value + 1.0) <= 0.03:
		say("Büyüklük doğru ama yön ters. Hangi araba daha fazla momentum taşıyor?", BAD)
	else:
		say("Çarpışmadan önceki toplam momentumu yönleriyle bul, sonra yapışmış sistemin kütlesine dağıt.", BAD)


func _enter_rescue() -> void:
	step = Step.RESCUE
	_tries = 3
	var view := _view()
	view.m1 = RESCUE_M1
	view.v1 = RESCUE_V1
	view.m2 = RESCUE_M2
	view.v2 = -1.0
	view.elastic = false
	view.show_arrows = false
	view.heat_limit = HEAT_LIMIT
	view.reset()
	screen(4, "KURTAR", "3 kg araba +2 m/s ile geliyor. Karşıdaki 5 kg arabanın hızını gir: yapışınca durmalılar.", "Hızı uygula",
		"Hızı yönüyle gir. Sonra kapının ısı sınırını (15 J) kontrol edeceksin. Üç hakkın var.")
	add_entry("v₂  (m/s, işaretli)")


func _run_rescue() -> void:
	var value := read_number()
	if is_nan(value):
		say("Hızı işaretli gir. Örnek: -1,5", BAD)
		return
	if absf(value) > 6.0:
		say("Araba 6 m/s'den hızlı gelemez.", BAD)
		return
	var view := _view()
	view.v2 = value
	view.reset()
	_collide()
	var common := Coll.stick_speed(RESCUE_M1, RESCUE_V1, RESCUE_M2, value)
	if absf(common) <= 0.02:
		_rescue_speed = value
		_enter_heat()
		return
	_tries -= 1
	if value > 0.0:
		say("İki araba da sağa gidiyor, ortak hız %s m/s. Karşıdan gelen arabanın yönü hakkında ne biliyorsun?" % _fmt(common), BAD)
	elif common > 0.0:
		say("Ortak hız hâlâ %s m/s, sağa gidiyorlar: karşı arabanın momentumu yetmiyor." % _fmt(common), BAD)
	else:
		say("Ortak hız %s m/s (sola): karşı araba fazla momentum taşıyor." % _fmt(common), BAD)
	if _tries <= 0:
		_tries = 3
		say("Üç hakkın bitti. Durmaları için iki momentum eşit büyüklükte ve ters yönde olmalı.")


func _enter_heat() -> void:
	step = Step.HEAT
	_tries = 3
	screen(4, "KURTAR", "Durdular. Kapının ısı sensörü: yapışırken kaç J enerji ısıya gitti?", "Onayla",
		"Çarpışma sırasında kaybolan enerji ısıya gider. Sınır 15 J.")
	add_entry("ısı  (J)")


func _run_heat() -> void:
	var value := read_number()
	if is_nan(value):
		say("Jul olarak gir. Örnek: 9,6", BAD)
		return
	var truth := Coll.heat_stick(RESCUE_M1, RESCUE_V1, RESCUE_M2, _rescue_speed)
	if absf(value - truth) <= 0.2:
		if truth <= HEAT_LIMIT:
			_finish(truth)
		else:
			say("Isı sınırı aşıldı.", BAD)
		return
	_tries -= 1
	var ke := Coll.kinetic(RESCUE_M1, RESCUE_V1) + Coll.kinetic(RESCUE_M2, _rescue_speed)
	if absf(value - ke * 0.5) < 0.3 or value <= 0.0:
		say("Her arabanın enerjisi ayrı ayrı hesaplanır. Sonrasında araçlar durduğuna göre geriye ne kalıyor?", BAD)
	else:
		say("Kaybolan enerjiyi çarpışma öncesi ve sonrası kinetik enerjilerin farkından bul. %s J bu değer değil." % _fmt(value), BAD)
	if _tries <= 0:
		_tries = 3
		say("Üç hakkın bitti. Önce her arabanın kinetik enerjisini, sonra farkı düşün.")


func _finish(heat: float) -> void:
	seal("Momentum vektör, enerji ayrı. Arabalar durdu, %s J ısıya gitti, kapı sağlam." % _fmt(heat), "Arabalar durdu, kapı sağlam.")


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
		Step.HEAT:
			_run_heat()
