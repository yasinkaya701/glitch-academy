extends SceneTree
const Circ = preload("res://scripts/physio/circulation.gd")

func _run(c, seconds := 8.0) -> Dictionary:
	var t := 0.0
	while t < seconds:
		c.advance(0.01)
		t += 0.01
	return c.last_beat

func _show(label: String, b: Dictionary) -> void:
	print("%-22s CO %.1f L/dk SV %.0f EDV %.0f ESV %.0f EF %.2f BP %.0f/%.0f MAP %.0f CVP %.1f PAP %.1f O2a %.2f O2v %.2f doku %.2f" % [label, b.cardiac_output, b.stroke_volume, b.edv, b.esv, b.ef, b.sbp, b.dbp, b.map, b.cvp, b.pap, b.o2_arterial, b.o2_venous, b.tissue])

func _init() -> void:
	var c = Circ.new()
	_show("saglikli", _run(c))
	print("  bulgular: ", c.findings(), " saglikli=", c.is_healthy())
	c.set_valve(Circ.MITRAL, true, false, 0.0, 0.7)
	_show("mitral yetersiz", _run(c)); print("  ", c.findings())
	c.repair_valve(Circ.MITRAL)
	c.set_valve(Circ.AORTIC, true, false, 0.7)
	_show("aort darlik", _run(c)); print("  ", c.findings())
	c.repair_valve(Circ.AORTIC)
	c.set_valve(Circ.AORTIC, true, true)
	_show("aort ters takili", _run(c))
	c.repair_valve(Circ.AORTIC)
	c.set_clamp(Circ.LUNGS, 0.7)
	_show("akciger kelepce", _run(c))
	c.set_clamp(Circ.LUNGS, 0.0)
	c.set_septal_defect(Circ.VSD, 1.0)
	_show("VSD", _run(c)); print("  ", c.findings())
	c.set_septal_defect(Circ.VSD, 0.0)
	c.heart_rate = 140.0; c.demand = 2.5
	_show("egzersiz 140", _run(c, 12.0))
	c.heart_rate = 72.0; c.demand = 1.0
	_show("toparlanma", _run(c, 12.0)); print("  saglikli=", c.is_healthy())
	c.add_blood(-800.0)
	_show("kanama -800", _run(c))
	quit()
