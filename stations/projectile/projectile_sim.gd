extends RefCounted
## Atış Alanı kuralı. Yatay atış: yatay hız sabit, düşey hareket serbest düşme. Hava direnci yok. Çizimden bağımsız.
## Kayma: cihaz yatay ve düşey hareketi birbirine bağlıyor (yatay hız arttıkça düşüşü yavaşlatıyor).

const G := 10.0


## Yükseklikten düşüş süresi, yatay hızdan bağımsız: t = √(2h/g).
static func fall_time(height: float) -> float:
	return sqrt(2.0 * height / G)


## Yatay menzil: x = v₀·t.
static func range_for(height: float, horizontal_speed: float) -> float:
	return horizontal_speed * fall_time(height)


## Hedef menzil için gereken yatay hız.
static func speed_for_range(height: float, target_range: float) -> float:
	return target_range / fall_time(height)


## Cihazın bozuk düşüş süresi: yatay hız arttıkça süre uzuyor.
static func faulty_fall_time(height: float, horizontal_speed: float) -> float:
	return fall_time(height) * (1.0 + 0.04 * horizontal_speed)


## t anında konum ve hız bileşenleri. Düşey eksen aşağı pozitif.
static func state_at(horizontal_speed: float, time: float) -> Dictionary:
	return {"x": horizontal_speed * time, "drop": 0.5 * G * time * time, "vx": horizontal_speed, "vy": G * time}
