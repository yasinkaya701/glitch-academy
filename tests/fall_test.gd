extends SceneTree
const Fall = preload("res://stations/free_fall/fall_sim.gd")

func _init() -> void:
	var failures := 0
	for body in [&"steel", &"foam"]:
		var air: Dictionary = Fall.fall(body, 20.0, 101.325)
		print("%s havada 20 m: %.2f s, çarpma %.1f m/s" % [body, air.time, air.speed])
	for pressure in [101.325, 60.0, 30.0, 10.0, 2.0, 0.0]:
		var steel: Dictionary = Fall.fall(&"steel", 20.0, pressure)
		var foam: Dictionary = Fall.fall(&"foam", 20.0, pressure)
		print("basınç %6.1f kPa  çelik %.3f s  sünger %.3f s  fark %.3f" % [pressure, steel.time, foam.time, foam.time - steel.time])
	var vacuum: Dictionary = Fall.fall(&"foam", 20.0, 0.0)
	print("vakum çözümü %.4f, kapalı form %.4f" % [vacuum.time, Fall.vacuum_time(20.0)])
	if absf(vacuum.time - Fall.vacuum_time(20.0)) > 0.002:
		failures += 1
	var cap: Dictionary = Fall.fall(&"capsule", 45.0, 0.0)
	print("kapsül 45 m vakum: %.3f s (hedef 3,00)" % cap.time)
	var cap_air: Dictionary = Fall.fall(&"capsule", 45.0, 101.325)
	print("kapsül 45 m havada: %.2f s, çarpma %.1f m/s" % [cap_air.time, cap_air.speed])
	var g_measured: float = 2.0 * 20.0 / pow(Fall.fall(&"steel", 20.0, 0.0).time, 2.0)
	print("ölçülen g (2h/t²): %.2f" % g_measured)
	print("BAŞARISIZ" if failures > 0 else "GEÇTİ")
	quit(failures)
