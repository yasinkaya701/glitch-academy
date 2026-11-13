extends "res://scripts/physics/experiment_mission.gd"
## AYT Fizik · Newton'un hareket yasaları. KRİZ: Arşiv kapısına gidecek kızak varış penceresini kaçırıyor. Cihaz ivmeyi
## kütleden bağımsız sayıyor (a = F). Çözüm: aynı itişte iki kütleyi karşılaştır, a = F/m'yi kanıtla, 6 kg yük için
## 40 m'yi tam 4 s'de aşacak kuvveti hesapla.
## Hesap newton_sim.gd'de, çizim newton_view.gd'de.

const View = preload("res://stations/newton/newton_view.gd")
const Newton = preload("res://stations/newton/newton_sim.gd")

const RAIL := 40.0
const WINDOW := 4.0               ## s, kapı penceresi
const LOAD := 6.0                 ## kg
const TOLERANCE := 0.1            ## s
const LIGHT := Color("#6fe3c1")
const HEAVY := Color("#f2a65a")

enum Step { CRISIS, TEST, REASON, MEASURE, RESCUE, DONE }

var step := Step.CRISIS
var _force := 10.0
var _mass_a := 2.0
var _mass_b := 5.0
var _runs: Array[Dictionary] = []
var _seen_mass := false
var _seen_force := false
var _tries := 3
var _crisis_launched := false


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


func _sleds(forces: Array, masses: Array) -> Array[Dictionary]:
	var list: Array[Dictionary] = []
	for i in masses.size():
		list.append({"mass": masses[i], "force": forces[i], "name": "Kızak %s" % ["A", "B"][i], "color": [LIGHT, HEAVY][i]})
	return list


func _enter_crisis() -> void:
	step = Step.CRISIS
	_crisis_launched = false
	var view := _view()
	view.rail_length = RAIL
	view.faulty_display = true
	view.show_slopes = true
	view.set_sleds(_sleds([10.0, 10.0], [2.0, 5.0]))
	screen(0, "KRİZ", "Aynı itiş, iki kızak. Cihaz ikisini de aynı hızlanacak sanıyor.", "Kızakları bırak",
		"Arşiv kapısı kısa bir pencere için açık. Cihaz varış zamanını a = F ile yazdı, ağır kızak geride kalacak.")


func _enter_test() -> void:
	step = Step.TEST
	_runs.clear()
	_seen_mass = false
	_seen_force = false
	var view := _view()
	view.faulty_display = false
	view.show_slopes = true
	_apply_test_setup()
	screen(1, "SINA", "Kuvveti ve kütleyi değiştir, kızakları bırak, grafiğin eğimini oku.", "",
		"Yavaşlat zamanı ¼ hıza çeker. İki şeye bak: aynı kuvvette kütle artınca eğim ne olur? Aynı kütlede kuvvet artınca?")
	_view().add_knob("Kuvvet (N)", 10.0, 40.0, _force, 10.0, func(v: float) -> void:
		_force = v
		_apply_test_setup())
	_view().add_knob("Kızak B (kg)", 2.0, 8.0, _mass_b, 1.0, func(v: float) -> void:
		_mass_b = v
		_apply_test_setup())
	_view().add_button("Yavaşlat", func(on: bool) -> void: _view().slow_motion = on, true)
	_view().add_button("Bırak", _release)


func _apply_test_setup() -> void:
	_view().set_sleds(_sleds([_force, _force], [_mass_a, _mass_b]))


func _release() -> void:
	_view().launch()
	_runs.append({"force": _force, "mass_a": _mass_a, "mass_b": _mass_b})
	_after_run()


func _after_run() -> void:
	if step != Step.TEST:
		return
	var current := _runs[_runs.size() - 1]
	if current["mass_a"] != current["mass_b"] and not _seen_mass:
		_seen_mass = true
		say("Aynı kuvvet, iki kütle: %s kg kızağın eğimi %s m/s², %s kg olanın %s m/s². Kütle arttıkça ivme azalıyor." % [
			_fmt(_mass_a), _fmt(Newton.acceleration(_force, _mass_a)), _fmt(_mass_b), _fmt(Newton.acceleration(_force, _mass_b))], GOOD)
	for earlier in _runs:
		if earlier["force"] != current["force"] and earlier["mass_b"] == current["mass_b"] and not _seen_force:
			_seen_force = true
			say("Aynı kütle, kuvvet %s N → %s N: eğim de aynı oranda değişti. Kuvvet iki katına çıkınca ivme iki katına çıkar." % [_fmt(earlier["force"]), _fmt(current["force"])], GOOD)
	if _seen_mass and _seen_force:
		hud.set_action("Nedeni seç", true)


func _fmt(value: float) -> String:
	return str(snappedf(value, 0.01)).replace(".", ",")


func _enter_reason() -> void:
	step = Step.REASON
	screen(2, "NEDEN", "İvmeyi ne belirliyor?", "",
		"Grafikte eğim ivmedir. Kuvvet iki katına çıkınca eğim iki katına çıktı, kütle artınca eğim azaldı.")
	var options := {
		&"force_only": "Yalnız kuvvet: a = F",
		&"ratio": "Kuvvet ve kütle birlikte: a = F / m",
		&"mass_only": "Yalnız kütle: ağır olan hep daha yavaş",
	}
	for choice in options:
		var button := Button.new()
		button.text = options[choice]
		button.pressed.connect(_on_reason.bind(choice))
		tools.add_child(button)


func _on_reason(choice: StringName) -> void:
	match choice:
		&"ratio":
			say("Doğru. Net kuvvet kütleyle ivmenin çarpımıdır: F = m·a, yani a = F / m.", GOOD)
			clear_tools()
			hud.set_action("İvmeyi hesapla", true)
		&"force_only":
			say("Aynı kuvvette 2 kg ve 5 kg farklı eğim verdi. Kütle denklemden silinemez.", BAD)
		_:
			say("Kuvveti ikiye katlayınca aynı kızağın eğimi arttı. Kuvvet de belirleyici.", BAD)


func _enter_measure() -> void:
	step = Step.MEASURE
	var view := _view()
	view.show_slopes = false
	view.set_sleds(_sleds([20.0], [4.0]))
	screen(3, "ÖLÇ", "4 kg yüke 20 N itiş. İvmesi kaç m/s²?", "Onayla",
		"Eğim yazısı gizli. İvmeyi sen bul, sonra Bırak ile grafikten doğrula.")
	add_entry("a  (m/s²)")
	_view().add_button("Bırak", func() -> void: _view().launch())


func _check_measure() -> void:
	var value := read_number()
	if is_nan(value):
		say("Sayı gir. Örnek: 5", BAD)
		return
	if absf(value - 5.0) <= 0.05:
		say("a = 20 / 4 = 5 m/s². 40 m yolu a = 2d/t² ile süreye çevirebilirsin.", GOOD)
		_enter_rescue()
	elif absf(value - 20.0) <= 0.05:
		say("20 cihazın yanlış sonucuyla aynı: kuvveti ivme sanmış. Kütle sonucu nasıl etkiler?", BAD)
	elif absf(value - 80.0) <= 0.5:
		say("Bu değer çok büyük: ağır yük aynı itişle daha çok mu, daha az mı hızlanır? Yönü kontrol et.", BAD)
	else:
		say("Sonuçta 2 kg kızağın 10 N ile 5 m/s² yaptığını hatırla: 4 kg ve 20 N için nicelikleri karşılaştır.", BAD)


func _enter_rescue() -> void:
	step = Step.RESCUE
	_tries = 3
	var view := _view()
	view.faulty_display = false
	view.show_slopes = false
	view.set_sleds(_sleds([0.0], [LOAD]))
	screen(4, "KURTAR", "6 kg yük, ray 40 m. Kızak durgun başlayıp tam 4 s'de varmalı. Kaç N itiş?", "İtişi uygula",
		"Hareketin yolu ve süresi belli, kızağın kütlesi belli. İtici kuvvetini bu şartlardan çıkar. Pencere ±0,1 s. Üç hakkın var.")
	add_entry("kuvvet  (N)")


func _run_rescue() -> void:
	var value := read_number()
	if is_nan(value):
		say("Kuvveti N olarak gir. Örnek: 30", BAD)
		return
	if value <= 0.0 or value > 100.0:
		say("İtici 1–100 N arasında çalışır.", BAD)
		return
	var view := _view()
	view.set_sleds(_sleds([value], [LOAD]))
	view.launch()
	var duration := Newton.time_to_cover(RAIL, Newton.acceleration(value, LOAD))
	if absf(duration - WINDOW) <= TOLERANCE:
		_finish()
		return
	_tries -= 1
	if duration > WINDOW:
		say("Kızak varışa %s s'de ulaşıyor, pencere 4 s: ivme yetersiz. Önce hareketi sağlayacak ivmeyi bul, sonra o ivmeyi kuvvete çevir." % _fmt(duration), BAD)
	else:
		say("Kızak %s s'de varıyor, pencerenin çok önünde: ivme fazla." % _fmt(duration), BAD)
	if _tries <= 0:
		_tries = 3
		say("Üç hakkın bitti. Sıra: önce yol ve süreden ivme, sonra ivme ve kütleden kuvvet.")


func _finish() -> void:
	seal("İvme yalnız kuvvete bağlı değildi. Kütle denklemden silinmişti.", "Kızak tam zamanında vardı, kapı açık.")


func _on_action() -> void:
	match step:
		Step.CRISIS:
			if _crisis_launched:
				_enter_test()
			else:
				_crisis_launched = true
				_view().launch()
				hud.set_action("Nedenini bul", true)
				say("Cihaz ikisini de 10 m/s² sanıyordu. Ağır kızak geride kaldı.", BAD)
		Step.TEST:
			_enter_reason()
		Step.REASON:
			_enter_measure()
		Step.MEASURE:
			_check_measure()
		Step.RESCUE:
			_run_rescue()
