extends SceneTree
## Komut: godot --headless --path . --script tests/new_simulations_test.gd
## Sayısal modeller + sahnedeki yanlış/doğru/onarım yollarını kontrol eder.

const Genetics = preload("res://stations/genetics/genetics_model.gd")
const Integral = preload("res://stations/integral/integral_model.gd")

var failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _check(label: String, condition: bool) -> void:
	print("%s  %s" % ["ok" if condition else "HATA", label])
	if not condition:
		failures += 1


func _run() -> void:
	var first := Genetics.cross("AA", "aa")
	_check("AA x aa: dört Aa", first.size() == 4 and first.count("Aa") == 4)
	var second := Genetics.cross("Aa", "Aa")
	_check("Aa x Aa: 1 AA / 2 Aa / 1 aa", second.count("AA") == 1 and second.count("Aa") == 2 and second.count("aa") == 1)
	_check("Aa x aa: çekinik olasılık %50", is_equal_approx(Genetics.recessive_probability("Aa", "aa"), 0.5))
	_check("geçersiz genotip reddedilir", Genetics.cross("abc", "aa").is_empty())

	_check("q(4) = 6 L/s", is_equal_approx(Integral.flow_at(4.0), 6.0))
	_check("V(2) = 6 L", is_equal_approx(Integral.volume_at(2.0), 6.0))
	_check("V(4) = 16 L", is_equal_approx(Integral.volume_at(4.0), 16.0))
	_check("bozuk sayaç 4 s'de 24 L hesaplar", is_equal_approx(Integral.broken_volume_at(4.0), 24.0))
	_check("V(6) = 30 L, t(30)=6 s", is_equal_approx(Integral.volume_at(6.0), 30.0) and is_equal_approx(Integral.time_for_volume(30.0), 6.0))
	_check("8 sol dikdörtgen yaklaşımı tam integralden küçüktür", Integral.left_sum(6.0, 8) < Integral.volume_at(6.0))

	var genetics = load("res://stations/genetics/mission.tscn").instantiate()
	root.add_child(genetics)
	await process_frame
	var g_done := [false]
	genetics.completed.connect(func() -> void: g_done[0] = true)
	_check("LGS ilk örnekten sonra devam kilitli", genetics._advance.disabled)
	genetics._select_example(0)
	genetics._select_example(1)
	_check("LGS iki gözlemden sonra devam açık", not genetics._advance.disabled)
	genetics._enter_prediction()
	genetics._predict(25)
	_check("LGS yanlış tahminde onarım yok", not g_done[0])
	genetics._predict(50)
	_check("LGS doğru tahminde onarım sinyali", g_done[0])
	genetics.queue_free()
	await process_frame

	var integral = load("res://stations/integral/mission.tscn").instantiate()
	root.add_child(integral)
	await process_frame
	var i_done := [false]
	integral.completed.connect(func() -> void: i_done[0] = true)
	_check("AYT iki ölçümden önce uygulama kilitli", integral._advance.disabled)
	integral._observe(0)
	integral._observe(1)
	_check("AYT iki ölçümden sonra uygulama açık", not integral._advance.disabled)
	integral._enter_application()
	integral._slider.value = 5.0
	integral._submit()
	_check("AYT 5 saniyede onarım yok", not i_done[0])
	integral._slider.value = 6.0
	integral._submit()
	_check("AYT 6 saniyede onarım sinyali", i_done[0])
	integral.queue_free()
	await process_frame

	print("BAŞARISIZ: %d" % failures if failures > 0 else "HEPSİ GEÇTİ")
	quit(failures)
