extends SceneTree
const Circ = preload("res://scripts/physio/circulation.gd")
func _init() -> void:
	for pair in [[72.0, 1.0], [110.0, 1.6], [150.0, 2.1], [180.0, 2.1], [60.0, 2.1]]:
		var c = Circ.new()
		c.heart_rate = pair[0]
		c.demand = pair[1]
		for i in 1500:
			c.advance(0.01)
		var b: Dictionary = c.last_beat
		print("hız %3d ihtiyaç x%.1f  atım hacmi %2d mL  debi %.1f L/dk  (hız×SV = %.1f)  doku %.2f" % [pair[0], pair[1], b.stroke_volume, b.cardiac_output, pair[0] * b.stroke_volume / 1000.0, b.tissue])
	quit()
