extends "res://scripts/physics/experiment_mission.gd"
## AYT Fizik · Dalgalar (girişim). KRİZ: iki kaynağın dalgaları A noktasındaki hassas sensörü aşırı yüklüyor, B noktasındaki
## veri alıcısı ise sinyal alamıyor. Cihaz dalgaların her yerde güçleneceğini sanıyor. Çözüm bütün konuyu ister:
## girişimin yol farkına bağlı olduğunu kanıtla, Δ/λ'yı hesapla ve tek bir frekansla A'yı söndürüp B'yi parlat.
## Hesap wave_sim.gd'de, çizim wave_view.gd'de ve wave_field.gdshader'da.

const View = preload("res://stations/waves/wave_view.gd")
const Wave = preload("res://stations/waves/wave_sim.gd")

const START_FREQUENCY := 4.0
const A_LIMIT := 0.3              ## A bunun altında sönük sayılır
const B_NEED := 1.7               ## B bunun üstünde parlak sayılır

enum Step { CRISIS, TEST, REASON, MEASURE, RESCUE, DONE }

var step := Step.CRISIS
var _seen_single := false
var _seen_constructive := false
var _seen_destructive := false
var _tries := 3


func _begin() -> void:
	step_total = 5
	_enter_crisis()


func _make_stage() -> Control:
	return View.new()


func _view() -> View:
	return stage as View


func _enter_crisis() -> void:
	step = Step.CRISIS
	var view := _view()
	view.frequency = START_FREQUENCY
	view.two_sources = true
	view.faulty_display = true
	screen(0, "KRİZ", "A sensörü aşırı yükleniyor, B alıcısı sinyal alamıyor.", "Nedenini bul",
		"İki kaynak aynı frekansla çalışıyor. A hassas bir sensör, B arşiv verisini alan alıcı. Cihaz dalgaların her yerde birbirini güçlendirdiğini sanıyor, oysa A tepeyle tepe, B yarım güçte.")


func _enter_test() -> void:
	step = Step.TEST
	_seen_single = false
	_seen_constructive = false
	_seen_destructive = false
	screen(1, "SINA", "Frekansı değiştir, ikinci kaynağı aç ve kapa. A'nın genliğini izle.", "",
		"Üç şeye bak: tek kaynakla A'da söner mi? İki kaynakla A ne zaman tam güçlenir? Ne zaman söner? Yol farkı / dalga boyu oranı sana söyler.")
	add_slider("Frekans", Wave.FREQ_MIN, Wave.FREQ_MAX, _view().frequency, 0.1, func(v: float) -> void:
		_view().frequency = v
		_after_change(), 300.0)
	add_gap()
	var second := add_power("Kaynak 2", "İkinci kaynağı aç ya da kapat", func(on: bool) -> void:
		_view().two_sources = on
		if not on:
			_seen_single = true
			say("Tek kaynak: genlik her yerde 1,0. Sönme yok, yalnızca iki dalga birleşince oluyor.", GOOD)
		_after_change(), true)
	second.set_pressed_no_signal(true)


func _after_change() -> void:
	if step != Step.TEST:
		return
	var view := _view()
	var amp := Wave.amplitude(Wave.SENSOR_A, view.frequency, view.two_sources)
	if view.two_sources:
		if not _seen_constructive and amp >= 1.95:
			_seen_constructive = true
			say("A'da Δ/λ = %s: tam sayı, tepe tepeyle buluştu, genlik 2,0." % str(snappedf(Wave.path_ratio(Wave.SENSOR_A, view.frequency), 0.01)).replace(".", ","), GOOD)
		if not _seen_destructive and amp <= 0.15:
			_seen_destructive = true
			say("A'da Δ/λ = %s: yarımın tek katı, tepe çukurla buluştu, genlik 0." % str(snappedf(Wave.path_ratio(Wave.SENSOR_A, view.frequency), 0.01)).replace(".", ","), GOOD)
	if _seen_single and _seen_constructive and _seen_destructive:
		hud.set_action("Nedeni seç", true)


func _enter_reason() -> void:
	step = Step.REASON
	screen(2, "NEDEN", "A'daki genliği ne belirliyor?", "",
		"Tek kaynakta sönme yoktu, iki kaynakta frekansa göre A bazen 2, bazen 0 oldu. Değişen, iki dalganın A'ya ulaşma farkı.")
	var options := {
		&"loss": "Dalgalar yol boyunca enerji kaybeder",
		&"path": "Yol farkı ve dalga boyu: tepe çukurla ya da tepeyle üst üste biner",
		&"speed": "Frekans dalganın hızını değiştirir",
	}
	for choice in options:
		var button := Button.new()
		button.text = options[choice]
		button.pressed.connect(_on_reason.bind(choice))
		tools.add_child(button)


func _on_reason(choice: StringName) -> void:
	match choice:
		&"path":
			say("Doğru. Δ = n·λ yapıcı (genlik 2), Δ = (n + ½)·λ yıkıcı (genlik 0). Süperpozisyon: anlık genlikler toplanır.", GOOD)
			clear_tools()
			hud.set_action("Δ/λ hesapla", true)
		&"loss":
			say("Tek kaynakta genlik her yerde 1,0 kaldı. Enerji kaybı süreyi açıklamaz.", BAD)
		_:
			say("Hız sabit (12 cm/s): λ = v / f. Frekans yalnızca dalga boyunu değiştirir.", BAD)


func _enter_measure() -> void:
	step = Step.MEASURE
	screen(3, "ÖLÇ", "A'da yol farkı 3 cm, dalga boyu 2 cm. Δ/λ kaç? A söner mi?", "Onayla",
		"Dalga boyu λ = v / f. Yol farkını dalga boyuna böl: tam sayıysa yapıcı, yarımın tek katıysa yıkıcı.")
	add_entry("Δ / λ")


func _check_measure() -> void:
	var value := read_number()
	if is_nan(value):
		say("Sayı gir. Örnek: 1,5", BAD)
		return
	if absf(value - 1.5) <= 0.05:
		say("Δ/λ = 3 / 2 = 1,5: yarımın tek katı, A söner. λ = 2 cm için frekans f = 12 / 2 = 6 Hz.", GOOD)
		_enter_rescue()
	elif absf(value - 0.667) < 0.03:
		say("Ters bölmüşsün. Yol farkı payda değil, pay: Δ / λ = 3 / 2.", BAD)
	else:
		say("Δ / λ = 3 cm / 2 cm. Sonuç tam sayı mı, yarımın tek katı mı?", BAD)


func _enter_rescue() -> void:
	step = Step.RESCUE
	_tries = 3
	var view := _view()
	view.faulty_display = false
	view.two_sources = true
	screen(4, "KURTAR", "A sönmeli (≤ 0,3), B parlamalı (≥ 1,7). Tek bir frekans gir.", "Frekansı kur",
		"Hız 12 cm/s, λ = v / f. A'da Δ = 3 cm, B'de Δ = 2 cm. İki koşulu birlikte sağlayan frekans 1–8 Hz aralığında tek. Üç hakkın var.")
	add_entry("frekans  (Hz)")


func _run_rescue() -> void:
	var value := read_number()
	if is_nan(value):
		say("Frekansı Hz olarak gir. Örnek: 6", BAD)
		return
	if value < Wave.FREQ_MIN or value > Wave.FREQ_MAX:
		say("Kaynaklar 1–8 Hz arasında çalışır.", BAD)
		return
	var view := _view()
	view.frequency = value
	var amp_a := Wave.amplitude(Wave.SENSOR_A, value)
	var amp_b := Wave.amplitude(Wave.SENSOR_B, value)
	if amp_a <= A_LIMIT and amp_b >= B_NEED:
		_finish()
		return
	_tries -= 1
	var ratio_a := Wave.path_ratio(Wave.SENSOR_A, value)
	var ratio_b := Wave.path_ratio(Wave.SENSOR_B, value)
	if amp_a > A_LIMIT:
		say("A hâlâ yükleniyor: Δ/λ = %s, yarımın tek katı (0,5; 1,5; 2,5) olmalı." % str(snappedf(ratio_a, 0.01)).replace(".", ","), BAD)
	else:
		say("A söndü ama B zayıf: Δ/λ = %s, tam sayı (1; 2) olmalı." % str(snappedf(ratio_b, 0.01)).replace(".", ","), BAD)
	if _tries <= 0:
		_tries = 3
		say("Üç hakkın bitti, yeniden başla: λ = v / f, A için Δ/λ = n + ½, B için Δ/λ = n.")


func _finish() -> void:
	seal("Dalgalar her yerde güçlenmiyordu. Girişim yol farkına bağlıydı.", "A sustu, B sinyal aldı: tek frekans, iki koşul.")


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
