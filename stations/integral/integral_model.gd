extends RefCounted
## Birimlerin tamamı SI zaman (s) ve hacim (L) cinsindedir.
## Debi q(t)=2+t L/s, 0 <= t <= 8 s; hacim q'nun integralidir.


static func flow_at(time: float) -> float:
	return 2.0 + maxf(time, 0.0)


static func volume_at(time: float) -> float:
	var t := maxf(time, 0.0)
	return 2.0 * t + 0.5 * t * t


static func broken_volume_at(time: float) -> float:
	var t := maxf(time, 0.0)
	return flow_at(t) * t


static func time_for_volume(volume: float) -> float:
	return sqrt(4.0 + 2.0 * maxf(volume, 0.0)) - 2.0


static func left_sum(time: float, slices: int) -> float:
	if slices <= 0:
		return 0.0
	var dt := maxf(time, 0.0) / float(slices)
	var total := 0.0
	for index in range(slices):
		total += flow_at(float(index) * dt) * dt
	return total
