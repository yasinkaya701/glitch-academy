extends "res://scripts/physics/experiment_mission.gd"
## Üç Güneş (final). AYT Fizik 15: Kütle çekim ve Kepler. Tasarım: stations/yks/THREE_SUNS_DESIGN_CARD.md.
## KRİZ: MERİDYEN, üç güneşli bir sistemin yörüngesini sınırsız süre öngörebileceğini söylüyor.
## Oyuncu önce iki cisimde Kepler'i uygular, sonra üç cisimde aynı başlangıcın aynı sonucu verdiğini,
## küçük bir farkın izleri ayırdığını ve ayrılma anını ölçer; yeni bir sistemde ikisini tek başına yapar.
## Hesap three_body_model.gd'dedir; sahne three_suns_stage.gd'dedir.

const Stage = preload("res://stations/yks/three_suns_stage.gd")
const Model = preload("res://stations/yks/three_body_model.gd")

const KEPLER_A := 4.0
const KEPLER_TOLERANCE := 0.2
const APPLY_A := 2.5
const APPLY_KEPLER_TOLERANCE := 0.15
const APPLY_DV := 0.03
const CRISIS_DV := 0.012
const DV_LOW := 0.002
const DV_HIGH := 0.08
const MAX_ATTEMPTS := 3

enum Step { CRISIS, KEPLER, SAME, DIFF, APPLY_KEPLER, APPLY_SEPARATION, DONE }

var step := Step.CRISIS
var attempts := MAX_ATTEMPTS
var _dv := 0.04
var _measured: Array[Vector2] = []  ## (Δv, doğru t*) çifti, doğrulanmış ölçümler
var _awaiting_entry := false
var _true_separation := -1.0
var _run_id := 0


func _begin() -> void:
	step_total = 6
	_enter_crisis()


func _make_stage() -> Control:
	var view := Stage.new()
	view.playback_finished.connect(_on_playback_finished)
	view.kepler_finished.connect(_on_kepler_finished)
	return view


func _stage() -> Stage:
	return stage as Stage


func _powers() -> void:
	_stage().time_scale = 1.0
	add_power("⟲  Sar", "İzi başa al, aynı koşulda yeniden oynat", func() -> void:
		_stage().rewind()
		Sfx.play(&"click", -12.0))
	add_power("◐  Yavaşlat", "Zamanı ¼ hıza çek", func(on: bool) -> void: _stage().time_scale = 0.25 if on else 1.0, true)
	add_gap()


# --- 0 · Kriz ----------------------------------------------------------------------

func _enter_crisis() -> void:
	step = Step.CRISIS
	attempts = MAX_ATTEMPTS
	_measured.clear()
	_awaiting_entry = false
	var view := _stage()
	view.time_scale = 1.0
	view.show_three(Model.simulate(0.0), Model.simulate(CRISIS_DV), Model.duration())
	view.play()
	screen(0, "KRİZ", "MERİDYEN yörüngeyi hiç şaşmadan öngördüğünü söylüyor. İki izi karşılaştır.", "Ölçmeye başla",
		"Üç güneşli bir sistemde yeşil iz MERİDYEN'in öngörüsü, kehribar iz ölçülen. MERİDYEN, öngörü ufkunun sınırsız olduğunu savunuyor. Küçük bir ilk hız farkı bu sınırı gerçekten kaldırıyor mu?")
	hud.skip.show()
	hud.skip.text = "Açılışı geç"


func _on_skip() -> void:
	if step == Step.CRISIS:
		_enter_kepler()


# --- 1 · Kepler (iki cisim) --------------------------------------------------------

func _enter_kepler() -> void:
	step = Step.KEPLER
	_awaiting_entry = false
	var view := _stage()
	view.show_kepler(KEPLER_A)
	screen(1, "İKİ CİSİM", "a = 1 yörüngesinin dönemi T₀. a = 4 yörüngesinin dönemi kaç T₀?", "Sayacı kur",
		"Tek gezegen, tek güneş. Dönem sayacını kurduğun değere ayarla; gezegen gerçek dönemiyle döner ve sayaç dolduğunda başlangıç çizgisine dönüp dönmediği görülür. Kepler'in üçüncü yasasını kullan.")
	_powers()
	add_entry("T  (T₀)")


func _check_kepler() -> void:
	var value := read_number()
	if is_nan(value) or value <= 0.0:
		say("Dönemi T₀ cinsinden sayı olarak gir. Örnek: 2,5", BAD)
		return
	var truth := Model.kepler_period(KEPLER_A)
	var correct := absf(value - truth) <= KEPLER_TOLERANCE
	hud.set_action("", false)
	_run_kepler(value, correct, _kepler_reason(value, KEPLER_A))


func _kepler_reason(value: float, axis: float) -> String:
	if is_equal_approx(value, axis) or absf(value - axis) < 0.3:
		return "Dönem a ile orantılı değil. Kepler: T² ∝ a³."
	if absf(value - axis * axis) < 0.5:
		return "a² değil. T² ∝ a³ → T = a^(3/2)."
	if absf(value - axis * axis * axis) < 1.5:
		return "T² ∝ a³: T = a³ değil."
	return "T² / a³ sabit; a = 1 için T = 1."


func _run_kepler(value: float, correct: bool, reason: String) -> void:
	var view := _stage()
	view.time_scale = 1.0
	view.run_kepler(value)
	_pending_kepler = {"value": value, "correct": correct, "reason": reason}


var _pending_kepler := {}


func _on_kepler_finished() -> void:
	if _pending_kepler.is_empty():
		return
	var pending := _pending_kepler
	_pending_kepler = {}
	var text := String.num(float(pending["value"]), 2).replace(".", ",")
	if pending["correct"]:
		say("T = %s T₀: tur kapandı. Tek güneşte yörünge tahmini tutar." % text, GOOD)
		if step == Step.KEPLER:
			_enter_same()
		elif step == Step.APPLY_KEPLER:
			_enter_apply_separation()
	else:
		attempts_penalty()
		say("T = %s T₀ ile gezegen başlangıçta değil. %s" % [text, pending["reason"]], BAD)
		if step == Step.KEPLER or step == Step.APPLY_KEPLER:
			hud.set_action("Sayacı kur", true)


## Yalnız bağımsız uygulamada hak harcanır.
func attempts_penalty() -> void:
	if step != Step.APPLY_KEPLER and step != Step.APPLY_SEPARATION:
		return
	attempts -= 1
	hud.set_steps(4, step_total, "UYGULAMA · %d hak" % maxi(attempts, 0))
	if attempts <= 0:
		say("Haklar bitti. Ölçümler silindi; krizin başına dönüyoruz.", BAD)
		get_tree().create_timer(1.6).timeout.connect(_enter_crisis)


# --- 2 · Aynı başlangıç ------------------------------------------------------------

func _enter_same() -> void:
	step = Step.SAME
	_awaiting_entry = false
	var view := _stage()
	view.show_three(Model.simulate(0.0), Model.simulate(0.0))
	screen(2, "AYNI BAŞLANGIÇ", "Üç güneş. Aynı başlangıçla iki kez başlat; izler çakışıyor mu?", "İki kez başlat",
		"Üç cisimli sistem de deterministiktir: aynı başlangıç koşulu aynı yörüngeyi verir. İki koşu aynı başlangıçla çalışır.")
	_powers()


func _on_same_finished() -> void:
	say("İki iz üst üste: aynı başlangıç aynı sonucu verdi.", GOOD)
	hud.set_action("Küçük fark ekle", true)
	_same_done = true


var _same_done := false


# --- 3 · Küçük fark ----------------------------------------------------------------

func _enter_diff() -> void:
	step = Step.DIFF
	_same_done = false
	_awaiting_entry = false
	var view := _stage()
	view.show_three(Model.simulate(0.0), [], -1.0)
	screen(3, "KÜÇÜK FARK", "İkinci koşunun ilk hızına küçük bir Δv ekle. İzler ne zaman ayrılıyor?", "Çalıştır",
		"Kehribar izin ilk hızı Δv kadar farklıdır. Ölçü cihazında iki iz arası en büyük mesafe d, eşik ε'u aşınca durum ▲ AYRILDI olur. O andaki t'yi oku.")
	_powers()
	add_slider("Δv", DV_LOW, DV_HIGH, _dv, 0.002, func(v: float) -> void: _dv = v, 220.0)


func _run_diff() -> void:
	var view := _stage()
	var dv := _dv
	var a := Model.simulate(0.0)
	var b := Model.simulate(dv)
	_true_separation = Model.separation_time(a, b)
	view.show_three(a, b, Model.duration())
	view.play()
	_run_id += 1
	_awaiting_entry = true
	hud.set_action("", false)


func _on_playback_finished() -> void:
	match step:
		Step.CRISIS:
			hud.set_action("Ölçmeye başla", true)
		Step.SAME:
			if not _same_done:
				_on_same_finished()
		Step.DIFF:
			_after_diff_run()
		Step.APPLY_SEPARATION:
			hud.set_action("Ayrılma anını onayla", true)
			_ensure_separation_entry()


func _after_diff_run() -> void:
	if _true_separation < 0.0:
		say("Bu Δv ile izler süre içinde ayrılmadı. Δv'yi büyüt.", BAD)
		hud.set_action("Çalıştır", true)
		_awaiting_entry = false
		return
	say("İzler ayrıldı. Cihazda ▲ AYRILDI görünen andaki t'yi oku.")
	if entry == null:
		add_entry("t*  (birim)")
	hud.set_action("Ölç", true)


func _check_separation(is_application: bool) -> void:
	var value := read_number()
	if is_nan(value):
		say("Ayrılma anını sayı olarak gir. Örnek: 3,4", BAD)
		return
	if _true_separation < 0.0:
		say("Bu koşuda izler ayrılmadı. Δv'yi büyütüp yeniden çalıştır.", BAD)
		return
	var tolerance := maxf(0.25, _true_separation * 0.12)
	if absf(value - _true_separation) <= tolerance:
		var text := String.num(_true_separation, 1).replace(".", ",")
		if is_application:
			say("Ayrılma t* ≈ %s. MERİDYEN'in sınırsız ufku bundan çok önce bitiyor." % text, GOOD)
			_enter_decision()
			return
		_measured.append(Vector2(_dv, _true_separation))
		_record_measurement(text)
	else:
		if is_application:
			attempts_penalty()
		if absf(value - Model.duration()) < 0.5:
			say("Sürenin sonunu okudun. İlk ayrıldığı anı oku (d > ε).", BAD)
		elif value < _true_separation:
			say("Bu anda d henüz ε'un altında. Daha geç bir t oku.", BAD)
		else:
			say("Bu anda iki iz çoktan ayrılmıştı. Daha erken bir t oku.", BAD)


func _record_measurement(text: String) -> void:
	if _measured.size() == 1:
		say("t* ≈ %s. Δv'yi küçült ve yeniden ölç: ayrılma ne zaman?" % text, GOOD)
		_restart_diff_round()
		return
	var first := _measured[0]
	var second := _measured[_measured.size() - 1]
	if second.x < first.x * 0.7 and second.y > first.y:
		say("Δv küçüldü, t* uzadı (%s → %s). Ayrılma ertelendi ama kaybolmadı." % [String.num(first.y, 1).replace(".", ","), String.num(second.y, 1).replace(".", ",")], GOOD)
		_enter_apply_kepler()
	else:
		say("Önceki Δv'den belirgin biçimde küçük bir Δv seç ve yeniden ölç.", BAD)
		_measured.remove_at(_measured.size() - 1)
		_restart_diff_round()


func _restart_diff_round() -> void:
	_awaiting_entry = false
	if entry != null:
		entry.queue_free()
		entry = null
	hud.set_action("Çalıştır", true)


# --- 4 · Bağımsız uygulama ---------------------------------------------------------

func _enter_apply_kepler() -> void:
	step = Step.APPLY_KEPLER
	_awaiting_entry = false
	var view := _stage()
	view.show_kepler(APPLY_A)
	screen(4, "UYGULAMA · %d hak" % attempts, "Yeni bir gezegen: a = 2,5. Dönemini kaç T₀'ya kurmalısın?", "Sayacı kur",
		"Yeni durum. Bu kez referans da ipucu da yok: önce a = 2,5 yörüngesinin dönemini, ardından yeni bir üç güneş sisteminde ayrılma anını kendin bul. Üç hakkın var.")
	_powers()
	add_entry("T  (T₀)")


func _check_apply_kepler() -> void:
	var value := read_number()
	if is_nan(value) or value <= 0.0:
		say("Dönemi T₀ cinsinden sayı olarak gir.", BAD)
		return
	var correct := absf(value - Model.kepler_period(APPLY_A)) <= APPLY_KEPLER_TOLERANCE
	hud.set_action("", false)
	_run_kepler(value, correct, _kepler_reason(value, APPLY_A))


func _enter_apply_separation() -> void:
	step = Step.APPLY_SEPARATION
	var view := _stage()
	var a := Model.simulate(0.0)
	var b := Model.simulate(APPLY_DV)
	_true_separation = Model.separation_time(a, b)
	view.show_three(a, b, Model.duration())
	screen(4, "UYGULAMA · %d hak" % attempts, "Yeni başlangıç: Δv = 0,030. İzler ne zaman ayrılıyor? MERİDYEN'in ufku %s." % String.num(Model.duration(), 1).replace(".", ","), "Çalıştır",
		"Yeni sistem, yeni Δv. İki izi çalıştır, ölçü cihazında ayrılma anını oku ve MERİDYEN'in sınırsız ufkunu çürüt.")
	_powers()


func _ensure_separation_entry() -> void:
	if entry == null:
		add_entry("t*  (birim)")


func _run_apply_separation() -> void:
	var view := _stage()
	view.show_three(Model.simulate(0.0), Model.simulate(APPLY_DV), Model.duration())
	view.play()
	hud.set_action("", false)


# --- 5 · Karar ---------------------------------------------------------------------

func _enter_decision() -> void:
	step = Step.DONE
	if entry != null:
		entry.queue_free()
		entry = null
	screen(5, "KARAR", "Belirsizliği ölçtün. MERİDYEN'in ufku sınırsız değil: t* kadar.", "MERİDYEN yetkisini kaldır",
		"Küçük bir fark er ya da geç büyür. Öngörülemezlik de ölçülebilir bir şeydir: yasa yerinde, ufuk sınırlı.")


# --- Eylem düğmesi ----------------------------------------------------------------

func _on_action() -> void:
	match step:
		Step.CRISIS:
			_enter_kepler()
		Step.KEPLER:
			_check_kepler()
		Step.SAME:
			if _same_done:
				_enter_diff()
			else:
				hud.set_action("", false)
				_stage().show_three(Model.simulate(0.0), Model.simulate(0.0))
				_stage().play()
		Step.DIFF:
			if _awaiting_entry and _true_separation >= 0.0 and entry != null and entry.text.strip_edges() != "":
				_check_separation(false)
			else:
				_run_diff()
		Step.APPLY_KEPLER:
			_check_apply_kepler()
		Step.APPLY_SEPARATION:
			if entry != null and entry.text.strip_edges() != "":
				_check_separation(true)
			else:
				_run_apply_separation()
		Step.DONE:
			seal("Öngörülemezlik de ölçülebilir.", "Mühürlendi: öngörü ufku sınırsız değil. Yasalar yerinde, kapı açık.")
