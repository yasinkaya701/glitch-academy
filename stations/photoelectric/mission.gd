extends "res://scripts/physics/experiment_mission.gd"
## AYT Fizik · Fotoelektrik olay. KRİZ: Arşiv kapısı, plakadan sökülen elektronların akımıyla açılır. Misafirler lambayı
## eşik altına (kırmızı) çevirdi, cihaz ise şiddet artırınca kapının açılacağını sanıyor. Kapı kapalı kalıyor.
## Çözüm bütün konuyu ister: şiddetin akımı, frekansın elektron enerjisini belirlediğini kanıtla, eşik frekansını hesapla,
## sonra kapının iki koşulunu (akım ve elektron enerjisi aralığı) birlikte sağlayan lambayı kur.
## Hesap photo_sim.gd'de, çizim photo_view.gd'de.

const View = preload("res://stations/photoelectric/photo_view.gd")
const Photo = preload("res://stations/photoelectric/photo_sim.gd")

const START_FREQUENCY := 4.3e14
const PHI := 2.07                 ## eV, sezyum
const CURRENT_NEED := 4.0         ## µA, kapının açılması için
const K_LOW := 1.0                ## eV
const K_HIGH := 2.0               ## eV, üstünde kapı yanar

enum Step { CRISIS, TEST, REASON, MEASURE, RESCUE, DONE }

var step := Step.CRISIS
var _f := START_FREQUENCY
var _i := 1.0
var _seen_below := false
var _seen_intensity := false
var _seen_frequency := false
var _anchor_f := 0.0
var _anchor_i := 0.0
var _anchor_k := 0.0
var _tries := 3


func _begin() -> void:
	step_total = 5
	_enter_crisis()


func _make_stage() -> Control:
	return View.new()


func _view() -> View:
	return stage as View


func _sync_view() -> void:
	var view := _view()
	view.frequency = _f
	view.intensity = _i


func _lamp_sliders(frequency_too: bool = true) -> void:
	add_slider("Frekans", 3.0, 14.0, _f / 1e14, 0.1, func(v: float) -> void:
		_f = v * 1e14
		_sync_view()
		_after_change(), 260.0)
	add_slider("Şiddet", 0.0, 100.0, _i * 100.0, 5.0, func(v: float) -> void:
		_i = v / 100.0
		_sync_view()
		_after_change(), 200.0)


# --- 0 · Kriz ----------------------------------------------------------------------

func _enter_crisis() -> void:
	step = Step.CRISIS
	_f = START_FREQUENCY
	_i = 1.0
	var view := _view()
	view.faulty_display = true
	view.door_open = false
	view.door_burned = false
	_sync_view()
	screen(0, "KRİZ", "Lamba en güçlü, ama Arşiv kapısı kapalı.", "Nedenini bul",
		"Kapı, sezyum plakadan sökülen elektronların akımıyla açılır. Misafirler lambayı kırmızıya çevirdi. Cihaz şiddet artınca akım çıkacağını sanıp lambayı sonuna kadar açtı: ampermetre sıfırda.")


# --- 1 · Sına ----------------------------------------------------------------------

func _enter_test() -> void:
	step = Step.TEST
	_seen_below = false
	_seen_intensity = false
	_seen_frequency = false
	_view().faulty_display = true
	screen(1, "SINA", "Frekansı ve şiddeti değiştir. Akımı ve elektron enerjisini izle.", "",
		"Üç şeye bak: eşik altında şiddet akım verir mi? Eşik üstünde şiddeti değiştirince elektron enerjisi ne olur? Frekansı değiştirince ne olur?")
	_lamp_sliders()
	_anchor_f = _f
	_anchor_i = _i
	_anchor_k = Photo.k_max(_f, PHI)


func _after_change() -> void:
	if step != Step.TEST:
		return
	var k := Photo.k_max(_f, PHI)
	var current := Photo.photocurrent(_f, _i, PHI)
	if not _seen_below and Photo.photon_energy(_f) <= PHI and _i >= 0.9:
		_seen_below = true
		say("Eşik altında, şiddet en güçlü: akım %s µA. Şiddet elektron sökmüyor." % str(current).replace(".", ","), GOOD)
	elif Photo.photon_energy(_f) > PHI:
		if not _seen_intensity and absf(_i - _anchor_i) >= 0.3 and absf(_f - _anchor_f) < 1e12 and k > 0.0:
			_seen_intensity = true
			say("Şiddet değişti: akım değişti, elektronların en fazla enerjisi %s eV kaldı. Şiddet sayıyı belirliyor." % str(snappedf(k, 0.01)).replace(".", ","), GOOD)
		if not _seen_frequency and absf(k - _anchor_k) >= 0.5 and absf(_i - _anchor_i) < 0.01:
			_seen_frequency = true
			say("Frekans değişti: elektron enerjisi %s eV oldu. Enerjiyi frekans belirliyor." % str(snappedf(k, 0.01)).replace(".", ","), GOOD)
	if _seen_below and _seen_intensity and _seen_frequency:
		hud.set_action("Nedeni seç", true)
	_anchor_if_idle()


func _anchor_if_idle() -> void:
	# Her değişikliğin başlangıç noktasını bir saniye sonra güncelle: tek değişkenli karşılaştırma için.
	var snapshot_f := _f
	var snapshot_i := _i
	get_tree().create_timer(1.2).timeout.connect(func() -> void:
		if step == Step.TEST and snapshot_f == _f and snapshot_i == _i:
			_anchor_f = _f
			_anchor_i = _i
			_anchor_k = Photo.k_max(_f, PHI))


# --- 2 · Neden ---------------------------------------------------------------------

func _enter_reason() -> void:
	step = Step.REASON
	screen(2, "NEDEN", "Kırmızı ışık en güçlü açıkken neden elektron sökülmedi?", "",
		"Eşik altında şiddeti ne kadar artırsan da akım sıfır kaldı. Eşik üstünde şiddet akımı, frekans enerjiyi belirledi.")
	for choice in [&"intensity", &"frequency", &"plate"]:
		var button := Button.new()
		button.text = {&"intensity": "Şiddet yetmedi", &"frequency": "Foton enerjisi (frekans) yetmedi", &"plate": "Plaka bozuk"}[choice]
		button.pressed.connect(_on_reason.bind(choice))
		tools.add_child(button)


func _on_reason(choice: StringName) -> void:
	match choice:
		&"frequency":
			say("Doğru. Tek bir foton elektronu sökecek enerjiye sahip olmalı: h·f > φ. Şiddet yalnızca foton sayısıdır.", GOOD)
			clear_tools()
			hud.set_action("Eşiği hesapla", true)
		&"intensity":
			say("Şiddeti sonuna kadar açtık, akım yine sıfırdı. Şiddet neden olamaz.", BAD)
		_:
			say("Aynı plaka yüksek frekansta elektron saldı. Plaka bozuk değil.", BAD)


# --- 3 · Ölç -----------------------------------------------------------------------

func _enter_measure() -> void:
	step = Step.MEASURE
	screen(3, "ÖLÇ", "Sezyumun iş fonksiyonu 2,07 eV. Eşik frekansı kaç ×10¹⁴ Hz?", "Onayla",
		"Foton enerjisi E = h·f, h = 4,14·10⁻¹⁵ eV·s. Elektron sökülmesi için E ≥ φ. Eşik: f₀ = φ / h.")
	add_entry("f₀  (×10¹⁴ Hz)")


func _check_measure() -> void:
	var value := read_number()
	if is_nan(value):
		say("Sayı gir. Örnek: 5,0", BAD)
		return
	if absf(value - 5.0) <= 0.1:
		say("f₀ = 2,07 / 4,14·10⁻¹⁵ = 5,0·10¹⁴ Hz. Kırmızı lamba (4,3·10¹⁴ Hz) eşiğin altındaydı.", GOOD)
		_enter_rescue()
	elif absf(value - 0.5) < 0.05 or absf(value - 50.0) < 1.0:
		say("Üssü kaçırmış olabilirsin: 2,07 / 4,14 = 0,5 ve h'nin üssü 10⁻¹⁵, yani 5·10¹⁴ Hz.", BAD)
	else:
		say("f₀ = φ / h. Elektron sökmek için gereken en küçük frekans: 2,07 eV bölü 4,14·10⁻¹⁵ eV·s.", BAD)


# --- 4 · Kurtar --------------------------------------------------------------------

func _enter_rescue() -> void:
	step = Step.RESCUE
	_tries = 3
	_view().faulty_display = false
	screen(4, "KURTAR", "Kapı için lambayı kur: akım ≥ 4 µA ve elektron enerjisi 1,0–2,0 eV.", "Lambayı kur",
		"Üç hakkın var. Akım yetmezse kapı açılmaz. Elektronlar 1,0 eV'tan yavaşsa algılanmaz, 2,0 eV'tan hızlıysa kapı yanar. Frekans ve şiddeti birlikte seç.")
	add_entry("frekans  (×10¹⁴ Hz)")
	var intensity_entry := LineEdit.new()
	intensity_entry.placeholder_text = "şiddet  (%)"
	intensity_entry.custom_minimum_size = Vector2(150, 0)
	intensity_entry.name = "IntensityEntry"
	intensity_entry.text_submitted.connect(func(_t: String) -> void: _on_action())
	tools.add_child(intensity_entry)


func _run_rescue() -> void:
	var frequency := read_number()
	var intensity_entry: LineEdit = tools.get_node_or_null("IntensityEntry")
	var intensity := NAN
	if intensity_entry != null and intensity_entry.text.strip_edges() != "":
		var text := intensity_entry.text.strip_edges().replace(",", ".")
		intensity = text.to_float() if text.is_valid_float() else NAN
	if is_nan(frequency) or is_nan(intensity):
		say("Frekansı (×10¹⁴ Hz) ve şiddeti (%) gir. Örnek: 8  ve  70", BAD)
		return
	if frequency < 3.0 or frequency > 14.0 or intensity < 0.0 or intensity > 100.0:
		say("Lamba 3–14 ×10¹⁴ Hz ve 0–100 % aralığında çalışır.", BAD)
		return
	_f = frequency * 1e14
	_i = intensity / 100.0
	_sync_view()
	var k := Photo.k_max(_f, PHI)
	var current := Photo.photocurrent(_f, _i, PHI)
	var view := _view()
	if k >= K_LOW and k <= K_HIGH and current >= CURRENT_NEED:
		view.door_open = true
		_finish()
		return
	_tries -= 1
	var why := ""
	if Photo.photon_energy(_f) <= PHI:
		why = "Eşik altı: akım sıfır. Şiddet yetmez, frekansı eşiğin (5·10¹⁴ Hz) üstüne çıkar."
	elif k > K_HIGH:
		view.door_burned = true
		why = "Elektronlar %s eV ile çıktı, sınır 2,0 eV: kapı yandı. Frekansı düşür." % str(snappedf(k, 0.01)).replace(".", ",")
	elif k < K_LOW:
		why = "Elektronlar yalnızca %s eV: 1,0 eV altı algılanmaz. Frekansı artır." % str(snappedf(k, 0.01)).replace(".", ",")
	else:
		why = "Akım %s µA, kapı 4 µA ister. Şiddet (foton sayısı) akımı belirler, onu artır." % str(snappedf(current, 0.1)).replace(".", ",")
	say(why, BAD)
	if _tries <= 0:
		_tries = 3
		say("Kapı kilidi yenilendi. E = h·f ve K_max = h·f − φ ile frekansı, akım için şiddeti seç.")
	await get_tree().create_timer(2.2).timeout
	view.door_burned = false


func _finish() -> void:
	seal("Şiddet sayıyı artırıyordu. Enerjiyi frekans belirliyordu.", "Arşiv kapısı açıldı: doğru frekans, yeterli akım.")


# --- Yönlendirme ---------------------------------------------------------------------

func _on_action() -> void:
	match step:
		Step.CRISIS:
			_enter_test()
		Step.TEST:
			_enter_reason()
		Step.REASON:
			_enter_measure()
		Step.MEASURE:
			if hud.action.text == "Eşiği hesapla":
				_enter_measure()
			else:
				_check_measure()
		Step.RESCUE:
			_run_rescue()
