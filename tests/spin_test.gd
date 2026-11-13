extends SceneTree
const Spin = preload("res://stations/spin/spin_sim.gd")
var failures := 0

func _near(label: String, got: float, want: float, tolerance: float = 0.001) -> void:
	var ok := absf(got - want) <= tolerance
	print("%s  %s  (beklenen %s, bulunan %s)" % ["ok " if ok else "HATA", label, str(want), str(snappedf(got, 0.0001))])
	if not ok:
		failures += 1

func _s(axis: StringName, sign: int) -> Dictionary:
	return {"axis": axis, "sign": sign}

func _init() -> void:
	var f: Dictionary = Spin.fractions([], &"z")
	_near("süzgeçsiz, Z dedektör: yukarı", f.up, 0.5)
	f = Spin.fractions([], &"x")
	_near("süzgeçsiz, X dedektör: yukarı", f.up, 0.5)
	f = Spin.fractions([_s(&"z", 1)], &"z")
	_near("Z↑ süz, Z ölç: yukarı", f.up, 1.0)
	_near("Z↑ süz: ulaşan oran", f.reach, 0.5)
	f = Spin.fractions([_s(&"z", 1)], &"x")
	_near("Z↑ süz, X ölç: yukarı", f.up, 0.5)
	f = Spin.fractions([_s(&"z", 1), _s(&"x", 1)], &"z")
	_near("Z↑, X↑ süz, Z ölç: yukarı (bilgi silindi)", f.up, 0.5)
	_near("Z↑, X↑: ulaşan oran", f.reach, 0.25)
	f = Spin.fractions([_s(&"z", 1), _s(&"x", 1)], &"x")
	_near("Z↑, X↑ süz, X ölç: yukarı", f.up, 1.0)
	f = Spin.fractions([_s(&"z", 1), _s(&"z", -1)], &"z")
	_near("Z↑ sonra Z↓: hiç atom geçmez", f.reach, 0.0)
	f = Spin.fractions([_s(&"x", 1), _s(&"z", 1), _s(&"x", 1)], &"z")
	_near("X↑, Z↑, X↑ süz, Z ölç: yukarı", f.up, 0.5)
	# Örnekleme ile uyum
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var ups := 0
	var reached := 0
	for i in 20000:
		var r: Dictionary = Spin.sample_atom(rng, [_s(&"z", 1), _s(&"x", 1)], &"z")
		if r.absorbed_at == -1:
			reached += 1
			if r.result > 0:
				ups += 1
	_near("örnekleme: ulaşan oran ≈ 0,25", float(reached) / 20000.0, 0.25, 0.01)
	_near("örnekleme: yukarı oranı ≈ 0,5", float(ups) / float(reached), 0.5, 0.02)
	print("BAŞARISIZ: %d" % failures if failures > 0 else "HEPSİ GEÇTİ")
	quit(failures)
