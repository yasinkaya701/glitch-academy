extends Node
## Üç Güneş finalini doğru ve yanlış girişlerle baştan sona oynar.
## Kullanım: godot --headless --path . tests/three_suns_flow_test.tscn

const Model = preload("res://stations/yks/three_body_model.gd")

var mission: Control
var completed := false
var failures := 0


func _check(label: String, ok: bool) -> void:
	print("%s  %s" % ["ok " if ok else "HATA", label])
	if not ok:
		failures += 1


func _wait_until(condition: Callable, timeout: float = 20.0) -> bool:
	var waited := 0.0
	while not condition.call() and waited < timeout:
		await get_tree().create_timer(0.1).timeout
		waited += 0.1
	return condition.call()


func _ready() -> void:
	_model_checks()
	mission = load("res://stations/yks/three_suns.tscn").instantiate()
	mission.completed.connect(func() -> void: completed = true)
	add_child(mission)
	await get_tree().create_timer(0.3).timeout
	var view = mission.stage
	_check("kriz adımı", mission.step == mission.Step.CRISIS)
	mission._on_action()
	_check("kepler adımı", mission.step == mission.Step.KEPLER)
	# Yanlış dönem: a ile orantılı (4) → ilerlemez
	mission.entry.text = "4"
	mission._on_action()
	view.time_scale = 10.0
	await _wait_until(func() -> bool: return mission.hud.action.visible, 15.0)
	_check("T = 4: ilerlemedi", mission.step == mission.Step.KEPLER)
	mission.entry.text = "8"
	mission._on_action()
	view.time_scale = 10.0
	await _wait_until(func() -> bool: return mission.step == mission.Step.SAME, 15.0)
	_check("T = 8: aynı başlangıç adımı", mission.step == mission.Step.SAME)
	mission._on_action()
	view.time_scale = 12.0
	await _wait_until(func() -> bool: return mission.hud.action.visible and mission.hud.action.text == "Küçük fark ekle", 20.0)
	_check("aynı başlangıç: iki iz çakıştı", Model.separation_time(Model.simulate(0.0), Model.simulate(0.0)) < 0.0)
	mission._on_action()
	_check("küçük fark adımı", mission.step == mission.Step.DIFF)
	# Δv = 0,04 ölç
	mission._dv = 0.04
	view.time_scale = 12.0
	mission._on_action()
	await _wait_until(func() -> bool: return mission.entry != null, 20.0)
	var first_truth: float = mission._true_separation
	mission.entry.text = "7,9"
	mission._on_action()
	_check("yanlış t* (süre sonu): ölçüm sayılmadı", mission._measured.size() == 0)
	mission.entry.text = str(snappedf(first_truth, 0.01))
	mission._on_action()
	_check("doğru t*: ölçüm kaydedildi", mission._measured.size() == 1)
	# Aynı Δv ile ikinci ölçüm sayılmaz
	mission._dv = 0.04
	view.time_scale = 12.0
	mission._on_action()
	await _wait_until(func() -> bool: return mission.entry != null, 20.0)
	mission.entry.text = str(snappedf(mission._true_separation, 0.01))
	mission._on_action()
	_check("küçülmeyen Δv: ilerlemedi", mission.step == mission.Step.DIFF and mission._measured.size() == 1)
	# Daha küçük Δv
	mission._dv = 0.01
	view.time_scale = 12.0
	mission._on_action()
	await _wait_until(func() -> bool: return mission.entry != null, 20.0)
	_check("küçük Δv: ayrılma daha geç", mission._true_separation > first_truth)
	mission.entry.text = str(snappedf(mission._true_separation, 0.01))
	mission._on_action()
	_check("uygulama: kepler", mission.step == mission.Step.APPLY_KEPLER)
	# Hak harcayan yanlış giriş
	mission.entry.text = "6,25"
	mission._on_action()
	view.time_scale = 10.0
	await _wait_until(func() -> bool: return mission.hud.action.visible, 15.0)
	_check("a² (6,25): hak düştü", mission.attempts == 2 and mission.step == mission.Step.APPLY_KEPLER)
	mission.entry.text = "3,95"
	mission._on_action()
	view.time_scale = 10.0
	await _wait_until(func() -> bool: return mission.step == mission.Step.APPLY_SEPARATION, 15.0)
	_check("T = 3,95: ayrılma adımı", mission.step == mission.Step.APPLY_SEPARATION)
	view.time_scale = 12.0
	mission._on_action()
	await _wait_until(func() -> bool: return mission.entry != null, 20.0)
	mission.entry.text = "7,9"
	mission._on_action()
	_check("yanlış t*: hak düştü", mission.attempts == 1 and mission.step == mission.Step.APPLY_SEPARATION)
	mission.entry.text = str(snappedf(mission._true_separation, 0.01))
	mission._on_action()
	_check("doğru t*: karar adımı", mission.step == mission.Step.DONE)
	_check("henüz mühür yok", not completed)
	mission._on_action()
	_check("mühür: görev tamamlandı", completed)
	print("HEPSİ GEÇTİ" if failures == 0 else "%d HATA" % failures)
	get_tree().quit(failures)


func _model_checks() -> void:
	var base := Model.simulate(0.0)
	var again := Model.simulate(0.0)
	var same := true
	for body in 3:
		for sample in base[body].size():
			if base[body][sample] != again[body][sample]:
				same = false
	_check("model: aynı başlangıç aynı iz", same)
	_check("model: Kepler T(4) = 8", is_equal_approx(Model.kepler_period(4.0), 8.0))
	_check("model: Kepler T(2,5) ≈ 3,95", absf(Model.kepler_period(2.5) - 3.953) < 0.01)
	var coarse := Model.separation_time(base, Model.simulate(0.04))
	var fine := Model.separation_time(base, Model.simulate(0.01))
	_check("model: Δv küçülünce t* uzar", fine > coarse and coarse > 0.0)
	_check("model: Δv = 0 iken ayrılma yok", Model.separation_time(base, again) < 0.0)
	_check("model: ayrılma süresi tahmin ufkunun içinde", coarse < Model.duration() and fine < Model.duration())
