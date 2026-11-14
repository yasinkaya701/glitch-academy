extends SceneTree
## Uç durumlarda motorun sayısal olarak sağlam kaldığını denetler (NaN, patlama, negatif hacim).
const Circ = preload("res://scripts/physio/circulation.gd")

var failures := 0

func _check(label: String, c) -> void:
	for t in 1500:
		c.advance(0.01)
	var bad := false
	for id in c.net.nodes:
		var n = c.net.nodes[id]
		if is_nan(n.volume) or is_nan(n.pressure) or n.volume < 0.0 or n.pressure > 600.0 or n.o2 < 0.0 or n.o2 > 1.0:
			bad = true
			print("  ! ", id, " vol ", n.volume, " p ", n.pressure, " o2 ", n.o2)
	var total: float = c.net.total_volume()
	print("%-28s %s  toplam hacim %.0f  debi %.1f  MAP %.0f" % [label, "BOZUK" if bad else "ok", total, c.last_beat.get("cardiac_output", -1.0), c.last_beat.get("map", -1.0)])
	if bad:
		failures += 1

func _init() -> void:
	var start: float = Circ.new().net.total_volume()
	print("başlangıç toplam hacim %.0f" % start)
	var c = Circ.new()
	for v in Circ.VALVES:
		c.set_valve(v, false)
	_check("hiç kapak yok", c)
	c = Circ.new()
	for v in Circ.VALVES:
		c.set_valve(v, true, true)
	_check("tüm kapaklar ters", c)
	c = Circ.new()
	for v in Circ.VESSELS:
		c.set_clamp(v, 1.0)
	_check("tüm damarlar kapalı", c)
	c = Circ.new()
	c.heart_rate = 220.0
	c.demand = 3.0
	_check("hız 220, ihtiyaç x3", c)
	c = Circ.new()
	c.heart_rate = 30.0
	_check("hız 30", c)
	c = Circ.new()
	for v in Circ.VALVES:
		c.set_valve(v, true, false, 0.0, 0.9)
	_check("tüm kapaklar yetersiz", c)
	c = Circ.new()
	c.set_valve(Circ.AORTIC, true, true)
	c.set_valve(Circ.MITRAL, true, true)
	_check("sol kalp kapakları ters", c)
	var kept := Circ.new()
	var before: float = kept.net.total_volume()
	for t in 3000:
		kept.advance(0.01)
	print("hacim korunumu: %.4f -> %.4f" % [before, kept.net.total_volume()])
	if absf(before - kept.net.total_volume()) > 0.5:
		failures += 1
	print("BAŞARISIZ: %d" % failures if failures > 0 else "HEPSİ GEÇTİ")
	quit(failures)
