extends SceneTree
const Wave = preload("res://stations/waves/wave_sim.gd")
var failures := 0

func _near(label: String, got: float, want: float, tolerance: float = 0.01) -> void:
	var ok := absf(got - want) <= tolerance
	print("%s  %s  (beklenen %s, bulunan %s)" % ["ok " if ok else "HATA", label, str(want), str(snappedf(got, 0.001))])
	if not ok:
		failures += 1

func _init() -> void:
	_near("A noktası yol farkı (cm)", Wave.path_difference(Wave.SENSOR_A), 3.0, 0.01)
	_near("B noktası yol farkı (cm)", Wave.path_difference(Wave.SENSOR_B), 2.0, 0.01)
	_near("f=6 Hz dalga boyu (cm)", Wave.wavelength(6.0), 2.0)
	_near("f=6: A genliği (yıkıcı)", Wave.amplitude(Wave.SENSOR_A, 6.0), 0.0, 0.01)
	_near("f=6: B genliği (yapıcı)", Wave.amplitude(Wave.SENSOR_B, 6.0), 2.0, 0.01)
	_near("f=4: A genliği (yapıcı, aşırı yük)", Wave.amplitude(Wave.SENSOR_A, 4.0), 2.0, 0.01)
	_near("f=2: A yıkıcı", Wave.amplitude(Wave.SENSOR_A, 2.0), 0.0, 0.01)
	_near("f=2: B yetersiz (≈1,0)", Wave.amplitude(Wave.SENSOR_B, 2.0), 1.0, 0.01)
	# Aralıkta (1–8 Hz) hem A ≤ 0,3 hem B ≥ 1,7 olan tek çözüm 6 Hz civarı
	var solutions := []
	var f := Wave.FREQ_MIN
	while f <= Wave.FREQ_MAX + 0.001:
		if Wave.amplitude(Wave.SENSOR_A, f) <= 0.3 and Wave.amplitude(Wave.SENSOR_B, f) >= 1.7:
			solutions.append(snappedf(f, 0.01))
		f += 0.01
	print("çözüm frekansları: ", solutions.front(), " … ", solutions.back(), " (", solutions.size(), " nokta)")
	_near("çözüm aralığı ortası 6 Hz", (float(solutions.front()) + float(solutions.back())) * 0.5, 6.0, 0.05)
	_near("tek kaynak genliği", Wave.amplitude(Wave.SENSOR_A, 6.0, false), 1.0)
	print("BAŞARISIZ: %d" % failures if failures > 0 else "HEPSİ GEÇTİ")
	quit(failures)
