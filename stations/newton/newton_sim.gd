extends RefCounted
## Newton Kızağı kuralı. Hava yastıklı ray (sürtünmesiz), sabit itiş kuvveti. Çizimden bağımsız.
## Gerçek: a = F / m. Kayma: cihaz a = F kabul ediyor, kütleyi hesaba katmıyor.

const G := 10.0


## Gerçek ivme (m/s²).
static func acceleration(force: float, mass: float) -> float:
	return force / maxf(mass, 0.001)


## Cihazın (bozuk) ivmesi: kütleyi yok sayar.
static func faulty_acceleration(force: float, _mass: float) -> float:
	return force


## Durgun halden `distance` kadar yolu gitme süresi: d = ½·a·t².
static func time_to_cover(distance: float, accel: float) -> float:
	return sqrt(2.0 * distance / maxf(accel, 0.0001))


## Verilen süre ve yol için gereken ivme: a = 2d / t².
static func required_acceleration(distance: float, time: float) -> float:
	return 2.0 * distance / (time * time)


## Verilen süre ve yol için gereken kuvvet.
static func required_force(distance: float, time: float, mass: float) -> float:
	return mass * required_acceleration(distance, time)


## t anındaki hız ve konum (durgun başlangıç).
static func state_at(accel: float, time: float) -> Dictionary:
	return {"speed": accel * time, "position": 0.5 * accel * time * time}
