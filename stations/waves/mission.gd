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
var _constructive_record := ""
var _destructive_record := ""


func _begin() -> void:
	step_total = 6
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
			say("Tek kaynak açık; A göstergesi 1,0.")
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
			_constructive_record = "f = %s Hz; A genliği = %s" % [str(view.frequency), str(snappedf(amp, 0.01))]
			say("A genliği 2,0 olarak kaydedildi.")
		if not _seen_destructive and amp <= 0.15:
			_seen_destructive = true
			_destructive_record = "f = %s Hz; A genliği = %s" % [str(view.frequency), str(snappedf(amp, 0.01))]
			say("A genliği sıfır olarak kaydedildi.")
	if _seen_single and _seen_constructive and _seen_destructive:
		hud.set_action("Kanıtları incele", true)


func _enter_reason() -> void:
	if not (_seen_single and _seen_constructive and _seen_destructive):
		return
	step = Step.REASON
	screen(2, "TEŞHİS", "Ölçümleri çeliştikleri MERİDYEN ayarına taşı.")
	show_evidence_diagnosis([_constructive_record, _destructive_record], {
		&"path": "Genlik hesabı: iki kaynak her yerde güçlenir",
		&"loss": "Tek kaynak genliği: 1,0",
		&"speed": "Ortamın dalga hızı: sabit"
	}, &"path", _on_reason)


func _on_reason(choice: StringName) -> void:
	if choice == &"path" and not evidence_verified:
		return
	match choice:
		&"path":
			say("İki kayıt aynı ayarla çelişti; mühür açıldı.", GOOD)
			clear_tools()
			hud.set_action("Δ/λ hesapla", true)
		&"loss":
			say("Bu satır tek kaynak kaydıyla tutarlı.", BAD)
		_:
			say("Ortam değişmedi; bu satır kayıtla çelişmiyor.", BAD)


func _enter_measure() -> void:
	step = Step.MEASURE
	_view().frequency = 4.0
	screen(3, "DÜZELT", "Cihazdaki yol farkını dalga boyuna böl; kontrol oranını gir.", "Onayla",
		"Dalga boyu λ = v / f. Yol farkını dalga boyuna böl: tam sayıysa yapıcı, yarımın tek katıysa yıkıcı.")
	add_entry("Δ / λ")


func _check_measure() -> void:
	var value := read_number()
	if is_nan(value):
		say("Oranı sayı olarak gir; ondalık virgül kullanabilirsin.", BAD)
		return
	if absf(value - Wave.path_ratio(Wave.SENSOR_A, 4.0)) <= 0.05:
		say("Kontrol oranı ölçümle eşleşti.", GOOD)
		_enter_rescue()
	elif absf(value - 0.667) < 0.03:
		say("Bölme sırasını denetle: yol farkı / dalga boyu.", BAD)
	else:
		say("Cihazdaki yol farkını ve dalga boyunu yeniden oku.", BAD)


func _enter_rescue() -> void:
	step = Step.RESCUE
	_tries = 3
	var view := _view()
	view.faulty_display = false
	view.two_sources = true
	screen(4, "TOPARLA", "A sönmeli (≤ 0,3), B parlamalı (≥ 1,7). Tek bir frekans gir.", "Frekansı kur",
		"Hız 12 cm/s, λ = v / f. A'da Δ = 3 cm, B'de Δ = 2 cm. İki koşulu birlikte sağlayan frekans 1–8 Hz aralığında tek. Üç hakkın var.")
	add_entry("frekans  (Hz)")


func _run_rescue() -> void:
	if step != Step.RESCUE or _tries <= 0 or _sealed:
		return
	var value := read_number()
	if is_nan(value):
		say("Frekansı Hz olarak sayı ile gir.", BAD)
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
		step = Step.DONE
		clear_tools()
		hud.set_action("Krize sar", true)
		say("Üç hak bitti; krizi yeniden ölçmen gerekiyor.", BAD)


func _finish() -> void:
	seal("Dalgalar her yerde güçlenmiyordu. Girişim yol farkına bağlıydı.", "A sustu, B sinyal aldı: tek frekans, iki koşul.")


func _on_action() -> void:
	match step:
		Step.CRISIS:
			_enter_test()
		Step.TEST:
			_enter_reason()
		Step.REASON:
			if evidence_verified:
				_enter_measure()
		Step.MEASURE:
			_check_measure()
		Step.RESCUE:
			_run_rescue()

		Step.DONE:
			if not _sealed:
				_enter_crisis()
