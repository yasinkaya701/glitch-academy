extends SceneTree
## Hikâye kayma sayılarının fizikle tuttuğunu doğrular (docs/FIZIK_KAYMALARI.md).
const Newton = preload("res://stations/newton/newton_sim.gd")
const Shot = preload("res://stations/projectile/projectile_sim.gd")
const Hit = preload("res://stations/collision/collision_sim.gd")

var failures := 0

func _near(label: String, got: float, want: float, tolerance: float = 0.001) -> void:
	var ok := absf(got - want) <= tolerance
	print("%s  %s  (beklenen %s, bulunan %s)" % ["ok " if ok else "HATA", label, str(want), str(snappedf(got, 0.0001))])
	if not ok:
		failures += 1

func _init() -> void:
	# Newton Kızağı
	_near("2 kg, 10 N → ivme", Newton.acceleration(10.0, 2.0), 5.0)
	_near("5 kg, 10 N → ivme", Newton.acceleration(10.0, 5.0), 2.0)
	_near("cihaz (bozuk) ivme, 5 kg", Newton.faulty_acceleration(10.0, 5.0), 10.0)
	_near("40 m, 4 s için ivme", Newton.required_acceleration(40.0, 4.0), 5.0)
	_near("40 m, 4 s, 6 kg için kuvvet", Newton.required_force(40.0, 4.0, 6.0), 30.0)
	_near("bozuk F=5 N, 6 kg: 40 m süresi", Newton.time_to_cover(40.0, Newton.acceleration(5.0, 6.0)), 9.798, 0.01)
	# Atış Alanı
	_near("45 m düşüş süresi", Shot.fall_time(45.0), 3.0)
	_near("45 m, 20 m/s menzil", Shot.range_for(45.0, 20.0), 60.0)
	_near("45 m, 60 m hedefi için hız", Shot.speed_for_range(45.0, 60.0), 20.0)
	_near("yatay ve serbest düşüş aynı sürede", Shot.fall_time(20.0), 2.0)
	_near("bozuk süre, 20 m/s", Shot.faulty_fall_time(45.0, 20.0), 5.4, 0.001)
	_near("yanlış v=15: menzil", Shot.range_for(45.0, 15.0), 45.0)
	# Çarpışma Hattı
	_near("2 kg +3, 1 kg −3: ortak hız", Hit.stick_speed(2.0, 3.0, 1.0, -3.0), 1.0)
	_near("cihaz (bozuk) hız", Hit.faulty_stick_speed(2.0, 3.0, 1.0, -3.0), 3.0)
	_near("3 kg +4, B 5 kg için durdurma hızı", Hit.speed_to_stop(3.0, 4.0, 5.0), -2.4)
	_near("durdurma: sonuç momentum", Hit.momentum(3.0, 4.0, 5.0, -2.4), 0.0)
	var e := Hit.elastic(2.0, 3.0, 2.0, -3.0)
	_near("eşit kütle esnek: hızlar yer değiştirir", e.x, -3.0)
	_near("enerji korunumu (esnek)", Hit.kinetic(2.0, e.x) + Hit.kinetic(2.0, e.y), Hit.kinetic(2.0, 3.0) + Hit.kinetic(2.0, -3.0))
	var lost := Hit.kinetic(2.0, 3.0) + Hit.kinetic(1.0, -3.0) - Hit.kinetic(3.0, 1.0)
	_near("yapışan çarpışmada kaybolan enerji (J)", lost, 12.0)
	print("BAŞARISIZ: %d" % failures if failures > 0 else "HEPSİ GEÇTİ")
	quit(failures)
